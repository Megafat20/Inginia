import '../services/api_service.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? serviceName;
  final String? location;
  final int? minPrice;
  final String? slogan;
  final String? adresse;
  final String? profilePhotoUrl;
  final double? avgRating;
  final bool isAgency;
  final List<int> professionIds;
  final List<String> professionNames;
  final double? latitude;
  final double? longitude;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.serviceName,
    this.location,
    this.minPrice,
    this.slogan,
    this.adresse,
    this.profilePhotoUrl,
    this.avgRating,
    this.isAgency = false,
    this.professionIds = const <int>[],
    this.professionNames = const <String>[],
    this.latitude,
    this.longitude,
  });

  String get displayName {
    if (isAgency && serviceName != null && serviceName!.isNotEmpty) {
      return serviceName!;
    }
    return name;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Determine photo URL
    String? photo =
        json['profile_photo']?.toString() ?? json['photo']?.toString();
    if (photo != null && photo.isNotEmpty && !photo.startsWith('http')) {
      // Build full URL if it's just a filename
      final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
      photo = Uri.encodeFull('$baseUrl/storage/profile_photos/$photo');
    }

    return User(
      id: json['id'],
      name: json['name'] ?? 'Utilisateur Inconnu',
      email: json['email'] ?? '',
      phone: json['phone']?.toString(),
      role: json['role'] ?? 'user',
      serviceName:
          json['service'] ??
          json['service_name'], // Backend might send 'service' or 'service_name'
      location: json['location'],
      minPrice: json['min_price'] != null
          ? (double.tryParse(json['min_price'].toString())?.toInt())
          : null,
      slogan: json['slogan'],
      adresse: json['adresse'],
      profilePhotoUrl: photo,
      avgRating: json['rating'] != null
          ? double.tryParse(json['rating'].toString())
          : 0.0,
      isAgency:
          json['is_agency'] == 1 ||
          json['is_agency'] == true ||
          json['is_agency'] == '1',
      professionIds:
          (json['professions'] as List?)
              ?.map((p) => int.tryParse(p['id']?.toString() ?? '') ?? 0)
              .toList() ??
          <int>[],
      professionNames:
          (json['professions'] as List?)
              ?.map((p) => p['name']?.toString() ?? '')
              .toList() ??
          <String>[],
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }
}
