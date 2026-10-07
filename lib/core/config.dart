/// Build-time settings. Override with `--dart-define`, e.g. for a local backend on the Android emulator:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000`
abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://zukkolar.uz');
}
