# Login & Logout — the whole flow

Every step from a tap on **SIGN IN** to the dashboard, and back out again.
Nothing is skipped: each hop names the file it happens in.

- [The cast](#the-cast)
- [Startup: which screen opens](#startup-which-screen-opens)
- [Login, step by step](#login-step-by-step)
- [Validation](#validation)
- [Errors and the toast](#errors-and-the-toast)
- [Redirecting both ways](#redirecting-both-ways)
- [Logout, step by step](#logout-step-by-step)
- [Session expiry mid-use](#session-expiry-mid-use)
- [What is tested](#what-is-tested)
- [Wiring a new screen into it](#wiring-a-new-screen-into-it)

---

## The cast

| Piece | File | Job |
| --- | --- | --- |
| `LoginForm` | `features/auth/presentation/widgets/login_form.dart` | Collects and validates input |
| `LoginPage` | `features/auth/presentation/pages/login_page.dart` | Calls the provider, shows the toast |
| `AuthProvider` | `features/auth/presentation/providers/auth_provider.dart` | Holds the session state, notifies the app |
| `AuthGate` | `features/auth/presentation/widgets/auth_gate.dart` | Picks the screen from that state |
| `AuthRepository` | `features/auth/domain/repositories/` | The contract (interface) |
| `AuthRepositoryImpl` | `features/auth/data/repositories/` | API + storage, maps errors |
| `AuthRemoteDataSource` | `features/auth/data/datasources/` | The HTTP calls |
| `AuthInterceptor` | `core/network/auth_interceptor.dart` | Attaches and refreshes the token |
| `TokenStorage` | `core/storage/token_storage.dart` | Keychain / EncryptedSharedPrefs |
| `AppToast` | `core/widgets/app_toast.dart` | The message at the bottom of the screen |

The rule that shapes all of it: **screens never navigate on sign-in or
sign-out.** They change one piece of state, and the gate re-renders. See
[Redirecting both ways](#redirecting-both-ways).

---

## Startup: which screen opens

**Step 1 — build the object graph.** `main.dart` creates one `ApiClient`, wires
it to a repository, and hands that to `AuthProvider`. One instance for the life
of the app: each `ApiClient` carries its own Dio and connection pool.

```dart
_apiClient = ApiClient(
  onSessionExpired: () => _authProvider.onSessionExpired(),
);
final AuthRepository repository = AuthRepositoryImpl(
  remoteDataSource: AuthRemoteDataSource(apiClient: _apiClient),
  tokenStorage: _apiClient.storage,
);
_authProvider = AuthProvider(repository);
_authProvider.bootstrap();
```

**Step 2 — `bootstrap()` asks whether anyone is signed in.** Status starts at
`AuthStatus.unknown`, so `AuthGate` shows `SplashPage`.

**Step 3 — `restoreSession()` decides.** In `AuthRepositoryImpl`:

1. Read the access token from secure storage. **No token → return `null`.** No
   network call, so a first-run launch is instant.
2. There is a token → `GET /v1/auth/me`.
3. Expired token? `AuthInterceptor` refreshes and replays it before this code
   ever sees a failure ([details](architecture.md#on-a-401)).
4. A 401 that survives the refresh means the session is unrecoverable: clear
   the tokens, return `null`.
5. Offline (`connectionError`) → throws `AuthFailure`; `bootstrap()` catches it
   and treats it as signed out, because there is no screen yet on which to show
   an error.

**Step 4 — the status flips** to `authenticated` or `unauthenticated`, and the
gate swaps the splash for the dashboard or the login page.

> The splash is shown for exactly as long as the check takes. It used to
> navigate on a 2-second timer, which raced the real answer.

---

## Login, step by step

### 1. Capture the input

`LoginForm` owns two `TextEditingController`s and a `FocusNode`, so the page
above it stays stateless. Email → password on **next**; **done** submits.

### 2. Dismiss the keyboard, then validate

```dart
void _submit() {
  FocusScope.of(context).unfocus();   // errors would hide behind the keyboard
  if (widget.isSubmitting) return;    // guards a double tap
  if (!(_formKey.currentState?.validate() ?? false)) return;
  widget.onSubmit?.call(_emailController.text.trim(), _passwordController.text);
}
```

The email is **trimmed**, the password is **not** — a trailing space may be
deliberate.

### 3. The page calls the provider

`LoginPage._signIn` — the only place that knows both the UI and the provider:

```dart
try {
  await context.read<AuthProvider>().login(email: email, password: password);
} on AuthFailure catch (failure) {
  if (!context.mounted) return;
  AppToast.error(context, failure.message);
}
```

`context.mounted` matters: the user can leave while the request is in flight,
and using a dead context throws.

### 4. The provider flips to submitting

`AuthProvider.login` sets `isSubmitting = true` and notifies. `LoginPage`
watches only that flag:

```dart
isSubmitting: context.select<AuthProvider, bool>((auth) => auth.isSubmitting),
```

`select`, not `watch`: only this one boolean triggers a rebuild. `CtaButton`
swaps its label for a spinner and stops accepting taps.

The reset lives in a `finally`, not on the success path — the button has to
come back when the password was wrong.

### 5. The repository calls the API

`AuthRemoteDataSource.login` → `POST /v1/auth/login`

```json
{ "email": "anna@bookslane.com", "password": "..." }
```

### 6. Parse the response

`LoginResponse.fromJson` reads app-api's `LoginResponseDto` — flat, snake_case,
no `data` envelope:

```json
{
  "access_token": "...",
  "refresh_token": "...",
  "token_type": "Bearer",
  "expires_in": 900,
  "user": { "id": "...", "email": "..." }
}
```

`user.id` arrives as a UUID string here and as an int elsewhere; `User.parseId`
normalises both to a `String`.

### 7. Persist the tokens — before returning

```dart
await tokenStorage.saveTokens(
  accessToken: response.accessToken,
  refreshToken: response.refreshToken,
);
```

**Skip this and sign-in silently does nothing useful:** every later request goes
out anonymous, because `AuthInterceptor` reads the token from here.

### 8. Return a domain entity

`response.user.toEntity()` → a `User`. Tokens are not returned; nothing above
the data layer handles them.

### 9. The provider stores the session

`_setSession(user)` sets `user`, flips `status` to `authenticated`, and calls
`notifyListeners()`.

### 10. The gate swaps the screen

`AuthGate` rebuilds and returns `DashboardPage`. **No `Navigator` call
anywhere.** The dashboard greets `auth.user?.displayName`.

---

## Validation

Two layers, and both matter.

**Client-side** (`LoginForm`), so an obviously bad email never becomes a round
trip:

| Field | Rule | Message |
| --- | --- | --- |
| Email | not empty | `Please enter your email` |
| Email | `AppConstants.emailPattern` | `Please enter a valid email address` |
| Password | not empty | `Please enter your password` |

**Server-side** (`app-api`'s `LoginDto`): valid email, password 8-255 chars.
NestJS returns those in `message` as a string or a list, and
`AuthRepositoryImpl._serverMessage` pulls the first one out for the toast.

The client rules are deliberately looser than the server's — never tell someone
their *existing* password is "too short" at the sign-in screen.

---

## Errors and the toast

`DioException` stops at the data layer. `AuthRepositoryImpl._mapDioError`
converts it to an `AuthFailure` carrying a message meant for a person, so no
widget ever inspects a status code.

| Cause | `AuthFailureKind` | Message |
| --- | --- | --- |
| 401 on login | `invalidCredentials` | Incorrect email or password. |
| Timeout | `network` | The server took too long to respond. Please try again. |
| No connection | `network` | Cannot reach the server. Check your connection and try again. |
| Bad TLS certificate | `network` | The server could not be verified. |
| 4xx with a message | `server` | *the server's own message* |
| 5xx | `server` | Something went wrong on our side. Please try again. |
| Unparseable body | `server` | The server sent something unexpected. Please try again. |

`AppToast.error` shows it: red background, icon, one at a time — a queue of
stale errors helps nobody. `LoginPage` also has a bare `catch` as a backstop;
nothing should reach it, but a crash on the sign-in screen would trap the user
with no way forward.

---

## Redirecting both ways

`AuthGate` **derives** the screen instead of pushing routes:

```dart
final status = context.select<AuthProvider, AuthStatus>((p) => p.status);

return switch (status) {
  AuthStatus.unknown        => const SplashPage(),
  AuthStatus.authenticated  => const DashboardPage(),
  AuthStatus.unauthenticated => const LoginPage(),
};
```

That single expression is the entire redirect requirement:

- **Signed in and the login page opens?** It cannot. While `status` is
  `authenticated` the gate only ever builds `DashboardPage`.
- **Signed out and the dashboard opens?** Same, in reverse.
- **After signing in**, the login page is *replaced* — it isn't sitting under a
  route waiting for a back gesture.
- **After signing out**, the dashboard is disposed, so no screen keeps polling
  with a dead token.

A push-based version would need a redirect check on every route, and would still
leave stale screens on the stack. This has one rule in one place.

---

## Logout, step by step

**1. The control.** `DashboardAppBar` shows a sign-out icon when
`onLogoutPressed` is passed. It's optional, so other screens can reuse the bar
without one.

**2. Confirm.** `_confirmLogout` opens an `AlertDialog` — *"Log out? You will
need to sign in again to continue."* Cancel returns `false` and nothing
happens.

**3. `AuthProvider.logout()`** sets `isSubmitting`, then calls the repository.

**4. Tell the server**, then clear locally:

```dart
try {
  await remoteDataSource.logout();   // POST /v1/auth/logout → 204
} on DioException {
  // deliberately swallowed
} finally {
  await tokenStorage.clear();
}
```

The swallowed error is the point: **a user who taps "Log out" must end up
logged out on this device**, even with no connection or an already-dead token.
Failing here would strand them signed in.

**5. `_setSession(null)`** clears the user, sets `unauthenticated`, notifies.

**6. The gate swaps back** to `LoginPage`, and a success toast confirms it.
Again, no `Navigator` call.

---

## Session expiry mid-use

A token can die while someone is using the app. That path is automatic:

1. A request 401s.
2. `AuthInterceptor` refreshes and replays it — the user sees nothing.
3. If the refresh also fails, the interceptor clears the tokens and calls
   `onSessionExpired`.
4. `main.dart` routed that to `AuthProvider.onSessionExpired()`, which sets
   `unauthenticated`.
5. `AuthGate` returns them to the login page, from whatever screen they were on.

Concurrency detail worth knowing: several requests failing at once share **one**
refresh, because app-api rotates refresh tokens and parallel refreshes would log
the user out. See [architecture.md](architecture.md#on-a-401).

---

## What is tested

`test/features/auth/auth_flow_test.dart` — 10 widget tests against a fake
repository, no network:

- splash while the session is being checked
- no stored session → login page
- stored session → dashboard, greeting the real user
- valid credentials → dashboard, repository called once
- spinner while the request is in flight
- rejected sign-in → toast, stays on login, button recovers
- invalid input never reaches the API
- logout confirmed → back to login
- logout cancelled → session kept
- `onSessionExpired()` mid-session → back to login

`test/features/auth/auth_repository_impl_test.dart` — 10 unit tests on parsing,
token persistence, id normalisation and the 401 path.
`test/core/network/auth_interceptor_test.dart` — 4 on the bearer header,
refresh-and-replay, failed refresh, and single-flight concurrency.

```sh
flutter test
```

---

## Wiring a new screen into it

**Read the user:**

```dart
final user = context.watch<AuthProvider>().user;
```

Prefer `select` when you need one field — it rebuilds far less:

```dart
final name = context.select<AuthProvider, String>(
  (auth) => auth.user?.displayName ?? 'there',
);
```

**Add a sign-out button anywhere:**

```dart
await context.read<AuthProvider>().logout();
```

`read`, not `watch`, inside a callback — you want the value, not a subscription.

**Do not** guard a screen with a manual "am I logged in" check. If it is below
`AuthGate` and the status is `authenticated`, a user is signed in; when that
stops being true the screen is disposed for you.
