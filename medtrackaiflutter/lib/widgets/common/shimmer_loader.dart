import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

/// A premium skeleton loader that provides an elegant, sweeping shimmer effect.
/// Replaces generic circular progress indicators to maintain a high-fidelity
/// production feel across list forms and cards during data fetches.
class ShimmerLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry? borderRadius;

  const ShimmerLoader({
    super.key,
    this.width = double.infinity,
    this.height = 80,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.L.card.withValues(alpha: 0.5),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.L.border.withValues(alpha: 0.0),
              context.L.border.withValues(alpha: 0.2),
              context.L.border.withValues(alpha: 0.0),
            ],
            stops: const [0.3, 0.5, 0.7],
          ),
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(
            duration: 1500.ms,
            color: context.L.text.withValues(alpha: 0.1),
          ),
    );
  }
}
