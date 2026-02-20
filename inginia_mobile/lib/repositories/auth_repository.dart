import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();

  // -----------------------------------------------------------------------------
  // 1. Authentication (Login & Registration)
  // -----------------------------------------------------------------------------

  Future<User?> login({
    String? email,
    String? phone,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'password': password,
        'remember_me': rememberMe,
      };
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;

      final response = await _apiService.client.post('/login', data: data);

      if (response.statusCode == 200) {
        final data = response.data;
        // The API returns { 'message': ..., 'user': ..., 'token': ... }
        if (data['token'] != null) {
          await _apiService.storage.write(
            key: 'auth_token',
            value: data['token'],
          );
        }
        if (data['refresh_token'] != null) {
          await _apiService.storage.write(
            key: 'refresh_token',
            value: data['refresh_token'],
          );
        }
        return User.fromJson(data['user']);
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        throw Exception(e.response?.data['error'] ?? 'Erreur de connexion');
      }
      throw Exception('Impossible de joindre le serveur ou erreur interne');
    }
    return null;
  }

  Future<User?> loginWithGoogle(String idToken) async {
    try {
      final response = await _apiService.client.post(
        '/auth/google',
        data: {'credential': idToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['token'] != null) {
          await _apiService.storage.write(
            key: 'auth_token',
            value: data['token'],
          );
        }
        return User.fromJson(data['user']);
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        throw Exception(e.response?.data['error'] ?? 'Erreur Google Login');
      }
      throw Exception('Impossible de joindre le serveur');
    }
    return null;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String password,
    String? email,
    String? phone,
    String? role, // 'client' or 'prestataire'
    bool? isAgency,
    List<String>? professionIds,
    List<String>? customProfessions,
    String? minPrice,
    String? slogan,
    String? location,
    String? adresse,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Build form data (matching React's FormData approach)
      final Map<String, dynamic> data = {
        'password': password,
        'role': role ?? 'client',
      };

      if (email != null && email.isNotEmpty) data['email'] = email;
      if (phone != null && phone.isNotEmpty) data['phone'] = phone;

      if (role == 'prestataire') {
        data['name'] =
            name; // Nom requis pour tous (nom agence ou nom prestataire)

        if (isAgency == true) {
          data['service'] = name; // Agency name goes as service too
        }

        data['is_agency'] = isAgency == true;

        // Professions
        if (professionIds != null && professionIds.isNotEmpty) {
          data['profession_ids'] = professionIds;
        }
        if (customProfessions != null && customProfessions.isNotEmpty) {
          data['custom_professions'] = customProfessions;
        }

        data['min_price'] = minPrice ?? '';
        data['slogan'] = slogan ?? '';
        data['location'] = location ?? '';
        data['adresse'] = adresse ?? '';
        data['latitude'] = latitude ?? 0.0;
        data['longitude'] = longitude ?? 0.0;
      } else {
        // Client
        data['name'] = name;
      }

      final response = await _apiService.client.post('/register', data: data);

      if (response.statusCode == 201) {
        final responseData = response.data;
        if (responseData['token'] != null) {
          await _apiService.storage.write(
            key: 'auth_token',
            value: responseData['token'],
          );
        }

        return {
          'user': User.fromJson(responseData['user']),
          'requireVerification': responseData['require_verification'] ?? false,
          'message': responseData['message'],
        };
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final msg =
            e.response?.data['message'] ??
            e.response?.data['error'] ??
            'Erreur d\'inscription';
        throw Exception(msg);
      }
      throw Exception('Impossible de joindre le serveur');
    }
    return {};
  }

  Future<void> sendOtp(String identifier, String type) async {
    try {
      await _apiService.client.post(
        '/otp/send',
        data: {'identifier': identifier, 'type': type},
      );
    } on DioException catch (e) {
      String errorMsg = 'Erreur lors de l\'envoi du code';
      if (e.response != null && e.response?.data is Map) {
        errorMsg = e.response?.data['error'] ?? errorMsg;
      }
      throw Exception(errorMsg);
    }
  }

  Future<void> verifyOtp(String identifier, String code, String type) async {
    try {
      await _apiService.client.post(
        '/otp/verify',
        data: {'identifier': identifier, 'code': code, 'type': type},
      );
    } on DioException catch (e) {
      String errorMsg = 'Code invalide ou expiré';
      if (e.response != null && e.response?.data is Map) {
        errorMsg = e.response?.data['error'] ?? errorMsg;
      }
      throw Exception(errorMsg);
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.client.post('/logout');
    } catch (_) {}
    await _apiService.storage.delete(key: 'auth_token');
  }

  // -----------------------------------------------------------------------------
  // 2. User Profile Management
  // -----------------------------------------------------------------------------

  Future<User?> getMe() async {
    try {
      final response = await _apiService.client.get('/me');
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  Future<User?> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? slogan,
    String? adresse,
    String? photoPath,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final Map<String, dynamic> map = {};

      // L'API Laravel Inginia requiert l'email pour la validation même en mise à jour partielle
      if (email != null) {
        map['email'] = email;
      }

      if (name != null) map['name'] = name;
      if (phone != null) map['phone'] = phone;
      if (slogan != null) map['slogan'] = slogan;
      if (adresse != null) map['adresse'] = adresse;
      if (latitude != null) map['latitude'] = latitude;
      if (longitude != null) map['longitude'] = longitude;

      if (photoPath != null) {
        map['profile_photo'] = await MultipartFile.fromFile(photoPath);
      }

      final formData = FormData.fromMap(map);

      final response = await _apiService.client.post('/me', data: formData);

      if (response.statusCode == 200) {
        return User.fromJson(response.data['user']);
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Erreur lors de la mise à jour',
      );
    }
    return null;
  }

  Future<User?> updateAvailability(bool value) async {
    try {
      final response = await _apiService.client.put(
        '/me/availability',
        data: {'is_available': value},
      );
      if (response.statusCode == 200) {
        return await getMe();
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        throw Exception(
          e.response?.data['message'] ??
              e.response?.data['error'] ??
              'Erreur lors de la mise à jour',
        );
      }
      throw Exception('Impossible de joindre le serveur');
    }
    return null;
  }
}
