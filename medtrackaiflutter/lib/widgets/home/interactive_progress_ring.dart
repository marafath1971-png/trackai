import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../shared/shared_widgets.dart';

class InteractiveProgressRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final VoidCallback? onTap;
  final String label;
  final String valueText;

  const InteractiveProgressRing({
    super.key,
    required this.progress,
    this.onTap,
    required this.label,
    required this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return BouncingButton(
      onTap: () {
        if (onTap != null) onTap!();
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.roundSquircle,
          boxShadow: AppShadows.neumorphic,
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: progress,
                        backgroundColor: L.border.withValues(alpha: 0.1),
                        progressColor: _getStatusColor(L),
                      ),
                    ),
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: L.text,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: L.text,
                      fontSize: 20,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    valueText,
                    style: AppTypography.bodyMedium.copyWith(
                      color: L.sub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickLogBtn(L),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Color _getStatusColor(AppThemeColors L) {
    if (progress >= 0.8) return L.success;
    if (progress >= 0.5) return L.warning;
    return L.error;
  }

  Widget _buildQuickLogBtn(AppThemeColors L) {
    return BouncingButton(
      hapticEnabled: false,
      onTap: () {
        HapticEngine.heavyImpact();
        if (onTap != null) onTap!();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: L.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.max),
          border:
              Border.all(color: L.primary.withValues(alpha: 0.1), width: 1.5),
          boxShadow: AppShadows.subtle,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, color: L.primary, size: 14),
            const SizedBox(width: 6),
            Text(
              'QUICK LOG',
              style: AppTypography.labelSmall.copyWith(
                color: L.primary,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  _RingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    const strokeWidth = 12.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final pgPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -pi / 2,
      sweepAngle,
      false,
      pgPaint,
    );

    // Add a gloss effect at the end of the progress
    if (progress > 0) {
      final glossPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
        ..strokeWidth = strokeWidth / 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        -pi / 2 + sweepAngle - 0.1,
        0.1,
        false,
        glossPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
