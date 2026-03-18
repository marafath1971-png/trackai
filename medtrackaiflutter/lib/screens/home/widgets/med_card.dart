import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../domain/entities/entities.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared/shared_widgets.dart';
import '../../../core/utils/haptic_engine.dart';

// ══════════════════════════════════════════════
// MED CARD
// ══════════════════════════════════════════════

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
    // Granular selection for adherence
    final adh = context.select<AppState, int>((s) => s.getAdherenceForMed(med.id));

    final pct = med.totalCount > 0 ? (med.count / med.totalCount).clamp(0.0, 1.0) : 0.0;
    final isLow = med.count <= (med.refillAt);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: AppRadius.roundL,
        border: Border.all(
          color: L.border,
          width: 1.0,
        ),
        boxShadow: L.shadowSoft,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.roundL,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticEngine.selection();
              onView();
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Medicine Icon
                      Stack(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: L.text.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: med.imageUrl != null && med.imageUrl!.isNotEmpty
                                  ? ClipOval(child: MedImage(imageUrl: med.imageUrl!, fit: BoxFit.cover, width: 56, height: 56))
                                  : Text(_getCategoryEmoji(med.category),
                                      style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                          if (isLow)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: L.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: L.card, width: 2),
                                ),
                                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 10),
                              ).animate(onPlay: (c) => c.repeat(reverse: true))
                               .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1.seconds)
                               .boxShadow(begin: BoxShadow(color: L.red.withValues(alpha: 0)), end: BoxShadow(color: L.red.withValues(alpha: 0.4), blurRadius: 4)),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      // Medicine Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      med.name,
                                      style: AppTypography.titleLarge.copyWith(
                                        color: L.text,
                                        letterSpacing: -0.4,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (med.brand.isNotEmpty)
                                      Text(
                                        med.brand.toUpperCase(),
                                        style: AppTypography.labelMedium.copyWith(
                                          fontSize: 10,
                                          color: L.sub.withValues(alpha: 0.5),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                  ],
                                ),
                                if (adh != -1)
                                  Text('$adh%',
                                      style: AppTypography.labelLarge.copyWith(
                                          fontSize: 11,
                                          color: L.text.withValues(alpha: 0.6))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${med.dose} · ${med.frequency}',
                                    style: AppTypography.bodyMedium.copyWith(
                                        fontSize: 12,
                                        color: L.sub,
                                        fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (med.intakeInstructions.isNotEmpty && med.intakeInstructions != 'None') ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: L.text.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      med.intakeInstructions,
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: L.text.withValues(alpha: 0.7)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (med.schedule.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  med.schedule.map((s) => '${s.h}:${s.m.toString().padLeft(2, "0")}').join(", "),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: L.sub.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Compact Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isLow ? 'LOW STOCK' : 'SUPPLY',
                            style: AppTypography.labelMedium.copyWith(
                                fontSize: 9,
                                color: isLow ? L.text : L.sub,
                                letterSpacing: 0.4),
                          ),
                          Text(
                            '${med.count} ${med.unit} left',
                            style: AppTypography.labelMedium.copyWith(
                                fontSize: 9,
                                color: L.sub),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                            color: L.fill.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: pct,
                          child: Container(
                            decoration: BoxDecoration(
                              color: L.text,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Action Strip
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: L.text.withValues(alpha: 0.02),
                    border: Border(
                        top: BorderSide(
                            color: L.border.withValues(alpha: 0.08), width: 1.0)),
                  ),
                  child: Row(
                    children: [
                      _buildAction(
                          label: 'EDIT',
                          color: L.sub.withValues(alpha: 0.6),
                          onTap: onEdit),
                      Container(
                        width: 1,
                        height: 16,
                        color: L.border.withValues(alpha: 0.1),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StepBtn(
                                icon: Icons.remove_rounded,
                                onTap: () {
                                  HapticEngine.selection();
                                  context.read<AppState>().updateMed(med.id,
                                      count: (med.count - 1).clamp(0, med.totalCount));
                                },
                                color: L.text,
                                bg: L.bg),
                            const SizedBox(width: 18),
                            Text(
                              '${med.count}',
                              style: AppTypography.displayMedium.copyWith(
                                  fontSize: 18,
                                  color: L.text,
                                  letterSpacing: -0.5),
                            ),
                            const SizedBox(width: 18),
                            _StepBtn(
                                icon: Icons.add_rounded,
                                onTap: () {
                                  HapticEngine.success();
                                  context.read<AppState>().updateMed(med.id,
                                      count: (med.count + 1).clamp(0, 9999));
                                },
                                color: L.bg,
                                bg: L.text),
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
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.02, end: 0);
  }

  Widget _buildAction(
      {required String label,
      required Color color,
      IconData? icon,
      required VoidCallback onTap}) {
    return Expanded(
      flex: 2,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6)
              ],
              Text(label,
                  style: AppTypography.labelLarge.copyWith(
                      fontSize: 13,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }

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
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(child: Icon(icon, size: 18, color: color)),
        ),
      );
}
