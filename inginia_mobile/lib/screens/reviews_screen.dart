import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../repositories/review_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/review_card.dart';

class ReviewsScreen extends StatefulWidget {
  final int providerId;
  final String providerName;
  final bool isProvider;

  const ReviewsScreen({
    super.key,
    required this.providerId,
    required this.providerName,
    this.isProvider = false,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final _reviewRepository = ReviewRepository();

  List<Review> _reviews = [];
  ReviewStats? _stats;
  double _providerRating = 0;
  bool _isLoading = true;

  // Filters
  int? _minRating;
  bool _withPhotosOnly = false;
  bool _verifiedOnly = false;
  String _sortBy = 'recent';

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);

    try {
      final data = await _reviewRepository.getProviderReviews(
        widget.providerId,
        minRating: _minRating,
        withPhotos: _withPhotosOnly ? true : null,
        verified: _verifiedOnly ? true : null,
        sortBy: _sortBy,
      );

      setState(() {
        _reviews = data['reviews'] as List<Review>;
        _stats = data['stats'] as ReviewStats;
        _providerRating = data['rating'] as double;
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

  void _showRespondDialog(Review review) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Répondre à l\'avis'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Votre réponse...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              try {
                await _reviewRepository.respondToReview(
                  review.id,
                  controller.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Réponse publiée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadReviews();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Publier'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Avis'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReviews,
              child: CustomScrollView(
                slivers: [
                  // Stats Header
                  if (_stats != null)
                    SliverToBoxAdapter(child: _buildStatsHeader()),

                  // Reviews List
                  if (_reviews.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Aucun avis pour le moment',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return ReviewCard(
                            review: _reviews[index],
                            isProvider: widget.isProvider,
                            onRespond: widget.isProvider
                                ? () => _showRespondDialog(_reviews[index])
                                : null,
                          );
                        }, childCount: _reviews.length),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Overall Rating
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      _providerRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        Icon(Icons.star, color: Colors.amber, size: 20),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_stats!.total} avis',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(5, _stats!.distribution[5] ?? 0),
                    _buildRatingBar(4, _stats!.distribution[4] ?? 0),
                    _buildRatingBar(3, _stats!.distribution[3] ?? 0),
                    _buildRatingBar(2, _stats!.distribution[2] ?? 0),
                    _buildRatingBar(1, _stats!.distribution[1] ?? 0),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // Criteria Averages
          const Text(
            'Critères détaillés',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCriteriaChip(
                '⏰ Ponctualité',
                _stats!.criteriaAverages['ponctualite'] ?? 0,
              ),
              _buildCriteriaChip(
                '✨ Qualité',
                _stats!.criteriaAverages['qualite'] ?? 0,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCriteriaChip(
                '💰 Prix',
                _stats!.criteriaAverages['prix'] ?? 0,
              ),
              _buildCriteriaChip(
                '💬 Communication',
                _stats!.criteriaAverages['communication'] ?? 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count) {
    final percentage = _stats!.total > 0 ? (count / _stats!.total) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$stars',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaChip(String label, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtrer les avis',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                // Min Rating Filter
                const Text('Note minimale', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [null, 5, 4, 3, 2, 1].map((rating) {
                    return ChoiceChip(
                      label: Text(rating == null ? 'Toutes' : '$rating ⭐'),
                      selected: _minRating == rating,
                      onSelected: (selected) {
                        setModalState(
                          () => _minRating = selected ? rating : null,
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Other Filters
                CheckboxListTile(
                  title: const Text('Avec photos uniquement'),
                  value: _withPhotosOnly,
                  onChanged: (value) {
                    setModalState(() => _withPhotosOnly = value ?? false);
                  },
                ),
                CheckboxListTile(
                  title: const Text('Avis vérifiés uniquement'),
                  value: _verifiedOnly,
                  onChanged: (value) {
                    setModalState(() => _verifiedOnly = value ?? false);
                  },
                ),
                const SizedBox(height: 16),

                // Sort By
                const Text('Trier par', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      [
                        {'value': 'recent', 'label': 'Plus récents'},
                        {'value': 'helpful', 'label': 'Plus utiles'},
                        {'value': 'rating_high', 'label': 'Note décroissante'},
                        {'value': 'rating_low', 'label': 'Note croissante'},
                      ].map((sort) {
                        return ChoiceChip(
                          label: Text(sort['label']!),
                          selected: _sortBy == sort['value'],
                          onSelected: (selected) {
                            setModalState(() => _sortBy = sort['value']!);
                          },
                        );
                      }).toList(),
                ),
                const SizedBox(height: 20),

                // Apply Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _loadReviews();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Appliquer les filtres'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
