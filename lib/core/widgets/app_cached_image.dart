import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';

class AppCachedImage extends StatelessWidget {
  const AppCachedImage({
    required this.imageUrl,
    required this.borderRadius,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String imageUrl;
  final BorderRadius borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return _Fallback(borderRadius: borderRadius);

    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        placeholder: (_, __) => const ColoredBox(color: Color(0xFFE2E8F0)),
        errorWidget: (_, __, ___) => _Fallback(borderRadius: borderRadius),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.borderRadius});

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        color: const Color(0xFFFFEEDB),
        alignment: Alignment.center,
        child: const Icon(LucideIcons.image, color: AppColors.primary),
      ),
    );
  }
}
