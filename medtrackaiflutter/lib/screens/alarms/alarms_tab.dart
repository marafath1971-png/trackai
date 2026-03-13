import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../domain/entities/entities.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../widgets/common/modern_time_picker.dart';
import '../../core/utils/date_formatter.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';

// ══════════════════════════════════════════════
// ALARMS TAB
// ══════════════════════════════════════════════

class AlarmsTab extends StatefulWidget {
  const AlarmsTab({super.key});

  @override
  State<AlarmsTab> createState() => _AlarmsTabState();
}

class _AlarmsTabState extends State<AlarmsTab> {
  Medicine? _addingFor;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final L = context.L;
    final allSchedules = state.meds
        .expand((m) => m.schedule
            .asMap()
            .entries
            .map((e) => (med: m, sched: e.value, idx: e.key)))
        .toList();
    allSchedules.sort(
        (a, b) => (a.sched.h * 60 + a.sched.m) - (b.sched.h * 60 + b.sched.m));
    final activeCount = allSchedules.where((x) => x.sched.enabled).length;

    // isDark removed as unused

    final activeSchedules = allSchedules.where((x) => x.sched.enabled).toList();
    final inactiveSchedules =
        allSchedules.where((x) => !x.sched.enabled).toList();

    final now = DateTime.now();
    final nowM = now.hour * 60 + now.minute;
    final nextDose = activeSchedules
            .where((s) => (s.sched.h * 60 + s.sched.m) > nowM)
            .firstOrNull ??
        (activeSchedules.isNotEmpty ? activeSchedules.first : null);

    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    top: 100 + MediaQuery.of(context).padding.top,
                    left: 20,
                    right: 20,
                    bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (nextDose != null) ...[
                      _NextDoseIndicator(sch: nextDose, L: L),
                      const SizedBox(height: 24),
                    ],
                    if (activeSchedules.isNotEmpty) ...[
                      Text("Active Reminders",
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: L.text,
                              letterSpacing: -0.3)),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
              if (activeSchedules.isNotEmpty)
                ..._buildGroupedAlarms(activeSchedules, state, L),
              if (inactiveSchedules.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Text("Paused",
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: L.text,
                          letterSpacing: -0.3)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: inactiveSchedules.length,
                    itemBuilder: (context, idx) {
                      final sch = inactiveSchedules[idx];
                      return _TimelineAlarmCard(
                        sch: sch,
                        state: state,
                        L: L,
                        onToggle: () =>
                            state.toggleSchedule(sch.med.id, sch.idx),
                        onRemove: () =>
                            state.removeSchedule(sch.med.id, sch.idx),
                      );
                    },
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                child: Text('All Medicines',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: L.text,
                        letterSpacing: -0.3)),
              ),
              if (state.meds.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildEmptyState(context, L),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.meds.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) => _MedAlarmContainer(
                      med: state.meds[idx],
                      state: state,
                      L: L,
                      onAdd: () => setState(() => _addingFor = state.meds[idx]),
                    ),
                  ),
                ),
              const SizedBox(height: 120),
            ],
          ),
        ),

        // Fixed Premium Header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: EdgeInsets.fromLTRB(24, 60 + MediaQuery.of(context).padding.top, 24, 20),
                decoration: BoxDecoration(
                  color: L.bg.withValues(alpha: 0.8),
                  border: Border(
                    bottom: BorderSide(color: L.border.withValues(alpha: 0.5), width: 0.5),
                  ),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reminders',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: L.text,
                                    letterSpacing: -1.2)),
                            const SizedBox(height: 4),
                            Text(
                                activeCount > 0
                                    ? 'You have $activeCount scheduled doses'
                                    : (state.meds.isEmpty
                                        ? 'Start by adding a medicine'
                                        : 'No active reminders'),
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: L.sub,
                                    fontWeight: FontWeight.w600)),
                          ]),
                      if (activeCount > 0)
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                              color: const Color(0xFF111111),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFA3E635).withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                )
                              ]),
                          child: const Center(
                            child: Icon(Icons.notifications_active_rounded,
                                color: Color(0xFFA3E635), size: 22),
                          ),
                        ),
                    ]),
              ),
            ),
          ),
        ),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 0.1), end: Offset.zero)
                      .animate(anim),
                  child: child)),
          child: _addingFor != null
              ? _AddAlarmSheet(
                  key: const ValueKey('add_alarm'),
                  med: _addingFor!,
                  onClose: () => setState(() => _addingFor = null))
              : const SizedBox.shrink(key: ValueKey('empty_alarm')),
        ),
      ]),
    );
  }
}

