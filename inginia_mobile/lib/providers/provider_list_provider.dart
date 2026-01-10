import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/provider_repository.dart';

class ProviderListProvider extends ChangeNotifier {
  final ProviderRepository _repository = ProviderRepository();

  List<User> _providers = [];
  bool _isLoading = false;
  String? _error;

  List<User> get providers => _providers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProviders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _providers = await _repository.getProviders();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
