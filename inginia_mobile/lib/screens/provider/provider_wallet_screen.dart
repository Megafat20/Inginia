import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

import '../../services/api_service.dart';

class ProviderWalletScreen extends StatefulWidget {
  const ProviderWalletScreen({super.key});

  @override
  State<ProviderWalletScreen> createState() => _ProviderWalletScreenState();
}

class _ProviderWalletScreenState extends State<ProviderWalletScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  double _balance = 0.0;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    try {
      final response = await _apiService.client.get('/wallet');
      setState(() {
        _balance = (response.data['balance'] ?? 0.0).toDouble();
        _transactions = List<Map<String, dynamic>>.from(
          response.data['transactions'].map(
            (t) => {
              'type': t['type'],
              'title': t['description'] ?? 'Transaction',
              'subtitle': t['reference'] ?? 'Ref: ---',
              'amount': (t['amount'] ?? 0.0).toDouble(),
              'date': DateTime.parse(t['created_at']),
            },
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching wallet: $e');
      setState(() => _isLoading = false);
      // Quiet fail or show snackbar
    }
  }

  void _showRechargeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RechargeModal(
        onSuccess: (amount, providerName) {
          setState(() {
            _balance += amount;
            _transactions.insert(0, {
              'type': 'credit',
              'title': 'Recharge $providerName',
              'subtitle': 'Succès • Mobile',
              'amount': amount,
              'date': DateTime.now(),
            });
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          "Mon Portefeuille",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Balance Card
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Solde Disponible",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _balance.toStringAsFixed(0),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "FCFA",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.add_card_rounded,
                                label: "Recharger",
                                onTap: _showRechargeModal,
                                isPrimary: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Optional: Withdraw button (future feature)
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.history_rounded,
                                label: "Historique",
                                onTap: () {},
                                isPrimary: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Transactions Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Transactions",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text("Tout voir"),
                        ),
                      ],
                    ),
                  ),

                  // Transactions List
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tx = _transactions[index];
                      final isCredit = tx['type'] == 'credit';
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isCredit
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCredit
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                color: isCredit ? Colors.green : Colors.red,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx['title'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  Text(
                                    tx['subtitle'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "${isCredit ? '+' : '-'}${tx['amount'].toStringAsFixed(0)} F",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCredit ? Colors.green : Colors.red,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: Colors.white70),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary ? AppTheme.primary : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? AppTheme.primary : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RechargeModal extends StatefulWidget {
  final Function(double, String) onSuccess;

  const RechargeModal({super.key, required this.onSuccess});

  @override
  State<RechargeModal> createState() => _RechargeModalState();
}

class _RechargeModalState extends State<RechargeModal> {
  String _selectedProvider = 'nita';
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _providers = [
    {
      'id': 'nita',
      'name': 'Nita Transfert',
      'color': Colors.green,
      'icon': Icons.account_balance_wallet, // Placeholder for Nita logo
    },
    {
      'id': 'orange',
      'name': 'Orange Money',
      'color': Colors.orange,
      'icon': Icons.phone_android_rounded, // Placeholder for OM logo
    },
    {
      'id': 'airtel',
      'name': 'Airtel Money',
      'color': Colors.red,
      'icon': Icons.sim_card_rounded,
    },
    {
      'id': 'moov',
      'name': 'Moov Money',
      'color': Colors.blue,
      'icon': Icons.network_cell_rounded,
    },
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _processRecharge() async {
    if (_amountController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;

    setState(() => _isLoading = true);

    try {
      // 🚀 Real API Call via ApiService
      final api = ApiService();
      await api.client.post(
        '/wallet/recharge',
        data: {
          'amount': amount,
          'provider': _selectedProvider,
          'phone': _phoneController.text,
        },
      );

      if (mounted) {
        // Get provider name for the label
        final providerName = _providers
            .firstWhere((p) => p['id'] == _selectedProvider)['name']
            .toString()
            .split(' ')[0];

        setState(() => _isLoading = false);

        // Update Parent State
        widget.onSuccess(amount, providerName);

        Navigator.pop(context);

        // Show Success Dialog
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Paiement Validé !",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Votre compte a été crédité de ${amount.toStringAsFixed(0)} FCFA.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textLight),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Génial"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur de paiement: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Recharger mon compte",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 24),

            // Provider Selection
            const Text(
              "Moyen de paiement",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _providers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final p = _providers[index];
                  final isSelected = _selectedProvider == p['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedProvider = p['id']),
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? p['color'].withOpacity(0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? p['color'] : Colors.grey.shade200,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(p['icon'], color: p['color']),
                          const SizedBox(height: 8),
                          Text(
                            p['name'].split(
                              ' ',
                            )[0], // First word only for space
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? p['color'] : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Inputs
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Numéro de téléphone",
                prefixIcon: const Icon(Icons.phone_iphone_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: "Montant (FCFA)",
                prefixIcon: const Icon(Icons.monetization_on_rounded),
                suffixText: "FCFA",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Button
            ElevatedButton(
              onPressed: _isLoading ? null : _processRecharge,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Payer maintenant",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
