import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // ADD THIS
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/push_notification_service.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isOfflineMode = false;
  bool _showLogin = false;
  bool _hasSeenOnboarding = true;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isOfflineMode => _isOfflineMode;
  bool get shouldShowLogin => _showLogin;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  // ✅ THE KEY FIX: never notify mid-frame
  void _safeNotify() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void setHasSeenOnboarding(bool value) {
    _hasSeenOnboarding = value;
    _safeNotify();
  }

  void setShowLogin(bool value) {
    _showLogin = value;
    _safeNotify();
  }

  void setOfflineMode(bool value) {
    _isOfflineMode = value;
    _safeNotify();
  }

  Future<void> updateAvailability(bool value) async {
    try {
      await _authRepository.updateAvailability(value);
      if (_user != null) {
        _user = _user!.copyWith(isAvailable: value);
        _safeNotify();
      }
    } catch (e) {
      print("Error updating availability: $e");
      rethrow;
    }
  }

  Future<void> checkAuth() async {
    _isLoading = true;
    _safeNotify();
    try {
      _user = await _authRepository.getMe();
      if (_user != null) {
        try {
          PushNotificationService.uploadPendingToken();
        } catch (e) {
          print("⚠️ Error uploading token on checkAuth: $e");
        }

        LocationService()
            .getCurrentLocation()
            .then((loc) {
              if (loc != null) {
                _authRepository.updateProfile(
                  email: _user?.email,
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
      _safeNotify();
    }
  }

  Future<bool> login({
    String? email,
    String? phone,
    required String password,
    bool rememberMe = false,
  }) async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      if ((email == null && phone == null) || password.isEmpty) {
        _error = 'Email/Téléphone et mot de passe requis';
        _isLoading = false;
        _safeNotify();
        return false;
      }

      _user = await _authRepository.login(
        email: email,
        phone: phone,
        password: password,
        rememberMe: rememberMe,
      );

      try {
        PushNotificationService.uploadPendingToken();
      } catch (e) {
        print('⚠️ FCM upload failed: $e');
      }

      try {
        final loc = await LocationService().getCurrentLocation();
        if (loc != null) {
          await _authRepository.updateProfile(
            email: _user?.email,
            latitude: loc.latitude,
            longitude: loc.longitude,
          );
          final updatedUser = await _authRepository.getMe();
          if (updatedUser != null) _user = updatedUser;
        }
      } catch (e) {
        print("⚠️ Failed to update location on login: $e");
      }

      _isLoading = false;
      _showLogin = false;
      _safeNotify();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print('⚠️ Failed to signOut: $e');
      }

      await _googleSignIn.initialize();
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) throw Exception("ID Token Google manquant");

      _user = await _authRepository.loginWithGoogle(idToken);

      PushNotificationService.uploadPendingToken();
      _showLogin = false;
      _isLoading = false;
      _safeNotify();
      return true;
    } catch (e) {
      if (e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
        _error = e.toString().contains('16')
            ? 'Erreur Google (Code 16): Vérifiez la configuration SHA-1.'
            : 'Authentification annulée.';
      } else {
        _error = e.toString().replaceAll('Exception: ', '');
      }
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    String? email,
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
    _safeNotify();

    try {
      final result = await _authRepository.register(
        name: name,
        email: email != null && email.isNotEmpty ? email : null,
        password: password,
        phone: phone != null && phone.isNotEmpty ? phone : null,
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

      _user = result['user'];
      PushNotificationService.uploadPendingToken();
      _isLoading = false;
      _safeNotify();

      return {
        'success': true,
        'requireVerification': result['requireVerification'] ?? false,
        'message': result['message'],
        'identifier': email ?? phone,
        'verificationMethod': email != null ? 'email' : 'phone',
      };
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      _safeNotify();
      return {'success': false, 'error': _error};
    }
  }

  Future<void> sendOtp(String identifier, String type) async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      await _authRepository.sendOtp(identifier, type);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<void> verifyOtp(String identifier, String code, String type) async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      await _authRepository.verifyOtp(identifier, code, type);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
      _user = null;
      _isOfflineMode = false;
      _safeNotify();
    } catch (e) {
      print('⚠️ Logout error: $e');
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    _isLoading = true;
    _safeNotify();

    try {
      await _authRepository.updateProfile(
        email: _user?.email,
        latitude: latitude,
        longitude: longitude,
      );
      _user = await _authRepository.getMe();
    } catch (e) {
      print("🔴 Error updating location: $e");
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }
}