List<Widget> _buildGroupedAlarms(
    List<dynamic> active, AppState state, AppThemeColors L) {
  final Map<TimePeriod, List<dynamic>> grouped = {
    TimePeriod.morning: [],
    TimePeriod.afternoon: [],
    TimePeriod.evening: [],
    TimePeriod.night: [],
  };

  for (var sch in active) {
    grouped[_getTimePeriod(sch.sched.h)]!.add(sch);
  }

  final List<Widget> widgets = [];
  for (var period in TimePeriod.values) {
    final list = grouped[period]!;
    if (list.isEmpty) continue;

    widgets.add(Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(_getPeriodEmoji(period), style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            _getPeriodLabel(period).toUpperCase(),
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: L.sub,
                letterSpacing: 1),
          ),
        ],
      ),
    ));

    widgets.add(Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        itemBuilder: (context, idx) {
          final sch = list[idx];
          return _TimelineAlarmCard(
            sch: sch,
            state: state,
            L: L,
            onToggle: () {
              HapticFeedback.lightImpact();
              state.toggleSchedule(sch.med.id, sch.idx);
            },
            onRemove: () {
              HapticFeedback.mediumImpact();
              state.removeSchedule(sch.med.id, sch.idx);
            },
          );
        },
      ),
    ));
  }
  return widgets;
}

class _NextDoseIndicator extends StatelessWidget {
  final dynamic sch;
  final AppThemeColors L;
  const _NextDoseIndicator({required this.sch, required this.L});

  @override
  Widget build(BuildContext context) {
    final med = sch.med as Medicine;
    final s = sch.sched as ScheduleEntry;
    final medColor = hexToColor(med.color);

    final now = DateTime.now();
    final schedTime = DateTime(now.year, now.month, now.day, s.h, s.m);
    var target = schedTime;
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }
    final diff = target.difference(now);
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    final diffStr = hours > 0 ? 'in ${hours}h ${mins}m' : 'in ${mins}m';

