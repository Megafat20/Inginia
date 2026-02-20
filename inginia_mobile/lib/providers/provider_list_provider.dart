import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/provider_repository.dart';

class ProviderListProvider extends ChangeNotifier {
  final ProviderRepository _repository = ProviderRepository();

  List<User> _providers = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String? _error;

  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;

  // Filters
  String _searchQuery = '';
  int? _activeProfessionId;
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  bool _filterOnlyAvailable = false;
  String _sortOption = 'default';

  // Localization
  double? _latitude;
  double? _longitude;
  double? _radius = 20.0; // km

  // Getters
  List<User> get providers => _providers;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  String? get error => _error;
  bool get filterOnlyAvailable => _filterOnlyAvailable;
  String get searchQuery => _searchQuery;
  int? get activeProfessionId => _activeProfessionId;
  String get sortOption => _sortOption;
  bool get hasMore => _currentPage < _lastPage;

  // Setters with notify
  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchProviders(); // Refresh list on search
  }

  void setFilterOnlyAvailable(bool value) {
    _filterOnlyAvailable = value;
    fetchProviders();
  }

  void setActiveProfession(int? id) {
    _activeProfessionId = id;
    fetchProviders();
  }

  void setSortOption(String option) {
    _sortOption = option;
    fetchProviders();
  }

  void setLocationFilters(double? lat, double? lng, double? radius) {
    _latitude = lat;
    _longitude = lng;
    _radius = radius;
  }

  void applyAdvancedFilters({
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) {
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _minRating = minRating;
    fetchProviders();
  }

  Future<void> fetchProviders({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (_isFetchingMore || !hasMore) return;
      _isFetchingMore = true;
      _currentPage++;
    } else {
      _isLoading = true;
      _currentPage = 1;
      _providers = [];
    }

    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getProviders(
        q: _searchQuery,
        professionId: _activeProfessionId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
        onlyAvailable: _filterOnlyAvailable,
        latitude: _latitude,
        longitude: _longitude,
        radius: _radius,
        sort: _sortOption,
        page: _currentPage,
      );

      final List<User> newProviders = result['providers'];
      final meta = result['meta'];

      if (isLoadMore) {
        _providers.addAll(newProviders);
      } else {
        _providers = newProviders;
      }

      _currentPage = meta['current_page'];
      _lastPage = meta['last_page'];
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    }
  }
}
