import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white,
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: const [0.3, 0.5, 0.7],
          ),
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(
            duration: 1500.ms,
            color: Colors.white.withValues(alpha: 0.3),
          ),
    );
  }
}
