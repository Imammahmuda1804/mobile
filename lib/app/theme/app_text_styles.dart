import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const title = TextStyle(
    fontSize: 32,
    height: 1.05,
    fontWeight: FontWeight.w900,
    color: AppColors.text,
  );

  static const sectionTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: AppColors.text,
  );

  static const body = TextStyle(
    fontSize: 14,
    height: 1.55,
    fontWeight: FontWeight.w600,
    color: AppColors.muted,
  );

  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w900,
    letterSpacing: .7,
    color: AppColors.primary,
  );
}
