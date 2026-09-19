import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Production Railway Backend URL
  static const String _productionUrl = 'https://my-project-production-f607.up.railway.app';

  // Configurable base URL.
  // Defaults to production URL when built for release, or localhost/10.0.2.2 in debug.
  static String get serverUrl {
    if (kReleaseMode) {
      return _productionUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    } else {
      return 'http://localhost:3000';
    }
  }

  static String get baseUrl => '$serverUrl/api';

  static String getImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$serverUrl$cleanPath';
  }

  static Map<String, String> headers([String? token]) {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      map['Authorization'] = 'Bearer $token';
    }
    return map;
  }
}
