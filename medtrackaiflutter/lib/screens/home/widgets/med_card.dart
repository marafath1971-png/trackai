import 'dart:ui' as ui;
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
    final upcomingDose = context.select<AppState, DoseItem?>((s) => s
        .getDoses()
        .where((d) => d.med.id == med.id && s.takenToday[d.key] != true)
        .firstOrNull);

    final displayName = (showGeneric && med.genericName.isNotEmpty)
        ? med.genericName
        : med.name;
    final friendlyName = _toTitleCase(displayName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BouncingButton(
        onTap: onView,
        scaleFactor: 0.98,
        child: Container(
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: L.text.withValues(alpha: 0.05), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // ── INDUSTRIAL DECOR ──
              Positioned(
                top: 0,
                right: 30,
                child: Container(
                  width: 1,
                  height: 120,
                  color: L.text.withValues(alpha: 0.03),
                ),
              ),
              Positioned(
                top: 50,
                right: 0,
                child: Container(
                  height: 1,
                  width: 80,
                  color: L.text.withValues(alpha: 0.03),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Top Section ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Glassy Category Icon
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: L.text.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: L.text.withValues(alpha: 0.05), width: 1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Center(
                                child: Text(
                                  _categoryEmoji(med.category),
                                  style: const TextStyle(fontSize: 28),
                                )
                                    .animate(
                                        onPlay: (c) => c.repeat(reverse: true))
                                    .scale(
                                      begin: const Offset(1.0, 1.0),
                                      end: const Offset(1.1, 1.1),
                                      duration: 2500.ms,
                                      curve: Curves.easeInOut,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
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
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                  fontSize: 19,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: L.text.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'RX_${med.id.toString().padLeft(4, '0').substring(0, 4).toUpperCase()}',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: L.sub.withValues(alpha: 0.5),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${med.dose} · ${med.form.toUpperCase()}',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: L.sub.withValues(alpha: 0.45),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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

                  // ── UPCOMING DOSE HINT ──
                  if (upcomingDose != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: L.success.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: L.success.withValues(alpha: 0.1),
                              width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_filled_rounded,
                                size: 12, color: L.success),
                            const SizedBox(width: 6),
                            Text(
                              'NEXT DOSE AT ${upcomingDose.sched.h.toString().padLeft(2, '0')}:${upcomingDose.sched.m.toString().padLeft(2, '0')}',
                              style: AppTypography.labelSmall.copyWith(
                                color: L.success,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Digital Stock Instrument ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'INVENTORY_LEVEL',
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: L.sub.withValues(alpha: 0.3),
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              '${(pct * 100).toInt()}%',
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: isLow ? L.warning : L.text,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _ModernDigitalStockBar(pct: pct, isLow: isLow, L: L),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Bottom Control Panel ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
                    decoration: BoxDecoration(
                      color: L.text.withValues(alpha: 0.02),
                      border: Border(
                          top: BorderSide(
                              color: L.text.withValues(alpha: 0.03),
                              width: 1)),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLow ? 'CRITICAL_STOCK' : 'REMAINING_UNITS',
                              style: AppTypography.labelSmall.copyWith(
                                color: isLow ? L.warning : L.sub.withValues(alpha: 0.3),
                                fontWeight: FontWeight.w900,
                                fontSize: 8,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${med.count} ${med.form.toUpperCase()}S',
                              style: AppTypography.labelLarge.copyWith(
                                color: isLow ? L.warning : L.text,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: L.text.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              _PreciseStepBtn(
                                icon: Icons.remove_rounded,
                                onTap: () {
                                  HapticEngine.selection();
                                  context.read<AppState>().updateMed(med.id,
                                      count: (med.count - 1).clamp(0, 999));
                                },
                              ),
                              const SizedBox(width: 4),
                              _PreciseStepBtn(
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
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOutQuart);
  }

  String _toTitleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: chipColor.withValues(alpha: 0.18), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(chipEmoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            '$adh%',
            style: AppTypography.labelMedium.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreciseStepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _PreciseStepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return BouncingButton(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 36,
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Center(
            child: Icon(icon, size: 18, color: L.text.withValues(alpha: 0.8))),
      ),
    );
  }
}

class _ModernDigitalStockBar extends StatelessWidget {
  final double pct;
  final bool isLow;
  final AppThemeColors L;
  const _ModernDigitalStockBar(
      {required this.pct, required this.isLow, required this.L});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: L.text.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        return Stack(
          children: [
            Row(
              children: List.generate(24, (index) {
                final threshold = index / 24;
                final isActive = pct > threshold;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isActive
                          ? (isLow ? L.warning : L.text)
                          : L.text.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                );
              }),
            ),
            if (isLow)
              Positioned.fill(
                child: Container()
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 1.5.seconds, color: Colors.white.withValues(alpha: 0.2)),
              ),
          ],
        );
      }),
    );
  }
}
