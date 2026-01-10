import 'dart:async';

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../repositories/provider_repository.dart';
import '../../models/reservation_model.dart';
import '../../services/tracking_service.dart';
import '../chat_screen.dart';
import '../tracking_map_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/websocket_service.dart';
import '../../widgets/shimmer_loading.dart';

class ProviderMissionsTab extends StatefulWidget {
  const ProviderMissionsTab({super.key});

  @override
  State<ProviderMissionsTab> createState() => _ProviderMissionsTabState();
}

class _ProviderMissionsTabState extends State<ProviderMissionsTab>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final _repository = ProviderRepository();
  List<Reservation>? _reservations;
  bool _isLoading = true;
  late TabController _tabController;
  Timer? _trackingTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchMissions();
    _initWebSocket();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Rafraîchir les missions quand le widget redevient visible
    if (mounted && !_isLoading) {
      _fetchMissions();
    }
  }

  void _initWebSocket() {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId != null) {
      WebSocketService().listenToUserUpdates(userId, (data) {
        _fetchMissions();
      });
    }
  }

  Future<void> _fetchMissions() async {
    try {
      final list = await _repository.getMyReservationsAsProvider();
      if (mounted) {
        setState(() {
          _reservations = list;
          _isLoading = false;
        });
        _checkTracking();

        // Listen to specific mission updates
        for (var res in list) {
          WebSocketService().listenToReservationUpdates(res.id, (data) {
            _fetchMissions();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  void _refresh() => _fetchMissions();

  void _checkTracking() {
    TrackingService.checkAndStartTracking();
  }

  Future<void> _updateStatus(int id, String status) async {
    String? reason;
    if (status == 'cancelled') {
      reason = await _showCancellationDialog();
      if (reason == null) return; // User cancelled the dialog
    }

    try {
      await ProviderRepository().updateMissionStatus(
        id,
        status,
        reason: reason,
      );

      if (status == 'accepted' || status == 'in_progress') {
        TrackingService.startTracking(id);
      } else {
        TrackingService.checkAndStartTracking();
      }

      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Statut mis à jour: $status"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showCancellationDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Annuler la mission"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Veuillez indiquer la raison de l'annulation :"),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Ex: Empêchement de dernière minute...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("FERMER"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("CONFIRMER L'ANNULATION"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Column(
      children: [
        // Header & Tabs
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Gestion des Missions",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: Colors.grey.shade600,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      indicatorPadding: const EdgeInsets.all(4),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      tabs: const [
                        Tab(text: "En attente"),
                        Tab(text: "En cours"),
                        Tab(text: "Terminées"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Content
        Expanded(
          child: Builder(
            builder: (context) {
              if (_isLoading && _reservations == null) {
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, __) => const MissionCardShimmer(),
                );
              }

              final all = _reservations ?? [];

              final pending = all.where((r) => r.status == 'pending').toList();
              final active = all
                  .where(
                    (r) => [
                      'confirmed',
                      'accepted',
                      'in_progress',
                    ].contains(r.status),
                  )
                  .toList();
              final history = all
                  .where(
                    (r) => [
                      'completed',
                      'cancelled',
                      'declined',
                    ].contains(r.status),
                  )
                  .toList();

              return TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildList(pending, isPending: true),
                  _buildList(active, isActive: true),
                  _buildList(history),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildList(
    List<Reservation> list, {
    bool isPending = false,
    bool isActive = false,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 50,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Aucune mission ici",
              style: TextStyle(
                color: AppTheme.textLight,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final r = list[index];
        return _buildCard(r, isPending: isPending, isActive: isActive);
      },
    );
  }

  Widget _buildCard(
    Reservation r, {
    bool isPending = false,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with client info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  backgroundImage: r.clientPhoto != null
                      ? NetworkImage(r.clientPhoto!)
                      : null,
                  child: r.clientPhoto == null
                      ? Text(
                          (r.clientName != null && r.clientName!.isNotEmpty
                                  ? r.clientName![0]
                                  : '?')
                              .toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.clientName ?? "Client",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.serviceTitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Chat Button
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            reservationId: r.id,
                            otherUserName: r.clientName ?? 'Client',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Date & Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  "${r.requestedDate.day}/${r.requestedDate.month}/${r.requestedDate.year} à ${r.requestedDate.hour}h${r.requestedDate.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(r.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(r.status),
                    style: TextStyle(
                      color: _getStatusColor(r.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (r.description != null && r.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  r.description!,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action Buttons
          if (isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateStatus(r.id, 'declined'),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text("Refuser"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(r.id, 'accepted'),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text("Accepter"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (isActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrackingMapScreen(
                            reservation: r,
                            isProvider: true,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.navigation_outlined, size: 18),
                    label: const Text("Itinéraire"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(r.id, 'completed'),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text("Marquer comme terminé"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Add footer with Chat and Report
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          reservationId: r.id,
                          otherUserName: r.clientName ?? 'Client',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text("Message"),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.flag_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: () => _reportProblem(r),
                  tooltip: "Signaler un problème",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reportProblem(Reservation r) async {
    final reasonController = TextEditingController();
    final descController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Signaler un problème"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Décrivez le problème rencontré avec ce client."),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: "Sujet / Motif",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: "Détails supplémentaires",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ANNULER"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) return;
              try {
                await ProviderRepository().reportProblem(
                  reportedId: r.clientId ?? 0,
                  reservationId: r.id,
                  reason: reasonController.text,
                  description: descController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Signalement envoyé."),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Erreur: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("ENVOYER"),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'confirmed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.teal;
      case 'declined':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'accepted':
        return 'Acceptée';
      case 'confirmed':
        return 'Confirmée';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminée';
      case 'declined':
        return 'Refusée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }
}
