import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../main.dart';
import '../firebase_options.dart';
import '../screens/chat_screen.dart';
import '../screens/mission_screen.dart';
import 'api_service.dart';

class PushNotificationService {
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final StreamController<Map<String, dynamic>> _messageStream =
      StreamController.broadcast();
  static Stream<Map<String, dynamic>> get messageStream =>
      _messageStream.stream;

  static Future<void> init() async {
    // 1. Firebase should be initialized in main.dart before calling this

    // 2. Request Permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Initialize Local Notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle local notification click
        final payload = details.payload;
        if (payload != null) {
          // Parse JSON payload if needed
        }
      },
    );

    // 4. Get Token and Save
    final token = await _firebaseMessaging.getToken();
    print("📢 FCM Token: $token");
    if (token != null) {
      await _saveTokenToBackend(token);
    }

    // 5. Handle Token Refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToBackend);

    // 6. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Message Received: ${message.notification?.title}");
      _messageStream.add(message.data);
      // Optional: Check if we are in chat before showing notification
      _showLocalNotification(message);
    });

    // 7. Handle Background Open
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🔄 App Opened via Notification: ${message.data}");
      _handleMessageNavigation(message);
    });

    // 8. Handle Terminated State Open
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print("🚀 App launched from terminated state via notification");
      // Give the app a moment to load
      Future.delayed(const Duration(seconds: 1), () {
        _handleMessageNavigation(initialMessage);
      });
    }
  }

  static void _handleMessageNavigation(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    final reservationIdStr = data['reservation_id'];

    if (type == 'chat' && reservationIdStr != null) {
      final reservationId = int.tryParse(reservationIdStr);
      if (reservationId != null) {
        MyApp.navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              reservationId: reservationId,
              otherUserName: "Contact", // On pourrait passer le nom dans DATA
            ),
          ),
        );
      }
    } else if (type == 'reservation') {
      // Naviguer vers la liste des missions/réservations
      MyApp.navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const MissionScreen()),
      );
    } else if (type == 'sos') {
      // Naviguer vers le dashboard provider où s'affichent les SOS
      // Ou une page SOS spécifique
    }
  }

  static Future<void> _saveTokenToBackend(String token) async {
    try {
      final storage = const FlutterSecureStorage();
      final authToken = await storage.read(key: 'auth_token');

      if (authToken == null) {
        print("⚠️ Waiting for login to save FCM token");
        // Optionnel: on peut stocker le token localement pour l'envoyer juste après le login
        await storage.write(key: 'pending_fcm_token', value: token);
        return;
      }

      final api = ApiService();
      String platform = 'web';
      if (Platform.isAndroid) platform = 'android';
      if (Platform.isIOS) platform = 'ios';

      await api.client.post(
        '/devices/register',
        data: {'token': token, 'platform': platform},
      );
      print("✅ FCM Token registered to backend ($platform)");

      // Nettoyer le token en attente si existant
      await storage.delete(key: 'pending_fcm_token');
    } catch (e) {
      print("❌ Error saving FCM token: $e");
    }
  }

  static Future<void> uploadPendingToken() async {
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'pending_fcm_token');
    if (token != null) {
      print("📤 Found pending FCM token, uploading...");
      await _saveTokenToBackend(token);
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'inginia_channel',
          'Inginia Notifications',
          channelDescription: 'Notifications for Inginia app',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Nouvelle notification',
      message.notification?.body ?? '',
      platformDetails,
    );
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("📬 Background message: ${message.notification?.title}");
}
