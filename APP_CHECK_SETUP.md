# Firebase App Check Setup

This project now initializes Firebase App Check in `lib/main.dart`.

## What is configured in code

- Android:
  - Release builds use `Play Integrity`.
  - Debug builds use the App Check `Debug` provider.
- iOS/macOS:
  - Release builds use `Device Check`.
  - Debug builds use the App Check `Debug` provider.
- Web:
  - Uses reCAPTCHA v3 provider.
  - Site key must be passed via Dart define:
    - `--dart-define=APP_CHECK_WEB_RECAPTCHA_SITE_KEY=YOUR_RECAPTCHA_V3_SITE_KEY`
- Windows/Linux/Fuchsia:
  - App Check activation is skipped.

## Firebase Console registration steps

1. Open Firebase Console -> Build -> App Check.
2. Register each app:
   - Android app `com.pornosocial.app`: choose `Play Integrity`.
   - iOS app `com.pornosocial.pornoSocial`: choose `Device Check`.
   - Web app `porno_social (web)`: choose `reCAPTCHA v3` and copy site key.
3. For the web app, keep enforcement off until the site key is configured and deployed.
4. Add the web site key when running/building web:
   - Local run:
     - `flutter run -d chrome --dart-define=APP_CHECK_WEB_RECAPTCHA_SITE_KEY=YOUR_KEY`
   - Web build:
     - `flutter build web --release --dart-define=APP_CHECK_WEB_RECAPTCHA_SITE_KEY=YOUR_KEY`
5. After confirming tokens are being accepted in App Check metrics, enable enforcement for Firestore, Storage, and Functions.

## Debug provider notes

- Android/iOS debug builds will require registering debug tokens in App Check.
- You can view debug token output in logs when running the app locally, then add those tokens in Firebase Console -> App Check -> Manage debug tokens.

## CI/CD note

If you build Flutter web in CI, add secret `APP_CHECK_WEB_RECAPTCHA_SITE_KEY` and pass it to Flutter with `--dart-define`.

For GitHub Actions in this repository:

1. Open GitHub -> Settings -> Secrets and variables -> Actions.
2. Create repository secret `APP_CHECK_WEB_RECAPTCHA_SITE_KEY`.
3. The workflow in `.github/workflows/deploy.yml` will automatically inject it into the web build as a Dart define.

## Pre-enforcement checklist (Firestore + Cloud Functions)

Before turning App Check enforcement on, verify these items to avoid lockouts:

1. Confirm all client platforms are registering valid App Check tokens:
  - Android release (Play Integrity)
  - iOS release (Device Check)
  - Web release (reCAPTCHA v3 key deployed)
2. Confirm debug tokens are added for local/dev devices still in use.
3. Confirm App Check metrics show accepted requests for Firestore and Functions from your active app versions.
4. Confirm your production web build includes:
  - `--dart-define=APP_CHECK_WEB_RECAPTCHA_SITE_KEY=...`
5. Confirm backend-only traffic does not rely on client SDK calls that will suddenly require App Check.
6. Roll out enforcement in stages:
  - Enable Firestore first, monitor errors.
  - Then enable Cloud Functions, monitor errors.
7. Keep a rollback path ready:
  - If traffic drops or users are blocked, temporarily disable enforcement and review App Check metrics + client version adoption.

Recommended validation window before full enforcement: 24-48 hours of normal traffic with no unexplained denied requests.
