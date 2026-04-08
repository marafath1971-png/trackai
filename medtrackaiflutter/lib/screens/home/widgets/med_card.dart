import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../core/utils/refill_helper.dart';
import '../../../widgets/shared/shared_widgets.dart';

class MedCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final L = context.L;
    final adh =
        context.select<AppState, int>((s) => s.getAdherenceForMed(med.id));
    final pct =
        med.totalCount > 0 ? (med.count / med.totalCount).clamp(0.0, 1.0) : 0.0;
    final isLow = RefillHelper.isCriticallyLow(med);
    final showGeneric = context
        .select<AppState, bool>((s) => s.profile?.showGenericNames ?? false);
    final displayName = (showGeneric && med.genericName.isNotEmpty)
        ? med.genericName
        : med.name;
    final friendlyName = _toTitleCase(displayName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BouncingButton(
        onTap: onView,
        scaleFactor: 0.98,
        child: SquircleCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top Section ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: L.text.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                _categoryEmoji(med.category),
                                style: const TextStyle(fontSize: 26),
                              )
                                  .animate(
                                      onPlay: (c) => c.repeat(reverse: true))
                                  .scale(
                                    begin: const Offset(1.0, 1.0),
                                    end: const Offset(1.12, 1.12),
                                    duration: 2200.ms,
                                    curve: Curves.easeInOut,
                                  ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.05),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.02),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat()).shimmer(
                        duration: 3.seconds,
                        color: Colors.white.withValues(alpha: 0.05)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friendlyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleLarge.copyWith(
                              color: L.text,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${med.dose} · ${med.form.toLowerCase()}',
                            style: AppTypography.labelMedium.copyWith(
                              color: L.sub.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (adh != -1)
                      _AdherenceChip(adh: adh, L: L)
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .scale(
                              begin: const Offset(0.9, 0.9),
                              end: const Offset(1, 1),
                              curve: Curves.easeOutBack),
                  ],
                ),
              ),

              // ── Stock bar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SegmentedStockBar(pct: pct, isLow: isLow, L: L),
              ),

              const SizedBox(height: 16),

              // ── Bottom strip ──
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                decoration: BoxDecoration(
                  color: L.text.withValues(alpha: 0.03),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isLow
                          ? Icons.warning_amber_rounded
                          : Icons.inventory_2_rounded,
                      size: 13,
                      color: isLow ? L.warning : L.sub.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isLow
                          ? '${med.count} units — refill soon'
                          : '${med.count} units remaining',
                      style: AppTypography.labelSmall.copyWith(
                        color: isLow ? L.warning : L.sub.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.2,
                        height: 1.0,
                      ),
                    ),
                    const Spacer(),
                    _StepBtn(
                      icon: Icons.remove_rounded,
                      onTap: () {
                        HapticEngine.selection();
                        context.read<AppState>().updateMed(med.id,
                            count: (med.count - 1).clamp(0, 999));
                      },
                    ),
                    const SizedBox(width: 8),
                    _StepBtn(
                      icon: Icons.add_rounded,
                      onTap: () {
                        HapticEngine.success();
                        context.read<AppState>().updateMed(med.id,
                            count: (med.count + 1).clamp(0, 999));
                      },
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
        .slideY(begin: 0.04, end: 0, curve: Curves.easeOutBack);
  }

  String _toTitleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // 2026 design: expressive emoji per category
  String _categoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'tablet':
        return '💊';
      case 'capsule':
        return '💊';
      case 'liquid':
        return '💧';
      case 'spray':
        return '💨';
      case 'injection':
        return '💉';
      case 'cream':
        return '🧴';
      case 'drops':
        return '🪷';
      case 'patch':
        return '🩹';
      case 'inhaler':
        return '🌬️';
      default:
        return '💊';
    }
  }
}

class _AdherenceChip extends StatelessWidget {
  final int adh;
  final AppThemeColors L;
  const _AdherenceChip({required this.adh, required this.L});
  @override
  Widget build(BuildContext context) {
    final chipEmoji = adh >= 90
        ? '🎯'
        : adh >= 70
            ? '😊'
            : adh >= 50
                ? '😐'
                : '😔';
    final chipColor = adh >= 80
        ? L.success
        : adh >= 50
            ? L.warning
            : Colors.red.shade400;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: chipColor.withValues(alpha: 0.18), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(chipEmoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Text(
            '$adh%',
            style: AppTypography.labelMedium.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return BouncingButton(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 38,
        decoration: BoxDecoration(
          color: L.text.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
            child: Icon(icon, size: 18, color: L.text.withValues(alpha: 0.7))),
      ),
    );
  }
}

class _SegmentedStockBar extends StatelessWidget {
  final double pct;
  final bool isLow;
  final AppThemeColors L;
  const _SegmentedStockBar(
      {required this.pct, required this.isLow, required this.L});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(40, (index) {
        final threshold = index / 40;
        final isActive = pct > threshold;
        return Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 0.4),
            decoration: BoxDecoration(
              color: isActive
                  ? (isLow ? L.warning : L.text)
                  : L.fill.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(0.5),
            ),
          ).animate(target: (isLow && isActive) ? 1 : 0).shimmer(
              duration: 2.seconds, color: Colors.white.withValues(alpha: 0.2)),
        );
      }),
    );
  }
}
