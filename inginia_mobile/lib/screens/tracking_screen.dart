import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../repositories/provider_repository.dart'; // Pour getClientReservations (en fait on veut getReservationById)
import '../../models/reservation_model.dart';
import '../../services/api_service.dart'; // Si besoin direct
import '../../theme/app_theme.dart';

class TrackingScreen extends StatefulWidget {
  final int reservationId;

  const TrackingScreen({super.key, required this.reservationId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _repository =
      ProviderRepository(); // On ajoutera getReservationById si besoin ou Api direct
  // On va utiliser un ApiService direct pour simplifier ou ajouter la méthode au repo
  final _api = ApiService();

  Reservation? _reservation;
  LatLng? _providerPos;
  LatLng? _clientPos;
  Timer? _timer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchData(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData({bool silent = false}) async {
    try {
      // Appel direct API car repo n'a pas getById simple public (il a getClientReservations)
      // Ajustez selon votre repo
      final response = await _api.client.get(
        '/reservations/${widget.reservationId}',
      );
      final data = Reservation.fromJson(response.data);

      if (mounted) {
        setState(() {
          _reservation = data;
          if (data.clientLat != null && data.clientLng != null) {
            _clientPos = LatLng(data.clientLat!, data.clientLng!);
          } else {
            // Default Casablanca if null
            _clientPos = const LatLng(33.5731, -7.5898);
          }

          if (data.providerLat != null && data.providerLng != null) {
            _providerPos = LatLng(data.providerLat!, data.providerLng!);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Tracking Error: $e");
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Suivi de mission"),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _clientPos == null
          ? const Center(child: Text("Position introuvable"))
          : FlutterMap(
              options: MapOptions(
                initialCenter: _clientPos!, // Center on client
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.inginia.app',
                ),
                MarkerLayer(
                  markers: [
                    // Client Marker
                    Marker(
                      point: _clientPos!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: AppTheme.primary,
                        size: 40,
                      ),
                    ),
                    // Provider Marker (Car)
                    if (_providerPos != null)
                      Marker(
                        point: _providerPos!,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(blurRadius: 5, color: Colors.black26),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_car_rounded,
                            color: Colors.black,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
      bottomSheet: _reservation != null ? _buildBottomPanel() : null,
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _reservation!.providerName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Statut: ${_getStatusLabel(_reservation!.status)}",
            style: TextStyle(
              color: _getStatusColor(_reservation!.status),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Info or Distance could affect here
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (['accepted', 'confirmed'].contains(status)) return Colors.green;
    if (status == 'in_progress') return Colors.blue;
    return Colors.grey;
  }

  String _getStatusLabel(String status) {
    if (status == 'in_progress') return 'En route';
    return status;
  }
}
