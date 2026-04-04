import 'package:flutter/material.dart';

class MeshGradientPainter extends CustomPainter {
  final Color baseColor;
  final Color accentColor;

  MeshGradientPainter({required this.baseColor, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);

    final accentPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60.0);

    accentPaint.color = accentColor;
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.2), 200, accentPaint);
    canvas.drawCircle(
        Offset(size.width * 0.9, size.height * 0.8), 250, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
class MeshGradient extends StatelessWidget {
  final List<Color> colors;
  final Widget? child;

  const MeshGradient({super.key, required this.colors, this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: MeshGradientPainter(
          baseColor: colors.first,
          accentColor: colors.length > 1 ? colors[1] : colors.first,
        ),
        child: child,
      ),
    );
  }
}
