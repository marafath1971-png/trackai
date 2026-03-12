import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// ══════════════════════════════════════════════
// RING CHART (CustomPainter — matches JSX Ring component)
// ══════════════════════════════════════════════

class RingChart extends StatelessWidget {
  final double percent; // 0.0 – 1.0
  final double size;
  final double strokeWidth;
  final Color color;
  final String label;
  final String sub;

  const RingChart({
    super.key,
    required this.percent,
    this.size = 100,
    this.strokeWidth = 8,
    required this.color,
    required this.label,
    this.sub = '',
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        CustomPaint(
          size: Size(size, size),
          painter: _RingPainter(
              percent: percent.clamp(0, 1),
              color: color,
              bg: L.border,
              strokeWidth: strokeWidth),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.185,
                  color: L.text,
                  letterSpacing: -0.5)),
          if (sub.isNotEmpty)
            Text(sub,
                style: TextStyle(
                    fontFamily: 'Inter', fontSize: size * 0.1, color: L.sub),
                textAlign: TextAlign.center),
        ]),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color bg;
  final double strokeWidth;
  const _RingPainter(
      {required this.percent,
      required this.color,
      required this.bg,
      required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -1.5708; // -π/2

    // Background
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * 3.14159,
      false,
      Paint()
        ..color = bg
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
    // Foreground
    if (percent > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * 3.14159 * percent,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.percent != percent || o.color != color;
}

// ══════════════════════════════════════════════
// iOS TOGGLE (matches JSX Cal AI toggle)
// ══════════════════════════════════════════════

class AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const AppToggle(
      {super.key,
      required this.value,
      required this.onChanged,
      this.activeColor = const Color(0xFF111111)});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          color: value ? activeColor : const Color(0x4C787880),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Stack(children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.elasticOut,
            top: 3,
            left: value ? null : 3,
            right: value ? 3 : null,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1))
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// BADGE (pill chip)
// ══════════════════════════════════════════════

class AppBadge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color textColor;

  const AppBadge(
      {super.key,
      required this.text,
      required this.bg,
      required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
              fontFamily: 'Inter')),
    );
  }
}

// ══════════════════════════════════════════════
// TOAST (pill-style)
// ══════════════════════════════════════════════

class AppToast extends StatelessWidget {
  final String message;
  final String type; // success, error, warning, info

  const AppToast({super.key, required this.message, this.type = 'success'});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    switch (type) {
      case 'error':
        bg = const Color(0xFFEF4444);
        break;
      case 'warning':
        bg = const Color(0xFFF97316);
        break;
      case 'info':
        bg = const Color(0xFF3B82F6);
        break;
      default:
        bg = const Color(0xFF111111);
    }
    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 350),
        curve: const Cubic(0.34, 1.56, 0.64, 1),
        builder: (ctx, v, child) => Transform.translate(
          offset: Offset(0, 20 * (1 - v)),
          child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
        ),
        child: Center(
            child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                  color: bg.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Text(message,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  fontFamily: 'Inter')),
        )),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// SKELETON SHIMMER LOADER
// ══════════════════════════════════════════════

class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const SkeletonBox(
      {super.key, required this.width, required this.height, this.radius = 8});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.0, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                gradient: LinearGradient(
                  colors: [L.fill, L.border, L.fill],
                  stops: [0, _anim.value, 1],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ));
  }
}

// ══════════════════════════════════════════════
// SETTINGS ROW (label + right content)
// ══════════════════════════════════════════════

class SettingsRow extends StatelessWidget {
  final Widget leading;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsRow(
      {super.key,
      required this.leading,
      required this.label,
      this.subtitle,
      this.trailing,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: L.border, width: 0.5)),
        ),
        child: Row(children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Text(label,
                    style: TextStyle(
                        color: L.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        fontFamily: 'Inter')),
                if (subtitle != null)
                  Text(subtitle!,
                      style: TextStyle(
                          color: L.sub, fontSize: 12, fontFamily: 'Inter')),
              ])),
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// SECTION LABEL (uppercase small - like Lbl in JSX)
// ══════════════════════════════════════════════

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.08 * 11,
            color: context.L.sub,
            fontFamily: 'Inter'),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// INFO ROW (IRow in JSX)
// ══════════════════════════════════════════════

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isWarning;
  const InfoRow(
      {super.key,
      required this.label,
      required this.value,
      this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: TextStyle(fontSize: 13, color: L.sub, fontFamily: 'Inter')),
      Flexible(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isWarning ? L.red : L.text,
                  fontFamily: 'Inter'),
              textAlign: TextAlign.right)),
    ]);
  }
}

// ══════════════════════════════════════════════
// LIGHT INPUT FIELD (matches LightInp in JSX)
// ══════════════════════════════════════════════

class LightInput extends StatelessWidget {
  final String label;
  final String? placeholder;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;
  final int maxLines;

  const LightInput({
    super.key,
    required this.label,
    this.placeholder,
    required this.value,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.08 * 10,
              color: L.sub,
              fontFamily: 'Inter')),
      const SizedBox(height: 5),
      TextFormField(
        initialValue: value,
        onChanged: onChanged,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: L.text,
            fontFamily: 'Inter'),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: L.sub, fontFamily: 'Inter'),
          filled: true,
          fillColor: L.bg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: L.border, width: 0.5)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: L.border, width: 0.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: context.isDark ? AppColors.dGreen : AppColors.lBlue,
                  width: 1.5)),
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════
// COLOR SWATCH CIRCLE
// ══════════════════════════════════════════════

// ══════════════════════════════════════════════
// MED IMAGE (Intelligent Image Loader)
// ══════════════════════════════════════════════

class MedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? placeholder;

  const MedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    Widget image;
    if (imageUrl == null || imageUrl!.isEmpty) {
      image = placeholder ??
          Container(
            color: L.fill,
            child: Icon(Icons.medication_rounded,
                color: L.sub, size: width != null ? width! * 0.4 : 24),
          );
    } else if (imageUrl!.startsWith('http')) {
      image = Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            placeholder ??
            Container(
              color: L.fill,
              child: Icon(Icons.broken_image_rounded, color: L.sub),
            ),
      );
    } else {
      // Assume local file path
      image = Image.file(
        File(imageUrl!),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            placeholder ??
            Container(
              color: L.fill,
              child: Icon(Icons.broken_image_rounded, color: L.sub),
            ),
      );
    }

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      );
    }
    return image;
  }
}

Color hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
