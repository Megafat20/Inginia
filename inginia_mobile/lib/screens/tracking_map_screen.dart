import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../models/reservation_model.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';

class TrackingMapScreen extends StatefulWidget {
  final Reservation reservation;
  final bool isProvider;

  const TrackingMapScreen({
    super.key,
    required this.reservation,
    this.isProvider = false,
  });

  @override
  State<TrackingMapScreen> createState() => _TrackingMapScreenState();
}

class _TrackingMapScreenState extends State<TrackingMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _providerPos;
  LatLng? _clientPos;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();

    _clientPos = LatLng(
      widget.reservation.clientLat ?? 33.5731,
      widget.reservation.clientLng ?? -7.5898,
    );

    _providerPos = LatLng(
      widget.reservation.providerLat ?? 33.5731,
      widget.reservation.providerLng ?? -7.5898,
    );

    _fetchRoute();

    // If client, listen to real-time updates from provider
    if (!widget.isProvider) {
      WebSocketService().listenToReservationUpdates(widget.reservation.id, (
        data,
      ) {
        if (data['latitude'] != null && data['longitude'] != null) {
          setState(() {
            _providerPos = LatLng(data['latitude'], data['longitude']);
          });
          _updateRoute();
        }
      });
    }
  }

  Future<void> _fetchRoute() async {
    if (_providerPos == null || _clientPos == null) return;

    final url =
        'https://router.project-osrm.org/route/v1/driving/'
        '${_providerPos!.longitude},${_providerPos!.latitude};'
        '${_clientPos!.longitude},${_clientPos!.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List coords = data['routes'][0]['geometry']['coordinates'];
        setState(() {
          _routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      print("Error fetching route: $e");
      setState(() => _isLoadingRoute = false);
    }
  }

  void _updateRoute() {
    // Optionally throttle route updates to save batteries/data
    _fetchRoute();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isProvider ? "Itinéraire Client" : "Suivi Prestataire",
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _providerPos ?? _clientPos!,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.inginia.niger',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: AppTheme.primary,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Client Marker
                  Marker(
                    point: _clientPos!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.person_pin_circle,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                  // Provider Marker
                  if (_providerPos != null)
                    Marker(
                      point: _providerPos!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.directions_bike,
                        color: AppTheme.primary,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (_isLoadingRoute)
            const Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Calcul de l'itinéraire..."),
                  ),
                ),
              ),
            ),
          // Info Overlay
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Icon(
                        widget.isProvider ? Icons.person : Icons.engineering,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isProvider
                                ? "Client: ${widget.reservation.clientName}"
                                : "Prestataire: ${widget.reservation.providerName}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.isProvider
                                ? "Destination d'intervention"
                                : "En route vers vous",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: () {
                        if (_providerPos != null) {
                          _mapController.move(_providerPos!, 15.0);
                        }
                      },
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
}
