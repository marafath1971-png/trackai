import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../domain/entities/medicine.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/color_utils.dart';
import '../../../widgets/common/bouncing_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../../widgets/shared/shared_widgets.dart';
import '../../../core/utils/refill_helper.dart';

class MedCard extends StatefulWidget {
  final Medicine med;
  final VoidCallback onView;
  final VoidCallback onEdit;

  const MedCard({
    super.key,
    required this.med,
    required this.onView,
    required this.onEdit,
  });

  @override
  State<MedCard> createState() => _MedCardState();
}

class _MedCardState extends State<MedCard> {


  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final adh = context
        .select<AppState, int>((s) => s.getAdherenceForMed(widget.med.id));
    final pct = widget.med.totalCount > 0
        ? (widget.med.count / widget.med.totalCount).clamp(0.0, 1.0)
        : 0.0;
    final isLow = RefillHelper.isCriticallyLow(widget.med);
    final exhaustionStatus = RefillHelper.getExhaustionStatus(widget.med);
    final medColor = hexToColor(widget.med.color);
    final showGeneric = context
        .select<AppState, bool>((s) => s.profile?.showGenericNames ?? false);
    final displayName =
        (showGeneric && widget.med.genericName.isNotEmpty)
            ? widget.med.genericName
            : widget.med.name;
    final subtitleName =
        (showGeneric && widget.med.genericName.isNotEmpty)
            ? widget.med.name
            : widget.med.brand;

    const double cardRadius = AppRadius.l;

    return BouncingButton(
      onTap: widget.onView,
      scaleFactor: 0.985,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(color: L.border, width: 1.0),
          boxShadow: L.shadowSoft,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cardRadius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── TOP ACCENT BAR ──────────────────────────────
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      medColor,
                      medColor.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),

