import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  Timer? _heartbeatTimer; // Added heartbeat timer

  Future<void> init() async {
    if (_isConnected) {
      print("⚠️ WebSocket already connected");
      return;
    }

    try {
      // Configure host
      // Android Emulator: 10.0.2.2
      // iOS/Web: 127.0.0.1 (or specific IP)
      String host = '127.0.0.1';
      if (Platform.isAndroid) {
        host = '10.0.2.2';
      }

      // Connect to Reverb using Pusher protocol
      // Format: ws://host:port/app/{app_key}?protocol=7&client=dart&version=1.0.0
      final wsUrl =
          'ws://$host:8080/app/inginia-key?protocol=7&client=dart&version=1.0.0';

      print("🔌 Connecting to: $wsUrl");
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen to connection
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          print("❌ WebSocket Error: $error");
          _isConnected = false;
          _heartbeatTimer?.cancel(); // Cancel timer on error
        },
        onDone: () {
          print("🔌 WebSocket connection closed");
          _isConnected = false;
          _heartbeatTimer?.cancel(); // Cancel timer on done
        },
      );

      _isConnected = true;

      // Start heartbeat every 30 seconds
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (_isConnected && _channel != null) {
          _channel!.sink.add(jsonEncode({'event': 'pusher:ping', 'data': {}}));
        }
      });

      print("✅ WebSocket Service Initialized");
    } catch (e) {
      print("❌ WebSocket Init Error: $e");
    }
  }

  final Map<String, Function(dynamic)> _callbacks = {};

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
        // Heartbeat
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
          // Note: we might want to pass the event name too so the callback knows what happened
          // For now, let's inject it into the data if it's a map
          if (finalData is Map<String, dynamic>) {
            finalData['_event'] = event;
          }
          _callbacks[channel]!(finalData);
        }
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
    _callbacks[channel] = onData;
    _subscribe(channel);
  }

  Future<void> listenToReservationUpdates(
    int reservationId,
    Function(dynamic) onData,
  ) async {
    // Le backend doit utiliser PrivateChannel('reservation.$id')
    // Le WebSocket ajoute le préfixe 'private-' pour l'auth
    final channel = 'private-reservation.$reservationId';
    _callbacks[channel] = onData;
    _subscribe(channel);
  }

  Future<void> listenToChat(int reservationId, Function(dynamic) onData) async {
    // Canal défini dans routes/channels.php : chat.{id}
    final channel = 'private-chat.$reservationId';
    _callbacks[channel] = onData;
    _subscribe(channel);
  }

  Future<void> _subscribe(String channel) async {
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
    // So we need to construct the full URL manually
    String host = '127.0.0.1';
    if (Platform.isAndroid) {
      host = '10.0.2.2';
    }
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

  Future<void> dispose() async {
    if (_channel != null) {
      await _channel!.sink.close();
      _isConnected = false;
      _callbacks.clear();
    }
  }
}
