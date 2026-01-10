import '../services/api_service.dart';

class AdminService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _apiService.client.get('/admin/dashboard/stats');
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

  Future<void> validateProvider(int providerId) async {
    try {
      await _apiService.client.post('/admin/providers/$providerId/validate');
    } catch (e) {
      throw Exception('Erreur validation prestataire: $e');
    }
  }

  Future<void> rejectProvider(int providerId) async {
    try {
      await _apiService.client.delete('/admin/providers/$providerId/reject');
    } catch (e) {
      throw Exception('Erreur rejet prestataire: $e');
    }
  }

  Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await _apiService.client.get('/admin/users');
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Erreur chargement utilisateurs: $e');
    }
  }
}
