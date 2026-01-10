import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/provider_list_provider.dart';
import 'screens/login_screen.dart';
import 'screens/client_dashboard_screen.dart';
import 'screens/provider/provider_dashboard_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'services/push_notification_service.dart';

import 'services/websocket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize push notifications
  await PushNotificationService.init();

  // Initialize WebSocket Service for Realtime
  await WebSocketService().init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
        ChangeNotifierProvider(
          create: (_) => ProviderListProvider(),
        ), // <--- Ajout du Provider
      ],
      child: MaterialApp(
        title: 'Inginia Mobile',
        navigatorKey: navigatorKey, // <--- Ajout de la clé de navigation
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme, // <--- Application du Design System
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    // User is authenticated - show dashboard based on role
    final user = authProvider.user;

    // Admin Dashboard
    if (user?.role == 'admin') {
      return const AdminDashboardScreen();
    }

    // Provider Dashboard
    if (user?.role == 'prestataire' || user?.role == 'provider') {
      return const ProviderDashboardScreen();
    }

    // Client Dashboard (default)
    return const ClientDashboardScreen();
  }
}
