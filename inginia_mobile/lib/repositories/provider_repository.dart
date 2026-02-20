import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/provider_details_model.dart';
import '../models/reservation_model.dart';
import '../models/availability_model.dart';

class ProviderRepository {
  final ApiService _apiService = ApiService();

  Future<Reservation> getReservation(int id) async {
    try {
      final response = await _apiService.client.get('/reservations/$id');
      return Reservation.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Erreur lors de la récupération',
      );
    }
  }

  Future<void> updateMissionLocation(
    int reservationId,
    double lat,
    double lng,
  ) async {
    try {
      await _apiService.client.post(
        '/reservations/$reservationId/location',
        data: {'latitude': lat, 'longitude': lng},
      );
    } on DioException catch (e) {
      print("Error updating mission location: $e");
    }
  }

  // -----------------------------------------------------------------------------
  // 3. Provider Actions (Accept/Decline/Complete)
  // -----------------------------------------------------------------------------

  // -----------------------------------------------------------------------------
  // 1. Provider Discovery (Public/Client View)
  // -----------------------------------------------------------------------------

  Future<Map<String, dynamic>> getProviders({
    String? q,
    int? professionId,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? onlyAvailable,
    double? latitude,
    double? longitude,
    double? radius,
    int page = 1,
    String? sort,
  }) async {
    try {
      final response = await _apiService.client.get(
        '/providers',
        queryParameters: {
          if (q != null && q.isNotEmpty) 'q': q,
          if (professionId != null) 'profession_id': professionId,
          if (minPrice != null) 'min_price': minPrice,
          if (maxPrice != null) 'max_price': maxPrice,
          if (minRating != null) 'min_rating': minRating,
          if (onlyAvailable == true) 'available': 1,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (radius != null) 'radius': radius,
          if (sort != null) 'sort': sort,
          'page': page,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final List<User> providers = data
            .map((json) => User.fromJson(json))
            .toList();

        return {
          'providers': providers,
          'meta': {
            'current_page': response.data['current_page'],
            'last_page': response.data['last_page'],
            'total': response.data['total'],
          },
        };
      } else {
        throw Exception('Failed to load providers');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load providers',
      );
    }
  }

  Future<ProviderDetails?> getProviderDetails(int id) async {
    try {
      final response = await _apiService.client.get('/provider/$id/dashboard');
      if (response.statusCode == 200) {
        return ProviderDetails.fromJson(response.data);
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode == 404) {
        throw Exception("Prestataire introuvable");
      }
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load provider details',
      );
    }
    return null;
  }

  Future<Map<String, dynamic>> getProviderReviews(int providerId) async {
    try {
      final response = await _apiService.client.get('/avis/$providerId');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Erreur lors du chargement des avis',
      );
    }
  }

  // -----------------------------------------------------------------------------
  // 2. Client Actions (Booking & Reviews)
  // -----------------------------------------------------------------------------

  Future<void> submitReservation({
    required int providerId,
    required DateTime requestedDate,
    required String time, // Format "HH:mm"
    required String description,
    int? competanceId,
    String? otherService,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final dateStr = requestedDate.toIso8601String().split('T')[0];
      final fullDateTime = '$dateStr $time:00';

      final data = {
        'requested_date': fullDateTime,
        'description': description,
        if (competanceId != null) 'competance_id': competanceId,
        if (otherService != null) 'other_service': otherService,
        'latitude': latitude,
        'longitude': longitude,
      };

      await _apiService.client.post('/reservations/$providerId', data: data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to submit reservation',
      );
    }
  }

  Future<void> submitReview({
    required int providerId,
    required int rating,
    required int reservationId,
    String? comment,
  }) async {
    try {
      await _apiService.client.post(
        '/avis/$providerId',
        data: {
          'rating': rating,
          'reservation_id': reservationId,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Erreur lors de l\'envoi de l\'avis',
      );
    }
  }

  // -----------------------------------------------------------------------------
  // 3. Reservation Management (Fetching)
  // -----------------------------------------------------------------------------

  // For Client: Fetch THEIR reservations
  Future<List<Reservation>> getMyReservationsAsClient() async {
    try {
      final response = await _apiService.client.get('/client/my-reservations');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['reservations'] ?? [];
        return data.map((json) => Reservation.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load client missions',
      );
    }
  }

  // For Provider: Fetch THEIR missions
  Future<List<Reservation>> getMyReservationsAsProvider() async {
    try {
      final response = await _apiService.client.get('/provider/reservations');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['reservations'] ?? [];
        return data.map((json) => Reservation.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw Exception(
        e.response?.data['message'] ?? 'Failed to load provider missions',
      );
    }
  }

  // Legacy alias
  Future<List<Reservation>> getClientReservations() async {
    return getMyReservationsAsClient();
  }

  // -----------------------------------------------------------------------------
  // 4. Mission Actions (Status, Location, Reports)
  // -----------------------------------------------------------------------------

  Future<void> updateMissionStatus(
    int reservationId,
    String status, {
    String? reason,
  }) async {
    try {
      await _apiService.client.patch(
        '/reservations/$reservationId/status',
        data: {'status': status, if (reason != null) 'reason': reason},
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Erreur lors de la mise à jour',
      );
    }
  }

  Future<void> updateLocation(int reservationId, double lat, double lng) async {
    try {
      await _apiService.client.post(
        '/reservations/$reservationId/location',
        data: {'latitude': lat, 'longitude': lng},
      );
    } catch (e) {
      // Silent error or print
      print("Loc update error: $e");
    }
  }

  Future<void> uploadReservationPhotos({
    required int reservationId,
    required List<String> filePaths,
    required String type, // 'before' or 'after'
  }) async {
    try {
      final List<MultipartFile> files = [];
      for (String path in filePaths) {
        files.add(await MultipartFile.fromFile(path));
      }

      final formData = FormData.fromMap({'photos[]': files, 'type': type});

      await _apiService.client.post(
        '/reservations/$reservationId/photos',
        data: formData,
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Erreur lors de l\'upload des photos',
      );
    }
  }

  Future<void> reportProblem({
    required int reportedId,
    required String reason,
    int? reservationId,
    String? description,
  }) async {
    try {
      await _apiService.client.post(
        '/reports',
        data: {
          'reported_id': reportedId,
          'reason': reason,
          if (reservationId != null) 'reservation_id': reservationId,
          if (description != null) 'description': description,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Erreur lors du signalement',
      );
    }
  }

  // -----------------------------------------------------------------------------
  // 5. Provider Services Management
  // -----------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getMyProfessions() async {
    try {
      final response = await _apiService.client.get('/provider/myprofessions');
      final list = response.data['professions'] as List;
      return list
          .map((e) => {'id': e['id'], 'name': e['name']})
          .toList()
          .cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllProfessions() async {
    try {
      final response = await _apiService.client.get('/professions');
      final list = response.data is List
          ? response.data
          : response.data['data'] ?? [];
      return (list as List)
          .map((e) => {'id': e['id'], 'name': e['name']})
          .toList()
          .cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<void> addService(Map<String, dynamic> data) async {
    try {
      await _apiService.client.post('/provider/services', data: data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Erreur lors de l\'ajout du service',
      );
    }
  }

  Future<void> updateService(int id, Map<String, dynamic> data) async {
    try {
      await _apiService.client.put('/provider/services/$id', data: data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Erreur lors de la modification',
      );
    }
  }

  Future<void> deleteService(int id) async {
    try {
      await _apiService.client.delete('/provider/services/$id');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Erreur lors de la suppression',
      );
    }
  }

  // -----------------------------------------------------------------------------
  // 6. Availability Management
  // -----------------------------------------------------------------------------

  Future<List<Availability>> getAvailabilities() async {
    try {
      final response = await _apiService.client.get('/availabilities');
      final list = response.data is List
          ? response.data
          : response.data['data'] ?? [];
      return (list as List).map((e) => Availability.fromJson(e)).toList();
    } catch (e) {
      print("Error fetching availabilities: $e");
      return [];
    }
  }

  Future<void> updateAvailabilities(List<Availability> schedule) async {
    try {
      final data = {'schedule': schedule.map((e) => e.toJson()).toList()};
      await _apiService.client.post('/availabilities', data: data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ??
            'Erreur lors de la mise à jour du planning',
      );
    }
  }

  // -----------------------------------------------------------------------------
  // 7. Profile & Portfolio
  // -----------------------------------------------------------------------------

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await _apiService.client.post('/me', data: data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ??
            'Erreur lors de la mise à jour du profil',
      );
    }
  }

  // -----------------------------------------------------------------------------
  // 8. Favorites Management
  // -----------------------------------------------------------------------------

  Future<void> toggleFavorite(int providerId) async {
    try {
      await _apiService.client.post('/favorite/$providerId');
    } catch (e) {
      // Ignore or throw specific error
      throw Exception('Erreur lors de la mise à jour des favoris');
    }
  }

  Future<List<User>> getFavorites() async {
    try {
      final response = await _apiService.client.get('/favorites');
      final list = response.data is List
          ? response.data
          : response.data['data'] ?? [];
      // On suppose que l'API renvoie une liste d'objets User complètes ou partielles
      // Note: Assurez-vous que le modèle User.fromJson gère les champs renvoyés
      return (list as List).map((e) => User.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> uploadPortfolioImage({
    required String filePath,
    String? title,
    String? description,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
        if (title != null) 'title': title,
        if (description != null) 'description': description,
      });

      await _apiService.client.post('/provider/portfolio', data: formData);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Erreur lors de l\'upload de l\'image',
      );
    }
  }

  Future<void> deletePortfolioImage(int id) async {
    try {
      await _apiService.client.delete('/provider/portfolio/$id');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Erreur lors de la suppression',
      );
    }
  }

  // -----------------------------------------------------------------------------
  // 9. Provider Statistics
  // -----------------------------------------------------------------------------

  Future<Map<String, dynamic>> getProviderStats() async {
    try {
      final response = await _apiService.client.get('/provider/stats');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print("Error fetching provider stats: $e");
      return {};
    }
  }
}
