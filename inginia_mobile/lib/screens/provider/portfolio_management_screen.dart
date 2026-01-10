import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../repositories/provider_repository.dart';
import '../../models/provider_details_model.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class PortfolioManagementScreen extends StatefulWidget {
  const PortfolioManagementScreen({super.key});

  @override
  State<PortfolioManagementScreen> createState() =>
      _PortfolioManagementScreenState();
}

class _PortfolioManagementScreenState extends State<PortfolioManagementScreen> {
  final _repository = ProviderRepository();
  bool _isLoading = true;
  ProviderDetails? _details;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null) {
        final details = await _repository.getProviderDetails(auth.user!.id);
        setState(() {
          _details = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Erreur lors du chargement: $e");
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _pickAndUpload() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // Optional: Show a dialog to enter title/description
    final result = await _showAddDetailsDialog();
    if (result == null) return; // User cancelled

    setState(() => _isLoading = true);
    try {
      await _repository.uploadPortfolioImage(
        filePath: image.path,
        title: result['title'],
        description: result['description'],
      );
      await _fetchData();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Erreur upload: $e");
    }
  }

  Future<Map<String, String?>?> _showAddDetailsDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    return showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter une réalisation"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Titre (ex: Salon rénové)",
              ),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'title': titleController.text,
              'description': descController.text,
            }),
            child: const Text("Envoyer"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer ?"),
        content: const Text("Voulez-vous supprimer cette photo ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Non"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Oui", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _repository.deletePortfolioImage(id);
      await _fetchData();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Erreur suppression: $e");
    }
  }

  String _getImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final root = ApiService.baseUrl.replaceAll('/api', '');
    return '$root/storage/portfolios/$path';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mon Portfolio",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _details == null
          ? const Center(child: Text("Erreur de chargement"))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    "Ajoutez des photos de vos meilleurs travaux pour rassurer vos futurs clients.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _details!.portfolio.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo_library_outlined,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                const Text("Aucune photo pour le moment"),
                              ],
                            ),
                          )
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1,
                                ),
                            itemCount: _details!.portfolio.length,
                            itemBuilder: (context, index) {
                              final item = _details!.portfolio[index];
                              return Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          _getImageUrl(item.image),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.8,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 16,
                                        ),
                                        onPressed: () => _deleteItem(item.id),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndUpload,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }
}
