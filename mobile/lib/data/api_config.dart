import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Base URL backend FastAPI Hadirin.
  /// Bisa di-override saat build/run via `--dart-define=API_BASE_URL=http://<IP-PC>:8000`.
  /// Default Android Emulator: http://10.0.2.2:8000 | Web/Desktop: http://127.0.0.1:8000.
  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl.endsWith('/')
          ? _overrideBaseUrl.substring(0, _overrideBaseUrl.length - 1)
          : _overrideBaseUrl;
    }
    if (kIsWeb) return 'http://127.0.0.1:8000';
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {}
    return 'http://127.0.0.1:8000';
  }
}