    return Animate(
      effects: [
        FadeEffect(duration: 500.ms, curve: Curves.easeOut),
        ScaleEffect(begin: const Offset(0.95, 0.95), duration: 500.ms, curve: Curves.easeOut),
      ],
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA3E635).withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NEXT REMINDER',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFA3E635),
                            letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(diffStr,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5)),
                  ],
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(Icons.timer_outlined, color: const Color(0xFFA3E635), size: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: medColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                        child: Text(med.form == 'tablet' ? '💊' : '💧',
                            style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(med.name,
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3)),
                        Text('${s.label} · ${fmtTime(s.h, s.m)}',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum TimePeriod { morning, afternoon, evening, night }

TimePeriod _getTimePeriod(int h) {
  if (h >= 5 && h < 12) return TimePeriod.morning;
  if (h >= 12 && h < 17) return TimePeriod.afternoon;
  if (h >= 17 && h < 21) return TimePeriod.evening;
  return TimePeriod.night;
}

String _getPeriodLabel(TimePeriod p) {
  switch (p) {
    case TimePeriod.morning:
      return 'Morning';
    case TimePeriod.afternoon:
      return 'Afternoon';
    case TimePeriod.evening:
      return 'Evening';
    case TimePeriod.night:
      return 'Night';
  }
}

String _getPeriodEmoji(TimePeriod p) {
  switch (p) {
    case TimePeriod.morning:
      return '🌅';
    case TimePeriod.afternoon:
      return '☀️';
    case TimePeriod.evening:
      return '🌆';
    case TimePeriod.night:
      return '🌙';
  }
}

class _TimelineAlarmCard extends StatelessWidget {
  final dynamic sch; // {med, sched, idx}
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onToggle, onRemove;
  const _TimelineAlarmCard(
      {required this.sch,
      required this.state,
      required this.L,
      required this.onToggle,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final med = sch.med as Medicine;
    final s = sch.sched as ScheduleEntry;
    final medColor = hexToColor(med.color);

    return Animate(
      effects: [
        FadeEffect(duration: 400.ms, curve: Curves.easeOut),
        SlideEffect(begin: const Offset(0, 0.05), duration: 400.ms, curve: Curves.easeOut),
      ],
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: L.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(children: [
            // Left Accent Bar
            Container(width: 6, color: medColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Text(fmtTime(s.h, s.m),
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: L.text,
                                  letterSpacing: -1.0)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: L.fill,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(s.label.toUpperCase(),
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: L.sub,
                                    letterSpacing: 0.5)),
                          ),
                        ]),
                        _PremiumToggle(
                            value: s.enabled,
                            onChanged: (v) {
                              HapticFeedback.lightImpact();
                              onToggle();
                            }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                            color: medColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child: Center(
                            child: Icon(Icons.medication_rounded,
                                size: 16, color: medColor)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(med.name,
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: L.text,
                                    letterSpacing: -0.3)),
                            Text(med.dose,
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: L.sub,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onRemove,
                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: L.red.withValues(alpha: 0.7)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ]),
                    if (s.enabled) ...[
                      const SizedBox(height: 16),
                      Row(children: [
                        _SnoozeBtn(
                            label: '10m',
                            onTap: () {
                              HapticFeedback.selectionClick();
                              state.showToast('Snoozed ${med.name} for 10m', type: 'info');
                            },
                            L: L),
                        const SizedBox(width: 8),
                        _SnoozeBtn(
                            label: '1h',
                            onTap: () {
                              HapticFeedback.selectionClick();
                              state.showToast('Snoozed ${med.name} for 1h', type: 'info');
                            },
                            L: L),
                        const Spacer(),
                        // Days Indicator
                        Wrap(
                          spacing: 4,
                          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                              .asMap()
                              .entries
                              .map((e) {
                            final isScheduled = s.days.contains(e.key);
                            return Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: isScheduled
                                    ? const Color(0xFF111111)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isScheduled ? const Color(0xFF111111) : L.border,
                                    width: 1),
                              ),
                              child: Center(
                                  child: Text(e.value,
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: isScheduled ? Colors.white : L.sub))),
                            );
                          }).toList(),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PremiumToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PremiumToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      child: Container(
        width: 50,
        height: 28,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: value
                ? const Color(0xFF111111)
                : Colors.black.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100)),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2))
                ]),
          ),
        ),
      ),
    );
  }
}

class _MedAlarmContainer extends StatelessWidget {
  final Medicine med;
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onAdd;
  const _MedAlarmContainer(
      {required this.med,
      required this.state,
      required this.L,
      required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final medColor = hexToColor(med.color);
    final count = med.schedule.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: L.border.withValues(alpha: 0.5)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: medColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14)),
            child: Center(
                child: Text(med.form == 'tablet' ? '💊' : '💧',
                    style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(med.name,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: L.text,
                        letterSpacing: -0.5,
                        overflow: TextOverflow.ellipsis)),
                Text(
                    '${med.dose}${count > 0 ? " · $count schedule${count != 1 ? "s" : ""}" : " · No schedules"}',
                    style: TextStyle(
                        fontFamily: 'Inter', fontSize: 13, color: L.sub, fontWeight: FontWeight.w500)),
              ])),
          GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onAdd();
              },
              child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                      color: Color(0xFF111111), shape: BoxShape.circle),
                  child: const Icon(Icons.add_rounded,
                      color: Color(0xFFA3E635), size: 20))),
        ]),
        if (med.schedule.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...med.schedule.asMap().entries.map((e) {
            final idx = e.key;
            final s = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                  color: L.fill.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: L.border.withValues(alpha: 0.3))),
              child: Row(children: [
                Text(fmtTime(s.h, s.m),
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: s.enabled ? L.text : L.sub,
                        letterSpacing: -0.5)),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(s.label,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: L.sub,
                            fontWeight: FontWeight.w600))),
                _PremiumToggle(
                    value: s.enabled,
                    onChanged: (v) {
                      HapticFeedback.lightImpact();
                      state.toggleSchedule(med.id, idx);
                    }),
              ]),
            );
          }),
        ],
      ]),
    );
  }
}

