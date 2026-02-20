import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'push_notification_service.dart';
import 'api_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isConnecting = false;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  final Set<String> _subscribedChannels = {};
  final Map<String, List<Function(dynamic)>> _callbacks = {};
  final StreamController<Map<String, dynamic>> _eventStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get eventStream => _eventStreamController.stream;

  final StreamController<void> _manualRefreshController =
      StreamController<void>.broadcast();
  Stream<void> get manualRefreshStream => _manualRefreshController.stream;

  void triggerManualRefresh() {
    print("🔄 Triggering manual refresh for all listeners");
    _manualRefreshController.add(null);
  }

  Future<void> init() async {
    if (_isConnected || _isConnecting) return;
    _isConnecting = true;

    // Get host from ApiService
    String host = ApiService.serverHost;

    // Connect to Reverb using Pusher protocol
    final wsUrl =
        'ws://$host:8080/app/inginia-key?protocol=7&client=dart&version=1.0.0';

    print("🔌 Connecting to WebSocket: $wsUrl");
    _connect(wsUrl);
  }

  void _connect(String url) {
    try {
      _channel?.sink.close();
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen(
        (message) {
          _isConnecting = false;
          if (!_isConnected) {
            print("✅ WebSocket Connected");
            _isConnected = true;
            _startHeartbeat();
          }
          _handleMessage(message);
        },
        onError: (error) {
          print("❌ WebSocket Error: $error");
          _handleDisconnect(url);
        },
        onDone: () {
          print("🔌 WebSocket Connection Closed");
          _handleDisconnect(url);
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("❌ WebSocket Connection Exception: $e");
      _handleDisconnect(url);
    }
  }

  void _handleDisconnect(String url) {
    if (!_isConnected && !_isConnecting && _reconnectTimer?.isActive == true)
      return;

    _isConnected = false;
    _isConnecting = false;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _socketId = null;
    _subscribedChannels.clear();

    // Retry connection after 5 seconds
    print("🔄 Attempting to reconnect in 5s...");
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected && !_isConnecting) {
        _isConnecting = true;
        _connect(url);
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _subscribedChannels
        .clear(); // Reset to allow resubscribing on new connection
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isConnected && _channel != null) {
        _channel!.sink.add(jsonEncode({'event': 'pusher:ping', 'data': {}}));
      }
    });
  }

  void _addCallback(String channel, Function(dynamic) callback) {
    if (!_callbacks.containsKey(channel)) {
      _callbacks[channel] = [];
    }
    _callbacks[channel]!.add(callback);
  }

  String? _socketId;

  void _handleMessage(dynamic message) {
    try {
      final decoded = jsonDecode(message);
      final event = decoded['event'];
      final channel = decoded['channel'];
      final rawData = decoded['data'];

      print("📨 Received Event: $event on Channel: $channel");

      if (event == 'pusher:connection_established') {
        final data = jsonDecode(rawData);
        _socketId = data['socket_id'];
        print("✅ Connection established to Reverb. Socket ID: $_socketId");
      } else if (event == 'pusher:pong') {
        // Heartbeat - silent
      } else if (event == 'pusher_internal:subscription_succeeded') {
        print("✅ Subscription succeeded for $channel");
      } else {
        // Handle all other events (dynamic dispatch)
        dynamic finalData = rawData;
        if (rawData is String) {
          try {
            finalData = jsonDecode(rawData);
          } catch (_) {}
        }

        // Call global callback for urgent if applicable
        if (event == 'urgent.created' && _urgentRequestCallback != null) {
          _urgentRequestCallback!(finalData);
        }

        // Call specific channel callback with EVENT and DATA
        if (channel != null && _callbacks.containsKey(channel)) {
          if (finalData is Map<String, dynamic>) {
            finalData['_event'] = event;
          }
          for (var callback in _callbacks[channel]!) {
            callback(finalData);
          }
        }

        // Emit globally
        _eventStreamController.add({
          'channel': channel,
          'event': event,
          'data': finalData,
        });
      }

      // Log for debug if needed
      // print("   Raw message: $decoded");
    } catch (e) {
      print("❌ Error parsing message: $e");
    }
  }

  Function(dynamic)? _urgentRequestCallback;

  Future<void> listenToUrgentRequests(Function(dynamic) onData) async {
    _urgentRequestCallback = onData;
    _subscribe('urgent-requests');
  }

  Future<void> listenToUserUpdates(int userId, Function(dynamic) onData) async {
    final channel = 'private-user.$userId';
    _addCallback(channel, onData);
    _subscribe(channel);
  }

  Future<void> listenToReservationUpdates(
    int reservationId,
    Function(dynamic) onData,
  ) async {
    final channel = 'private-reservation.$reservationId';
    _addCallback(channel, onData);
    _subscribe(channel);
  }

  Future<void> listenToChat(int reservationId, Function(dynamic) onData) async {
    final channel = 'private-chat.$reservationId';
    _addCallback(channel, onData);
    _subscribe(channel);
  }

  Future<void> _subscribe(String channel) async {
    if (_subscribedChannels.contains(channel)) return;

    if (_channel == null || !_isConnected) {
      // Wait a bit and retry if we are just connecting
      await Future.delayed(const Duration(milliseconds: 500));
      if (_channel == null || !_isConnected) return;
    }

    Map<String, dynamic> data = {'channel': channel};

    if (channel.startsWith('private-')) {
      // Get auth signature from server
      try {
        final authData = await _getAuthSignature(channel);
        data['auth'] = authData['auth'];
      } catch (e) {
        print("❌ Auth failed for channel $channel: $e");
        return;
      }
    }

    final subscribeMessage = jsonEncode({
      'event': 'pusher:subscribe',
      'data': data,
    });

    _channel!.sink.add(subscribeMessage);
    _subscribedChannels.add(channel);
    print("📡 Subscribed to $channel");
  }

  Future<Map<String, dynamic>> _getAuthSignature(String channel) async {
    // Wait for socketId if it's not ready yet
    int retries = 0;
    while (_socketId == null && retries < 30) {
      await Future.delayed(const Duration(milliseconds: 200));
      retries++;
    }

    if (_socketId == null) throw Exception("Socket ID not available");

    // Broadcasting auth endpoint is at root level, not under /api
    String host = ApiService.serverHost;

    final authUrl = 'http://$host:8000/broadcasting/auth';

    // Get the auth token for the request
    final token = await ApiService().storage.read(key: 'auth_token');

    final response = await Dio().post(
      authUrl,
      data: {'socket_id': _socketId, 'channel_name': channel},
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return response.data;
  }

  Future<void> listenToGlobalUserEvents(int userId) async {
    final channel = 'private-user.$userId';
    _subscribe(channel);
    _addCallback(channel, (data) {
      // Analyze event type and show notification
      // Data usually comes with an '_event' key if we injected it, or we rely on the implementation to pass it.
      // In _handleMessage, I need to ensure event name is passed.

      final event = data['_event'] ?? '';
      final payload = data;

      if (event.contains('ReservationCreated') ||
          event.contains('reservation.created')) {
        PushNotificationService.showLocalNotification(
          RemoteMessage(
            notification: RemoteNotification(
              title: "Nouvelle Réservation",
              body: "Vous avez reçu une nouvelle demande de réservation.",
            ),
            data: {'type': 'new_reservation', 'reservation_id': payload['id']},
          ),
        );
      } else if (event.contains('ReservationUpdated') ||
          event.contains('reservation.updated')) {
        final status = payload['status'] ?? 'mis à jour';
        PushNotificationService.showLocalNotification(
          RemoteMessage(
            notification: RemoteNotification(
              title: "Mise à jour Réservation",
              body: "Le statut de votre réservation a changé : $status",
            ),
            data: {'type': 'status_change', 'reservation_id': payload['id']},
          ),
        );
      } else if (event.contains('MessageSent') ||
          event.contains('message.new') ||
          event.contains('message.sent')) {
        PushNotificationService.showLocalNotification(
          RemoteMessage(
            notification: RemoteNotification(
              title: "Nouveau Message",
              body: payload['message'] ?? "Vous avez un nouveau message",
            ),
            data: {
              'type': 'new_message',
              'reservation_id': payload['reservation_id'],
            },
          ),
        );
      } else if (event.contains('ProviderArrived') ||
          event.contains('tracking.arrived')) {
        PushNotificationService.showLocalNotification(
          RemoteMessage(
            notification: RemoteNotification(
              title: "Prestataire Arrivé",
              body: "Votre prestataire est arrivé sur le lieu du rendez-vous.",
            ),
            data: {
              'type': 'proximity',
              'reservation_id': payload['reservation_id'],
            },
          ),
        );
      } else if (event.contains('AccountValidated') ||
          event.contains('provider.validated')) {
        PushNotificationService.showLocalNotification(
          RemoteMessage(
            notification: RemoteNotification(
              title: "Compte Validé 🎉",
              body:
                  "Votre compte prestataire a été validé ! Vous pouvez maintenant recevoir des missions.",
            ),
            data: {'type': 'account_validated'},
          ),
        );
      }
    });
  }

  Future<void> dispose() async {
    if (_channel != null) {
      await _channel!.sink.close();
      _isConnected = false;
      _callbacks.clear();
      _heartbeatTimer?.cancel();
    }
  }
}
