import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../main.dart';
import '../screens/chat_screen.dart';
import '../screens/mission_screen.dart';
import 'api_service.dart';

// Handler for background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 Background Message: ${message.notification?.title}");
}

class PushNotificationService {
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final StreamController<Map<String, dynamic>> _messageStream =
      StreamController.broadcast();
  static Stream<Map<String, dynamic>> get messageStream =>
      _messageStream.stream;

  static int _notificationId = 0;
  static int _badgeCount = 0;

  static Future<void> init() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request Permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true,
    );

    print("📱 Notification Permission: ${settings.authorizationStatus}");

    // Initialize Local Notifications with channels
    await _initializeLocalNotifications();

    // Get Token and Save
    final token = await _firebaseMessaging.getToken();
    print("📢 FCM Token: $token");
    if (token != null) {
      await _saveTokenToBackend(token);
    }

    // Handle Token Refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToBackend);

    // Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground Message: ${message.notification?.title}");
      _messageStream.add(message.data);
      _showLocalNotification(message);
      _incrementBadge();
    });

    // Handle Background/Terminated App Open
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🔄 App Opened via Notification");
      _handleMessageNavigation(message);
      _clearBadge();
    });

    // Handle Terminated State Open
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print("🚀 App launched from notification");
      Future.delayed(const Duration(seconds: 1), () {
        _handleMessageNavigation(initialMessage);
      });
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    // Android Notification Channels
    const AndroidNotificationChannel defaultChannel =
        AndroidNotificationChannel(
          'default',
          'Notifications générales',
          description: 'Notifications générales de l\'application',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );

    const AndroidNotificationChannel reservationsChannel =
        AndroidNotificationChannel(
          'reservations',
          'Réservations',
          description: 'Nouvelles demandes de réservation',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
        );

    const AndroidNotificationChannel messagesChannel =
        AndroidNotificationChannel(
          'messages',
          'Messages',
          description: 'Nouveaux messages',
          importance: Importance.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('message_sound'),
        );

    const AndroidNotificationChannel urgentChannel = AndroidNotificationChannel(
      'urgent',
      'Urgences',
      description: 'Demandes urgentes',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFFDC2626),
      sound: RawResourceAndroidNotificationSound('urgent_sound'),
    );

    const AndroidNotificationChannel statusChannel = AndroidNotificationChannel(
      'status_updates',
      'Mises à jour de statut',
      description: 'Changements de statut des réservations',
      importance: Importance.high,
    );

    const AndroidNotificationChannel trackingChannel =
        AndroidNotificationChannel(
          'tracking',
          'Suivi en temps réel',
          description: 'Notifications de localisation',
          importance: Importance.defaultImportance,
        );

    // Create channels
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(defaultChannel);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(reservationsChannel);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(messagesChannel);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(urgentChannel);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(statusChannel);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(trackingChannel);

    // Initialize settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          try {
            final data = jsonDecode(details.payload!);
            _navigateFromPayload(data);
          } catch (e) {
            print("Error parsing notification payload: $e");
          }
        }
      },
    );
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification == null) return;

    final type = data['type'] ?? 'default';
    final channelId = _getChannelId(type);

    // Determine notification style and priority
    final importance = type == 'urgent_request'
        ? Importance.max
        : (type == 'new_reservation'
              ? Importance.high
              : Importance.defaultImportance);

    final priority = type == 'urgent_request'
        ? Priority.max
        : (type == 'new_reservation'
              ? Priority.high
              : Priority.defaultPriority);

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId,
          _getChannelName(channelId),
          channelDescription: _getChannelDescription(channelId),
          importance: importance,
          priority: priority,
          playSound: true,
          enableVibration: true,
          color: _getNotificationColor(type),
          icon: '@mipmap/ic_launcher',
          largeIcon: notification.android?.imageUrl != null
              ? DrawableResourceAndroidBitmap('@mipmap/ic_launcher')
              : null,
          styleInformation: notification.body != null
              ? BigTextStyleInformation(
                  notification.body!,
                  contentTitle: notification.title,
                )
              : null,
          number: _badgeCount,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      _notificationId++,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(data),
    );
  }

  static String _getChannelId(String type) {
    switch (type) {
      case 'new_reservation':
        return 'reservations';
      case 'new_message':
        return 'messages';
      case 'urgent_request':
        return 'urgent';
      case 'status_change':
        return 'status_updates';
      case 'proximity':
        return 'tracking';
      default:
        return 'default';
    }
  }

  static String _getChannelName(String channelId) {
    switch (channelId) {
      case 'reservations':
        return 'Réservations';
      case 'messages':
        return 'Messages';
      case 'urgent':
        return 'Urgences';
      case 'status_updates':
        return 'Mises à jour';
      case 'tracking':
        return 'Suivi';
      default:
        return 'Notifications';
    }
  }

  static String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'reservations':
        return 'Nouvelles demandes de réservation';
      case 'messages':
        return 'Nouveaux messages';
      case 'urgent':
        return 'Demandes urgentes';
      case 'status_updates':
        return 'Changements de statut';
      case 'tracking':
        return 'Notifications de localisation';
      default:
        return 'Notifications générales';
    }
  }

  static Color _getNotificationColor(String type) {
    switch (type) {
      case 'new_reservation':
        return const Color(0xFF10B981);
      case 'new_message':
        return const Color(0xFF3B82F6);
      case 'urgent_request':
        return const Color(0xFFDC2626);
      case 'status_change':
        return const Color(0xFFF59E0B);
      case 'proximity':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF4F46E5);
    }
  }

  static void _handleMessageNavigation(RemoteMessage message) {
    _navigateFromPayload(message.data);
  }

  static void _navigateFromPayload(Map<String, dynamic> data) {
    final type = data['type'];
    final screen = data['screen'];
    final reservationIdStr = data['reservation_id'];

    if (reservationIdStr != null) {
      final reservationId = int.tryParse(reservationIdStr.toString());
      if (reservationId != null) {
        if (screen == 'chat' || type == 'new_message') {
          MyApp.navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                reservationId: reservationId,
                otherUserName: data['sender_name'] ?? "Contact",
              ),
            ),
          );
        } else if (screen == 'reservation_details' ||
            screen == 'mission_details') {
          MyApp.navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) =>
                  MissionScreen(initialReservationId: reservationId),
            ),
          );
        }
      }
    }
  }

  static Future<void> _saveTokenToBackend(String token) async {
    try {
      final storage = const FlutterSecureStorage();
      final authToken = await storage.read(key: 'auth_token');

      if (authToken == null) {
        print("⚠️ No auth token, skipping FCM token save");
        return;
      }

      final apiService = ApiService();
      await apiService.client.post(
        '/device-tokens/register',
        data: {
          'token': token,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        },
      );
      print("✅ FCM Token saved to backend");
    } catch (e) {
      print("❌ Error saving FCM token: $e");
    }
  }

  static Future<void> uploadPendingToken() async {
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToBackend(token);
    }
  }

  static void _incrementBadge() {
    _badgeCount++;
  }

  static void _clearBadge() {
    _badgeCount = 0;
  }

  static Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
    _clearBadge();
  }

  static Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}
