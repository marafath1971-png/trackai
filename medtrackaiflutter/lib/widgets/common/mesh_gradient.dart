import 'package:flutter/material.dart';
import 'dart:math' as math;

class MeshGradientPainter extends CustomPainter {
  final Color baseColor;
  final Color accentColor;
  final double animationValue;

  MeshGradientPainter({
    required this.baseColor,
    required this.accentColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);

    final accentPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120.0);

    accentPaint.color = accentColor.withValues(alpha: 0.5);

    final centerOffset1 = Offset(
      size.width * (0.2 + 0.3 * math.sin(animationValue * math.pi * 2)),
      size.height * (0.2 + 0.2 * math.cos(animationValue * math.pi * 2)),
    );

    final centerOffset2 = Offset(
      size.width * (0.8 - 0.2 * math.cos(animationValue * math.pi * 2)),
      size.height * (0.7 + 0.3 * math.sin(animationValue * math.pi * 2)),
    );

    final centerOffset3 = Offset(
      size.width * (0.5 + 0.4 * math.sin(animationValue * math.pi)),
      size.height * (0.9 - 0.2 * math.cos(animationValue * math.pi)),
    );

    canvas.drawCircle(centerOffset1, size.width * 0.5, accentPaint);
    canvas.drawCircle(centerOffset2, size.width * 0.6, accentPaint);
    canvas.drawCircle(centerOffset3, size.width * 0.4, accentPaint);
  }

  @override
  bool shouldRepaint(covariant MeshGradientPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.accentColor != accentColor;
  }
}

class MeshGradient extends StatefulWidget {
  final List<Color> colors;
  final Widget? child;

  const MeshGradient({super.key, required this.colors, this.child});

  @override
  State<MeshGradient> createState() => _MeshGradientState();
}

class _MeshGradientState extends State<MeshGradient>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: MeshGradientPainter(
              baseColor: widget.colors.first,
              accentColor:
                  widget.colors.length > 1 ? widget.colors[1] : widget.colors.first,
              animationValue: _controller.value,
            ),
            child: widget.child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
