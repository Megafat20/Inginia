import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_service.dart';

class ProviderValidationScreen extends StatefulWidget {
  const ProviderValidationScreen({super.key});

  @override
  State<ProviderValidationScreen> createState() =>
      _ProviderValidationScreenState();
}

class _ProviderValidationScreenState extends State<ProviderValidationScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;

  List<dynamic> _pendingProviders = [];
  List<dynamic> _validatedProviders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _loading = true);
      final pending = await _adminService.getPendingProviders();
      final validated = await _adminService.getValidatedProviders();
      setState(() {
        _pendingProviders = pending;
        _validatedProviders = validated;
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

  Future<void> _validateProvider(int providerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la validation'),
        content: Text('Voulez-vous valider ce prestataire ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Valider'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _adminService.validateProvider(providerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prestataire validé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _rejectProvider(int providerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer le rejet'),
        content: Text(
          'Voulez-vous rejeter et supprimer ce prestataire ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Rejeter'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _adminService.rejectProvider(providerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prestataire rejeté'),
            backgroundColor: Colors.red,
          ),
        );
      }
      await _loadData();
    } catch (e) {
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Validation Prestataires'),
        elevation: 0,
        backgroundColor: AppTheme.primary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'En Attente (${_pendingProviders.length})'),
            Tab(text: 'Validés (${_validatedProviders.length})'),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Pending Tab
                  _pendingProviders.isEmpty
                      ? _buildEmptyState(
                          'Aucune demande en attente',
                          Icons.check_circle_outline,
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _pendingProviders.length,
                          itemBuilder: (context, index) {
                            final provider = _pendingProviders[index];
                            return _buildProviderCard(provider, true);
                          },
                        ),

                  // Validated Tab
                  _validatedProviders.isEmpty
                      ? _buildEmptyState(
                          'Aucun prestataire validé',
                          Icons.info_outline,
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _validatedProviders.length,
                          itemBuilder: (context, index) {
                            final provider = _validatedProviders[index];
                            return _buildProviderCard(provider, false);
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(dynamic provider, bool showActions) {
    final isAgency = provider['is_agency'] == true;
    final professions = provider['professions'] as List<dynamic>? ?? [];

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  backgroundImage: provider['profile_photo'] != null
                      ? NetworkImage(provider['profile_photo'])
                      : null,
                  child: provider['profile_photo'] == null
                      ? Text(
                          (provider['name'] ?? '?')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider['name'] ?? 'Sans nom',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      if (provider['service'] != null)
                        Text(
                          provider['service'],
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isAgency)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.business, size: 12, color: Colors.purple),
                        SizedBox(width: 4),
                        Text(
                          'AGENCE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            SizedBox(height: 12),
            Divider(),
            SizedBox(height: 12),

            // Info
            _buildInfoRow(Icons.email, provider['email'] ?? ''),
            if (provider['phone'] != null)
              _buildInfoRow(Icons.phone, provider['phone']),
            if (provider['location'] != null)
              _buildInfoRow(Icons.location_on, provider['location']),

            if (professions.isNotEmpty) ...[
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: professions.map<Widget>((prof) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      prof['name'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            if (showActions) ...[
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _validateProvider(provider['id']),
                      icon: Icon(Icons.check_circle, size: 20),
                      label: Text('Valider'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _rejectProvider(provider['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Icon(Icons.cancel, size: 24),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
