import 'package:flutter/foundation.dart';

class ApiConfig {
  // Production Railway Backend URL
  static String productionUrl = 'https://my-project-production-f607.up.railway.app';
  static const String localUrl = 'http://localhost:3000';

  // Configurable base URL.
  // - Web: dynamically switches to localUrl when testing on localhost, productionUrl on Netlify.
  // - Mobile (Android APK / iOS): always connects to live Railway productionUrl so APK works on all phones.
  static String get serverUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      final isLocal = host == 'localhost' || host == '127.0.0.1' || host.isEmpty;
      return isLocal ? localUrl : productionUrl;
    }

    // Always connect to live Railway production backend on mobile devices
    return productionUrl;
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
