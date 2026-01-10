import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/provider_list_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'provider_detail_screen.dart';
import 'mission_screen.dart';
import 'client_profile_screen.dart';
import '../models/user_model.dart';
import '../services/location_service.dart';

import '../repositories/provider_repository.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _activeCategory = 'all';
  String _sortOption = 'rating_desc';
  bool _showFavoritesOnly = false;

  final ProviderRepository _providerRepository = ProviderRepository();
  final LocationService _locationService = LocationService();
  List<Map<String, dynamic>> _professions = [];
  Set<int> _favoriteIds = {};
  Position? _userPosition;
  double _radiusFilter = 20.0; // Rayon par défaut : 20km

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();

    // Fetch providers on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProviderListProvider>(
        context,
        listen: false,
      ).fetchProviders();
    });
  }

  Future<void> _loadData() async {
    try {
      final profs = await _providerRepository.getAllProfessions();
      final favs = await _providerRepository.getFavorites();

      // Obtenir la position de l'utilisateur
      final position = await _locationService.getCurrentLocation();

      if (mounted) {
        setState(() {
          _professions = profs;
          _favoriteIds = favs.map((u) => u.id).toSet();
          _userPosition = position;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final authProvider = Provider.of<AuthProvider>(context);
    final providerListProvider = Provider.of<ProviderListProvider>(context);

    return Scaffold(
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showSOSDialog,
              backgroundColor: Colors.red,
              icon: const Icon(Icons.sos_rounded, color: Colors.white),
              label: const Text(
                "URGENCE",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          // Background Gradient Blobs
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accent.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          Column(
            children: [
              // Hero Section (only visible on Explorer tab)
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: _tabController.index == 0
                    ? 340
                    : 0, // Reduced height slightly to fit better
                child: _tabController.index == 0
                    ? _buildHeroSection()
                    : const SizedBox.shrink(),
              ),

              // Floating Tab Navigation
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppTheme.primaryDark,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textSecondary,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.explore_rounded, size: 20),
                        text: 'Explorer',
                      ),
                      Tab(
                        icon: Icon(Icons.assignment_rounded, size: 20),
                        text: 'Missions',
                      ),
                      Tab(
                        icon: Icon(Icons.person_rounded, size: 20),
                        text: 'Profil',
                      ),
                    ],
                    onTap: (index) => setState(() {}),
                  ),
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExplorerTab(providerListProvider),
                    _buildMissionsTab(),
                    const ClientProfileScreen(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSOSDialog() {
    final descriptionController = TextEditingController();
    String selectedType = 'Plomberie';
    final types = [
      'Plomberie',
      'Électricité',
      'Serrurerie',
      'Mécanique',
      'Autre',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 30,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Lancer une alerte SOS",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  "Type de problème",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: types.map((type) {
                    return ChoiceChip(
                      label: Text(type),
                      selected: selectedType == type,
                      selectedColor: Colors.red.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: selectedType == type ? Colors.red : Colors.black,
                        fontWeight: selectedType == type
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setStateModal(() {
                            selectedType = type;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: "Description (Optionnel)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _sendSOS(selectedType, descriptionController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "ENVOYER L'ALERTE",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _sendSOS(String type, String description) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.red)),
    );

    try {
      // 1. Get current position
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Les permissions de localisation sont refusées');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Les permissions de localisation sont définitivement refusées',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 2. Prepare data
      final data = {
        'problem_type': type,
        'description': description.isEmpty ? 'Urgence $type' : description,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print("🚨 Sending SOS: $data");

      // 3. Send to API
      final apiService = ApiService();
      await apiService.client.post('/sos', data: data);
    } catch (e) {
      print("❌ Error sending SOS: $e");
      if (mounted) Navigator.pop(context); // Close loading

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.pop(context); // Close loading

      // Show success dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Expanded(child: Text("Alerte Envoyée")),
            ],
          ),
          content: const Text(
            "Votre demande d'urgence a été diffusée à tous les prestataires à proximité. Vous serez notifié dès qu'un prestataire accepte.",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "OK",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildHeroSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryDark, AppTheme.primary],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header with Logout
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () {
                      // Using read to access provider without listening in this method
                      // Import provider package needed if not present, usually is.
                      // Accessing AuthProvider via context
                      // We need to import 'package:provider/provider.dart' and 'auth_provider.dart'
                      // Assuming they are imported.
                      // The logic to logout:
                      final auth = context
                          .read<AuthProvider>(); // Need to cast or import
                      auth.logout();
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.power_settings_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.2),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'SERVICES DISPONIBLES 24/7',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Main Title
                const Text(
                  'L\'expertise pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),

                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [AppTheme.accent, Colors.blue.shade200],
                  ).createShader(bounds),
                  child: const Text(
                    'au bout des doigts.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 28),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) => setState(() {}),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Électricien, Coach, Plombier...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppTheme.accent,
                              size: 24,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 8,
                            shadowColor: AppTheme.primary.withOpacity(0.5),
                          ),
                          child: const Text(
                            'Trouver',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExplorerTab(ProviderListProvider providerListProvider) {
    // Logic de Filtrage et Tri
    var filteredProviders = providerListProvider.providers.where((provider) {
      // Filtre Catégorie
      bool matchesCategory = true;
      if (_activeCategory != 'all') {
        // On cherche le nom de la profession sélectionnée
        final category = _professions.firstWhere(
          (p) => p['id'].toString() == _activeCategory.toString(),
          orElse: () => {'name': ''},
        );
        final categoryName = category['name'].toString().toLowerCase();

        // On vérifie si le service du provider correspond
        final serviceName = (provider.serviceName ?? '').toLowerCase();
        // Ou si le nom du provider contient le mot clé (recherche large)
        matchesCategory = serviceName.contains(categoryName);
      }

      // Filtre Favoris
      bool matchesFavorites = true;
      if (_showFavoritesOnly) {
        matchesFavorites = _favoriteIds.contains(provider.id);
      }

      return matchesCategory && matchesFavorites;
    }).toList();

    // Tri
    filteredProviders.sort((a, b) {
      switch (_sortOption) {
        case 'rating_desc':
          return (b.avgRating ?? 0).compareTo(a.avgRating ?? 0);
        case 'price_asc':
          // Traitement des nulls comme infini pour asc ou 0
          if (a.minPrice == null) return 1;
          if (b.minPrice == null) return -1;
          return a.minPrice!.compareTo(b.minPrice!);
        case 'price_desc':
          return (b.minPrice ?? 0).compareTo(a.minPrice ?? 0);
        default:
          return 0;
      }
    });

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Filters
            Row(
              children: [
                Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Catégories populaires',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryChip('Tout voir', 'all'),
                  ..._professions.map(
                    (cat) =>
                        _buildCategoryChip(cat['name']!, cat['id'].toString()),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Prestataires à proximité (New Section)
            if (providerListProvider.providers.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'À proximité',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    // Filtre par rayon
                    if (_userPosition != null)
                      PopupMenuButton<double>(
                        initialValue: _radiusFilter,
                        onSelected: (value) =>
                            setState(() => _radiusFilter = value),
                        icon: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.tune,
                                size: 16,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_radiusFilter.toInt()}km',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 5.0,
                            child: Text('📍 5 km'),
                          ),
                          const PopupMenuItem(
                            value: 10.0,
                            child: Text('📍 10 km'),
                          ),
                          const PopupMenuItem(
                            value: 20.0,
                            child: Text('📍 20 km'),
                          ),
                          const PopupMenuItem(
                            value: 50.0,
                            child: Text('📍 50 km'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 210, // Hauteur ajustée pour inclure la distance
                child: Builder(
                  builder: (context) {
                    // Trier et filtrer les prestataires par distance
                    List<User> nearbyProviders = providerListProvider.providers;

                    if (_userPosition != null) {
                      // Filtrer par rayon
                      nearbyProviders = LocationService.filterByRadius(
                        nearbyProviders,
                        _userPosition!.latitude,
                        _userPosition!.longitude,
                        _radiusFilter,
                      );

                      // Trier par distance
                      nearbyProviders = LocationService.sortByDistance(
                        nearbyProviders,
                        _userPosition!.latitude,
                        _userPosition!.longitude,
                      );
                    }

                    // Limiter à 10 prestataires
                    nearbyProviders = nearbyProviders.take(10).toList();

                    if (nearbyProviders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Aucun prestataire dans un rayon de ${_radiusFilter.toInt()}km',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: nearbyProviders.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final provider = nearbyProviders[index];
                        double? distance;
                        if (_userPosition != null) {
                          distance = LocationService.getProviderDistance(
                            provider,
                            _userPosition!.latitude,
                            _userPosition!.longitude,
                          );
                        }
                        return _buildNearbyProviderCard(provider, distance);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Filters Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.surface),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortOption,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        onChanged: (value) =>
                            setState(() => _sortOption = value!),
                        items: const [
                          DropdownMenuItem(
                            value: 'rating_desc',
                            child: Text('⭐ Mieux notés'),
                          ),
                          DropdownMenuItem(
                            value: 'price_asc',
                            child: Text('💰 Moins chers'),
                          ),
                          DropdownMenuItem(
                            value: 'price_desc',
                            child: Text('💎 Haut de gamme'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Favorites Toggle
                Material(
                  color: _showFavoritesOnly
                      ? AppTheme.accent.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () => setState(
                      () => _showFavoritesOnly = !_showFavoritesOnly,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _showFavoritesOnly
                              ? AppTheme.accent
                              : AppTheme.surface,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        _showFavoritesOnly
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _showFavoritesOnly
                            ? AppTheme.accent
                            : AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Providers Grid with FILTERED LIST
            providerListProvider.isLoading
                ? _buildLoadingGrid()
                : filteredProviders.isEmpty
                ? _buildEmptyState()
                : _buildProvidersGrid(filteredProviders),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    final isActive = _activeCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: isActive ? AppTheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: isActive ? 4 : 0,
        shadowColor: isActive
            ? AppTheme.primary.withOpacity(0.3)
            : Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _activeCategory = value),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: isActive ? AppTheme.primary : AppTheme.surface,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyProviderCard(User provider, [double? distance]) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderDetailScreen(
              providerId: provider.id,
              providerName: provider.name,
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  image: provider.profilePhotoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(provider.profilePhotoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: AppTheme.primary.withOpacity(0.1),
                ),
                child: provider.profilePhotoUrl == null
                    ? Center(
                        child: Text(
                          provider.name.isNotEmpty ? provider.name[0] : '?',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    provider.serviceName ?? 'Prestataire',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            provider.avgRating?.toStringAsFixed(1) ?? "Nouveau",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      // Afficher la distance si disponible
                      if (distance != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 10,
                                color: AppTheme.accent,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                LocationService.getFormattedDistance(distance),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvidersGrid(List providers) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        return _buildProviderCard(provider);
      },
    );
  }

  Widget _buildProviderCard(dynamic provider) {
    return GestureDetector(
      onTap: () {
        if (provider.id != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProviderDetailScreen(
                providerId: provider.id!,
                providerName: provider.name,
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.surface),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Center(
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: AppTheme.primary.withOpacity(0.2),
                        child: Text(
                          (provider.name ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Favorite Button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite_border,
                        color: AppTheme.textSecondary,
                        size: 16,
                      ),
                    ),
                  ),

                  // Verified Badge
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            color: AppTheme.primary,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'VÉRIFIÉ',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.name ?? 'Provider',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                provider.location ?? 'Non spécifié',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.star, color: Colors.amber, size: 12),
                              SizedBox(width: 4),
                              Text(
                                '5.0',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ), // Column
      ), // Container
    ); // GestureDetector
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(28),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🔎', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun résultat trouvé',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Réessayez avec d\'autres filtres',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsTab() {
    return const MissionScreen();
  }
}
