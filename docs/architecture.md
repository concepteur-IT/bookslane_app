# Bookslane App — Architecture

How this Flutter app is organised, and the rules that keep it that way.

## Layers

The app follows a feature-first Clean Architecture split. The rule that makes
it work is one-directional dependency:

```
presentation  ──▶  domain  ◀──  data
   (widgets)      (contracts)   (API, storage)
```

**Domain never imports data or presentation.** It holds entities and abstract
repositories — plain Dart, no Dio, no JSON, no Flutter. That is what lets you
swap the API, add caching, or test a screen against a fake without touching
business rules.

`presentation` and `data` both point *inward* at `domain`, and never at each
other.

### Why the implementation lives in `data/`

`AuthRepositoryImpl` needs Dio and secure storage. If it sat in
`domain/repositories/`, the domain layer would transitively depend on the data
layer and the arrow would point both ways. So:

| File | Layer |
| --- | --- |
| `domain/repositories/auth_repository.dart` | the interface — what the app can do |
| `data/repositories/auth_repository_impl.dart` | the implementation — how it happens |

## Folder map

```
lib/
├── core/                     shared by every feature
│   ├── config/               environments, API endpoints, constants, assets
│   ├── network/              ApiClient (Dio) + AuthInterceptor
│   ├── storage/              TokenStorage
│   ├── theme/                design tokens + ThemeData
│   └── widgets/              shared UI components
└── features/
    └── <feature>/
        ├── data/
        │   ├── datasources/  talks HTTP, knows JSON
        │   ├── models/       wire formats, with fromJson / toEntity
        │   └── repositories/ implementations
        ├── domain/
        │   ├── entities/     plain objects the app reasons about
        │   └── repositories/ abstract contracts
        └── presentation/
            ├── pages/        whole screens
            └── widgets/      pieces of those screens
```

`core/widgets/` is for widgets with **no feature knowledge** that two or more
screens could use. Anything that knows about auth, books or orders belongs in
that feature's own `presentation/widgets/`.

## Entities vs models

`User` (domain) and `UserModel` (data) look alike on purpose.

- `UserModel` mirrors the wire format and owns `fromJson`. When the API renames
  a field, only this file changes.
- `User` is what the rest of the app uses. It has no idea JSON exists.

`UserModel.toEntity()` is the bridge, and repositories return entities.

### User ids accept an int or a String

app-api sends a UUID string; other services send numeric ids. `User.id` is
always a `String`, normalised on the way in:

```dart
User.parseId(7)        // '7'
User.parseId('7')      // '7'      — equal to the above
User.parseId('c7f1')   // 'c7f1'
User.parseId(null)     // throws FormatException
```

Normalising at the boundary means comparison, routing and storage never depend
on which type arrived. Anything else throws immediately, at the edge, rather
than surfacing as a mysterious null inside a screen.

`User.name` is nullable — app-api's `AppUserDto` carries only `id` and `email`.
Use `user.displayName` for anything shown on screen; it falls back to the email.

## The auth flow

```
LoginForm ──▶ AuthRepository.login(email, password)
                   │
                   ├─▶ AuthRemoteDataSource ──▶ POST /v1/auth/login
                   │                              └─▶ LoginResponse.fromJson
                   └─▶ TokenStorage.saveTokens(...)   (secure storage)
                                    │
                                    ▼
        every later request ──▶ AuthInterceptor attaches
                                Authorization: Bearer <access_token>
```

The repository persists the tokens itself and returns only the `User`. Nothing
above the data layer handles tokens.

### Response shape

`/v1/auth/login` and `/v1/auth/refresh` both return app-api's
`LoginResponseDto` — **flat, snake_case, no `data` envelope**:

```json
{
  "access_token": "...",
  "refresh_token": "...",
  "token_type": "Bearer",
  "expires_in": 900,
  "user": { "id": "...", "email": "..." }
}
```

### On a 401

`AuthInterceptor` refreshes and replays the original request, so callers never
see the failure. Three details matter:

1. The refresh goes out on a **separate Dio**, or its own 401 would recurse.
2. Retried requests are flagged (`extra['auth_retried']`), so a permanently
   rejected token cannot loop.
3. Concurrent 401s share **one** refresh — the API rotates refresh tokens, so
   parallel refreshes would log the user out.

A failed refresh clears the tokens and fires `onSessionExpired`.

## Configuration

Everything environment-dependent is resolved at compile time in
`core/config/app_config.dart`:

```sh
flutter run                                          # dev
flutter run --dart-define=ENV=staging
flutter build apk --dart-define=ENV=production
```

| Where the app runs | API host |
| --- | --- |
| Android emulator | `10.0.2.2:3002` |
| iOS simulator, desktop, web | `localhost:3002` |
| Physical device | your machine's LAN address |

The app cannot discover your machine's address at runtime — it runs on the
phone. `./scripts/run_dev.sh` resolves it on the Mac and bakes it in, or uses
`adb reverse` over USB when an Android device is attached.

Precedence: `API_BASE_URL` > `DEV_HOST` > the platform default. Both overrides
are ignored in production.

**No secrets in config.** Anything compiled into the app ships to every device
and is readable from the binary. The app only ever holds the tokens login
returns, in `flutter_secure_storage` — Keychain on iOS, EncryptedSharedPrefs on
Android.

## UI conventions

Design tokens live in `core/theme/` and are documented in
[`lib/core/theme/README.md`](../lib/core/theme/README.md). The short version:

- No raw values in feature code — no `Color(0xFF...)`, no `fontSize: 17`.
- Name colours by role: `AppColors.ctaBackground`, not `AppPalette.red500`.
- Component styling belongs in `app_theme.dart`, not in the widget.

## Adding a feature

1. `domain/entities/` — what it is, in plain Dart.
2. `domain/repositories/` — an abstract class saying what you can do with it.
3. `data/models/` — the wire format, with `fromJson` and `toEntity`.
4. `data/datasources/` — the HTTP calls, using `ApiEndpoints`.
5. `data/repositories/` — the implementation.
6. `presentation/` — pages and widgets, depending only on the domain contract.

Steps 1-5 are testable without Flutter. See
`test/features/auth/auth_repository_impl_test.dart` for the pattern: a fake
`HttpClientAdapter` scripts the API, a fake `TokenStorage` replaces the
keychain, and no network or platform channel is involved.

## Testing

```sh
flutter test
flutter analyze
```

Tests mirror `lib/`: `test/core/network/auth_interceptor_test.dart`,
`test/features/auth/auth_repository_impl_test.dart`.
