import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../models/reservation_model.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

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
          if (!mounted) return;
          setState(() {
            _providerPos = LatLng(data['latitude'], data['longitude']);
          });
          _updateRoute();
          _fitMap();
        }
      });
    }

    // Auto-fit after a short delay
    Future.delayed(const Duration(milliseconds: 500), _fitMap);
  }

  void _fitMap() {
    if (_providerPos == null || _clientPos == null || !mounted) return;

    final bounds = LatLngBounds(_providerPos!, _clientPos!);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(70)),
    );
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
                    width: 50,
                    height: 50,
                    child:
                        Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.red,
                                  size: 30,
                                ),
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat())
                            .scale(
                              duration: 1.seconds,
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.1, 1.1),
                              curve: Curves.easeInOut,
                            )
                            .then()
                            .scale(
                              duration: 1.seconds,
                              begin: const Offset(1.1, 1.1),
                              end: const Offset(0.8, 0.8),
                              curve: Curves.easeInOut,
                            ),
                  ),
                  // Provider Marker
                  if (_providerPos != null)
                    Marker(
                      point: _providerPos!,
                      width: 50,
                      height: 50,
                      child:
                          Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withOpacity(0.4),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.directions_bike_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .moveY(
                                begin: -5,
                                end: 0,
                                duration: 600.ms,
                                curve: Curves.easeInOut,
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
                bottom: 30,
                left: 20,
                right: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
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
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.isProvider
                                  ? Icons.person_rounded
                                  : Icons.engineering_rounded,
                              color: AppTheme.primary,
                              size: 30,
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
                                      ? widget.reservation.clientName ??
                                            "Client"
                                      : widget.reservation.providerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  widget.isProvider
                                      ? "Destination d'intervention"
                                      : "En route vers vous",
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.my_location_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                if (_providerPos != null) {
                                  _fitMap();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: 500.ms)
              .slideY(
                begin: 0.5,
                end: 0,
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ),
        ],
      ),
    );
  }
}
