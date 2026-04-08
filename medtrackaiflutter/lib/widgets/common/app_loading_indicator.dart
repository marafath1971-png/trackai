import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final bool showText;
  final String? text;
  final Color? color;

  const AppLoadingIndicator({
    super.key,
    this.size = 56,
    this.showText = false,
    this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // ── Background Glow
            Container(
              width: size * 0.8,
              height: size * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 32,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.2, 1.2),
                  duration: 1500.ms,
                  curve: Curves.easeInOut,
                ),
            
            // ── Outer Spinning Arc
            SizedBox(
              width: size * 1.2,
              height: size * 1.2,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.black.withValues(alpha: 0.1),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2000.ms),

            // ── The Logo
            Image.asset(
              'assets/images/home_logo.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.05, 1.05),
                  duration: 1000.ms,
                  curve: Curves.easeInOutSine,
                )
                .shimmer(
                    duration: 3000.ms, 
                    color: Colors.white.withValues(alpha: 0.2)),
          ],
        ),
        if (showText || text != null) ...[
          const SizedBox(height: 24),
          Text(
            (text ?? 'Processing...').toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: L.text.withValues(alpha: 0.4),
              letterSpacing: 2.0,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 1500.ms, curve: Curves.easeInOut)
              .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1)),
        ],
      ],
    );
  }
}
