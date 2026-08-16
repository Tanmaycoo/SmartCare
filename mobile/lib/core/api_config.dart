/// Central API Configuration for SmartCare Mobile Client.
class ApiConfig {
  /// Optional build-time parameter override:
  /// flutter run --dart-define=SMARTCARE_API_BASE_URL=https://...
  static const String _configuredBaseUrl = String.fromEnvironment(
    'SMARTCARE_API_BASE_URL',
  );

  /// Default production cloud API URL on Render
  static const String defaultCloudBaseUrl =
      'https://smartcare-api-r14o.onrender.com';

  /// Centralized getter for the API base URL.
  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }
    return defaultCloudBaseUrl;
  }
}
