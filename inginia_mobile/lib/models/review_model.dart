class Review {
  final int id;
  final int rating;
  final String? comment;
  final ReviewCriteria? criteria;
  final List<String> photos;
  final String reviewerName;
  final String? reviewerPhoto;
  final bool verified;
  final int helpfulCount;
  final String? reponsePrestataire;
  final DateTime? reponseAt;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.rating,
    this.comment,
    this.criteria,
    this.photos = const [],
    required this.reviewerName,
    this.reviewerPhoto,
    this.verified = false,
    this.helpfulCount = 0,
    this.reponsePrestataire,
    this.reponseAt,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      rating: json['rating'] ?? json['note'] ?? 0,
      comment: json['comment'] ?? json['commentaire'],
      criteria: json['criteria'] != null
          ? ReviewCriteria.fromJson(json['criteria'])
          : null,
      photos: json['photos'] != null ? List<String>.from(json['photos']) : [],
      reviewerName:
          json['reviewer_name'] ?? json['client_name'] ?? 'Utilisateur',
      reviewerPhoto: json['reviewer_photo'] ?? json['client_photo'],
      verified: json['verified'] ?? false,
      helpfulCount: json['helpful_count'] ?? 0,
      reponsePrestataire: json['reponse_prestataire'],
      reponseAt: json['reponse_at'] != null
          ? DateTime.parse(json['reponse_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ReviewCriteria {
  final int? ponctualite;
  final int? qualite;
  final int? prix;
  final int? communication;

  ReviewCriteria({
    this.ponctualite,
    this.qualite,
    this.prix,
    this.communication,
  });

  factory ReviewCriteria.fromJson(Map<String, dynamic> json) {
    return ReviewCriteria(
      ponctualite: json['ponctualite'],
      qualite: json['qualite'],
      prix: json['prix'],
      communication: json['communication'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ponctualite': ponctualite,
      'qualite': qualite,
      'prix': prix,
      'communication': communication,
    };
  }

  double get average {
    final values = [
      ponctualite,
      qualite,
      prix,
      communication,
    ].where((v) => v != null).cast<int>();
    return values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;
  }
}

class ReviewStats {
  final int total;
  final double average;
  final Map<int, int> distribution;
  final Map<String, double> criteriaAverages;

  ReviewStats({
    required this.total,
    required this.average,
    required this.distribution,
    required this.criteriaAverages,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    return ReviewStats(
      total: json['total'],
      average: (json['average'] as num).toDouble(),
      distribution: Map<int, int>.from(json['distribution']),
      criteriaAverages: Map<String, double>.from(
        json['criteria_averages'].map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
    );
  }
}

class ProviderBadge {
  final String type;
  final String label;
  final String color;
  final String description;
  final DateTime earnedAt;

  ProviderBadge({
    required this.type,
    required this.label,
    required this.color,
    required this.description,
    required this.earnedAt,
  });

  factory ProviderBadge.fromJson(Map<String, dynamic> json) {
    return ProviderBadge(
      type: json['type'],
      label: json['label'],
      color: json['color'],
      description: json['description'],
      earnedAt: DateTime.parse(json['earned_at']),
    );
  }
}
