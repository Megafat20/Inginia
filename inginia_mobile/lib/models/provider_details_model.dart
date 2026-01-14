import 'user_model.dart';

class ProviderDetails {
  final User provider;
  final List<Competance> competances;
  final List<Review> reviews;
  final List<PortfolioItem> portfolio;
  final int completedMissions;
  final Map<int, int> ratingDistribution;

  ProviderDetails({
    required this.provider,
    required this.competances,
    required this.reviews,
    required this.portfolio,
    this.completedMissions = 0,
    this.ratingDistribution = const {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
  });

  factory ProviderDetails.fromJson(Map<String, dynamic> json) {
    // Parser la distribution
    final Map<int, int> distribution = {};
    if (json['stats']?['rating_distribution'] != null) {
      final distJson = json['stats']['rating_distribution'] as Map;
      distJson.forEach((key, value) {
        final star = int.tryParse(key.toString()) ?? 0;
        final count = int.tryParse(value.toString()) ?? 0;
        if (star >= 1 && star <= 5) {
          distribution[star] = count;
        }
      });
    }

    return ProviderDetails(
      provider: User.fromJson(json['provider']),
      completedMissions: json['stats']?['total_completed'] ?? 0,
      ratingDistribution: distribution,
      competances:
          (json['competances'] as List?)
              ?.map((e) => Competance.fromJson(e))
              .toList() ??
          [],
      reviews:
          (json['reviews'] as List?)?.map((e) => Review.fromJson(e)).toList() ??
          [],
      portfolio:
          (json['portfolio'] as List?)
              ?.map((e) => PortfolioItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class PortfolioItem {
  final int id;
  final String image;
  final String? title;
  final String? description;

  PortfolioItem({
    required this.id,
    required this.image,
    this.title,
    this.description,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: json['id'],
      image: json['image'],
      title: json['title'],
      description: json['description'],
    );
  }
}

class Competance {
  final int id;
  final String title;
  final String? description;
  final int price;

  Competance({
    required this.id,
    required this.title,
    this.description,
    required this.price,
  });

  factory Competance.fromJson(Map<String, dynamic> json) {
    return Competance(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: json['price'] != null
          ? (double.tryParse(json['price'].toString())?.toInt() ?? 0)
          : 0,
    );
  }
}

class Review {
  final int id;
  final int rating;
  final String? comment;
  final String reviewerName; // We might need to map user relationship
  final DateTime createdAt;

  Review({
    required this.id,
    required this.rating,
    this.comment,
    required this.reviewerName,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      rating: json['rating'] is int
          ? json['rating']
          : int.tryParse(json['rating'].toString()) ?? 5,
      comment: json['comment'],
      reviewerName: json['reviewer_name'] ?? 'Anonyme',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
