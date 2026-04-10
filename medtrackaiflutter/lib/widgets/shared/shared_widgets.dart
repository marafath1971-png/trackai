import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/color_utils.dart';
import '../../domain/entities/medicine.dart';

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
    this.strokeWidth = 6, // Refined thinner stroke
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
              bg: Colors.black.withValues(alpha: 0.05),
              strokeWidth: strokeWidth),
        ),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: AppTypography.displaySmall.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: size * 0.22,
                  color: L.text,
                  letterSpacing: -1.0,
                  height: 1.0)),
          if (sub.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(sub.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                      fontSize: size * 0.08,
                      color: L.sub,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center),
            ),
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

    final bgPaint = Paint()
      ..color = bg
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * 3.14159,
      false,
      bgPaint,
    );

    // Foreground
    if (percent > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * 3.14159 * percent,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.percent != percent || o.color != color;
}

class AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AppToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTap: () {
        if (!value) {
          HapticEngine.success();
        } else {
          HapticEngine.light();
        }
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: 500.ms,
        curve: Curves.elasticOut,
        width: 52,
        height: 30,
        decoration: BoxDecoration(
          color: value ? L.text : L.fill.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Stack(children: [
          AnimatedAlign(
            duration: 500.ms,
            curve: Curves.elasticOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: value ? 0.2 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// GLASS CARD (iOS 26 Frosted Glass)
// ══════════════════════════════════════════════

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool showBorder;
  final Color? tintColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
    this.showBorder = true,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final r = borderRadius ?? AppRadius.roundSquircle;

    return ClipPath(
      clipper: ShapeBorderClipper(
        shape: ContinuousRectangleBorder(borderRadius: r),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: ShapeDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (tintColor ?? Colors.white).withValues(alpha: 0.14),
                (tintColor ?? Colors.white).withValues(alpha: 0.04),
              ],
            ),
            shape: ContinuousRectangleBorder(
              borderRadius: r,
              side: showBorder
                  ? BorderSide(
                      color: L.glassBorder.withValues(alpha: 0.12),
                      width: 0.5,
                    )
                  : BorderSide.none,
            ),
            shadows: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 48,
                offset: const Offset(0, 24),
                spreadRadius: -12,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.35),
                blurRadius: 1,
                offset: const Offset(0, -0.5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// BOUNCING BUTTON (iOS 26 Spring Interaction)
// ══════════════════════════════════════════════

class BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final bool hapticEnabled;
  final Duration duration;

  const BouncingButton({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.95,
    this.hapticEnabled = true,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        if (widget.hapticEnabled) HapticEngine.light();
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleFactor : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: _isPressed ? 0.05 : 0),
            BlendMode.srcATop,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// SQUIRCLE CARD (iOS 26 High-Fidelity)
// ══════════════════════════════════════════════

class SquircleCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final List<BoxShadow>? boxShadow;
  final bool showBorder;
  final double? borderRadius;
  final double? radius;
  final double? borderWidth;

  const SquircleCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.boxShadow,
    this.showBorder = true,
    this.borderRadius,
    this.radius,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = radius ?? borderRadius ?? AppRadius.squircle;
    final bw = borderWidth ?? 0.5;

    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (color ?? L.card).withValues(alpha: isDark ? 0.95 : 1.0),
            (color ?? L.card).withValues(alpha: isDark ? 0.88 : 0.97),
          ],
        ),
        borderRadius: BorderRadius.circular(r),
        border: showBorder
            ? Border.all(
                color: L.border.withValues(alpha: isDark ? 0.12 : 0.07),
                width: bw,
              )
            : null,
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                blurRadius: 40,
                offset: const Offset(0, 16),
                spreadRadius: -8,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
      ),
      child: child,
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
    final String emoji;

    switch (type) {
      case 'error':
        emoji = '🚨';
        break;
      case 'warning':
        emoji = '⚠️';
        break;
      case 'info':
        emoji = 'ℹ️';
        break;
      default:
        emoji = '✅';
    }

    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Positioned(
      bottom: bottomPadding + 120,
      left: 24,
      right: 24,
      child: Center(
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: BorderRadius.circular(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.5, end: 0, curve: Curves.easeOutQuart)
          .shimmer(
              delay: 600.ms,
              duration: 1200.ms,
              color: Colors.white.withValues(alpha: 0.1)),
    );
  }
}

class SyncStatusBanner extends StatelessWidget {
  final bool isSyncing;
  final DateTime? lastSynced;
  const SyncStatusBanner({super.key, required this.isSyncing, this.lastSynced});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    if (!isSyncing && lastSynced == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: L.bg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: L.border.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isSyncing ? L.warning : L.success,
              shape: BoxShape.circle,
            ),
          )
              .animate(
                  onPlay: isSyncing ? (c) => c.repeat(reverse: true) : null)
              .fade(duration: 500.ms),
          const SizedBox(width: 8),
          Text(
            isSyncing ? 'SYNCING_CLOUD' : 'CLOUD_STABLE',
            style: AppTypography.labelSmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: L.sub.withValues(alpha: 0.5),
              letterSpacing: 1.0,
            ),
          ),
        ],
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
    return AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius),
                gradient: LinearGradient(
                  colors: [
                    context.L.card.withValues(alpha: 0.5),
                    context.L.card,
                    context.L.card.withValues(alpha: 0.5),
                  ],
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
        decoration: const BoxDecoration(
          border: Border(top: BorderSide.none),
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
              borderSide: BorderSide(
                  color: L.border.withValues(alpha: 0.1), width: 0.5)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(
                  color: L.border.withValues(alpha: 0.1), width: 0.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide:
                  BorderSide(color: L.text.withValues(alpha: 0.2), width: 0.5)),
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
  final double? borderRadius;
  final Widget? placeholder;

  const MedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
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
      // Assume local file path or package asset
      if (imageUrl!.startsWith('assets/')) {
        image = Image.asset(
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
    }

    final radius = borderRadius ?? AppRadius.squircle;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: image,
    );
  }
}

