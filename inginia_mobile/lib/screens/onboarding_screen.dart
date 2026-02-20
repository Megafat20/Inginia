import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Bienvenue sur Inginia",
      description:
          "La plateforme qui connecte les experts et les clients en un clic. Trouvez le professionnel idéal pour vos besoins.",
      image: "assets/images/onboarding_welcome.png",
      color: AppTheme.primary,
    ),
    OnboardingData(
      title: "Des Experts Qualifiés",
      description:
          "Tous nos prestataires sont vérifiés et notés par la communauté pour vous garantir un service d'excellence.",
      image: "assets/images/onboarding_expert.png",
      color: AppTheme.accent,
    ),
    OnboardingData(
      title: "Paiement Sécurisé",
      description:
          "Bénéficiez d'une transparence totale sur les prix et d'un système de paiement sécurisé pour votre tranquillité.",
      image: "assets/images/onboarding_secure.png",
      color: Colors.teal,
    ),
    OnboardingData(
      title: "Configuration Initiale",
      description:
          "Pour vous offrir la meilleure expérience, Inginia a besoin de connaître votre position pour trouver des experts proches de vous.",
      image: "assets/images/onboarding_welcome.png",
      color: Colors.deepOrange,
      isConfig: true,
    ),
  ];

  bool _locationPermissionGranted = false;
  bool _notificationPermissionGranted = false;

  Future<void> _requestLocation() async {
    final status = await Permission.location.request();
    setState(() {
      _locationPermissionGranted = status.isGranted;
    });
  }

  Future<void> _requestNotifications() async {
    final status = await Permission.notification.request();
    setState(() {
      _notificationPermissionGranted = status.isGranted;
    });
  }

  void _onFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      Provider.of<AuthProvider>(
        context,
        listen: false,
      ).setHasSeenOnboarding(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          AnimatedContainer(
            duration: 500.ms,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _pages[_currentPage].color.withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
          ),

          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return Padding(
                padding: const EdgeInsets.all(40.0),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        Image.asset(
                              page.image,
                              height: MediaQuery.of(context).size.height * 0.3,
                            )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1, 1),
                              curve: Curves.easeOutBack,
                            ),
                        const SizedBox(height: 40),
                        Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textDark,
                              ),
                            )
                            .animate(key: ValueKey('title_$index'))
                            .fadeIn(delay: 200.ms)
                            .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 20),
                        Text(
                              page.description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                            )
                            .animate(key: ValueKey('desc_$index'))
                            .fadeIn(delay: 400.ms)
                            .slideY(begin: 0.2, end: 0),
                        if (page.isConfig) ...[
                          const SizedBox(height: 40),
                          _buildPermissionTile(
                                icon: Icons.location_on_rounded,
                                title: "Position GPS",
                                subtitle: "Pour vous localiser sur la carte",
                                isGranted: _locationPermissionGranted,
                                onTap: _requestLocation,
                              )
                              .animate()
                              .fadeIn(delay: 600.ms)
                              .slideY(begin: 0.2, end: 0),
                          const SizedBox(height: 12),
                          _buildPermissionTile(
                                icon: Icons.notifications_active_rounded,
                                title: "Notifications",
                                subtitle: "Pour ne rater aucune mission",
                                isGranted: _notificationPermissionGranted,
                                onTap: _requestNotifications,
                              )
                              .animate()
                              .fadeIn(delay: 800.ms)
                              .slideY(begin: 0.2, end: 0),
                        ],
                        const SizedBox(height: 100), // Air for bottom controls
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Bottom Controls
          Positioned(
            bottom: 60,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicators
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: 300.ms,
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppTheme.primary
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                // Button
                ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          _onFinish();
                        } else {
                          _pageController.nextPage(
                            duration: 500.ms,
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        elevation: 5,
                        shadowColor: AppTheme.primary.withOpacity(0.4),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? "Commencer"
                            : "Suivant",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    )
                    .animate(key: ValueKey('btn_$_currentPage'))
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                    ),
              ],
            ),
          ),

          // Skip Button
          Positioned(
            top: 60,
            right: 20,
            child: TextButton(
              onPressed: _onFinish,
              child: Text(
                "Passer",
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isGranted ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isGranted ? Colors.green.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isGranted ? Colors.green : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isGranted ? Colors.green : AppTheme.primary)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isGranted ? Icons.check : icon,
                color: isGranted ? Colors.green : AppTheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!isGranted)
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String image;
  final Color color;
  final bool isConfig;

  OnboardingData({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
    this.isConfig = false,
  });
}
