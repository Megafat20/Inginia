import 'dart:convert';
import 'package:flutter/material.dart';
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
import 'package:google_fonts/google_fonts.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const RepaintBoundary(
      child: ProviderHomeTabEnhanced(key: ValueKey('home')),
    ),
    const RepaintBoundary(
      child: ProviderMissionsTab(key: ValueKey('missions')),
    ),
    const RepaintBoundary(
      child: ProviderServicesTab(key: ValueKey('services')),
    ),
    const RepaintBoundary(child: ProviderProfileTab(key: ValueKey('profile'))),
  ];

  @override
  void initState() {
    super.initState();
    WebSocketService().listenToUrgentRequests(_handleUrgentRequest);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated && authProvider.user != null) {
        WebSocketService().listenToGlobalUserEvents(authProvider.user!.id);
      }
    });
  }

  void _handleUrgentRequest(dynamic rawData) {
    if (!mounted) return;

    Map<String, dynamic> data = {};
    try {
      if (rawData is String) {
        data = jsonDecode(rawData);
      } else if (rawData is Map) {
        data = Map<String, dynamic>.from(rawData);
      }

      if (data.containsKey('requestData') && data['requestData'] is Map) {
        data = Map<String, dynamic>.from(data['requestData']);
      }
    } catch (e) {
      return;
    }

    final String clientName = data['user_name'] ?? 'Inconnu';
    final String problemType = data['problem_type'] ?? 'Urgence';
    final String description = data['description'] ?? 'Pas de description';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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
              child: const Text(
                "IGNORER",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => _acceptUrgentRequest(ctx, data),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("ACCEPTER LA MISSION"),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _acceptUrgentRequest(
    BuildContext dialogContext,
    Map<String, dynamic> data,
  ) async {
    Navigator.of(dialogContext).pop();
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

    try {
      final api = ApiService();
      final response = await api.client.post('/sos/accept', data: payload);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mission acceptée !"),
            backgroundColor: Colors.green,
          ),
        );

        final reservationId = response.data['reservation_id'];
        if (reservationId != null) {
          TrackingService.startTracking(reservationId);
        }

        setState(() => _currentIndex = 1);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = context.select<AuthProvider, bool>(
      (auth) => auth.user?.isAvailable ?? false,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            "Espace Prestataire",
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
              fontSize: 22,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isAvailable
                    ? Colors.green.shade200
                    : Colors.red.shade200,
              ),
            ),
            child: RepaintBoundary(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isAvailable ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAvailable ? "Disponible" : "Indisponible",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isAvailable
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 24,
                    width: 36,
                    child: Switch(
                      value: isAvailable,
                      activeColor: Colors.green,
                      activeTrackColor: Colors.green.shade200,
                      inactiveThumbColor: Colors.red,
                      inactiveTrackColor: Colors.red.shade200,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (value) async {
                        try {
                          await context.read<AuthProvider>().updateAvailability(
                            value,
                          );
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceAll('Exception: ', ''),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs.asMap().entries.map((entry) {
          return ExcludeSemantics(
            excluding: _currentIndex != entry.key,
            child: entry.value,
          );
        }).toList(),
      ),
      bottomNavigationBar: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, "Accueil"),
            _buildNavItem(1, Icons.assignment_rounded, "Missions"),
            _buildNavItem(2, Icons.business_center_rounded, "Services"),
            _buildNavItem(3, Icons.person_rounded, "Profil"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 16 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primary : Colors.grey.shade500,
                size: 22,
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
