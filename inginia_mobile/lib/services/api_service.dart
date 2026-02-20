import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Central API service for managing HTTP requests and authentication
///
/// This service provides:
/// - Automatic platform-specific base URL configuration
/// - Token-based authentication via interceptors
/// - Secure token storage
class ApiService {
  // -----------------------------------------------------------------------------
  // Configuration
  // -----------------------------------------------------------------------------

  /// Get just the host part (IP or domain)
  static String get serverHost {
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '192.168.10.187'; // Computer LAN IP
    if (Platform.isWindows) return 'localhost';
    return '127.0.0.1';
  }

  static String get baseUrl {
    return 'http://$serverHost:8000/api';
  }

  // NOTE: Sur un appareil physique, vous devez remplacer l'URL ci-dessus par l'IP de votre PC (ex: 192.168.1.x)
  // et lancer le serveur avec: php artisan serve --host=0.0.0.0

  // -----------------------------------------------------------------------------
  // HTTP Client & Storage
  // -----------------------------------------------------------------------------

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // -----------------------------------------------------------------------------
  // Initialization & Interceptors
  // -----------------------------------------------------------------------------

  ApiService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // You can handle global errors here (like 401 logging out)
          return handler.next(e);
        },
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // Public Accessors
  // -----------------------------------------------------------------------------

  Dio get client => _dio;
  FlutterSecureStorage get storage => _storage;
}