// ══════════════════════════════════════════════
// DOSE CARD (iOS 26 High-Fidelity)
// ══════════════════════════════════════════════

class DoseCard extends StatefulWidget {
  final Medicine med;
  final ScheduleEntry sched;
  final bool taken;
  final bool overdue;
  final bool isNext;
  final VoidCallback onTake;
  final VoidCallback onSnooze;
  final VoidCallback onTap;

  const DoseCard({
    super.key,
    required this.med,
    required this.sched,
    required this.taken,
    required this.overdue,
    required this.isNext,
    required this.onTake,
    required this.onSnooze,
    required this.onTap,
  });

  @override
  State<DoseCard> createState() => _DoseCardState();
}

class _DoseCardState extends State<DoseCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final medColor = hexToColor(widget.med.color);
    final isDone = widget.taken;

    return Dismissible(
      key: ValueKey('dose_${widget.sched.id}_${widget.taken}'),
      direction: isDone ? DismissDirection.none : DismissDirection.startToEnd,
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          HapticEngine.doseTaken();
          Future.delayed(const Duration(milliseconds: 180), widget.onTake);
        }
        return false;
      },
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: L.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: L.success.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Row(
          children: [
            const Text('✅', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Text('Mark taken',
                style: AppTypography.labelMedium.copyWith(
                    color: L.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1.0,
          duration: 100.ms,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDone ? L.card.withValues(alpha: 0.6) : L.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: L.border.withValues(alpha: 0.08), width: 0.5),
              boxShadow: widget.isNext && !isDone
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                        spreadRadius: -5,
                      ),
                      ...AppShadows.neumorphic,
                    ]
                  : AppShadows.neumorphic,
            ),
            child: Row(
              children: [
                // ── Colored icon container ──
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDone
                        ? medColor.withValues(alpha: 0.07)
                        : medColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: isDone
                        ? const Text('✅', style: TextStyle(fontSize: 16))
                        : const Text('💊', style: TextStyle(fontSize: 18)),
                  ),
                )
                    .animate(target: isDone ? 1 : 0)
                    .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.2, 1.2),
                        duration: 200.ms,
                        curve: Curves.elasticOut)
                    .then()
                    .scale(
                        begin: const Offset(1.2, 1.2),
                        end: const Offset(1.0, 1.0),
                        duration: 200.ms),
                const SizedBox(width: 14),
                // ── Med name + time ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.med.name,
                        style: AppTypography.labelLarge.copyWith(
                          color:
                              isDone ? L.text.withValues(alpha: 0.3) : L.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.3,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          decorationColor: L.text.withValues(alpha: 0.2),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            fmtTime(widget.sched.h, widget.sched.m, context),
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDone
                                  ? L.sub.withValues(alpha: 0.25)
                                  : widget.overdue
                                      ? L.error.withValues(alpha: 0.8)
                                      : L.sub.withValues(alpha: 0.55),
                            ),
                          ),
                          if (widget.med.dose.isNotEmpty) ...[
                            Text(' · ',
                                style: AppTypography.labelSmall.copyWith(
                                    color: L.sub.withValues(alpha: 0.25),
                                    fontSize: 12)),
                            Text(widget.med.dose,
                                style: AppTypography.labelSmall.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: L.sub.withValues(alpha: 0.4))),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildCta(L, medColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCta(AppThemeColors L, Color medColor) {
    if (widget.taken) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: L.success.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded,
            color: L.success.withValues(alpha: 0.55), size: 16),
      );
    }
    if (widget.overdue) {
      return GestureDetector(
        onTap: widget.onTake,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: L.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: L.error.withValues(alpha: 0.2), width: 1),
          ),
          child: Text('LATE',
              style: AppTypography.labelSmall.copyWith(
                  color: L.error,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.5)),
        ),
      );
    }
    if (widget.isNext) {
      return GestureDetector(
        onTap: widget.onTake,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: L.text,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: L.text.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Text('Take',
              style: AppTypography.labelMedium.copyWith(
                  color: L.bg,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0)),
        ),
      );
    }
    return GestureDetector(
      onTap: widget.onTake,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: L.fill.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.add_rounded,
            size: 20, color: L.text.withValues(alpha: 0.5)),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool glow;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ]
            : null,
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: L.bg,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
