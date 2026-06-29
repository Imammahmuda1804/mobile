import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const title = TextStyle(
    fontSize: 32,
    height: 1.08,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );

  static const sectionTitle = TextStyle(
    fontSize: 22,
    height: 1.15,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
  );

  static const body = TextStyle(
    fontSize: 14,
    height: 1.55,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
  );

  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: .4,
    color: AppColors.primary,
  );
}
