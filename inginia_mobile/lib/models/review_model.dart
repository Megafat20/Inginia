class Review {
  final int id;
  final int rating;
  final String? comment;
  final String clientName;
  final String? clientPhoto;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.rating,
    this.comment,
    required this.clientName,
    this.clientPhoto,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      rating: json['note'] is int
          ? json['note']
          : int.parse(json['note'].toString()),
      comment: json['commentaire'],
      clientName: json['client_name'] ?? 'Client',
      clientPhoto: json['client_photo'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
