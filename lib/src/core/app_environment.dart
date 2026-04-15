import 'package:flutter/foundation.dart';

/// Configuración de entorno de la app.
///
/// La URL base se inyecta con `--dart-define=FAN_API_BASE_URL=...` para poder
/// apuntar fácil a distintos ambientes sin meter paquetes de configuración.
class AppEnvironment {
  static const String _defaultApiBaseUrl = 'http://127.0.0.1:8000/api';
  static const String _defaultGoogleWebClientId =
      '160522199946-9dnsan0lj8kiv3ecq6puapa1972am42i.apps.googleusercontent.com';

  static const String _rawApiBaseUrl = String.fromEnvironment(
    'FAN_API_BASE_URL',
    defaultValue: _defaultApiBaseUrl,
  );

  static const String _rawGoogleWebClientId = String.fromEnvironment(
    'FAN_GOOGLE_WEB_CLIENT_ID',
    defaultValue: _defaultGoogleWebClientId,
  );

  static String get apiBaseUrl {
    final trimmed = _rawApiBaseUrl.trim();

    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }

    return trimmed;
  }

  static bool get usesDefaultApiBaseUrl => apiBaseUrl == _defaultApiBaseUrl;

  static String get googleWebClientId => _rawGoogleWebClientId.trim();

  static bool get hasGoogleWebClientId => googleWebClientId.isNotEmpty;

  static bool get showDeveloperAnnotations => !kReleaseMode;
}
