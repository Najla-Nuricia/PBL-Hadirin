import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  /// Base URL backend FastAPI Hadirin.
  /// Android Emulator: 10.0.2.2:8000
  /// Web / Windows / Desktop: 127.0.0.1:8000
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {}
    return 'http://127.0.0.1:8000';
  }
}

