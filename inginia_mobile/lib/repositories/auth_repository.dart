import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();

  // -----------------------------------------------------------------------------
  // 1. Authentication (Login & Registration)
  // -----------------------------------------------------------------------------

  Future<User?> login(String email, String password) async {
    try {
      final response = await _apiService.client.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // The API returns { 'message': ..., 'user': ..., 'token': ... }
        if (data['token'] != null) {
          await _apiService.storage.write(
            key: 'auth_token',
            value: data['token'],
          );
        }
        return User.fromJson(data['user']);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['error'] ?? 'Erreur de connexion');
      }
      throw Exception('Impossible de joindre le serveur');
    }
    return null;
  }

  Future<User?> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? role, // 'client' or 'prestataire'
    bool? isAgency,
    List<String>? professionIds,
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
        'email': email,
        'password': password,
        'phone': phone ?? '',
        'role': role ?? 'client',
      };

      if (role == 'prestataire') {
        if (isAgency == true) {
          data['service'] = name; // Agency name goes as service
        } else {
          data['name'] = name; // Individual name
        }

        data['is_agency'] = isAgency == true;

        // Professions
        if (professionIds != null && professionIds.isNotEmpty) {
          data['profession_ids'] = professionIds;
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
        return User.fromJson(responseData['user']);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final msg = e.response?.data['message'] ?? 'Erreur d\'inscription';
        throw Exception(msg);
      }
      throw Exception('Impossible de joindre le serveur');
    }
    return null;
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
      if (name != null) map['name'] = name;
      if (email != null) map['email'] = email;
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
        return User.fromJson(response.data);
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Erreur lors de la mise à jour',
      );
    }
    return null;
  }
}
