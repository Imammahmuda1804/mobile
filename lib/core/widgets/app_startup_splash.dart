import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import 'app_logo.dart';

class AppStartupSplash extends StatefulWidget {
  const AppStartupSplash({this.message, super.key});

  final String? message;

  @override
  State<AppStartupSplash> createState() => _AppStartupSplashState();
}

class _AppStartupSplashState extends State<AppStartupSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, .45, curve: Curves.easeOutCubic),
    );
    _scale = Tween<double>(begin: .94, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, .55, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/auth-bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _AssetBackgroundFallback(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xF7F8FAFC),
                  Color(0xF2FFF3EC),
                  Color(0xFAF8FAFC),
                ],
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -90,
            child: _GlowOrb(
              size: 220,
              color: AppColors.primary.withValues(alpha: .22),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: _GlowOrb(
              size: 240,
              color: AppColors.secondary.withValues(alpha: .18),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return SizedBox(
                              width: 138,
                              height: 138,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.rotate(
                                    angle: _controller.value * math.pi * 2,
                                    child: CustomPaint(
                                      painter: _RingPainter(_controller.value),
                                      size: const Size.square(138),
                                    ),
                                  ),
                                  const AppLogo(size: 76, showText: false),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 26),
                        const AppLogo(size: 34),
                        const SizedBox(height: 12),
                        Text(
                          widget.message ?? 'Membaca vibe destinasi...',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Menyiapkan rekomendasi, sentimen, dan favorit Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            height: 1.45,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 28),
                        const _LoadingSteps(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetBackgroundFallback extends StatelessWidget {
  const _AssetBackgroundFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF3EC),
            AppColors.background,
            Color(0xFFEAF6FB),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 6;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .72);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          AppColors.primary,
          AppColors.secondary,
          Color(0xFFFFD0BA),
          AppColors.primary,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * (1.15 + progress * .2),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 80, spreadRadius: 20),
        ],
      ),
    );
  }
}

class _LoadingSteps extends StatelessWidget {
  const _LoadingSteps();

  @override
  Widget build(BuildContext context) {
    final items = [
      (LucideIcons.sparkles, 'Vibe'),
      (LucideIcons.messageSquareText, 'Ulasan'),
      (LucideIcons.mapPinned, 'Destinasi'),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .82),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFFFD0BA)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.$1, size: 15, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  item.$2,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
