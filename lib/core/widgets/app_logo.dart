import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    this.size = 36,
    this.showText = true,
    this.textColor = AppColors.text,
    super.key,
  });

  final double size;
  final bool showText;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * .12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * .32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x220F172A),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo-icon.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _LogoFallback(size: size),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 9),
          Text(
            'RANAHINSIGHT',
            style: TextStyle(
              color: textColor,
              fontSize: size * .44,
              fontWeight: FontWeight.w900,
              letterSpacing: .3,
            ),
          ),
        ],
      ],
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(size * .24),
      ),
      child: Center(
        child: Icon(
          LucideIcons.sparkles,
          size: size * .46,
          color: Colors.white,
        ),
      ),
    );
  }
}
