import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import 'app_cached_image.dart';

void showImagePreview(
  BuildContext context, {
  required String imageUrl,
  String title = 'Preview foto',
  bool showHeader = true,
}) {
  if (imageUrl.trim().isEmpty) return;

  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: EdgeInsets.all(showHeader ? 14 : 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader) ...[
                Row(
                  children: [
                    const Icon(LucideIcons.image, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup preview',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(LucideIcons.x),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              AspectRatio(
                aspectRatio: 1,
                child: GestureDetector(
                  onTap: showHeader ? null : () => Navigator.of(context).pop(),
                  child: AppCachedImage(
                    imageUrl: imageUrl,
                    borderRadius: BorderRadius.circular(showHeader ? 22 : 28),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
