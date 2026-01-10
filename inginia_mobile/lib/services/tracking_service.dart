import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

class TrackingService {
  static Timer? _timer;
  static final Set<int> _activeReservationIds = {};

  static void startTracking(int reservationId) {
    if (_activeReservationIds.contains(reservationId)) return;

    _activeReservationIds.add(reservationId);
    print("🚀 Starting Live Tracking for Reservation: $reservationId");

    _ensureTimerStarted();
  }

  static void _ensureTimerStarted() {
    if (_timer != null && _timer!.isActive) return;

    // Send update every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _sendLocationUpdate();
    });

    // Send immediate update
    _sendLocationUpdate();
  }

  static Future<void> checkAndStartTracking() async {
    try {
      final api = ApiService();
      final response = await api.client.get('/provider/reservations');
      final reservations = response.data['reservations'] as List;

      bool foundActive = false;
      for (var r in reservations) {
        if (r['status'] == 'accepted' || r['status'] == 'in_progress') {
          _activeReservationIds.add(r['id']);
          foundActive = true;
        }
      }

      if (foundActive) {
        _ensureTimerStarted();
      }
    } catch (e) {
      print("❌ Error checking active missions: $e");
    }
  }

  static void stopTracking() {
    print("🛑 Stopping all Live Tracking");
    _timer?.cancel();
    _timer = null;
    _activeReservationIds.clear();
  }

  static Future<void> _sendLocationUpdate() async {
    if (_activeReservationIds.isEmpty) {
      stopTracking();
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final api = ApiService();
      for (var id in _activeReservationIds) {
        await api.client.post(
          '/reservations/$id/location',
          data: {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
        );
      }
      print("📍 Location updated for ${_activeReservationIds.length} missions");
    } catch (e) {
      print("❌ Error updating location: $e");
    }
  }
}
