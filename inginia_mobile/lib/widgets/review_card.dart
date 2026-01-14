import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/review_model.dart';
import '../theme/app_theme.dart';
import '../repositories/review_repository.dart';

class ReviewCard extends StatefulWidget {
  final Review review;
  final bool isProvider;
  final VoidCallback? onRespond;

  const ReviewCard({
    super.key,
    required this.review,
    this.isProvider = false,
    this.onRespond,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  final _reviewRepository = ReviewRepository();
  int _helpfulCount = 0;
  bool _hasMarkedHelpful = false;

  @override
  void initState() {
    super.initState();
    _helpfulCount = widget.review.helpfulCount;
  }

  Future<void> _markHelpful() async {
    if (_hasMarkedHelpful) return;

    final newCount = await _reviewRepository.markReviewHelpful(
      widget.review.id,
    );
    if (newCount != null) {
      setState(() {
        _helpfulCount = newCount;
        _hasMarkedHelpful = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Rating
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                backgroundImage: widget.review.reviewerPhoto != null
                    ? NetworkImage(widget.review.reviewerPhoto!)
                    : null,
                child: widget.review.reviewerPhoto == null
                    ? Text(
                        widget.review.reviewerName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.review.reviewerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (widget.review.verified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'Vérifié',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeago.format(widget.review.createdAt, locale: 'fr'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Overall Rating
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getRatingColor(widget.review.rating).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: _getRatingColor(widget.review.rating),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.review.rating.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getRatingColor(widget.review.rating),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Detailed Criteria (if available)
          if (widget.review.criteria != null &&
              widget.review.criteria!.average > 0) ...[
            _buildCriteriaRow(),
            const SizedBox(height: 16),
          ],

          // Comment
          if (widget.review.comment != null &&
              widget.review.comment!.isNotEmpty) ...[
            Text(
              widget.review.comment!,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Photos
          if (widget.review.photos.isNotEmpty) ...[
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.review.photos.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _showPhotoGallery(context, index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(widget.review.photos[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Provider Response
          if (widget.review.reponsePrestataire != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.reply, size: 16, color: AppTheme.primary),
                      SizedBox(width: 6),
                      Text(
                        'Réponse du prestataire',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.review.reponsePrestataire!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (widget.review.reponseAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(widget.review.reponseAt!, locale: 'fr'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Actions
          Row(
            children: [
              // Helpful Button
              TextButton.icon(
                onPressed: _hasMarkedHelpful ? null : _markHelpful,
                icon: Icon(
                  _hasMarkedHelpful ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 16,
                  color: _hasMarkedHelpful
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                ),
                label: Text(
                  'Utile ($_helpfulCount)',
                  style: TextStyle(
                    fontSize: 12,
                    color: _hasMarkedHelpful
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              // Respond Button (Provider only)
              if (widget.isProvider &&
                  widget.review.reponsePrestataire == null &&
                  widget.onRespond != null)
                TextButton.icon(
                  onPressed: widget.onRespond,
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Répondre', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaRow() {
    final criteria = widget.review.criteria!;
    final items = <Map<String, dynamic>>[];

    if (criteria.ponctualite != null) {
      items.add({'label': 'Ponctualité', 'value': criteria.ponctualite});
    }
    if (criteria.qualite != null) {
      items.add({'label': 'Qualité', 'value': criteria.qualite});
    }
    if (criteria.prix != null) {
      items.add({'label': 'Prix', 'value': criteria.prix});
    }
    if (criteria.communication != null) {
      items.add({'label': 'Communication', 'value': criteria.communication});
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item['label'],
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.star, size: 12, color: Colors.amber),
              const SizedBox(width: 2),
              Text(
                item['value'].toString(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }

  void _showPhotoGallery(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoGalleryScreen(
          photos: widget.review.photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class PhotoGalleryScreen extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const PhotoGalleryScreen({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.photos.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.photos[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
