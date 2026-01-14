import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/provider_repository.dart';

class ProviderListProvider extends ChangeNotifier {
  final ProviderRepository _repository = ProviderRepository();

  List<User> _providers = [];
  bool _isLoading = false;
  String? _error;
  bool _filterOnlyAvailable = false;

  List<User> get providers => _providers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get filterOnlyAvailable => _filterOnlyAvailable;

  List<User> get filteredProviders {
    if (_filterOnlyAvailable) {
      return _providers.where((p) => p.isAvailable).toList();
    }
    return _providers;
  }

  void setFilterOnlyAvailable(bool value) {
    _filterOnlyAvailable = value;
    notifyListeners();
  }

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
