import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Production Railway Backend URL
  static String productionUrl = 'https://my-project-production-f607.up.railway.app';
  static const String localUrl = 'http://localhost:3000';

  // Configurable base URL.
  // When running locally on PC/browser/simulator: uses http://localhost:3000
  // When running deployed (e.g. Netlify): uses productionUrl
  static String get serverUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      final isLocal = host == 'localhost' || host == '127.0.0.1' || host.isEmpty;
      return isLocal ? localUrl : productionUrl;
    }

    if (kReleaseMode) {
      return productionUrl;
    }
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    } catch (_) {}

    return localUrl;
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
