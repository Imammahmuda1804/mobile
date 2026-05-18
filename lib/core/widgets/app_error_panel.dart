import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app_button.dart';
import 'empty_state.dart';

class AppErrorPanel extends StatelessWidget {
  const AppErrorPanel({
    required this.title,
    required this.message,
    this.onRetry,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: title,
      message: message,
      icon: LucideIcons.circleAlert,
      action: onRetry == null
          ? null
          : AppButton(
              label: 'Coba lagi',
              icon: LucideIcons.refreshCcw,
              onPressed: onRetry,
            ),
    );
  }
}
