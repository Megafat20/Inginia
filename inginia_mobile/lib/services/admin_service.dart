import '../services/api_service.dart';
import '../models/user_model.dart';

class AdminService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getDashboardStats({
    String period = 'month',
  }) async {
    try {
      final response = await _apiService.client.get(
        '/admin/dashboard/stats',
        queryParameters: {'period': period},
      );
      return response.data;
    } catch (e) {
      throw Exception('Erreur chargement statistiques: $e');
    }
  }

  Future<List<dynamic>> getPendingProviders() async {
    try {
      final response = await _apiService.client.get('/admin/providers/pending');
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Erreur chargement prestataires en attente: $e');
    }
  }

  Future<List<dynamic>> getValidatedProviders() async {
    try {
      final response = await _apiService.client.get(
        '/admin/providers/validated',
      );
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Erreur chargement prestataires validés: $e');
    }
  }

  Future<void> validateProvider(
    int providerId, {
    String? comment,
    String? expiresAt,
  }) async {
    try {
      await _apiService.client.post(
        '/admin/providers/$providerId/validate',
        data: {'comment': comment, 'expires_at': expiresAt},
      );
    } catch (e) {
      throw Exception('Erreur validation prestataire: $e');
    }
  }

  Future<void> rejectProvider(int providerId, {required String comment}) async {
    try {
      await _apiService.client.post(
        '/admin/providers/$providerId/reject',
        data: {'comment': comment},
      );
    } catch (e) {
      throw Exception('Erreur rejet prestataire: $e');
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      final response = await _apiService.client.get('/admin/users');
      return (response.data as List)
          .map((json) => User.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur chargement utilisateurs: $e');
    }
  }

  Future<void> updateUser(int userId, Map<String, dynamic> data) async {
    try {
      await _apiService.client.put('/admin/users/$userId', data: data);
    } catch (e) {
      throw Exception('Erreur modification utilisateur: $e');
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      await _apiService.client.delete('/admin/users/$userId');
    } catch (e) {
      throw Exception('Erreur suppression utilisateur: $e');
    }
  }

  Future<bool> toggleActiveStatus(int userId) async {
    try {
      final response = await _apiService.client.patch(
        '/admin/users/$userId/toggle-active',
      );
      return response.data['is_active'];
    } catch (e) {
      throw Exception('Erreur modification statut: $e');
    }
  }
}
