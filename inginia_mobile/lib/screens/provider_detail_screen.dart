import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

import '../models/provider_details_model.dart';
import '../repositories/provider_repository.dart';
import '../services/api_service.dart';
import 'components/reservation_modal.dart';
import '../widgets/shimmer_loading.dart';

class ProviderDetailScreen extends StatefulWidget {
  final int providerId;
  final String? providerName; // For placeholder while loading

  const ProviderDetailScreen({
    super.key,
    required this.providerId,
    this.providerName,
  });

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  late Future<ProviderDetails?> _futureDetails;
  final ProviderRepository _repository = ProviderRepository();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _futureDetails = _repository.getProviderDetails(widget.providerId);
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final favs = await _repository.getFavorites();
      if (mounted) {
        setState(() {
          _isFavorite = favs.any((u) => u.id == widget.providerId);
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isFavorite = !_isFavorite);
    try {
      await _repository.toggleFavorite(widget.providerId);
    } catch (e) {
      if (mounted) {
        setState(() => _isFavorite = !_isFavorite);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors de la mise à jour des favoris"),
          ),
        );
      }
    }
  }

  String _getImageUrl(String? path) {
    if (path == null) return "https://via.placeholder.com/150";
    if (path.startsWith('http')) return path;
    // Base URL hack: remove '/api' from the service URL to get storage root
    final apiBase = ApiService.baseUrl;
    final root = apiBase.replaceAll('/api', '');
    return '$root/storage/profile_photos/$path';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<ProviderDetails?>(
        future: _futureDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  const ShimmerLoading.rectangular(height: 300),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const ShimmerLoading.rectangular(
                              height: 30,
                              width: 200,
                            ),
                            const ShimmerLoading.circular(
                              width: 50,
                              height: 50,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const ShimmerLoading.rectangular(height: 100),
                        const SizedBox(height: 20),
                        const ShimmerLoading.rectangular(height: 200),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Prestataire introuvable"));
          }

          final details = snapshot.data!;
          final provider = details.provider;
          final competances = details.competances;
          final reviews = details.reviews;

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // --- 1. HERO HEADER WITH PHOTOS ---
                  SliverAppBar(
                    expandedHeight: 300.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.white,
                    leading: IconButton(
                      icon: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.arrow_back, color: Colors.black),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      IconButton(
                        icon: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite ? Colors.red : Colors.black,
                          ),
                        ),
                        onPressed: _toggleFavorite,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.share, color: Colors.black),
                        ),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 16),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            _getImageUrl(provider.profilePhotoUrl),
                            fit: BoxFit.cover,
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black45],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- 2. CONTENT ---
                  SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Info
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        provider.displayName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textDark,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: AppTheme.textLight,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            provider.location ?? "Non spécifié",
                                            style: const TextStyle(
                                              color: AppTheme.textLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Trust Badge
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.amber.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${provider.avgRating ?? '0.0'}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${details.completedMissions} missions",
                                        style: TextStyle(
                                          color: Colors.amber.shade900,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const Divider(height: 40),

                            // Bio
                            _buildSectionTitle(
                              "À propos",
                              Icons.person_outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              provider.slogan ??
                                  "Aucun slogan. Ce prestataire est discret.",
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: AppTheme.textDark,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              // provider.description ?? // Assuming description field exists in user model?
                              "Aucune description détaillée n'a été fournie pour le moment.",
                              style: const TextStyle(
                                color: AppTheme.textLight,
                                height: 1.5,
                              ),
                            ),

                            const Divider(height: 40),

                            // Portfolio / Réalisations
                            _buildPortfolioSection(details.portfolio),

                            const Divider(height: 40),

                            // Services
                            _buildSectionTitle(
                              "Services",
                              Icons.design_services,
                            ),
                            const SizedBox(height: 16),
                            if (competances.isEmpty)
                              const Text(
                                "Aucun service listé.",
                                style: TextStyle(color: AppTheme.textLight),
                              ),
                            ...competances.map(
                              (c) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (c.description != null)
                                            Text(
                                              c.description!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppTheme.textLight,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.textDark,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "${c.price} F",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const Divider(height: 40),

                            // Reviews
                            _buildSectionTitle("Avis", Icons.star_outline),
                            const SizedBox(height: 16),
                            if (reviews.isEmpty)
                              const Text(
                                "Aucun avis pour le moment.",
                                style: TextStyle(color: AppTheme.textLight),
                              ),
                            ...reviews.map(
                              (r) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.grey.shade200,
                                          child: Text(r.reviewerName[0]),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          r.reviewerName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          "${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}",
                                          style: const TextStyle(
                                            color: AppTheme.textLight,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (index) => Icon(
                                          index < r.rating
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 14,
                                          color: AppTheme.secondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      r.comment ?? "",
                                      style: const TextStyle(
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Bottom padding for fab
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ],
              ),

              // --- 3. STICKY BOTTOM BAR ---
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tarif de base".toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          Text(
                            provider.minPrice != null
                                ? "${provider.minPrice} F"
                                : "Sur devis",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => ReservationModal(
                              providerId: widget.providerId,
                              providerName: provider.displayName,
                              competances: competances,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Réserver", // Renamed from Contacter
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  String _getPortfolioImageUrl(String path) {
    if (path.startsWith('http')) return path;
    final apiBase = ApiService.baseUrl;
    final root = apiBase.replaceAll('/api', '');
    return '$root/storage/portfolios/$path';
  }

  Widget _buildPortfolioSection(List<PortfolioItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Réalisations", Icons.photo_library_outlined),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const Text(
            "Aucune photo de réalisation pour le moment.",
            style: TextStyle(color: AppTheme.textLight),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  onTap: () {
                    // Show full screen image
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: EdgeInsets.zero,
                        child: Stack(
                          children: [
                            InteractiveViewer(
                              child: Image.network(
                                _getPortfolioImageUrl(item.image),
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            Positioned(
                              top: 40,
                              right: 20,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: NetworkImage(_getPortfolioImageUrl(item.image)),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: (item.title != null || item.description != null)
                        ? Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            alignment: Alignment.bottomLeft,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.title != null)
                                  Text(
                                    item.title!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                if (item.description != null)
                                  Text(
                                    item.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

extension StringExtension on String {
  // Just to fix the uppercase: true syntax usage above which is wrong for TextStyle
  // but I used it for clarity.
}
