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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Mon Portfolio",
          style: AppTheme.headingStyle.copyWith(fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _details == null
          ? const Center(child: Text("Erreur de chargement"))
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxPadding(
                    padding: const EdgeInsets.all(20),
                    child: _buildHeader(),
                  ),
                  if (_details!.portfolio.isEmpty)
                    SliverFillRemaining(child: _buildEmptyState())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: _buildPortfolioGrid(),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndUpload,
        backgroundColor: AppTheme.primary,
        elevation: 4,
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text(
          "AJOUTER",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.stars_rounded, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            "Vitrine de vos talents",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Montrez vos meilleures réalisations pour gagner la confiance de nouveaux clients.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "Votre portfolio est vide",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Commencez par ajouter une photo de vos travaux.",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = _details!.portfolio[index];
        return _buildPortfolioCard(item);
      }, childCount: _details!.portfolio.length),
    );
  }

  Widget _buildPortfolioCard(PortfolioItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Hero(
                    tag: "portfolio_${item.id}",
                    child: Image.network(
                      _getImageUrl(item.image),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade100,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.title ?? "Réalisation",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (item.description != null)
                          Text(
                            item.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Badges
            if (item.type != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (item.type == 'before' ? Colors.orange : Colors.green)
                            .withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    item.type == 'before' ? "AVANT" : "APRÈS",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

            // Delete Action
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                  onPressed: () => _deleteItem(item.id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SliverToBoxPadding extends StatelessWidget {
  final EdgeInsets padding;
  final Widget child;

  const SliverToBoxPadding({
    super.key,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(padding: padding, child: child),
    );
  }
}
