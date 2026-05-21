import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../constants/destination_categories.dart';
import '../utils/formatters.dart';
import 'app_cached_image.dart';

class DestinationCardData {
  const DestinationCardData({
    required this.name,
    required this.slug,
    required this.city,
    required this.imageUrl,
    this.positiveRatio,
    this.score,
    this.googleRating,
    this.category,
    this.topics = const [],
  });

  final String name;
  final String slug;
  final String city;
  final String imageUrl;
  final num? positiveRatio;
  final num? score;
  final num? googleRating;
  final String? category;
  final List<String> topics;
}

class DestinationCard extends StatelessWidget {
  const DestinationCard({required this.destination, super.key});

  final DestinationCardData destination;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () => context.push('/destination/${destination.slug}'),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AppCachedImage(
                      imageUrl: destination.imageUrl,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    right: 12,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ImageBadge(
                          icon: LucideIcons.sparkles,
                          label: 'Skor ${scoreLabel(destination.score)}',
                          color: AppColors.ai,
                        ),
                        _ImageBadge(
                          icon: LucideIcons.star,
                          label: ratingLabel(destination.googleRating),
                        color: AppColors.neutral,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        size: 16,
                        color: AppColors.explore,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          destination.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Chip(
                        label: Text(destinationCategoryLabel(destination.category)),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                        backgroundColor: AppColors.surfaceWarm,
                      ),
                      for (final entry in destination.topics.take(3).indexed)
                        Chip(
                          label: Text(
                            entry.$1 == 0 ? 'Top topik: ${entry.$2}' : entry.$2,
                          ),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide.none,
                          backgroundColor: AppColors.surfaceCool,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.thumbsUp,
                        size: 16,
                        color: AppColors.positive,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Positif ${percentLabel(destination.positiveRatio)}',
                        style: const TextStyle(
                          color: AppColors.positive,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        LucideIcons.arrowUpRight,
                        size: 17,
                        color: AppColors.explore,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  const _ImageBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}
