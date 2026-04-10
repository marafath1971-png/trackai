import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';

class AmbientMeshBackground extends StatelessWidget {
  const AmbientMeshBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final L = context.L;

    // Determine ambient color based on adherence score
    final adherence = state.getAdherenceScore();
    final isDark = context.select<AppState, bool>((s) => s.darkMode);
    
    // Default fallback
    Color pulseColor = L.secondary;
    
    // Dynamic color shift based on adherence (Living UI in action)
    if (adherence >= 0.8) {
      pulseColor = L.success;
    } else if (adherence >= 0.5) {
      pulseColor = L.warning;
    } else if (adherence > 0) {
      pulseColor = L.error;
    } else {
      pulseColor = L.secondary; // No data yet
    }

    if (!isDark) {
      pulseColor = pulseColor.withValues(alpha: 0.15);
    } else {
      pulseColor = pulseColor.withValues(alpha: 0.25);
    }

    return Stack(
      children: [
        // Base mesh background
        Container(
          width: double.infinity,
          height: double.infinity,
          color: L.meshBg,
        ),

        // Animated Ambient Orb 1 (Top Left)
        Positioned(
          top: -150,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pulseColor,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 8.seconds)
              .fadeIn(duration: 2.seconds),
        ),

        // Animated Ambient Orb 2 (Bottom Right)
        Positioned(
          bottom: -150,
          right: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: L.secondary.withValues(alpha: isDark ? 0.15 : 0.08),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 10.seconds)
              .fadeIn(duration: 2.seconds),
        ),

        // Liquid Glass Blur Overlay
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
