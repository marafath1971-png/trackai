import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../models/models.dart';
import '../../../core/utils/color_utils.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared/shared_widgets.dart';

// ══════════════════════════════════════════════
// MED CARD (matches MedCard in JSX)
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
    final state = context.watch<AppState>();

    // Calculate adherence
    final allEntries = state.history.values
        .expand((e) => e)
        .where((e) => e.medId == med.id)
        .toList();
    final adh = allEntries.isEmpty
        ? -1
        : (allEntries.where((e) => e.taken).length * 100 / allEntries.length).round();

    final pct = med.totalCount > 0 ? (med.count / med.totalCount).clamp(0.0, 1.0) : 0.0;
    final isLow = med.count <= (med.refillAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: L.border.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onView();
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Medicine Icon
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
                      const SizedBox(width: 14),
                      // Medicine Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    med.name,
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: L.text,
                                        letterSpacing: -0.4),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (adh != -1)
                                  Text('$adh%',
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: L.text.withValues(alpha: 0.6))),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${med.dose} · ${med.frequency}',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: L.sub,
                                  fontWeight: FontWeight.w500),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isLow ? 'LOW STOCK' : 'SUPPLY',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: isLow ? L.text : L.sub,
                                letterSpacing: 0.4),
                          ),
                          Text(
                            '${med.count} ${med.unit} left',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
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
                                  HapticFeedback.selectionClick();
                                  state.updateMed(med.id,
                                      count: (med.count - 1).clamp(0, med.totalCount));
                                },
                                color: L.text,
                                bg: L.bg),
                            const SizedBox(width: 18),
                            Text(
                              '${med.count}',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: L.text,
                                  letterSpacing: -0.5),
                            ),
                            const SizedBox(width: 18),
                            _StepBtn(
                                icon: Icons.add_rounded,
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  state.updateMed(med.id,
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
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
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
