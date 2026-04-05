import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../domain/entities/medicine.dart';

class DoseCard extends StatefulWidget {
  final DoseItem dose;
  final bool taken;
  final bool overdue;
  final bool isNext;
  final AppThemeColors L;
  final VoidCallback onTake;
  final VoidCallback onSnooze;
  final VoidCallback onTap;

  const DoseCard(
      {super.key,
      required this.dose,
      required this.taken,
      required this.overdue,
      this.isNext = false,
      required this.L,
      required this.onTake,
      required this.onSnooze,
      required this.onTap});

  @override
  State<DoseCard> createState() => _DoseCardState();
}

class _DoseCardState extends State<DoseCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _checkController;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  void _handleTake(BuildContext context) {
    if (widget.taken) return;
    HapticEngine.doseTaken();
    _checkController.forward();
    widget.onTake();
  }

  @override
  Widget build(BuildContext context) {
    final medColor = hexToColor(widget.dose.med.color);
    final L = widget.L;

    // Card border glow: lime for NEXT, red for overdue
    // Status-driven industrial borders (Cal AI)
    Color borderColor;
    if (widget.taken) {
      borderColor = L.success; // Taken: Solid Green
    } else if (widget.overdue) {
      borderColor = L.error; // Overdue: Solid Red
    } else if (widget.isNext) {
      borderColor = L.text; // Next: High contrast Neutral
    } else {
      borderColor = L.border; // Default: Standard Industrial
    }

    // Card background
    Color cardBg;
    if (widget.taken) {
      cardBg = L.bg;
    } else if (widget.overdue) {
      cardBg = L.error.withValues(alpha: 0.03);
    } else if (widget.isNext) {
      cardBg = L.secondary.withValues(alpha: 0.04);
    } else {
      cardBg = L.card;
    }

    return Dismissible(
      key: ValueKey('dose_${widget.dose.key}'),
      direction:
          widget.taken ? DismissDirection.none : DismissDirection.horizontal,
      onDismissed: (direction) {},
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticEngine.doseTaken();
          // Delay state update slightly to let snap-back finish
          Future.delayed(const Duration(milliseconds: 200), () {
            widget.onTake();
          });
        } else {
          HapticEngine.light();
          widget.onSnooze();
        }
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
            gradient: AppGradients.main, borderRadius: AppRadius.roundXL),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
            color: L.sub.withValues(alpha: 0.08),
            borderRadius: AppRadius.roundXL),
        child: Icon(Icons.more_horiz_rounded, color: L.text, size: 24),
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        // Card body tap = navigate to medicine detail
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.975 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor, width: 1.5), // Industrial 1.5px border
            ),
            child: ClipRRect(
              borderRadius: AppRadius.roundXL,
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Left accent strip (medicine color)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 4,
                      decoration: BoxDecoration(
                        color: widget.taken
                            ? medColor.withValues(alpha: 0.2)
                            : medColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppRadius.xl),
                          bottomLeft: Radius.circular(AppRadius.xl),
                        ),
                      ),
                    ),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(children: [
                          // Time column
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                  fmtTime(widget.dose.sched.h,
                                      widget.dose.sched.m, context),
                                  style: AppTypography.titleMedium.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: widget.taken
                                        ? L.sub.withValues(alpha: 0.4)
                                        : L.text,
                                    letterSpacing: -0.5,
                                  )),
                              const SizedBox(height: 2),
                              Text(
                                widget.dose.sched.label,
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 10,
                                  color: L.sub.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          // Medicine name & dose
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.dose.sched.ritual != Ritual.none
                                      ? '${widget.dose.sched.ritual.displayName} ${widget.dose.sched.ritual.emoji}'
                                          .trim()
                                      : widget.dose.med.name,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontSize:
                                        widget.dose.sched.ritual != Ritual.none
                                            ? 14
                                            : 15,
                                    fontWeight: FontWeight.w800,
                                    color: widget.taken
                                        ? L.sub.withValues(alpha: 0.3)
                                        : (widget.dose.sched.ritual !=
                                                Ritual.none
                                            ? L.text.withValues(alpha: 0.7)
                                            : L.text),
                                    decoration: widget.taken
                                        ? TextDecoration.lineThrough
                                        : null,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  widget.dose.sched.ritual != Ritual.none
                                      ? '${widget.dose.med.name} · ${widget.dose.med.dose}'
                                      : widget.dose.med.dose,
                                  style: AppTypography.labelMedium.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: widget.taken
                                        ? L.sub.withValues(alpha: 0.25)
                                        : L.sub,
                                    decoration: widget.taken &&
                                            widget.dose.sched.ritual !=
                                                Ritual.none
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Right CTA area
                          GestureDetector(
                            onTap: widget.taken ? null : () => _handleTake(context),
                            behavior: HitTestBehavior.opaque,
                            child: _buildCta(L),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCta(AppThemeColors L) {
    if (widget.taken) {
      // Animated check badge
      return ScaleTransition(
        scale: CurvedAnimation(
          parent: _checkController,
          curve: Curves.elasticOut,
        ),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: L.text,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, color: L.bg, size: 14),
        ),
      );
    }
    if (widget.overdue) {
      return _OverdueBadge(L: L);
    }
    if (widget.isNext) {
      // Lime pill CTA — "TAKE NOW"
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: AppGradients.main,
          borderRadius: BorderRadius.circular(AppRadius.max),
          boxShadow: AppShadows.glow(L.secondary, intensity: 0.25),
        ),
        child: Text(
          'NOW',
          style: AppTypography.labelSmall.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: 0.5,
          ),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
            duration: 2500.ms,
            color: Colors.white.withValues(alpha: 0.4),
          );
    }
    // Default "TAKE" label
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: L.fill.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'TAKE',
        style: AppTypography.labelSmall.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: L.sub.withValues(alpha: 0.5),
          letterSpacing: 1.0,
        ),
      ),
    );

  }
}

// ─────────────────────────────────────────────────────────────
// OVERDUE BADGE — Pulsing red
// ─────────────────────────────────────────────────────────────
class _OverdueBadge extends StatelessWidget {
  final AppThemeColors L;
  const _OverdueBadge({required this.L});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: L.error,
        borderRadius: BorderRadius.circular(AppRadius.max),
        boxShadow: AppShadows.glow(L.error, intensity: 0.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1, end: 1.5, duration: 700.ms),
          const SizedBox(width: 5),
          Text(
            'LATE',
            style: AppTypography.labelSmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
