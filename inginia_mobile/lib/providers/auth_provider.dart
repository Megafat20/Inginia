import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/push_notification_service.dart';
import '../services/location_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isOfflineMode = false;
  bool _showLogin = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isOfflineMode => _isOfflineMode;
  bool get shouldShowLogin => _showLogin;

  void setShowLogin(bool value) {
    _showLogin = value;
    notifyListeners();
  }

  void setOfflineMode(bool value) {
    _isOfflineMode = value;
    notifyListeners();
  }

  Future<void> updateAvailability(bool value) async {
    try {
      await _authRepository.updateAvailability(value);
      if (_user != null) {
        _user = _user!.copyWith(isAvailable: value);
        notifyListeners();
      }
    } catch (e) {
      print("Error updating availability: $e");
    }
  }

  // Try to restore session on app start
  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authRepository.getMe();
      if (_user != null) {
        // Update location silently on startup
        LocationService()
            .getCurrentLocation()
            .then((loc) {
              if (loc != null) {
                _authRepository.updateProfile(
                  email: _user?.email, // Required by backend validation
                  latitude: loc.latitude,
                  longitude: loc.longitude,
                );
              }
            })
            .catchError((_) {});
      }
    } catch (_) {
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authRepository.login(email, password);
      // 🔥 Upload FCM token after login
      PushNotificationService.uploadPendingToken();

      // 🔥 Update Location on Login
      try {
        final loc = await LocationService().getCurrentLocation();
        if (loc != null) {
          await _authRepository.updateProfile(
            email: _user?.email, // Required by backend validation
            latitude: loc.latitude,
            longitude: loc.longitude,
          );
          // Refresh user data with new location
          final updatedUser = await _authRepository.getMe();
          if (updatedUser != null) _user = updatedUser;
        }
      } catch (e) {
        print("⚠️ Failed to update location on login: $e");
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? role,
    bool? isAgency,
    List<String>? professionIds,
    List<String>? customProfessions,
    String? minPrice,
    String? slogan,
    String? location,
    String? adresse,
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authRepository.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
        isAgency: isAgency,
        professionIds: professionIds,
        customProfessions: customProfessions,
        minPrice: minPrice,
        slogan: slogan,
        location: location,
        adresse: adresse,
        latitude: latitude,
        longitude: longitude,
      );
      // 🔥 Upload FCM token after registration
      PushNotificationService.uploadPendingToken();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    _isOfflineMode = false;
    notifyListeners();
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authRepository.updateProfile(
        email: _user?.email, // Indispensable pour la validation backend
        latitude: latitude,
        longitude: longitude,
      );
      // Update local user object
      _user = await _authRepository.getMe();
    } catch (e) {
      print("Error updating location: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
