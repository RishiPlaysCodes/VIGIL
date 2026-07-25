/// Application-wide configuration loaded from compile-time environment.
/// Use `--dart-define` to override at build time.
class AppConfig {
  AppConfig._();

  /// Base URL for the backend API.
  /// Override with: --dart-define=POCKET_GUARDIAN_API_URL=https://api.yourapp.com
  static const String apiBaseUrl = String.fromEnvironment(
    'POCKET_GUARDIAN_API_URL',
    defaultValue: 'https://pocket-guardian-backend.onrender.com/api',
  );

  /// Whether the app is running in production mode.
  static const bool isProduction = String.fromEnvironment(
    'POCKET_GUARDIAN_ENV',
    defaultValue: 'development',
  ) == 'production';

  /// Minimum PIN length for security PIN.
  static const int minPinLength = 4;

  /// Maximum PIN length for security PIN.
  static const int maxPinLength = 8;

  /// Default countdown seconds before alarm triggers.
  static const int defaultCountdownSeconds = 10;

  /// HTTP request timeout in seconds.
  static const int httpTimeoutSeconds = 60;

  /// Maximum retry attempts for failed API calls.
  static const int maxRetryAttempts = 2;

  /// Location update distance filter in meters.
  static const int locationDistanceFilterMeters = 10;

  /// Sensor monitoring window for strong movement detection.
  static const int sensorWindowSeconds = 2;

  /// App version for display purposes.
  static const String appVersion = '1.0.0';
}