Widget _buildEmptyState(BuildContext context, AppThemeColors L) {
  final state = context.read<AppState>();
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
    decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1))
        ]),
    child: Column(children: [
      Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(22)),
          child: const Center(
              child: Icon(Icons.notifications_active_rounded,
                  color: Colors.white, size: 32))),
      const SizedBox(height: 16),
      Text('No reminders yet',
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: L.text,
              letterSpacing: -0.5)),
      const SizedBox(height: 8),
      Text(
          state.meds.isEmpty
              ? 'Scan a medicine first, then come back to set your daily reminders.'
              : 'Set reminders for your medicines to keep track of your doses.',
          style: TextStyle(
              fontFamily: 'Inter', fontSize: 14, color: L.sub, height: 1.5),
          textAlign: TextAlign.center),
      const SizedBox(height: 24),
      if (state.meds.isEmpty)
        GestureDetector(
          onTap: () {
            // Navigation to Scan tab is handled by the parent AppShell
            // This is a placeholder for the user to trigger the scan overlay or tab change
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(14)),
            child: const Text('Scan a Medicine',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2)),
          ),
        ),
    ]),
  );
}

// ══════════════════════════════════════════════
// ADD ALARM SHEET
// ══════════════════════════════════════════════

class _AddAlarmSheet extends StatefulWidget {
  final Medicine med;
  final VoidCallback onClose;
  const _AddAlarmSheet({super.key, required this.med, required this.onClose});

  @override
  State<_AddAlarmSheet> createState() => _AddAlarmSheetState();
}

class _QuickTime {
  final String label, emoji;
  final int h, m;
  const _QuickTime(this.label, this.emoji, this.h, this.m);
}

const List<_QuickTime> _quickTimes = [
  _QuickTime("Morning", "🌅", 8, 0),
  _QuickTime("Afternoon", "☀️", 13, 0),
  _QuickTime("Evening", "🌆", 18, 0),
  _QuickTime("Night", "🌙", 21, 0),
];

