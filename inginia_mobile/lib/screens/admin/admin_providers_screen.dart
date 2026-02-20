import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminProvidersScreen extends StatefulWidget {
  const AdminProvidersScreen({super.key});

  @override
  State<AdminProvidersScreen> createState() => _AdminProvidersScreenState();
}

class _AdminProvidersScreenState extends State<AdminProvidersScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allProviders = [];
  List<Map<String, dynamic>> _filteredProviders = [];
  bool _isLoading = true;
  String _sortBy = 'name'; // name, balance, date
  bool _ascending = true;

  @override
  void initState() {
    super.initState();
    _fetchProviders();
    _searchController.addListener(_filterProviders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProviders() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.client.get('/admin/users');
      final users = List<Map<String, dynamic>>.from(response.data);

      // Filtrer uniquement les prestataires
      _allProviders = users.where((u) => u['role'] == 'prestataire').toList();
      _filteredProviders = List.from(_allProviders);
      _applySorting();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _filterProviders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProviders = List.from(_allProviders);
      } else {
        _filteredProviders = _allProviders.where((provider) {
          final name = (provider['name'] ?? '').toLowerCase();
          final email = (provider['email'] ?? '').toLowerCase();
          final phone = (provider['phone'] ?? '').toLowerCase();
          final service = (provider['service'] ?? '').toLowerCase();

          return name.contains(query) ||
              email.contains(query) ||
              phone.contains(query) ||
              service.contains(query);
        }).toList();
      }
      _applySorting();
    });
  }

  void _applySorting() {
    _filteredProviders.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case 'name':
          comparison = (a['name'] ?? '').compareTo(b['name'] ?? '');
          break;
        case 'balance':
          final balanceA =
              double.tryParse((a['balance'] ?? 0).toString()) ?? 0.0;
          final balanceB =
              double.tryParse((b['balance'] ?? 0).toString()) ?? 0.0;
          comparison = balanceA.compareTo(balanceB);
          break;
        case 'date':
          final dateA =
              DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
          final dateB =
              DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
          comparison = dateA.compareTo(dateB);
          break;
      }

      return _ascending ? comparison : -comparison;
    });
  }

  void _changeSorting(String newSort) {
    setState(() {
      if (_sortBy == newSort) {
        _ascending = !_ascending;
      } else {
        _sortBy = newSort;
        _ascending = true;
      }
      _applySorting();
    });
  }

  void _viewProviderWallet(int providerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProviderWalletDetailScreen(providerId: providerId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Gestion Prestataires',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchProviders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: AppTheme.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, email, téléphone...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Sort Options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Trier par:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(width: 12),
                _buildSortChip('Nom', 'name'),
                const SizedBox(width: 8),
                _buildSortChip('Solde', 'balance'),
                const SizedBox(width: 8),
                _buildSortChip('Date', 'date'),
              ],
            ),
          ),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredProviders.length} prestataire(s)',
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Providers List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProviders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun prestataire trouvé',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchProviders,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredProviders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final provider = _filteredProviders[index];
                        return _buildProviderCard(provider);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isActive = _sortBy == value;
    return GestureDetector(
      onTap: () => _changeSorting(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppTheme.textDark,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Icon(
                _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                color: Colors.white,
                size: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    final balance =
        double.tryParse((provider['balance'] ?? 0).toString()) ?? 0.0;
    final isValidated = provider['is_validated'] ?? false;
    final isAgency = provider['is_agency'] ?? false;

    return GestureDetector(
      onTap: () => _viewProviderWallet(provider['id']),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text(
                    provider['name']?[0]?.toUpperCase() ?? '?',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              provider['name'] ?? 'N/A',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isValidated) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified_rounded,
                              color: Colors.blue,
                              size: 18,
                            ),
                          ],
                          if (isAgency) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.business_rounded,
                              color: Colors.orange,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider['service'] ?? 'Service non défini',
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${balance.toStringAsFixed(0)} F',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: balance >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    const Text(
                      'Solde',
                      style: TextStyle(color: AppTheme.textLight, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    Icons.email_outlined,
                    provider['email'] ?? 'N/A',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    Icons.phone_outlined,
                    provider['phone'] ?? 'N/A',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textLight),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Écran détail prestataire - Missions & Commissions
class AdminProviderWalletDetailScreen extends StatefulWidget {
  final int providerId;
  const AdminProviderWalletDetailScreen({super.key, required this.providerId});

  @override
  State<AdminProviderWalletDetailScreen> createState() =>
      _AdminProviderWalletDetailScreenState();
}

class _AdminProviderWalletDetailScreenState
    extends State<AdminProviderWalletDetailScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _provider;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _missions = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.client.get(
        '/admin/providers/${widget.providerId}/reservations',
      );
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _provider = Map<String, dynamic>.from(data['provider']);
        _stats = Map<String, dynamic>.from(data['stats']);
        _missions = List<Map<String, dynamic>>.from(data['reservations']);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.teal;
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'confirmed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Terminée';
      case 'pending':
        return 'En attente';
      case 'accepted':
        return 'Acceptée';
      case 'confirmed':
        return 'Confirmée';
      case 'in_progress':
        return 'En cours';
      case 'cancelled':
        return 'Annulée';
      case 'declined':
        return 'Refusée';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          _provider?['name'] ?? 'Détails Prestataire',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Info Prestataire ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            (_provider?['name'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _provider?['name'] ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                _provider?['email'] ?? '',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                _provider?['phone'] ?? '',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Solde',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${(double.tryParse((_provider?['balance'] ?? 0).toString()) ?? 0).toStringAsFixed(0)} F',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── KPI Cards ────────────────────────────────
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _buildKpiCard(
                        'Total Missions',
                        '${_stats?['total_missions'] ?? 0}',
                        Icons.assignment_rounded,
                        Colors.blue,
                      ),
                      _buildKpiCard(
                        'Terminées',
                        '${_stats?['completed'] ?? 0}',
                        Icons.check_circle_rounded,
                        Colors.teal,
                      ),
                      _buildKpiCard(
                        'Montant Gagné',
                        '${(double.tryParse((_stats?['total_earned'] ?? 0).toString()) ?? 0).toStringAsFixed(0)} F',
                        Icons.payments_rounded,
                        Colors.green,
                      ),
                      _buildKpiCard(
                        'Commissions',
                        '${(double.tryParse((_stats?['total_commissions'] ?? 0).toString()) ?? 0).toStringAsFixed(0)} F',
                        Icons.percent_rounded,
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Liste des Missions ────────────────────────
                  const Text(
                    'Historique des Missions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_missions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 60,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune mission pour ce prestataire',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...(_missions.map((mission) {
                      final status = mission['status'] ?? 'pending';
                      final price =
                          double.tryParse((mission['price'] ?? 0).toString()) ??
                          0.0;
                      final commission =
                          double.tryParse(
                            (mission['commission'] ?? 0).toString(),
                          ) ??
                          0.0;
                      final priceSource =
                          mission['price_source'] ?? 'catalogue';
                      final hasFinalPrice = mission['final_price'] != null;
                      final date = mission['requested_date'] != null
                          ? DateTime.tryParse(mission['requested_date'])
                          : null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.work_outline_rounded,
                                color: _statusColor(status),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mission['service_title'] ??
                                        'Service personnalisé',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    mission['client_name'] ?? 'Client',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (date != null)
                                    Text(
                                      '${date.day}/${date.month}/${date.year}',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      status,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _statusLabel(status),
                                    style: TextStyle(
                                      color: _statusColor(status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Badge si prix négocié
                                if (hasFinalPrice)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 2),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.green.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      '✓ Prix négocié',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Text(
                                  price > 0
                                      ? '${price.toStringAsFixed(0)} F'
                                      : 'Prix non défini',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: price > 0
                                        ? AppTheme.textDark
                                        : Colors.grey,
                                  ),
                                ),
                                Text(
                                  commission > 0
                                      ? 'Com: ${commission.toStringAsFixed(0)} F (5%)'
                                      : 'Commission: N/A',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList()),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
