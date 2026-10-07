# zukkolar-mobile

The Zukkolar app for Android and iOS (Flutter). Same design, text and features as the web app
([zukkolar.uz](https://zukkolar.uz), repo `gamify`); it talks to the web app's `/api/v1`.

## Run

```bash
flutter pub get
flutter run                                                   # against https://zukkolar.uz
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000   # local backend, Android emulator
flutter run --dart-define=API_BASE_URL=http://localhost:3000  # local backend, iOS simulator
```

## Checks

```bash
flutter analyze
flutter test
flutter test test_shots --update-goldens   # renders the screens to test_shots/shots/*.png for a visual check
```

## Layout

```
lib/core/theme/     colours, gradients, shadows, type scale — the tokens of the web app's globals.css
lib/core/widgets/   shared pieces ported from the web (Button, Field, Logo, Avatar, page background)
lib/core/i18n/      t("auth.loginTitle") — same keys as the web
lib/core/api/       HTTP client, session token (Keychain / Keystore)
lib/features/       one folder per feature, named like src/features in the web app
assets/i18n/uz.json a copy of the web app's messages/uz.json — copy it again when the web text changes
assets/brand/       logo; app-icon*.png and splash.png are cut from logo-source.png
assets/chess/       the web app's piece pictures (see its README for their licence)
```

Mobile-only strings go in `assets/i18n/uz.mobile.json`.

## Icons and launch screen

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## App id

`uz.zukkolar` on both platforms (Android `applicationId`, iOS bundle identifier).