              // ── MAIN CONTENT ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Med icon
                    Stack(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: medColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: medColor.withValues(alpha: 0.2),
                                width: 1.0),
                          ),
                          child: Center(
                            child: widget.med.imageUrl != null &&
                                    widget.med.imageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: MedImage(
                                        imageUrl: widget.med.imageUrl!,
                                        fit: BoxFit.cover,
                                        width: 56,
                                        height: 56),
                                  )
                                : Text(
                                    _getCategoryEmoji(widget.med.category),
                                    style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                        if (isLow)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: L.error,
                                shape: BoxShape.circle,
                                border: Border.all(color: L.bg, width: 2),
                              ),
                              child: const Center(
                                child: Icon(Icons.priority_high_rounded,
                                    color: Colors.white, size: 10),
                              ),
                            )
                                .animate(
                                    onPlay: (c) => c.repeat(reverse: true))
                                .scale(
                                  begin: const Offset(1, 1),
                                  end: const Offset(1.15, 1.15),
                                  duration: 900.ms,
                                ),
                          ),
                      ],
                    ),

                    const SizedBox(width: 14),

                    // Name + details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: AppTypography.titleLarge.copyWith(
                                        color: L.text,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                        fontSize: 17,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (subtitleName.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitleName.toUpperCase(),
                                        style: AppTypography.labelSmall.copyWith(
                                          color: L.sub.withValues(alpha: 0.6),
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                          fontSize: 9,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // AI badge
                              _Badge(
                                label: widget.med.aiSafetyProfile != null
                                    ? 'VERIFIED'
                                    : 'AI SCAN',
                                icon: widget.med.aiSafetyProfile != null
                                    ? Icons.shield_rounded
                                    : Icons.auto_awesome_rounded,
                                color: widget.med.aiSafetyProfile != null
                                    ? L.success
                                    : AppColors.primaryBlue,
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Dose + frequency chips row
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _InfoChip(
                                label: widget.med.dose,
                                color: L.sub,
                                L: L,
                              ),
                              _InfoChip(
                                label: widget.med.frequency,
                                color: L.sub,
                                L: L,
                              ),
                              if (adh != -1)
                                _InfoChip(
                                  label: '$adh% adherence',
                                  color: adh >= 80
                                      ? L.success
                                      : adh >= 60
                                          ? L.warning
                                          : L.error,
                                  L: L,
                                  highlighted: true,
                                ),
                            ],
                          ),

                          if (widget.med.schedule.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              widget.med.schedule.map((s) {
                                final timeStr =
                                    '${s.h}:${s.m.toString().padLeft(2, "0")}';
                                return s.ritual != Ritual.none
                                    ? '$timeStr ${s.ritual.emoji}'
                                    : timeStr;
                              }).join("  ·  "),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelMedium.copyWith(
                                color: L.sub.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── STOCK INDICATOR ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isLow ? L.error : L.success,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  if (isLow)
                                    BoxShadow(
                                        color:
                                            L.error.withValues(alpha: 0.4),
                                        blurRadius: 4),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isLow ? 'LOW STOCK' : 'IN STOCK',
                              style: AppTypography.labelSmall.copyWith(
                                color: isLow ? L.error : L.success,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${widget.med.count} ${widget.med.unit} · $exhaustionStatus',
                          style: AppTypography.labelSmall.copyWith(
                            color: isLow ? L.error : L.sub,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Slim progress bar (replaces discrete dots)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: pct),
                      duration: 1000.ms,
                      curve: Curves.easeOutQuart,
                      builder: (_, val, __) {
                        final barColor = pct >= 0.5
                            ? L.success
                            : pct >= 0.2
                                ? L.warning
                                : L.error;
                        return ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppRadius.max),
                          child: Stack(
                            children: [
                              Container(
                                height: 6,
                                color: barColor.withValues(alpha: 0.1),
                              ),
                              FractionallySizedBox(
                                widthFactor: val.clamp(0.001, 1.0),
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        barColor.withValues(alpha: 0.7),
                                        barColor,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.max),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── ACTION STRIP ────────────────────────────────
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: L.fill.withValues(alpha: 0.04),
                  border: Border(
                    top: BorderSide(
                        color: L.border.withValues(alpha: 0.6), width: 1.0),
                  ),
                ),
                child: Row(
                  children: [
                    // Edit
                    _ActionBtn(
                      label: 'EDIT',
                      color: L.sub,
                      onTap: widget.onEdit,
                    ),

                    _vDivider(L),

                    if (isLow) ...[
                      _ActionBtn(
                        label: 'REFILL',
                        color: L.error,
                        icon: Icons.refresh_rounded,
                        onTap: () {
                          HapticEngine.success();
                          context.read<AppState>().updateMed(widget.med.id,
                              count: widget.med.totalCount);
                        },
                      ),
                      _vDivider(L),
                    ],

                    // Count stepper
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StepBtn(
                            icon: Icons.remove_rounded,
                            onTap: () {
                              HapticEngine.selection();
                              context.read<AppState>().updateMed(widget.med.id,
                                  count: (widget.med.count - 1)
                                      .clamp(0, widget.med.totalCount));
                            },
                            color: L.text,
                            bg: L.fill.withValues(alpha: 0.1),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${widget.med.count}',
                            style: AppTypography.headlineMedium.copyWith(
                              color: L.text,
                              letterSpacing: -1.0,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          _StepBtn(
                            icon: Icons.add_rounded,
                            onTap: () {
                              HapticEngine.success();
                              context.read<AppState>().updateMed(widget.med.id,
                                  count:
                                      (widget.med.count + 1).clamp(0, 9999));
                            },
                            color: Colors.white,
                            bg: AppColors.primaryBlue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.04, end: 0, curve: Curves.easeOutQuart);
  }

  Widget _vDivider(AppThemeColors L) =>
      Container(width: 1, height: 22, color: L.border.withValues(alpha: 0.5));

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'tablet':
      case 'pill':
        return '💊';
      case 'liquid':
      case 'syrup':
        return '💧';
      case 'spray':
        return '💨';
      case 'injection':
        return '💉';
      default:
        return '💊';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// BADGE CHIP
// ─────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Badge(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 8,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// INFO CHIP
// ─────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  final AppThemeColors L;
  final bool highlighted;

  const _InfoChip({
    required this.label,
    required this.color,
    required this.L,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlighted
            ? color.withValues(alpha: 0.1)
            : L.fill.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.max),
        border: highlighted
            ? Border.all(color: color.withValues(alpha: 0.25), width: 0.5)
            : null,
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: highlighted ? color : L.sub,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ACTION BUTTON
// ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: BouncingButton(
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STEP BUTTON (+ / -)
// ─────────────────────────────────────────────────────────────
class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color, bg;
  const _StepBtn(
      {required this.icon,
      required this.onTap,
      required this.color,
      required this.bg});
  @override
  Widget build(BuildContext context) => BouncingButton(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(child: Icon(icon, size: 20, color: color)),
        ),
      );
}
