import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared/shared_widgets.dart';

// ══════════════════════════════════════════════
// MED CARD (matches MedCard in JSX)
// ══════════════════════════════════════════════

class MedCard extends StatelessWidget {
  final Medicine med;
  final VoidCallback onView;
  final VoidCallback onEdit;

  const MedCard(
      {super.key,
      required this.med,
      required this.onView,
      required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final state = context.watch<AppState>();
    final medColor = hexToColor(med.color);

    // Calculate adherence (matches JSX logic)
    final allEntries = state.history.values
        .expand((e) => e)
        .where((e) => e.medId == med.id)
        .toList();
    final adh = allEntries.isEmpty
        ? -1
        : (allEntries.where((e) => e.taken).length * 100 / allEntries.length)
            .round();

    final unit = '';
    final pct =
        med.totalCount > 0 ? (med.count / med.totalCount).clamp(0.0, 1.0) : 0.0;
    final isLow = med.count <= (med.refillAt);

    final remindersCount = med.schedule.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isLow ? L.red.withValues(alpha: 0.3) : L.border.withValues(alpha: 0.5),
            width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Image/Icon Container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: medColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: medColor.withValues(alpha: 0.2), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: med.imageUrl != null && med.imageUrl!.isNotEmpty
                        ? MedImage(imageUrl: med.imageUrl!, fit: BoxFit.cover)
                        : Center(
                            child: Text(getCategoryEmoji(med.category),
                                style: const TextStyle(fontSize: 26)),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: L.text,
                                  overflow: TextOverflow.ellipsis),
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (adh >= 80 ? L.green : (adh >= 50 ? L.amber : L.red)).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              adh == -1 ? 'NEW' : '$adh%',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: adh >= 80
                                    ? L.green
                                    : adh >= 50
                                        ? L.amber
                                        : adh == -1
                                            ? L.sub
                                            : L.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${med.dose} · $remindersCount slots daily',
                        style: TextStyle(
                            fontSize: 12,
                            color: L.sub.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                            height: 1.0,
                            overflow: TextOverflow.ellipsis),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 10),
                      // Stock Progress Bar
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                  color: L.border.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(99)),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.easeOutCubic,
                                      width: constraints.maxWidth * pct,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isLow ? L.red : L.green,
                                        borderRadius: BorderRadius.circular(99),
                                        boxShadow: [
                                          if (!isLow) BoxShadow(color: L.green.withValues(alpha: 0.2), blurRadius: 4)
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${med.count} left',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isLow ? L.red : L.sub,
                                fontFamily: 'Inter'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Row
          Container(
            height: 48,
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: L.border.withValues(alpha: 0.5), width: 1))),
            child: Row(
              children: [
                _buildAction(label: 'Details', color: L.text, onTap: onView),
                _buildDivider(L),
                _buildAction(label: 'Edit', color: L.blue, icon: Icons.edit_outlined, onTap: onEdit),
                _buildDivider(L),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StepBtn(
                          icon: Icons.remove_rounded,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            state.updateMed(med.id, count: (med.count - 1).clamp(0, med.totalCount));
                          },
                          color: L.text,
                          bg: L.fill),
                      const SizedBox(width: 12),
                      Text(
                        '${med.count}',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: L.text),
                      ),
                      const SizedBox(width: 12),
                      _StepBtn(
                          icon: Icons.add_rounded,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            state.updateMed(med.id, count: (med.count + 1).clamp(0, 9999));
                          },
                          color: Colors.black,
                          bg: const Color(0xFFA3E635)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildAction({required String label, required Color color, IconData? icon, required VoidCallback onTap}) {
    return Expanded(
      flex: 2,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 6)],
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

  Widget _buildDivider(AppThemeColors L) {
    return Container(width: 1, color: L.border.withValues(alpha: 0.5), margin: const EdgeInsets.symmetric(vertical: 10));
  }

  String getCategoryEmoji(String category) {
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
        return '📦';
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
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(child: Icon(icon, size: 18, color: color)),
        ),
      );
}
