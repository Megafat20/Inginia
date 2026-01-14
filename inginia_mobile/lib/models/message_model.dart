class Message {
  final int id;
  final int senderId;
  final int reservationId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final String? senderName;

  Message({
    required this.id,
    required this.senderId,
    required this.reservationId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.senderName,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      senderId: json['sender_id'] is int
          ? json['sender_id']
          : int.parse(json['sender_id'].toString()),
      reservationId: json['reservation_id'] is int
          ? json['reservation_id']
          : int.parse(json['reservation_id'].toString()),
      content: json['message'] ?? '',
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at']) ?? DateTime.now())
          : DateTime.now(),
      senderName: json['user'] != null ? json['user']['name'] : null,
    );
  }
}
