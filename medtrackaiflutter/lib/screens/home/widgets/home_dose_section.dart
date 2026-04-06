import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../providers/app_state.dart';
import '../../../../theme/app_theme.dart';
import '../../../widgets/shared/shared_widgets.dart';

class HomeDoseSection extends StatefulWidget {
  final Medicine med;
  final List<DoseHistoryEntry> doses;
  final VoidCallback onAddDose;

  const HomeDoseSection({
    super.key,
    required this.med,
    required this.doses,
    required this.onAddDose,
  });

  @override
  State<HomeDoseSection> createState() => _HomeDoseSectionState();
}

class _HomeDoseSectionState extends State<HomeDoseSection> {
  @override
  Widget build(BuildContext context) {
    final L = context.L;
    // Map entries to manageable dose objects for the cards
    final doseObjects = widget.med.schedule.map((s) {
      final relevantDose = widget.doses.cast<DoseHistoryEntry?>().firstWhere(
            (d) => d?.scheduleId == s.id,
            orElse: () => null,
          );
      final taken = relevantDose != null;
      final now = TimeOfDay.now();
      final overdue = !taken && (s.h < now.hour || (s.h == now.hour && s.m < now.minute));
      
      return _DoseCardData(
        med: widget.med,
        sched: s,
        entry: relevantDose,
        taken: taken,
        overdue: overdue,
      );
    }).toList();

    // Sort: Taken last, otherwise by time
    doseObjects.sort((a, b) {
      if (a.taken != b.taken) return a.taken ? 1 : -1;
      if (a.sched.h != b.sched.h) return a.sched.h.compareTo(b.sched.h);
      return a.sched.m.compareTo(b.sched.m);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.med.name.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: L.sub.withValues(alpha: 0.5),
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 0.5, color: L.border.withValues(alpha: 0.1))),
          ],
        ),
        const SizedBox(height: 16),
        ...doseObjects.asMap().entries.map((e) {
          final isNext = !e.value.taken && e.key == 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DoseCard(
              dose: e.value,
              taken: e.value.taken,
              overdue: e.value.overdue,
              isNext: isNext,
              onTake: () => _markTaken(context, e.value),
              onSnooze: () => _snooze(context, e.value),
              onTap: () => _showMedDetail(context),
            ).animate(delay: (e.key * 80).ms).fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0),
          );
        }),
      ],
    );
  }

  void _markTaken(BuildContext context, _DoseCardData d) {
    final doseItem = DoseItem(med: d.med, sched: d.sched, key: '${d.med.id}_${d.sched.id}');
    context.read<AppState>().recordDose(doseItem);
  }

  void _snooze(BuildContext context, _DoseCardData d) {
  }

  void _showMedDetail(BuildContext context) {
  }
}

class _DoseCardData {
  final Medicine med;
  final ScheduleEntry sched;
  final DoseHistoryEntry? entry;
  final bool taken;
  final bool overdue;
  _DoseCardData({
    required this.med,
    required this.sched,
    this.entry,
    required this.taken,
    required this.overdue,
  });
}

class _DoseCard extends StatelessWidget {
  final _DoseCardData dose;
  final bool taken;
  final bool overdue;
  final bool isNext;
  final VoidCallback onTake;
  final VoidCallback onSnooze;
  final VoidCallback onTap;

  const _DoseCard({
    required this.dose,
    required this.taken,
    required this.overdue,
    required this.isNext,
    required this.onTake,
    required this.onSnooze,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DoseCard(
      med: dose.med,
      sched: dose.sched,
      taken: taken,
      overdue: overdue,
      isNext: isNext,
      onTake: onTake,
      onSnooze: onSnooze,
      onTap: onTap,
    );
  }
}
