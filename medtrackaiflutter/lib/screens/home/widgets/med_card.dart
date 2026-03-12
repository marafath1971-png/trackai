import 'package:flutter/material.dart';
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isLow ? L.red.withValues(alpha: 0.25) : L.border,
            width: 1.5),
      ),
      child: Column(
        children: [
          // Top section (Compact Layout matching JSX)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            child: Row(
              children: [
                // Image/Icon Container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: medColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: medColor.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: med.imageUrl != null && med.imageUrl!.isNotEmpty
                        ? MedImage(imageUrl: med.imageUrl!, fit: BoxFit.cover)
                        : Center(
                            child: const Text('💊',
                                style: TextStyle(fontSize: 24)),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: L.text,
                                  overflow: TextOverflow.ellipsis),
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            adh == -1 ? 'NEW' : '$adh%',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: adh >= 80
                                  ? L.green
                                  : adh >= 50
                                      ? L.amber
                                      : adh == -1
                                          ? L.sub
                                          : L.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${med.dose} · $remindersCount reminders/day',
                        style: TextStyle(
                            fontSize: 12,
                            color: L.sub,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                            height: 1.0,
                            overflow: TextOverflow.ellipsis),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 6),
                      // Stock Progress Bar
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                  color: L.border,
                                  borderRadius: BorderRadius.circular(99)),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 400),
                                      curve: Curves.easeInOut,
                                      width: constraints.maxWidth * pct,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: isLow ? L.red : L.green,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 44,
                            child: Text(
                              '${med.count}$unit',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isLow ? L.red : L.sub,
                                  fontFamily: 'Inter'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Row (3 Columns: Details, Edit, Stepper)
          Container(
            height: 44,
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: L.border, width: 1))),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onView,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Text('Details',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: L.text)),
                    ),
                  ),
                ),
                Container(
                    width: 1,
                    color: L.border,
                    margin: const EdgeInsets.symmetric(vertical: 6)),
                Expanded(
                  child: GestureDetector(
                    onTap: onEdit,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined, size: 13, color: L.blue),
                          const SizedBox(width: 5),
                          Text('Edit',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: L.blue)),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                    width: 1,
                    color: L.border,
                    margin: const EdgeInsets.symmetric(vertical: 6)),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StepBtn(
                          icon: Icons.remove_rounded,
                          onTap: () => state.updateMed(med.id,
                              count: (med.count - 1).clamp(0, med.totalCount)),
                          color: L.text,
                          bg: L.fill),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 26,
                        child: Text(
                          '${med.count}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: L.text),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _StepBtn(
                          icon: Icons.add_rounded,
                          onTap: () => state.updateMed(med.id,
                              count: (med.count + 1).clamp(0, 9999)),
                          color: Colors.white,
                          bg: const Color(0xFF111111)),
                    ],
                  ),
                ),
              ],
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
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(child: Icon(icon, size: 16, color: color)),
        ),
      );
}