class _AddAlarmSheetState extends State<_AddAlarmSheet> {
  int _h = 8, _m = 0;
  String _label = 'Morning';
  final List<int> _days = [1, 2, 3, 4, 5, 6, 0];
  bool _withFood = false;

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final state = context.read<AppState>();
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                  color: L.card,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24))),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: SingleChildScrollView(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Center(
                        child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                                color: L.border,
                                borderRadius: BorderRadius.circular(99)))),
                    const SizedBox(height: 16),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Add Reminder',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: L.text,
                                        letterSpacing: -0.4)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                          color: hexToColor(widget.med.color),
                                          shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Text(widget.med.name,
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          color: L.sub)),
                                ]),
                              ]),
                          GestureDetector(
                            onTap: widget.onClose,
                            child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                    color: L.fill, shape: BoxShape.circle),
                                child: Center(
                                    child: Icon(Icons.close_rounded,
                                        size: 14, color: L.sub))),
                          ),
                        ]),
                    const SizedBox(height: 20),

                    // Quick select pills
                    Text('Quick Select',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: L.sub,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                          children: _quickTimes.map((qt) {
                        final active =
                            _h == qt.h && _m == qt.m && _label == qt.label;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _h = qt.h;
                            _m = qt.m;
                            _label = qt.label;
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8, bottom: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                                color:
                                    active ? const Color(0xFF111111) : L.fill,
                                borderRadius: BorderRadius.circular(99)),
                            child: Row(children: [
                              Text(qt.emoji,
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(qt.label,
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: active ? Colors.white : L.text)),
                            ]),
                          ),
                        );
                      }).toList()),
                    ),
                    const SizedBox(height: 20),

                    // Time select
                    Text('Time',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: L.sub,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final res = await ModernTimePicker.show(
                          context,
                          initialTime: TimeOfDay(hour: _h, minute: _m),
                          title: "Select Time",
                        );
                        if (res != null) {
                          setState(() {
                            _h = res.hour;
                            _m = res.minute;
                            // Update label if it's one of the defaults
                            if (_label == 'Morning' || _label == 'Afternoon' || _label == 'Evening' || _label == 'Night') {
                              if (_h >= 5 && _h < 12) _label = 'Morning';
                              else if (_h >= 12 && _h < 17) _label = 'Afternoon';
                              else if (_h >= 17 && _h < 21) _label = 'Evening';
                              else _label = 'Night';
                            }
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                            color: L.fill,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: L.border.withValues(alpha: 0.5))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              fmtTime(_h, _m),
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: L.text,
                                  letterSpacing: -0.5),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF111111),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.access_time_filled_rounded,
                                  color: Color(0xFFA3E635), size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text('Label',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: L.sub,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                          color: L.fill,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: L.border.withValues(alpha: 0.5))),
                      child: TextField(
                        controller: TextEditingController(text: _label)
                          ..selection = TextSelection.fromPosition(
                              TextPosition(offset: _label.length)),
                        onChanged: (v) => _label = v,
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            isDense: true,
                            hintText: 'e.g. After Breakfast'),
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: L.text),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Day picker
                    Text('Repeat',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: L.sub,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    Row(
                        children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                            .asMap()
                            .entries
                            .map((e) {
                      final sel = _days.contains(e.key);
                      return Expanded(
                          child: GestureDetector(
                        onTap: () => setState(
                            () => sel ? _days.remove(e.key) : _days.add(e.key)),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                                color: sel
                                    ? const Color(0xFF111111)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: sel
                                        ? const Color(0xFF111111)
                                        : L.border,
                                    width: 2)),
                            child: Center(
                                child: Text(e.value,
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: sel ? Colors.white : L.sub))),
                          ),
                        ),
                      ));
                    }).toList()),
                    const SizedBox(height: 24),

                    // With food toggle
                    GestureDetector(
                      onTap: () => setState(() => _withFood = !_withFood),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                            color: L.fill,
                            borderRadius: BorderRadius.circular(14)),
                        child: Row(children: [
                          const Text('🍽️', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text('Take with food',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: L.text))),
                          Container(
                            width: 44,
                            height: 26,
                            decoration: BoxDecoration(
                                color: _withFood
                                    ? const Color(0xFF111111)
                                    : Colors.black.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(99)),
                            child: AnimatedAlign(
                                duration: const Duration(milliseconds: 200),
                                alignment: _withFood
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                    width: 20,
                                    height: 20,
                                    margin: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle))),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Preview
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: L.fill,
                          borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: const Color(0xFF111111),
                                borderRadius: BorderRadius.circular(12)),
                            child: const Center(
                                child: Icon(Icons.notifications_active_rounded,
                                    color: Colors.white, size: 18))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(fmtTime(_h, _m),
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: L.text,
                                      letterSpacing: -0.3)),
                              Text(
                                  '$_label · ${_days.length == 7 ? "Every day" : _days.isEmpty ? "No days" : "${_days.length} days"}${_withFood ? " · 🍽️ With food" : ""}',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: L.sub)),
                            ])),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Set button
                    GestureDetector(
                      onTap: () {
                        state.addSchedule(
                            widget.med.id,
                            ScheduleEntry(
                                h: _h,
                                m: _m,
                                label: _label,
                                days: _days));
                        widget.onClose();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(16)),
                        child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_active_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text('Set Reminder',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: Colors.white)),
                            ]),
                      ),
                    ),
                  ])),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeInput extends StatelessWidget {
  final String label, value;
  final VoidCallback onInc, onDec;
  const _TimeInput(
      {required this.label,
      required this.value,
      required this.onInc,
      required this.onDec});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: L.sub,
              letterSpacing: 0.8)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: L.fill, borderRadius: BorderRadius.circular(12)),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(value,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: L.text)),
          Column(children: [
            GestureDetector(
                onTap: onInc,
                child: Icon(Icons.keyboard_arrow_up_rounded,
                    size: 16, color: L.sub)),
            GestureDetector(
                onTap: onDec,
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: L.sub)),
          ]),
        ]),
      ),
    ]); // Added closing bracket for Column
  }
}

class _SnoozeBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final AppThemeColors L;
  const _SnoozeBtn({required this.label, required this.onTap, required this.L});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: L.fill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: L.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.snooze_rounded,
                size: 12, color: Color(0xFF6366F1)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: L.text)),
          ],
        ),
      ),
    );
  }
}
