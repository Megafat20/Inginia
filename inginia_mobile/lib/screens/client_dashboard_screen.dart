import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/provider_list_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'provider_detail_screen.dart';
import 'mission_screen.dart';
import 'client_profile_screen.dart';
import '../models/user_model.dart';
import '../services/location_service.dart';
import '../services/websocket_service.dart';
import 'package:google_fonts/google_fonts.dart';

import '../repositories/provider_repository.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:async';

enum ViewType { list, map }

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _activeCategory = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _sortOption = 'rating_desc';
  bool _showFavoritesOnly = false;

  final ProviderRepository _providerRepository = ProviderRepository();
  final LocationService _locationService = LocationService();
  List<Map<String, dynamic>> _professions = [];
  Set<int> _favoriteIds = {};
  Position? _userPosition;
  double _radiusFilter = 20.0; // Rayon par défaut : 20km

  ViewType _viewType = ViewType.list;
  bool _showFilters = false;
  double _minPrice = 0;
  double _maxPrice = 50000;
  double _minRating = 0;
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();

  bool _sosEnabled = false;
  Timer? _sosActivationTimer;

  String? _sosStatus;
  Timer? _sosCountdownTimer;
  final ApiService _apiService = ApiService();
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Listen to tab changes to update UI (like Hero section visibility)
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadData();

    // Scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        Provider.of<ProviderListProvider>(
          context,
          listen: false,
        ).fetchProviders(isLoadMore: true);
      }
    });

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
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isAuthenticated && authProvider.user != null) {
          WebSocketService().listenToGlobalUserEvents(authProvider.user!.id);
        }

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
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    _sosActivationTimer?.cancel();
    _sosCountdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final providerListProvider = Provider.of<ProviderListProvider>(context);

    return Scaffold(
      floatingActionButton:
          (_tabController.index == 0 && !authProvider.isOfflineMode)
          ? FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.heavyImpact();
                _showSOSDialog();
              },
              backgroundColor: AppTheme.error,
              icon: const Icon(Icons.sos_rounded, color: Colors.white),
              label: const Text(
                "URGENCE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              elevation: 4,
              highlightElevation: 8,
            )
          : null,
      body: Stack(
        children: [
          // Background Gradient Blobs with Animation (Static for now but prepped)
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
                    AppTheme.primary.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF6B4EFF).withOpacity(0.1), // Distinct accent
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmallHeight = constraints.maxHeight < 700;
              return Column(
                children: [
                  // Mode Consultation Banner
                  if (!authProvider.isAuthenticated ||
                      authProvider.isOfflineMode)
                    Container(
                      width: double.infinity,
                      color: Colors.amber.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.visibility_off_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      !authProvider.isAuthenticated
                                          ? "Mode Consultation (Connectez-vous pour commander)"
                                          : "Mode Consultation : Compte en attente de validation",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                if (!authProvider.isAuthenticated) {
                                  authProvider.setShowLogin(true);
                                } else {
                                  authProvider.setOfflineMode(false);
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 0,
                                ),
                                minimumSize: const Size(0, 30),
                              ),
                              child: Text(
                                !authProvider.isAuthenticated
                                    ? "Se connecter"
                                    : "Quitter",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Hero Section (only visible on Explorer tab)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutQuint,
                    height: _tabController.index == 0
                        ? (isSmallHeight
                              ? 280
                              : 340) // Reduced height per user request
                        : 0,
                    child: _tabController.index == 0
                        ? _buildHeroSection(isSmallHeight)
                        : const SizedBox.shrink(),
                  ),

                  // Floating Tab Navigation with Glassmorphism
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      isSmallHeight ? 10 : 20, // More breathing room
                      16,
                      isSmallHeight ? 4 : 10,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.85,
                        ), // Glass effect base
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        // BackdropFilter omitted for performance unless requested, simulated via opacity
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primary,
                                  AppTheme.primaryDark,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.grey[600],
                            labelPadding: EdgeInsets.zero,
                            labelStyle: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                            unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: 0,
                            ),
                            tabs: [
                              Tab(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.explore_outlined, size: 18),
                                      SizedBox(width: 4),
                                      Text('Explorer'),
                                    ],
                                  ),
                                ),
                              ),
                              Tab(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.grid_view_rounded, size: 18),
                                      SizedBox(width: 4),
                                      Text('Missions'),
                                    ],
                                  ),
                                ),
                              ),
                              Tab(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.person_outline_rounded,
                                        size: 18,
                                      ),
                                      SizedBox(width: 4),
                                      Text('Profil'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            onTap: (index) => setState(() {}),
                          ),
                        ),
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
              );
            },
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
                      HapticFeedback.mediumImpact();
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

      // NEW: Send to API
      final response = await _apiService.client.post('/sos', data: data);

      // NEW: Log SOS to database
      await _logSOSToDatabase(data);

      if (mounted) Navigator.pop(context);

      if (mounted) {
        setState(() {
          _sosStatus = 'Alerte Envoyée - En attente';
        });

        // NEW: Start countdown timer
        _startSOSCountdown();

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
    } catch (e) {
      print("❌ Error sending SOS: $e");
      if (mounted) Navigator.pop(context);

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
  }

  Future<void> _logSOSToDatabase(Map<String, dynamic> sosData) async {
    try {
      await _apiService.client.post(
        '/sos-logs',
        data: {
          ...sosData,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print("❌ Error logging SOS: $e");
    }
  }

  // NEW: Countdown timer for SOS feedback
  void _startSOSCountdown() {
    _sosCountdownTimer?.cancel();
    int seconds = 5;

    _sosCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _sosStatus = 'Confirmer dans $seconds s';
        });
        seconds--;
      }

      if (seconds < 0) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _sosStatus = null;
            _sosEnabled = false;
          });
        }
      }
    });
  }

  // NEW: User confirmation of SOS via snackbar
  void _confirmSOSWithSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Alerte confirmée"),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            setState(() {
              _sosEnabled = false;
              _sosStatus = null;
            });
          },
        ),
      ),
    );
  }

  // NEW: Handle SOS location retrieval error
  Future<void> _handleSOSLocationError() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur localisation"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // NEW: Automatic retry for SOS after 30 seconds
  void _startSOSRetryMechanism() {
    Timer(const Duration(seconds: 30), () {
      if (mounted && _sosStatus == 'Alerte Envoyée - En attente') {
        print("🔄 Retrying SOS...");
        _showSOSDialog();
      }
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
        Provider.of<ProviderListProvider>(
          context,
          listen: false,
        ).setSearchQuery(query);
      }
    });
  }

  Widget _buildHeroSection(bool isSmallHeight) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E1065), // Dark Purple
            const Color(0xFF7C3AED), // Violet
          ],
          stops: const [0.2, 0.9],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: isSmallHeight ? 8 : 16,
              ),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Service Badge & Logout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withOpacity(0.4),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'SERVICE 24/7',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isSmallHeight ? 10 : 20),

                    // Main Title
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trouvez le',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: isSmallHeight ? 20 : 24, // Reduced
                            fontWeight: FontWeight.normal,
                            height: 1.1,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'meilleur ',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: isSmallHeight ? 28 : 34, // Reduced
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            Expanded(
                              child: ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      colors: [
                                        Color(0xFF60A5FA),
                                        Color(0xFFA78BFA),
                                      ],
                                    ).createShader(bounds),
                                child: Text(
                                  'expert.',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: isSmallHeight
                                        ? 28
                                        : 34, // Reduced
                                    fontWeight: FontWeight.w800,
                                    fontStyle: FontStyle.italic,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(
                      height: isSmallHeight ? 12 : 16,
                    ), // Reduced spacing
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Électricien, Plombier...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: AppTheme.primary,
                                  size: 24,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                          Provider.of<ProviderListProvider>(
                                            context,
                                            listen: false,
                                          ).setSearchQuery('');
                                        },
                                      )
                                    : null,
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
                              onPressed: () {
                                // Trigger search or focus
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Trouver',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 12, // Reduced spacing
                    ),
                    // Filter Chips Row (No Scroll)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildFilterChip(
                            icon: Icons.map_rounded,
                            label: _viewType == ViewType.map
                                ? 'Liste'
                                : 'Carte',
                            isActive: true, // Always active style
                            onTap: () => setState(() {
                              _viewType = _viewType == ViewType.map
                                  ? ViewType.list
                                  : ViewType.map;
                            }),
                            isExpanded: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFilterChip(
                            icon: Icons.tune_rounded,
                            label: 'Filtres',
                            isActive: _showFilters,
                            onTap: () {
                              _showAdvancedFilters(context);
                            },
                            isExpanded: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildFilterChip(
                            icon: Icons.flash_on_rounded,
                            label: 'Dispo', // Shortened label
                            isActive: context
                                .watch<ProviderListProvider>()
                                .filterOnlyAvailable,
                            onTap: () {
                              final provider = context
                                  .read<ProviderListProvider>();
                              provider.setFilterOnlyAvailable(
                                !provider.filterOnlyAvailable,
                              );
                            },
                            isExpanded: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool isExpanded = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ), // Reduced horizontal padding
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20), // Slightly reduced radius
          border: Border.all(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: isExpanded
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppTheme.primary : Colors.white,
            ),
            const SizedBox(width: 6), // Reduced spacing
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? AppTheme.primary : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplorerTab(ProviderListProvider providerListProvider) {
    if (_viewType == ViewType.map) {
      return _buildMapView(providerListProvider);
    }

    // Logic de Filtrage et Tri
    var filteredProviders = providerListProvider.providers.where((provider) {
      // Filtre Catégorie
      bool matchesCategory = true;
      if (_activeCategory != 'all') {
        final categoryId = int.tryParse(_activeCategory);
        final matchById =
            categoryId != null && provider.professionIds.contains(categoryId);

        // On cherche le nom de la profession sélectionnée pour le fallback par nom
        final category = _professions.firstWhere(
          (p) => p['id'].toString() == _activeCategory.toString(),
          orElse: () => {'name': ''},
        );
        final categoryName = category['name'].toString().toLowerCase();

        // On vérifie si le service du provider correspond
        final serviceName = (provider.serviceName ?? '').toLowerCase();
        final professionNames = provider.professionNames
            .map((n) => n.toLowerCase())
            .toList();

        // On vérifie si la catégorie correspond soit au service, soit à une des professions
        final matchByName =
            serviceName.contains(categoryName) ||
            professionNames.any((name) => name.contains(categoryName));

        matchesCategory = matchById || matchByName;
      }

      // Filtre Favoris
      bool matchesFavorites = true;
      if (_showFavoritesOnly) {
        matchesFavorites = _favoriteIds.contains(provider.id);
      }

      // Filtre Recherche (Nom ou Service)
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = provider.name.toLowerCase();
        final service = (provider.serviceName ?? '').toLowerCase();
        final profs = provider.professionNames
            .map((n) => n.toLowerCase())
            .toList();

        matchesSearch =
            name.contains(query) ||
            service.contains(query) ||
            profs.any((p) => p.contains(query));
      }

      // Filtre Disponibilité
      bool matchesAvailability =
          !providerListProvider.filterOnlyAvailable || provider.isAvailable;

      return matchesCategory &&
          matchesFavorites &&
          matchesSearch &&
          matchesAvailability;
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

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([providerListProvider.fetchProviders(), _loadData()]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryChip('Tout voir', 'all'),
                    ..._professions.map(
                      (cat) => _buildCategoryChip(
                        cat['name']!,
                        cat['id'].toString(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Prestataires à proximité (Optimisé)
              Builder(
                builder: (context) {
                  List<User> nearbyProviders = filteredProviders;
                  if (_userPosition != null) {
                    nearbyProviders = LocationService.filterByRadius(
                      nearbyProviders,
                      _userPosition!.latitude,
                      _userPosition!.longitude,
                      _radiusFilter,
                    );
                    nearbyProviders = LocationService.sortByDistance(
                      nearbyProviders,
                      _userPosition!.latitude,
                      _userPosition!.longitude,
                    );
                  }
                  nearbyProviders = nearbyProviders.take(10).toList();
                  if (nearbyProviders.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'À proximité',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 250,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: nearbyProviders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 16),
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
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),

              // Simple Results Counter or Label
              const Text(
                'Résultats',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
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
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? value) {
    final isActive =
        Provider.of<ProviderListProvider>(
              context,
            ).activeProfessionId.toString() ==
            value.toString() ||
        (value == null &&
            Provider.of<ProviderListProvider>(context).activeProfessionId ==
                null);
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: Material(
          color: isActive ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          elevation: isActive ? 8 : 0,
          shadowColor: isActive
              ? AppTheme.primary.withOpacity(0.4)
              : Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              Provider.of<ProviderListProvider>(
                context,
                listen: false,
              ).setActiveProfession(value != null ? int.parse(value) : null);
              setState(
                () => _tabController.index = 0,
              ); // ensure we are on explorer
            },
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
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
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
      child:
          Container(
                width: 160, // Légèrement plus large pour les noms longs
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
                                  image: NetworkImage(
                                    provider.profilePhotoUrl!,
                                  ),
                                  fit: BoxFit.cover,
                                  onError: (exception, stackTrace) =>
                                      print("Image load error: $exception"),
                                )
                              : null,
                          color: AppTheme.primary.withOpacity(0.1),
                        ),
                        child: provider.profilePhotoUrl == null
                            ? Center(
                                child: Text(
                                  provider.name.isNotEmpty
                                      ? provider.name[0]
                                      : '?',
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
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    provider.avgRating?.toStringAsFixed(1) ??
                                        "Nouveau",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
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
                                        LocationService.getFormattedDistance(
                                          distance,
                                        ),
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
              )
              .animate()
              .fadeIn(duration: 200.ms)
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack,
              ),
    );
  }

  Widget _buildProvidersGrid(List providers) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.50, // More vertical space for content
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        return _buildProviderCard(provider)
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.1, end: 0);
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
            // Image Section
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: provider.profilePhotoUrl != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(28),
                              topRight: Radius.circular(28),
                            ),
                            child: Image.network(
                              provider.profilePhotoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                    child: Icon(
                                      Icons.person,
                                      size: 40,
                                      color: AppTheme.primary.withOpacity(0.5),
                                    ),
                                  ),
                            ),
                          )
                        : Center(
                            child: CircleAvatar(
                              radius: 35,
                              backgroundColor: AppTheme.primary.withOpacity(
                                0.2,
                              ),
                              child: Text(
                                (provider.name ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(
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
                      child: const Icon(
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
                          const Icon(
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

            // Info Section
            Expanded(
              flex: 3, // Increased flex for text content
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: SingleChildScrollView(
                  physics:
                      const NeverScrollableScrollPhysics(), // Only scroll if absolutely necessary, but actually Column will just fit better if we use start.
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
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
                              const Icon(
                                Icons.location_on,
                                size: 12,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  provider.location ?? 'Non spécifié',
                                  style: const TextStyle(
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
                          if (_userPosition != null)
                            Builder(
                              builder: (context) {
                                final dist =
                                    LocationService.getProviderDistance(
                                      provider,
                                      _userPosition!.latitude,
                                      _userPosition!.longitude,
                                    );
                                if (dist == null)
                                  return const SizedBox.shrink();
                                return Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
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
                                        LocationService.getFormattedDistance(
                                          dist,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.white,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.58,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.surface),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 10,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              height: 16,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Container(
                              height: 24,
                              width: 24,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 60,
                  color: AppTheme.primary.withOpacity(0.2),
                ),
                Text('🔎', style: TextStyle(fontSize: 40))
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(
                      duration: 2.seconds,
                      color: Colors.white.withOpacity(0.5),
                    )
                    .moveY(
                      begin: -5,
                      end: 5,
                      curve: Curves.easeInOut,
                      duration: 1.5.seconds,
                    )
                    .then()
                    .moveY(
                      begin: 5,
                      end: -5,
                      curve: Curves.easeInOut,
                      duration: 1.5.seconds,
                    ),
              ],
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
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 8),
          Text(
            'Réessayez avec d\'autres filtres ou catégories',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 32),
          if (_activeCategory != 'all' ||
              _searchQuery.isNotEmpty ||
              _showFavoritesOnly)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _activeCategory = 'all';
                  _searchQuery = '';
                  _searchController.clear();
                  _showFavoritesOnly = false;
                });
              },
              icon: Icon(Icons.refresh_rounded),
              label: Text("Réinitialiser les filtres"),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppTheme.primary.withOpacity(0.2)),
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  // Helper to build map view
  Widget _buildMapView(ProviderListProvider providerListProvider) {
    if (_userPosition == null) {
      return const Center(
        child: Text(
          "Localisation non disponible. Activez la localisation pour voir la carte.",
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(
          _userPosition!.latitude,
          _userPosition!.longitude,
        ),
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.inginia.mobile',
        ),
        MarkerLayer(
          markers: providerListProvider.providers
              .map((provider) {
                if (provider.latitude == null || provider.longitude == null) {
                  return null;
                }
                return Marker(
                  point: LatLng(provider.latitude!, provider.longitude!),
                  width: 60,
                  height: 60,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProviderDetailScreen(
                            providerId: provider.id,
                            providerName: provider.name,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primary,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: AppTheme.primary,
                            size: 24,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(blurRadius: 2, color: Colors.black12),
                            ],
                          ),
                          child: Text(
                            provider.displayName,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              })
              .whereType<Marker>()
              .toList(),
        ),
      ],
    );
  }

  void _showAdvancedFilters(BuildContext context) {
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Filtres",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setStateModal(() {
                          _minPrice = 0;
                          _maxPrice = 50000;
                          _minRating = 0;
                        });
                      },
                      child: const Text("Réinitialiser"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  "Fourchette de prix",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                RangeSlider(
                  values: RangeValues(_minPrice, _maxPrice),
                  min: 0,
                  max: 100000,
                  divisions: 20,
                  labels: RangeLabels(
                    "${_minPrice.round()} FCFA",
                    "${_maxPrice.round()} FCFA",
                  ),
                  onChanged: (RangeValues values) {
                    setStateModal(() {
                      _minPrice = values.start;
                      _maxPrice = values.end;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${_minPrice.round()} FCFA"),
                    Text("${_maxPrice.round()} FCFA"),
                  ],
                ),

                const SizedBox(height: 20),
                const Text(
                  "Trier par",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField<String>(
                    value: _sortOption,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
                    onChanged: (val) => setStateModal(() => _sortOption = val!),
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  "Rayon de recherche (km)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: _radiusFilter,
                  min: 5,
                  max: 100,
                  divisions: 19,
                  label: "${_radiusFilter.round()} km",
                  onChanged: (val) => setStateModal(() => _radiusFilter = val),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Uniquement mes favoris",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Switch(
                      value: _showFavoritesOnly,
                      activeColor: AppTheme.primary,
                      onChanged: (val) =>
                          setStateModal(() => _showFavoritesOnly = val),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(ctx);
                      setState(() {
                        _showFilters = true; // Mark filters as active
                      });
                      Provider.of<ProviderListProvider>(
                        context,
                        listen: false,
                      ).applyAdvancedFilters(
                        minPrice: _minPrice,
                        maxPrice: _maxPrice,
                        minRating: _minRating,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "Appliquer les filtres",
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildMissionsTab() {
    return const MissionScreen();
  }
}
