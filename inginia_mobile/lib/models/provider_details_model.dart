import 'user_model.dart';

class ProviderDetails {
  final User provider;
  final List<Competance> competances;
  final List<Review> reviews;
  final List<PortfolioItem> portfolio;
  final int completedMissions;

  ProviderDetails({
    required this.provider,
    required this.competances,
    required this.reviews,
    required this.portfolio,
    this.completedMissions = 0,
  });

  factory ProviderDetails.fromJson(Map<String, dynamic> json) {
    return ProviderDetails(
      provider: User.fromJson(json['provider']),
      completedMissions: json['stats']?['total_completed'] ?? 0,
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
