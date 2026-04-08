import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WeeklyWellnessRing extends StatelessWidget {
  final double adherence;
  final List<double> dailyRates;

  const WeeklyWellnessRing({
    super.key,
    required this.adherence,
    required this.dailyRates,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getColor(adherence).withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 10,
                )
              ],
            ),
          ),

          // Main Ring Painter
          CustomPaint(
            size: const Size(200, 200),
            painter: _WellnessRingPainter(
              adherence: adherence,
              dailyRates: dailyRates,
              color: _getColor(adherence),
            ),
          ).animate().rotate(duration: 800.ms, curve: Curves.easeOutCubic),

          // Center Text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(adherence * 100).round()}%',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -1,
                ),
              ),
              const Text(
                'ADHERENCE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.black26,
                  letterSpacing: 1,
                ),
              ),
            ],
          ).animate().scale(delay: 400.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Color _getColor(double rate) {
    if (rate >= 0.8) return const Color(0xFFD4F544);
    if (rate >= 0.5) return Colors.orange;
    return Colors.redAccent;
  }
}

class _WellnessRingPainter extends CustomPainter {
  final double adherence;
  final List<double> dailyRates;
  final Color color;

  _WellnessRingPainter({
    required this.adherence,
    required this.dailyRates,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    // 1. Draw Background Track
    final trackPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Draw Daily Segments
    const segmentAngle = (2 * pi) / 7;
    const gap = 0.1;
    
    for (int i = 0; i < 7; i++) {
      final rate = i < dailyRates.length ? dailyRates[i] : 0.0;
      final startAngle = -pi / 2 + (i * segmentAngle) + (gap / 2);
      final sweepAngle = (segmentAngle - gap) * rate;

      if (rate > 0) {
        final segmentPaint = Paint()
          ..color = color.withValues(alpha: 0.3 + (rate * 0.7))
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          segmentPaint,
        );
      }
    }

    // 3. Draw Overall Progress Ring (Thin)
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 10),
      -pi / 2,
      2 * pi * adherence,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
