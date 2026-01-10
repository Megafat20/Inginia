import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../services/location_service.dart';
import 'provider/portfolio_management_screen.dart';
import 'profile/edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Utilisateur non connecté")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Mon Profil',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              // Logout confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content: const Text(
                    'Voulez-vous vraiment vous déconnecter ?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(
                          context,
                        ); // Close profile screen (optional, depends on flow)
                        authProvider.logout();
                      },
                      child: const Text(
                        'Déconnecter',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.primaryLight.withOpacity(0.2),
                      backgroundImage: user.profilePhotoUrl != null
                          ? NetworkImage(user.profilePhotoUrl!)
                          : null,
                      child: user.profilePhotoUrl == null
                          ? Text(
                              user.name[0].toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 40,
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    user.email,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () async {
                      final scaffold = ScaffoldMessenger.of(context);
                      final authParams = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      try {
                        scaffold.showSnackBar(
                          const SnackBar(
                            content: Text("Géolocalisation en cours..."),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        final loc = await LocationService()
                            .getCurrentLocation();
                        if (loc != null) {
                          await authParams.updateLocation(
                            loc.latitude,
                            loc.longitude,
                          );
                          scaffold.hideCurrentSnackBar();
                          scaffold.showSnackBar(
                            const SnackBar(
                              content: Text("Position mise à jour !"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          scaffold.showSnackBar(
                            SnackBar(
                              content: const Text(
                                "Impossible de récupérer la position.",
                              ),
                              action: SnackBarAction(
                                label: "Réglages",
                                textColor: Colors.white,
                                onPressed: () =>
                                    LocationService().openSettings(),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        scaffold.showSnackBar(
                          SnackBar(
                            content: Text("Erreur: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.my_location, size: 18),
                    label: const Text("Actualiser ma position"),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Profile Details Section
            _buildProfileItem(
              Icons.phone,
              'Téléphone',
              user.phone ?? 'Non renseigné',
            ),
            _buildProfileItem(
              Icons.location_on,
              'Adresse',
              user.location ?? 'Non renseignée',
            ),
            if (user.serviceName != null)
              _buildProfileItem(Icons.work, 'Service', user.serviceName!),

            if (user.role == 'prestataire' || user.role == 'service')
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                title: const Text(
                  "Réalisations (Portfolio)",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text("Gérez les photos de vos travaux"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PortfolioManagementScreen(),
                    ),
                  );
                },
              ),

            const SizedBox(height: 32),

            // Edit Profile Button (Mockup)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text("Modifier le profil"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.primary),
                  foregroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.textLight, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
