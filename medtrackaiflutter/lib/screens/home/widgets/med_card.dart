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
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              // ── Leading Icon (Industrial Circle) ──
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: L.text.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _categoryEmoji(med.category),
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // ── Info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            friendlyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(
                              color: L.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '12:57pm', // Placeholder time
                          style: AppTypography.labelSmall.copyWith(
                            color: L.sub.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department_rounded, size: 14, color: L.text),
                        const SizedBox(width: 4),
                        Text(
                          '${med.dose} dose',
                          style: AppTypography.labelSmall.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _BuildMiniStat(icon: Icons.medication_rounded, label: med.form, color: Colors.blue),
                        const SizedBox(width: 8),
                        _BuildMiniStat(icon: Icons.calendar_today_rounded, label: '$adh%', color: Colors.orange),
                        const SizedBox(width: 8),
                        _BuildMiniStat(icon: Icons.category_rounded, label: med.category, color: Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildMiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BuildMiniStat({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Row(
      children: [
        Icon(icon, size: 12, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: L.sub.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
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
