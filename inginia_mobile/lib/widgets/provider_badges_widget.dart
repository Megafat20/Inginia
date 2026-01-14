import 'package:flutter/material.dart';
import '../models/review_model.dart';

class ProviderBadgesWidget extends StatelessWidget {
  final List<ProviderBadge> badges;
  final bool compact;

  const ProviderBadgesWidget({
    super.key,
    required this.badges,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();

    if (compact) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: badges
            .take(3)
            .map((badge) => _buildCompactBadge(badge))
            .toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Badges de qualité',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: badges
              .map((badge) => _buildFullBadge(context, badge))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCompactBadge(ProviderBadge badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _parseColor(badge.color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _parseColor(badge.color).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        badge.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _parseColor(badge.color),
        ),
      ),
    );
  }

  Widget _buildFullBadge(BuildContext context, ProviderBadge badge) {
    return GestureDetector(
      onTap: () => _showBadgeDetails(context, badge),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _parseColor(badge.color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _parseColor(badge.color).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _parseColor(badge.color),
                shape: BoxShape.circle,
              ),
              child: Text(
                _getBadgeIcon(badge.type),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _parseColor(badge.color),
                  ),
                ),
                Text(
                  badge.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: _parseColor(badge.color).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context, ProviderBadge badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _parseColor(badge.color),
                shape: BoxShape.circle,
              ),
              child: Text(
                _getBadgeIcon(badge.type),
                style: const TextStyle(fontSize: 40),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _parseColor(badge.color),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Obtenu le ${_formatDate(badge.earnedAt)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _getBadgeIcon(String type) {
    switch (type) {
      case 'top_rated':
        return '⭐';
      case 'responsive':
        return '⚡';
      case 'verified':
        return '✓';
      case 'expert':
        return '🏆';
      case 'punctual':
        return '⏰';
      default:
        return '🎖️';
    }
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
