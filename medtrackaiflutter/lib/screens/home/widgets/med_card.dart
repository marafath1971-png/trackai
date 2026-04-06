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
    final adh = context.select<AppState, int>((s) => s.getAdherenceForMed(med.id));
    final pct = med.totalCount > 0 ? (med.count / med.totalCount).clamp(0.0, 1.0) : 0.0;
    final isLow = RefillHelper.isCriticallyLow(med);
    final showGeneric = context.select<AppState, bool>((s) => s.profile?.showGenericNames ?? false);
    final displayName = (showGeneric && med.genericName.isNotEmpty) ? med.genericName : med.name;
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
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _categoryColor(med.category).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _categoryColor(med.category).withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _categoryIcon(med.category),
                          size: 24,
                          color: _categoryColor(med.category),
                        ),
                      ),
                    ),
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
                      _AdherenceChip(adh: adh, L: L),
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
                  color: L.fill.withValues(alpha: 0.08),
                  border: Border(top: BorderSide(color: L.border.withValues(alpha: 0.05), width: 1)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isLow ? Icons.warning_amber_rounded : Icons.inventory_2_rounded,
                      size: 13,
                      color: isLow ? L.warning : L.sub.withValues(alpha: 0.35),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isLow ? '${med.count} units — refill soon' : '${med.count} units remaining',
                      style: AppTypography.labelSmall.copyWith(
                        color: isLow ? L.warning : L.sub.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    _StepBtn(
                      icon: Icons.remove_rounded,
                      onTap: () {
                        HapticEngine.selection();
                        context.read<AppState>().updateMed(med.id, count: (med.count - 1).clamp(0, 999));
                      },
                    ),
                    const SizedBox(width: 8),
                    _StepBtn(
                      icon: Icons.add_rounded,
                      onTap: () {
                        HapticEngine.success();
                        context.read<AppState>().updateMed(med.id, count: (med.count + 1).clamp(0, 999));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate()
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

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tablet': return Icons.medication_rounded;
      case 'liquid': return Icons.water_drop_rounded;
      case 'spray': return Icons.air_rounded;
      case 'injection': return Icons.vaccines_rounded;
      case 'cream': return Icons.spa_rounded;
      case 'drops': return Icons.opacity_rounded;
      default: return Icons.medication_rounded;
    }
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'liquid': return const Color(0xFF0EA5E9);
      case 'spray': return const Color(0xFF8B5CF6);
      case 'injection': return const Color(0xFFEF4444);
      case 'cream': return const Color(0xFF10B981);
      default: return const Color(0xFF6366F1);
    }
  }
}

class _AdherenceChip extends StatelessWidget {
  final int adh;
  final AppThemeColors L;
  const _AdherenceChip({required this.adh, required this.L});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: L.success.withValues(alpha: 0.08),
        shape: StadiumBorder(side: BorderSide(color: L.success.withValues(alpha: 0.2))),
      ),
      child: Text(
        '$adh%',
        style: AppTypography.labelMedium.copyWith(
          color: L.success,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
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
          color: L.text.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: L.border.withValues(alpha: 0.1), width: 1),
        ),
        child: Center(child: Icon(icon, size: 18, color: L.text.withValues(alpha: 0.7))),
      ),
    );
  }
}

class _SegmentedStockBar extends StatelessWidget {
  final double pct;
  final bool isLow;
  final AppThemeColors L;
  const _SegmentedStockBar({required this.pct, required this.isLow, required this.L});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(30, (index) {
        final threshold = index / 30;
        final isActive = pct > threshold;
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 0.5),
            decoration: BoxDecoration(
              color: isActive
                  ? (isLow ? L.warning : L.primary)
                  : L.fill.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      }),
    );
  }
}
