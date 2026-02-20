import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/user_model.dart';

/// Service for handling device location and permissions
class LocationService {
  // -----------------------------------------------------------------------------
  // Location Access
  // -----------------------------------------------------------------------------

  /// Get the current device location with automatic permission handling
  ///
  /// Returns:
  /// - Position object if successful
  /// - null if location services are disabled or permissions denied
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled - user needs to enable them
      return null;
    }

    // Check current permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied - cannot access location
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever - user must enable in settings
      return null;
    }

    // Permissions granted - get current position
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    } catch (e) {
      print("Geolocator error: $e");
      return null;
    }
  }

  /// Get a stream of location updates
  Stream<Position> getPositionStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Open app settings
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }

  // -----------------------------------------------------------------------------
  // Distance Calculations
  // -----------------------------------------------------------------------------

  /// Calcule la distance en kilomètres entre deux points GPS (formule de Haversine)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Rayon de la Terre en km

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// Obtient la distance formatée pour l'affichage
  static String getFormattedDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)}km';
    } else {
      return '${distanceKm.round()}km';
    }
  }

  // -----------------------------------------------------------------------------
  // Provider Sorting & Filtering
  // -----------------------------------------------------------------------------

  /// Trie une liste de prestataires par distance
  static List<User> sortByDistance(
    List<User> providers,
    double userLat,
    double userLon,
  ) {
    // Créer une liste avec distances
    List<MapEntry<User, double>> providersWithDistance = [];

    for (var provider in providers) {
      if (provider.latitude != null && provider.longitude != null) {
        double distance = calculateDistance(
          userLat,
          userLon,
          provider.latitude!,
          provider.longitude!,
        );
        providersWithDistance.add(MapEntry(provider, distance));
      }
    }

    // Trier par distance
    providersWithDistance.sort((a, b) => a.value.compareTo(b.value));

    // Retourner uniquement les prestataires
    return providersWithDistance.map((e) => e.key).toList();
  }

  /// Filtre les prestataires par rayon (en km)
  static List<User> filterByRadius(
    List<User> providers,
    double userLat,
    double userLon,
    double radiusKm,
  ) {
    return providers.where((provider) {
      if (provider.latitude == null || provider.longitude == null) {
        return false;
      }

      double distance = calculateDistance(
        userLat,
        userLon,
        provider.latitude!,
        provider.longitude!,
      );

      return distance <= radiusKm;
    }).toList();
  }

  /// Obtient la distance d'un prestataire par rapport à une position
  static double? getProviderDistance(
    User provider,
    double userLat,
    double userLon,
  ) {
    if (provider.latitude == null || provider.longitude == null) {
      return null;
    }

    return calculateDistance(
      userLat,
      userLon,
      provider.latitude!,
      provider.longitude!,
    );
  }

  // -----------------------------------------------------------------------------
  // Geocoding
  // -----------------------------------------------------------------------------

  /// Convertit une adresse textuelle en coordonnées GPS
  /// Utilise Nominatim (OpenStreetMap)
  Future<Map<String, double>?> geocodeAddress(String address) async {
    try {
      final query = Uri.encodeComponent(address);
      final url =
          "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1&accept-language=fr";

      final dio = ApiService().client;
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent': 'InginiaApp/1.0 (com.inginia.world)',
            'Accept-Language': 'fr-FR,fr;q=0.9',
          },
        ),
      );

      if (response.data is List && (response.data as List).isNotEmpty) {
        final result = (response.data as List)[0];
        return {
          'lat': double.parse(result['lat'].toString()),
          'lng': double.parse(result['lon'].toString()),
        };
      }
      return null;
    } catch (e) {
      print("Geocoding error: $e");
      return null;
    }
  }

  /// Recherche des suggestions d'adresses (Autocomplete)
  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    if (query.length < 3) return [];

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url =
          "https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=5&addressdetails=1&accept-language=fr";

      final dio = ApiService().client;
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent': 'InginiaApp/1.0 (com.inginia.world)',
            'Accept-Language': 'fr-FR,fr;q=0.9',
          },
        ),
      );

      if (response.data is List) {
        return (response.data as List).map((item) {
          return {
            'display_name': item['display_name'],
            'lat': double.parse(item['lat'].toString()),
            'lng': double.parse(item['lon'].toString()),
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print("Search error: $e");
      return [];
    }
  }
}
