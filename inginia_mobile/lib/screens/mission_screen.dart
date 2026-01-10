import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../repositories/provider_repository.dart';
import '../models/reservation_model.dart';
import 'chat_screen.dart';
import 'tracking_map_screen.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/review_dialog.dart';
import '../providers/auth_provider.dart';
import '../services/websocket_service.dart';

class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen>
    with SingleTickerProviderStateMixin {
  final _repository = ProviderRepository();
  List<Reservation>? _reservations;
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, in_progress, pending, completed
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fetchReservations();
    _initWebSocket();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initWebSocket() {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId != null) {
      WebSocketService().listenToUserUpdates(userId, (data) {
        _fetchReservations();
      });
    }
  }

  Future<void> _fetchReservations() async {
    try {
      final data = await _repository.getClientReservations();
      if (mounted) {
        setState(() {
          _reservations = data;
          _isLoading = false;
        });

        // Re-subscribe to updates for each reservation
        for (var res in data) {
          WebSocketService().listenToReservationUpdates(res.id, (updateData) {
            _fetchReservations();
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

  List<Reservation> get _filteredReservations {
    if (_reservations == null) return [];
    if (_selectedFilter == 'all') return _reservations!;

    return _reservations!.where((r) {
      final status = r.status.toLowerCase();
      switch (_selectedFilter) {
        case 'in_progress':
          return status == 'accepted' ||
              status == 'in_progress' ||
              status == 'confirmed';
        case 'pending':
          return status == 'pending';
        case 'completed':
          return status == 'completed' || status == 'paid';
        case 'cancelled':
          return status == 'cancelled' ||
              status == 'declined' ||
              status == 'refused';
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          "Mes Missions",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.refresh,
                color: AppTheme.textDark,
                size: 20,
              ),
            ),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchReservations();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterTab('Toutes', 'all'),
                  _buildFilterTab('En cours', 'in_progress'),
                  _buildFilterTab('En attente', 'pending'),
                  _buildFilterTab('Terminées', 'completed'),
                  _buildFilterTab('Annulées', 'cancelled'),
                ],
              ),
            ),
          ),

          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedFilter = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _reservations == null) {
      return ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, __) => const MissionCardShimmer(),
      );
    }

    if (_reservations == null) {
      return _buildErrorState();
    }

    final filtered = _filteredReservations;

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _fetchReservations,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final reservation = filtered[index];
          return _buildPremiumReservationCard(reservation);
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "Erreur de connexion",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _fetchReservations,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text("Réessayer"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    IconData icon;
    String message;

    switch (_selectedFilter) {
      case 'in_progress':
        icon = Icons.timelapse_rounded;
        message = "Aucune mission en cours";
        break;
      case 'pending':
        icon = Icons.hourglass_empty_rounded;
        message = "Aucune demande en attente";
        break;
      case 'completed':
        icon = Icons.task_alt_rounded;
        message = "Aucune mission terminée";
        break;
      case 'cancelled':
        icon = Icons.cancel_outlined;
        message = "Aucune mission annulée";
        break;
      default:
        icon = Icons.calendar_month_rounded;
        message = "Aucune mission trouvée";
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 48,
              color: AppTheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumReservationCard(Reservation r) {
    Color statusColor = _getStatusColor(r.status);
    String statusLabel = _getStatusLabel(r.status);
    bool isActive =
        r.status == 'accepted' ||
        r.status == 'in_progress' ||
        r.status == 'confirmed';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  "${r.requestedDate.day}/${r.requestedDate.month} à ${r.requestedDate.hour}h${r.requestedDate.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Provider & Service Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  backgroundImage: r.providerPhoto != null
                      ? NetworkImage(r.providerPhoto!)
                      : null,
                  child: r.providerPhoto == null
                      ? Text(
                          r.providerName.isNotEmpty ? r.providerName[0] : '?',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.serviceTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.providerName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (r.price != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            "${r.price} F",
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textDark,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                if (isActive) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TrackingMapScreen(reservation: r),
                          ),
                        );
                      },
                      icon: const Icon(Icons.location_on_rounded, size: 18),
                      label: const Text("Suivre"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // Chat Button always visible
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            reservationId: r.id,
                            otherUserName: r.providerName,
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: isActive ? AppTheme.textDark : AppTheme.primary,
                    ),
                    label: Text(
                      "Message",
                      style: TextStyle(
                        color: isActive ? AppTheme.textDark : AppTheme.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isActive
                            ? Colors.grey.shade300
                            : AppTheme.primary,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                if (r.status == 'completed') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final rated = await showDialog<bool>(
                          context: context,
                          builder: (_) => ReviewDialog(
                            prestataireId: r.providerId ?? 0,
                            reservationId: r.id,
                            providerName: r.providerName,
                          ),
                        );
                        if (rated == true) _fetchReservations();
                      },
                      icon: const Icon(Icons.star_rounded, size: 18),
                      label: const Text("Avis"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],

                if (r.status == 'pending') ...[
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.red),
                      onPressed: () => _cancelMission(r),
                      tooltip: "Annuler",
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'accepted':
      case 'in_progress':
        return AppTheme.primary;
      case 'completed':
      case 'paid':
        return Colors.green;
      case 'cancelled':
      case 'declined':
      case 'refused':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return "En attente";
      case 'accepted':
        return "Acceptée";
      case 'confirmed':
        return "Confirmée";
      case 'in_progress':
        return "En cours";
      case 'completed':
        return "Terminée";
      case 'cancelled':
        return "Annulée";
      case 'declined':
        return "Refusée";
      default:
        return status;
    }
  }

  Future<void> _cancelMission(Reservation r) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Annuler la mission"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Cette action est irréversible."),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "Raison (optionnel)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("RETOUR"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("ANNULER"),
          ),
        ],
      ),
    );

    if (reason != null) {
      try {
        await ProviderRepository().updateMissionStatus(
          r.id,
          'cancelled',
          reason: reason,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Mission annulée"),
              backgroundColor: Colors.orange,
            ),
          );
          _fetchReservations();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
