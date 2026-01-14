import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; // Import Dio
import '../../theme/app_theme.dart';
import 'provider_home_tab_enhanced.dart';
import 'provider_missions_tab.dart';
import 'provider_services_tab.dart';
import 'provider_profile_tab.dart';
import '../../services/websocket_service.dart';
import '../../services/api_service.dart';
import '../../services/tracking_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}
// ... (rest of the file remains same until _acceptUrgentRequest)

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  int _currentIndex = 0;

  // Clés uniques pour forcer le rebuild des tabs
  final GlobalKey<State<StatefulWidget>> _homeKey = GlobalKey();
  final GlobalKey<State<StatefulWidget>> _missionsKey = GlobalKey();
  final GlobalKey<State<StatefulWidget>> _servicesKey = GlobalKey();
  final GlobalKey<State<StatefulWidget>> _profileKey = GlobalKey();

  // Méthode pour obtenir le widget actuel avec sa clé
  Widget _getCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return ProviderHomeTabEnhanced(key: _homeKey);
      case 1:
        return ProviderMissionsTab(key: _missionsKey);
      case 2:
        return ProviderServicesTab(key: _servicesKey);
      case 3:
        return ProviderProfileTab(key: _profileKey);
      default:
        return ProviderHomeTabEnhanced(key: _homeKey);
    }
  }

  @override
  void initState() {
    super.initState();
    // Listen to real-time updates
    WebSocketService().listenToUrgentRequests(_handleUrgentRequest);
  }

  void _handleUrgentRequest(dynamic rawData) {
    print("🔔 New Urgent Request received!");
    print("🔹 Raw Data Type: ${rawData.runtimeType}");
    print("🔹 Raw Data Content: $rawData");

    if (!mounted) return;

    // Parse data
    Map<String, dynamic> data = {};
    try {
      if (rawData is String) {
        print("🔹 Decoding JSON String...");
        final decoded = jsonDecode(rawData);
        print("🔹 Decoded Type: ${decoded.runtimeType}");
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        }
      } else if (rawData is Map) {
        print("🔹 Using Map directly...");
        data = Map<String, dynamic>.from(rawData);
      }

      print("🔹 Final Data Keys before check: ${data.keys.toList()}");

      // Laravel wraps event public properties. If property is $requestData, json is { "requestData": {...} }
      if (data.containsKey('requestData')) {
        print("🔹 Found wrapper 'requestData', extracting content...");
        if (data['requestData'] is Map) {
          data = Map<String, dynamic>.from(data['requestData']);
        }
      }

      print("🔹 Final Data Keys after check: ${data.keys.toList()}");
      print("🔹 Final Data Values: $data");
    } catch (e) {
      print("❌ Error parsing urgent request data: $e");
      return;
    }

    final String clientName = data['user_name'] ?? 'Inconnu';
    final String problemType = data['problem_type'] ?? 'Urgence';
    final String description = data['description'] ?? 'Pas de description';

    // Show a prominent notification
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 30,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Nouvelle Urgence !",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Client: $clientName",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Type: $problemType",
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Description:",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("IGNORER", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              // Accept logic
              _acceptUrgentRequest(ctx, data);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("ACCEPTER LA MISSION"),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptUrgentRequest(
    BuildContext dialogContext,
    Map<String, dynamic> data,
  ) async {
    // Close alert dialog
    Navigator.of(dialogContext).pop();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.red)),
    );

    final payload = {
      'client_id': data['user_id'],
      'latitude': data['latitude'],
      'longitude': data['longitude'],
      'problem_type': data['problem_type'],
    };
    print("🚀 Accepting SOS with payload: $payload");

    try {
      final api = ApiService();
      final response = await api.client.post('/sos/accept', data: payload);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading

        // Show success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mission acceptée !"),
            backgroundColor: Colors.green,
          ),
        );

        // 🔥 Démarrer le suivi GPS pour l'admin
        final reservationId = response.data['reservation_id'];
        if (reservationId != null) {
          TrackingService.startTracking(reservationId);
        }

        // Redirect to missions tab
        setState(() {
          _currentIndex = 1;
        });
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Close loading
      print("❌ Error accepting SOS: $e");

      String errorMessage = "Une erreur est survenue";
      if (e is DioException) {
        errorMessage = "Erreur ${e.response?.statusCode}: ${e.message}";
        if (e.response?.data != null) {
          print("Server Response Data: ${e.response?.data}");
          // Si c'est une validation Laravel (422), on a souvent { message: "...", errors: {...} }
          if (e.response?.data is Map) {
            final errData = e.response?.data as Map;
            if (errData.containsKey('message')) {
              errorMessage = errData['message'];
            }
            if (errData.containsKey('errors')) {
              errorMessage += "\n" + errData['errors'].toString();
            }
          } else {
            errorMessage += "\n" + e.response!.data.toString();
          }
        }
      } else {
        errorMessage = e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isAvailable = user?.isAvailable ?? false;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          "Tableau de bord",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Row(
            children: [
              Text(
                isAvailable ? "Disponible" : "Indisponible",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isAvailable ? Colors.green : Colors.red,
                ),
              ),
              Switch(
                value: isAvailable,
                activeColor: Colors.green,
                onChanged: (value) {
                  context.read<AuthProvider>().updateAvailability(value);
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      // Utilisation de _getCurrentTab() pour forcer le rebuild lors du changement d'onglet
      body: _getCurrentTab(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(
                    0,
                    Icons.grid_view_rounded,
                    "Accueil",
                  ), // Changed Icon
                  _buildNavItem(
                    1,
                    Icons.calendar_month_rounded,
                    "Missions",
                  ), // Changed Icon
                  _buildNavItem(2, Icons.design_services_rounded, "Services"),
                  _buildNavItem(
                    3,
                    Icons.person_outline_rounded,
                    "Profil",
                  ), // Changed Icon
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : Colors.grey.shade400,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
