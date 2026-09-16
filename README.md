# bookslane_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

#Open in Real device
adb devices

You want RZ8R409BKGP device — not offline, not unauthorized.

If it stays offline after a replug, revoke the old pairing and start fresh: Settings → Developer options → Revoke USB debugging authorizations, then replug and accept the new prompt.

One thing I should flag: I ran adb kill-server/start-server earlier while diagnosing, and a server restart can drop a device into offline until it re-handshakes. Your run_dev.sh run worked after that, so the state probably broke during the failed install — but a replug clears it either way.

Run cd /Users/ahirdas/Documents/Sites/bookslane_app && ./scripts/run_dev.sh

If the install fails again once it's back online

Get the real reason, which Flutter hid last time:
adb install -r build/app/outputs/flutter-apk/app-debug.apk

On a Samsung M51 the most likely message is INSTALL_FAILED_USER_RESTRICTED. Samsung blocks sideloading by default, and the fix is in Developer options:

Install via USB → on
Verify apps over USB → off

Some Samsung firmware greys out "Install via USB" until a SIM is in and you're signed into a Samsung account — that's a known quirk, not something wrong with the build.

The app itself is fine: the APK built in 60s, and adb reverse is already set up, so once the install goes through it'll reach the API on localhost:3002 through the cable. Start the API before signing in:

cd /Users/ahirdas/Documents/Sites/bookslane-api && npx nest start app-api