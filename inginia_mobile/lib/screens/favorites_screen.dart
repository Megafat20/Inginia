import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../repositories/provider_repository.dart';
import '../models/user_model.dart';
import 'provider_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // Liste réelle des favoris
  List<User> _favorites = [];
  bool _isLoading = true;
  final ProviderRepository _repository = ProviderRepository();
  List<User> _recommendedProviders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final favs = await _repository.getFavorites();
      List<User> recommended = [];

      if (favs.isEmpty) {
        // Chargement des recommandations si pas de favoris
        final result = await _repository.getProviders();
        final List<User> allProviders = result['providers'];
        recommended = allProviders.take(3).toList();
      }

      if (mounted) {
        setState(() {
          _favorites = favs;
          _recommendedProviders = recommended;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFavorite(User provider, bool isCurrentlyFavorite) async {
    // Optimistic UI update
    setState(() {
      if (isCurrentlyFavorite) {
        _favorites.removeWhere((p) => p.id == provider.id);
        // On pourrait ajouter aux recommandés, mais simplifions
        if (_favorites.isEmpty) {
          _isLoading = true; // Pour recharger les recommandés
        }
      } else {
        _favorites.add(provider);
        _recommendedProviders.removeWhere((p) => p.id == provider.id);
      }
    });

    try {
      await _repository.toggleFavorite(provider.id);

      // Si la liste est vide après retrait, recharger pour afficher les recommandations
      if (_favorites.isEmpty && isCurrentlyFavorite) {
        _loadData();
      }
    } catch (e) {
      // Revert en cas d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Une erreur est survenue")),
        );
        _loadData(); // Recharger l'état réel
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          "Mes Favoris",
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_favorites.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 60,
                  color: Colors.red.shade200,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Pas encore de favoris",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "Enregistrez vos prestataires préférés pour les retrouver facilement ici.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Recommandations
              if (_recommendedProviders.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        "Recommandés pour vous",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context), // Retour pour explorer
                        child: const Text("Voir tout"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recommendedProviders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _buildProviderCard(
                      _recommendedProviders[index],
                      isFavorite: false,
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _favorites.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _buildProviderCard(_favorites[index], isFavorite: true);
        },
      ),
    );
  }

  Widget _buildProviderCard(User provider, {bool isFavorite = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderDetailScreen(providerId: provider.id),
          ),
        ).then((_) => _loadData()); // Recharger au retour
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: provider.profilePhotoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(provider.profilePhotoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: AppTheme.primary.withOpacity(0.1),
                ),
                child: provider.profilePhotoUrl == null
                    ? Center(
                        child: Text(
                          provider.name.isNotEmpty ? provider.name[0] : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.serviceName ?? "Prestataire",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          provider.avgRating?.toStringAsFixed(1) ?? "Nouveau",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Favorite Action
              IconButton(
                onPressed: () => _toggleFavorite(provider, isFavorite),
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? Colors.red : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
