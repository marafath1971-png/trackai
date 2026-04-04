import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
              bg: L.fill,
              strokeWidth: strokeWidth),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.185,
                  color: L.text,
                  letterSpacing: -0.5)),
          if (sub.isNotEmpty)
            Text(sub,
                style: AppTypography.labelSmall
                    .copyWith(fontSize: size * 0.1, color: L.sub),
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

  const AppToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 48,
        height: 28,
        decoration: BoxDecoration(
          color: value ? L.text : L.fill,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: value ? L.text : L.border.withValues(alpha: 0.5),
            width: 1.0,
          ),
          boxShadow: [
            if (value)
              BoxShadow(
                color: L.text.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Stack(children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: value ? L.bg : L.onBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: L.onBg.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ],
                ),
              ),
            ),
          ).animate(target: value ? 1 : 0).then().scale(
              begin: const Offset(1.1, 1.1),
              end: const Offset(1, 1),
              duration: 150.ms),
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
          style: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor,
          )),
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
    final L = context.L;
    final Color accent;
    final IconData icon;

    switch (type) {
      case 'error':
        accent = L.error;
        icon = Icons.error_rounded;
        break;
      case 'warning':
        accent = L.warning;
        icon = Icons.warning_rounded;
        break;
      case 'info':
        accent = L.info;
        icon = Icons.info_rounded;
        break;
      default:
        accent = L.success;
        icon = Icons.check_circle_rounded;
    }

    return Positioned(
      bottom: 120, // Floating above the bottom nav
      left: 24,
      right: 24,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(AppRadius.max),
            border: Border.all(
              color: accent.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 32,
                offset: const Offset(0, 16),
                spreadRadius: -8,
              ),
              BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 16),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  message,
                  style: AppTypography.labelLarge.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.5, end: 0, curve: Curves.easeOutBack).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutBack),
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
      {super.key, required this.width, required this.height, this.radius = 16});

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
          border: Border(top: BorderSide(color: L.border, width: 1.0)),
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
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w600,
                    )),
                if (subtitle != null)
                  Text(subtitle!,
                      style: AppTypography.labelSmall.copyWith(
                        color: L.sub,
                      )),
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
        style: AppTypography.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08 * 11,
          color: context.L.sub,
        ),
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
          style: AppTypography.bodySmall.copyWith(
            color: L.sub,
          )),
      Flexible(
          child: Text(value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: isWarning ? L.red : L.text,
              ),
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
          style: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.08 * 10,
            color: L.sub,
          )),
      const SizedBox(height: 5),
      TextFormField(
        initialValue: value,
        onChanged: onChanged,
        keyboardType: keyboardType,
        maxLines: maxLines,
        cursorColor: L.text,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
          color: L.text,
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: L.sub,
          ),
          filled: true,
          fillColor: L.bg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: L.border, width: 1.0)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: L.border, width: 1.0)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: L.text, width: 1.0)),
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
