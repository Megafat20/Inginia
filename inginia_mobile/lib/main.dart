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
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pending_validation_screen.dart';
import 'providers/theme_provider.dart';
import 'package:flutter/foundation.dart'; // Added for defaultTargetPlatform

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  if (defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp();
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize push notifications
  await PushNotificationService.init();

  // Initialize WebSocket Service for Realtime
  await WebSocketService().init();

  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  runApp(MyApp(hasSeenOnboarding: hasSeenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  const MyApp({super.key, required this.hasSeenOnboarding});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()
            ..setHasSeenOnboarding(hasSeenOnboarding)
            ..checkAuth(),
        ),
        ChangeNotifierProvider(create: (_) => ProviderListProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Inginia Mobile',
            navigatorKey: MyApp.navigatorKey,
            debugShowCheckedModeBanner: false,
            showSemanticsDebugger: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  accessibleNavigation: false,
                ),
                child: child!,
              );
            },
          );
        },
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

    if (!authProvider.hasSeenOnboarding) {
      return const OnboardingScreen();
    }

    // User not authenticated
    if (!authProvider.isAuthenticated) {
      if (authProvider.shouldShowLogin) {
        return const LoginScreen();
      }
      return const ClientDashboardScreen();
    }

    // User is authenticated - show dashboard based on role
    final user = authProvider.user;

    // Mode Hors-ligne / Consultation
    if (authProvider.isOfflineMode) {
      return const ClientDashboardScreen();
    }

    // Admin Dashboard
    if (user?.role == 'admin') {
      return const AdminDashboardScreen();
    }

    // Provider Dashboard
    if (user?.role == 'prestataire' || user?.role == 'provider') {
      if (!user!.isValidated) {
        return const PendingValidationScreen();
      }
      return const ProviderDashboardScreen();
    }

    // Client Dashboard (default)
    return const ClientDashboardScreen();
  }
}
