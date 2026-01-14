import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_service.dart';
import '../../providers/auth_provider.dart';
import 'provider_validation_screen.dart';
import 'users_management_screen.dart';
import 'admin_commissions_screen.dart';
import 'admin_providers_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _adminService.getDashboardStats();
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tableau de Bord',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Administration',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _loadStats,
                          icon: Icon(Icons.refresh, color: Colors.white),
                          tooltip: 'Actualiser',
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Row(
                                  children: [
                                    Icon(
                                      Icons.logout_rounded,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 12),
                                    Text('Déconnexion'),
                                  ],
                                ),
                                content: Text(
                                  'Êtes-vous sûr de vouloir vous déconnecter ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text('Annuler'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      context.read<AuthProvider>().logout();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text('Se déconnecter'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: Icon(Icons.logout_rounded, color: Colors.white),
                          tooltip: 'Se déconnecter',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _loading
                      ? Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _loadStats,
                          child: ListView(
                            padding: EdgeInsets.all(20),
                            children: [
                              // Stats Grid
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.1,
                                children: [
                                  _buildStatCard(
                                    'Total Utilisateurs',
                                    '${_stats?['total_users'] ?? 0}',
                                    Icons.people,
                                    Colors.blue,
                                  ),
                                  _buildStatCard(
                                    'Clients',
                                    '${_stats?['total_clients'] ?? 0}',
                                    Icons.person,
                                    Colors.green,
                                  ),
                                  _buildStatCard(
                                    'Prestataires Validés',
                                    '${_stats?['validated_providers'] ?? 0}',
                                    Icons.verified_user,
                                    Colors.purple,
                                  ),
                                  _buildStatCard(
                                    'En Attente',
                                    '${_stats?['pending_providers'] ?? 0}',
                                    Icons.pending_actions,
                                    Colors.orange,
                                    highlight:
                                        (_stats?['pending_providers'] ?? 0) > 0,
                                  ),
                                  _buildStatCard(
                                    'Total Prestataires',
                                    '${_stats?['total_providers'] ?? 0}',
                                    Icons.business_center,
                                    Colors.indigo,
                                  ),
                                  _buildStatCard(
                                    'Agences',
                                    '${_stats?['total_agencies'] ?? 0}',
                                    Icons.business,
                                    Colors.pink,
                                  ),
                                ],
                              ),

                              SizedBox(height: 32),

                              // Actions Rapides
                              Text(
                                'Actions Rapides',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textDark,
                                ),
                              ),

                              SizedBox(height: 16),

                              _buildActionCard(
                                'Validation Prestataires',
                                '${_stats?['pending_providers'] ?? 0} demande(s) en attente',
                                Icons.check_circle,
                                Colors.orange,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProviderValidationScreen(),
                                    ),
                                  );
                                },
                                highlight:
                                    (_stats?['pending_providers'] ?? 0) > 0,
                              ),

                              SizedBox(height: 12),

                              _buildActionCard(
                                'Gestion Utilisateurs',
                                'Voir tous les utilisateurs',
                                Icons.manage_accounts,
                                Colors.blue,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          UsersManagementScreen(),
                                    ),
                                  );
                                },
                              ),

                              SizedBox(height: 12),

                              _buildActionCard(
                                'Gestion Commissions',
                                'Décaisser et gérer les commissions',
                                Icons.account_balance_wallet_rounded,
                                Colors.green,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AdminCommissionsScreen(),
                                    ),
                                  );
                                },
                              ),

                              SizedBox(height: 12),

                              _buildActionCard(
                                'Tous les Prestataires',
                                'Rechercher et gérer les prestataires',
                                Icons.people_alt_rounded,
                                Colors.purple,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AdminProvidersScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool highlight = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: highlight ? Border.all(color: Colors.orange, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: highlight
                ? Colors.orange.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool highlight = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: highlight ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: highlight ? Border.all(color: color, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
