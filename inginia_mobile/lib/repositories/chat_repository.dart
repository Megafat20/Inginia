import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/message_model.dart';

class ChatRepository {
  final ApiService _apiService = ApiService();

  // -----------------------------------------------------------------------------
  // Chat & Messaging
  // -----------------------------------------------------------------------------

  /// Fetch all messages for a specific reservation
  Future<List<Message>> getMessages(int reservationId) async {
    try {
      final response = await _apiService.client.get(
        '/reservations/$reservationId/messages',
      );
      /*
        Response format expected:
        {
          "messages": [ ... ]
        }
      */
      final list = response.data['messages'] as List;
      return list.map((e) => Message.fromJson(e)).toList();
    } catch (e) {
      // Silent error - return empty list
      return [];
    }
  }

  /// Send a new message in a reservation chat (text and/or image)
  Future<Message> sendMessage(
    int reservationId,
    String? content, {
    String? imagePath,
  }) async {
    try {
      dynamic data;

      if (imagePath != null) {
        data = FormData.fromMap({
          if (content != null) 'content': content,
          'image': await MultipartFile.fromFile(imagePath),
        });
      } else {
        data = {'content': content};
      }

      final response = await _apiService.client.post(
        '/reservations/$reservationId/messages',
        data: data,
      );

      return Message.fromJson(response.data['message']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur d\'envoi');
    }
  }
}
