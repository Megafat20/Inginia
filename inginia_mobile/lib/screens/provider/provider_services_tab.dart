import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/provider_repository.dart';
import '../../models/provider_details_model.dart'; // For Competance

class ProviderServicesTab extends StatefulWidget {
  const ProviderServicesTab({super.key});

  @override
  State<ProviderServicesTab> createState() => _ProviderServicesTabState();
}

class _ProviderServicesTabState extends State<ProviderServicesTab> {
  final _repository = ProviderRepository();
  Future<ProviderDetails?>? _futureDetails; // Make it nullable Future

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        _futureDetails = _repository.getProviderDetails(user.id);
      }
    });
  }

  Future<void> _deleteService(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer ce service ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repository.deleteService(id);
        _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Service supprimé"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erreur: ${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showServiceForm({Competance? service}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ServiceFormModal(
        service: service,
        onSave: (data) async {
          try {
            if (service == null) {
              await _repository.addService(data);
            } else {
              await _repository.updateService(service.id, data);
            }
            Navigator.pop(ctx);
            _refresh();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    service == null ? "Service ajouté" : "Service modifié",
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Erreur: ${e.toString()}"),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use Scaffold primarily for FAB support, but inside the tab view
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceForm(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Mes Services",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Gérez vos prestations et tarifs",
                        style: TextStyle(color: AppTheme.textLight),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.design_services_rounded,
                  size: 32,
                  color: AppTheme.primary,
                ),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<ProviderDetails?>(
              future: _futureDetails,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Erreur de chargement: ${snapshot.error}"),
                  );
                }

                final services = snapshot.data?.competances ?? [];

                if (services.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.library_add_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Ajoutez votre premier service",
                          style: TextStyle(color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final s = services[index];
                    return _buildServiceCard(s);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Competance s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  s.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              Text(
                "${s.price} F",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          if (s.description != null && s.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              s.description!,
              style: const TextStyle(color: AppTheme.textLight, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _deleteService(s.id),
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text("Supprimer"),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showServiceForm(service: s),
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: const Text("Modifier"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ServiceFormModal extends StatefulWidget {
  final Competance? service;
  final Function(Map<String, dynamic>) onSave;

  const ServiceFormModal({super.key, this.service, required this.onSave});

  @override
  State<ServiceFormModal> createState() => _ServiceFormModalState();
}

class _ServiceFormModalState extends State<ServiceFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  int? _selectedProfessionId;
  List<Map<String, dynamic>> _professions = [];
  bool _isLoading = false;
  bool _isFetchingProfessions = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.service?.title ?? '');
    _priceController = TextEditingController(
      text: widget.service?.price.toString() ?? '',
    );
    _descController = TextEditingController(
      text: widget.service?.description ?? '',
    );
    _fetchProfessions();
  }

  Future<void> _fetchProfessions() async {
    try {
      final repo = ProviderRepository();
      // Use getAllProfessions to allow picking any profession for a new service
      final profs = await repo.getAllProfessions();
      if (mounted) {
        setState(() {
          _professions = profs;
          // If editing, logic to pre-select profession would require service.profession_id which we might not have in Competance model yet.
          // For now, default to first one if new, or let user pick.
          if (_professions.isNotEmpty && widget.service == null) {
            _selectedProfessionId = _professions.first['id'];
          } else if (_professions.isNotEmpty && widget.service != null) {
            // Try to match or leave empty requiring update?
            // Since we don't have profession_id in Competance, we force user to select only if needed or keep existing logic.
            // But Wait! Update requires profession_id 'sometimes'.
            // Let's select the first one as a fallback or ask user.
            _selectedProfessionId = _professions.first['id'];
          }
          _isFetchingProfessions = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFetchingProfessions = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
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
      child: Form(
        key: _formKey,
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
              Text(
                widget.service == null
                    ? "Nouveau Service"
                    : "Modifier le Service",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 24),

              if (_isFetchingProfessions)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),

              if (!_isFetchingProfessions && _professions.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    "Aucune profession trouvée. Veuillez contacter le support.",
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              if (!_isFetchingProfessions && _professions.isNotEmpty) ...[
                DropdownButtonFormField<int>(
                  initialValue: _selectedProfessionId,
                  decoration: _inputDecoration("Profession"),
                  items: _professions.map((p) {
                    return DropdownMenuItem<int>(
                      value: p['id'],
                      child: Text(p['name']),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setState(() => _selectedProfessionId = val),
                  validator: (val) => val == null ? "Requis" : null,
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration("Titre (ex: Plomberie)"),
                validator: (v) => v!.isEmpty ? "Requis" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: _inputDecoration("Prix (F)"),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Requis" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: _inputDecoration("Description"),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    (_isLoading ||
                        (_professions.isEmpty && !_isFetchingProfessions))
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isLoading = true);
                          await widget.onSave({
                            'title': _titleController.text,
                            'price':
                                (double.tryParse(_priceController.text) ?? 0)
                                    .toInt(),
                            'description': _descController.text,
                            'profession_id': _selectedProfessionId, // Add this
                          });
                        }
                      },
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
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(widget.service == null ? "Ajouter" : "Enregistrer"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}
