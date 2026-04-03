import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final bool showText;
  final String? text;

  const AppLoadingIndicator({
    super.key,
    this.size = 40,
    this.showText = false,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/home_logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(
                duration: 2000.ms, color: context.L.onBg.withValues(alpha: 0.2))
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.1, 1.1),
              duration: 1000.ms,
              curve: Curves.easeInOutSine,
            )
            .then()
            .scale(
              begin: const Offset(1.1, 1.1),
              end: const Offset(0.9, 0.9),
              duration: 1000.ms,
              curve: Curves.easeInOutSine,
            ),
        if (showText || text != null) ...[
          const SizedBox(height: 16),
          Text(
            (text ?? 'Processing...').toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: context.L.sub,
              letterSpacing: 1.2,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(duration: 1000.ms)
              .then()
              .fadeOut(duration: 1000.ms),
        ],
      ],
    );
  }
}
