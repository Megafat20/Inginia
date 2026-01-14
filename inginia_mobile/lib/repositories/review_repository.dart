import 'package:dio/dio.dart';
import '../models/review_model.dart';
import '../services/api_service.dart';

class ReviewRepository {
  final ApiService _apiService = ApiService();

  /// Récupérer les avis d'un prestataire avec filtres
  Future<Map<String, dynamic>> getProviderReviews(
    int providerId, {
    int? minRating,
    bool? withPhotos,
    bool? verified,
    String sortBy = 'recent',
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (minRating != null) queryParams['min_rating'] = minRating;
      if (withPhotos != null) queryParams['with_photos'] = withPhotos;
      if (verified != null) queryParams['verified'] = verified;
      queryParams['sort_by'] = sortBy;

      final response = await _apiService.client.get(
        '/avis/$providerId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'reviews': (data['reviews'] as List)
              .map((json) => Review.fromJson(json))
              .toList(),
          'stats': ReviewStats.fromJson(data['stats']),
          'providerName': data['prestataire'],
          'rating': (data['rating'] as num).toDouble(),
        };
      }
    } on DioException catch (e) {
      print('Error fetching reviews: $e');
      throw Exception(
        e.response?.data['message'] ?? 'Erreur lors du chargement des avis',
      );
    }
    return {};
  }

  /// Créer un avis avec critères détaillés et photos
  Future<Review?> createReview({
    required int providerId,
    required int reservationId,
    required int rating,
    String? comment,
    int? ponctualite,
    int? qualite,
    int? prix,
    int? communication,
    List<String>? photoPaths,
  }) async {
    try {
      final formData = FormData.fromMap({
        'rating': rating,
        'reservation_id': reservationId,
        if (comment != null) 'comment': comment,
        if (ponctualite != null) 'ponctualite': ponctualite,
        if (qualite != null) 'qualite': qualite,
        if (prix != null) 'prix': prix,
        if (communication != null) 'communication': communication,
      });

      // Ajouter les photos
      if (photoPaths != null && photoPaths.isNotEmpty) {
        for (int i = 0; i < photoPaths.length; i++) {
          formData.files.add(
            MapEntry('photos[$i]', await MultipartFile.fromFile(photoPaths[i])),
          );
        }
      }

      final response = await _apiService.client.post(
        '/avis/$providerId',
        data: formData,
      );

      if (response.statusCode == 201) {
        return Review.fromJson(response.data['review']);
      }
    } on DioException catch (e) {
      print('Error creating review: $e');
      throw Exception(
        e.response?.data['error'] ?? 'Erreur lors de la création de l\'avis',
      );
    }
    return null;
  }

  /// Répondre à un avis (prestataire uniquement)
  Future<bool> respondToReview(int reviewId, String response) async {
    try {
      final result = await _apiService.client.post(
        '/avis/$reviewId/respond',
        data: {'reponse': response},
      );
      return result.statusCode == 200;
    } on DioException catch (e) {
      print('Error responding to review: $e');
      throw Exception(e.response?.data['error'] ?? 'Erreur lors de la réponse');
    }
  }

  /// Marquer un avis comme utile
  Future<int?> markReviewHelpful(int reviewId) async {
    try {
      final response = await _apiService.client.post('/avis/$reviewId/helpful');
      if (response.statusCode == 200) {
        return response.data['helpful_count'];
      }
    } on DioException catch (e) {
      print('Error marking review as helpful: $e');
    }
    return null;
  }
}
