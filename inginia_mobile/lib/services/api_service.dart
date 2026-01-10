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

  /// Détection automatique de l'URL du serveur selon la plateforme
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }
    // L'émulateur Android utilise 10.0.2.2 pour accéder au localhost de l'hôte
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    // Pour iOS Simulator, Windows, macOS, Linux
    return 'http://127.0.0.1:8000/api';
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
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
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
