import 'dart:math' as math;

class Reservation {
  final int id;
  final int? providerId;
  final int? clientId;
  final String status;
  final DateTime requestedDate;
  final String? description;
  final String providerName;
  final String? providerPhoto;
  final String serviceTitle;
  final int? price;
  final String? providerPhone;
  final String? clientName;
  final String? clientPhoto;
  final double? clientLat;
  final double? clientLng;
  final double? providerLat;
  final double? providerLng;

  Reservation({
    required this.id,
    this.providerId,
    this.clientId,
    required this.status,
    required this.requestedDate,
    this.description,
    required this.providerName,
    this.providerPhoto,
    required this.serviceTitle,
    this.price,
    this.providerPhone,
    this.clientName,
    this.clientPhoto,
    this.clientLat,
    this.clientLng,
    this.providerLat,
    this.providerLng,
  });

  String get eta {
    if (clientLat == null ||
        clientLng == null ||
        providerLat == null ||
        providerLng == null) {
      return "-- min";
    }

    const double p = 0.017453292519943295;
    final a =
        0.5 -
        math.cos((providerLat! - clientLat!) * p) / 2 +
        math.cos(clientLat! * p) *
            math.cos(providerLat! * p) *
            (1 - math.cos((providerLng! - clientLng!) * p)) /
            2;
    final distance = 12742 * math.asin(math.sqrt(a));

    final minutes = (distance / 0.5).round();

    if (minutes < 1) return "< 1 min";
    if (minutes > 60) return "${(minutes / 60).floor()}h ${minutes % 60} min";
    return "$minutes min";
  }

  factory Reservation.fromJson(Map<String, dynamic> json) {
    final provider = json['provider'] ?? {};
    final client = json['client'] ?? {};
    final competance = json['competance'] ?? {};

    return Reservation(
      id: json['id'],
      providerId: json['provider_id'],
      clientId: json['client_id'],
      status: json['status'] ?? 'pending',
      requestedDate:
          DateTime.tryParse(json['requested_date'] ?? '') ?? DateTime.now(),
      description: json['description'],
      providerName: provider['name'] ?? 'Prestataire Inconnu',
      providerPhoto: provider['profile_photo_url'],
      providerPhone: provider['phone'],
      clientName: client['name'] ?? 'Client Inconnu',
      clientPhoto: client['profile_photo_url'],
      serviceTitle: competance['title'] ?? 'Service personnalisé',
      price: competance['price'] != null
          ? (double.tryParse(competance['price'].toString())?.toInt())
          : null,
      clientLat: json['client_lat'] != null
          ? double.tryParse(json['client_lat'].toString())
          : null,
      clientLng: json['client_lng'] != null
          ? double.tryParse(json['client_lng'].toString())
          : null,
      providerLat: json['provider_lat'] != null
          ? double.tryParse(json['provider_lat'].toString())
          : null,
      providerLng: json['provider_lng'] != null
          ? double.tryParse(json['provider_lng'].toString())
          : null,
    );
  }
}
