import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../domain/entities/entities.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/color_utils.dart';
import '../../widgets/common/modern_time_picker.dart';
import '../../core/utils/date_formatter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../widgets/common/unified_header.dart';
import '../../widgets/common/refined_sheet_wrapper.dart';
import '../../widgets/common/premium_empty_state.dart';
import '../../core/utils/haptic_engine.dart';

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
  bool _isScrolled = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 10;
    if (scrolled != _isScrolled) {
      setState(() => _isScrolled = scrolled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSchedules = context.select<AppState, List<({Medicine med, ScheduleEntry sched, int idx})>>(
      (s) => s.getAllSchedules()
    );
    final meds = context.select<AppState, List<Medicine>>((s) => s.meds);
    final L = context.L;
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
        RefreshIndicator(
          onRefresh: () async {
            HapticEngine.selection();
            await context.read<AppState>().loadFromStorage();
          },
          displacement: 100,
          color: L.secondary,
          backgroundColor: L.bg,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              child: Column(
                children: [
                SizedBox(height: 110 + MediaQuery.of(context).padding.top),
                const SizedBox(height: AppSpacing.l),
                if (nextDose != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                    child: _NextDoseIndicator(sch: nextDose, L: L),
                  ),
                const SizedBox(height: AppSpacing.l),
                if (activeSchedules.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                    child: Text("Active Reminders",
                        style: AppTypography.titleLarge.copyWith(
                            fontSize: 18,
                            color: L.text,
                            letterSpacing: -0.3)),
                  ),
                const SizedBox(height: 16),
              if (activeSchedules.isNotEmpty)
                ..._buildGroupedAlarms(activeSchedules, context.read<AppState>(), L, nextDose),
              if (inactiveSchedules.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Text("Paused",
                      style: AppTypography.titleLarge.copyWith(
                          fontSize: 18,
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
                        state: context.read<AppState>(),
                        L: L,
                        isNext: false,
                        onToggle: () =>
                            context.read<AppState>().toggleSchedule(sch.med.id, sch.idx),
                        onRemove: () =>
                            context.read<AppState>().removeSchedule(sch.med.id, sch.idx),
                      );
                    },
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.xxl, AppSpacing.screenPadding, AppSpacing.m),
                child: Text('All Medicines',
                    style: AppTypography.titleLarge.copyWith(
                        fontSize: 18,
                        color: L.text,
                        letterSpacing: -0.3)),
              ),
              if (meds.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                  child: _buildEmptyState(context, L),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: meds.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) => _MedAlarmContainer(
                      med: meds[idx],
                      state: context.read<AppState>(),
                      L: L,
                      onAdd: () => setState(() => _addingFor = meds[idx]),
                    ),
                  ),
                ),
              const SizedBox(height: 120),
            ],
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
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: UnifiedHeader(
            isScrolled: _isScrolled,
            title: "Reminders",
            subtitle: activeCount > 0 
                ? "$activeCount active alarms" 
                : "No active alarms",
          ),
        ),
      ]),
    );
  }
}

List<Widget> _buildGroupedAlarms(
    List<dynamic> active, AppState state, AppThemeColors L, dynamic nextDose) {
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
            style: AppTypography.labelLarge.copyWith(
                fontSize: 11,
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
            isNext: sch == nextDose, // Pass isNext to highlight
            onToggle: () {
              HapticEngine.selection();
              state.toggleSchedule(sch.med.id, sch.idx);
            },
            onRemove: () {
              HapticEngine.alertWarning();
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
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: AppRadius.roundXL,
          boxShadow: L.shadowSoft,
          border: Border.all(color: L.border, width: 1.0),
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
                        style: AppTypography.labelLarge.copyWith(
                            fontSize: 10,
                            color: L.secondary,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(diffStr,
                        style: AppTypography.displayMedium.copyWith(
                            fontSize: 28,
                            color: L.text,
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
                    child: Icon(Icons.timer_outlined, color: L.green, size: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: L.fill,
                borderRadius: AppRadius.roundL,
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
                            style: AppTypography.titleLarge.copyWith(
                                fontSize: 16,
                                color: L.text,
                                letterSpacing: -0.3)),
                        Text('${s.label} · ${fmtTime(s.h, s.m, context)}',
                            style: AppTypography.bodySmall.copyWith(
                                fontSize: 13,
                                color: L.sub,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds, color: Colors.white.withValues(alpha: 0.05)),
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
  final bool isNext;
  final VoidCallback onToggle, onRemove;
  const _TimelineAlarmCard(
      {required this.sch,
      required this.state,
      required this.L,
      this.isNext = false,
      required this.onToggle,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final med = sch.med as Medicine;
    final s = sch.sched as ScheduleEntry;
    final medColor = hexToColor(med.color);

    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: AppRadius.roundL,
        border: Border.all(
            color: isNext ? L.secondary.withValues(alpha: 0.5) : L.border,
            width: 1.0),
        boxShadow: L.shadowSoft,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(children: [
          // Left Accent Bar (Glow if next)
          Container(
              width: isNext ? 8 : 6,
              color: isNext ? L.green : medColor,
              child: isNext
                  ? Animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                      effects: [
                        FadeEffect(
                            begin: 0.5, end: 1.0, duration: 1000.ms, curve: Curves.easeInOut)
                      ],
                      child: Container(color: L.text),
                    )
                  : null),
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
                          Text(fmtTime(s.h, s.m, context),
                              style: AppTypography.displayMedium.copyWith(
                                  fontSize: 24,
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
                        AppToggle(
                            value: s.enabled,
                            onChanged: (v) => onToggle()),
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
                                style: AppTypography.titleLarge.copyWith(
                                    fontSize: 15,
                                    color: L.text,
                                    letterSpacing: -0.3)),
                            Text(med.dose,
                                style: AppTypography.bodySmall.copyWith(
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
                                    ? L.card2
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isScheduled ? L.card2 : L.border,
                                    width: 1),
                              ),
                              child: Center(
                                  child: Text(e.value,
                                      style: AppTypography.labelMedium.copyWith(
                                          fontSize: 9,
                                          color: isScheduled ? L.text : L.sub))),
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
    );

    if (isNext) {
      card = Animate(
        onPlay: (controller) => controller.repeat(reverse: true),
        effects: [
          CustomEffect(
            builder: (context, value, child) {
              return Transform.scale(
                scale: 1.0 + (value * 0.015),
                child: child,
              );
            },
            duration: 1500.ms,
            curve: Curves.easeInOut,
          )
        ],
        child: card,
      );
    }

    return Animate(
      effects: [
        FadeEffect(duration: 400.ms, curve: Curves.easeOut),
        SlideEffect(begin: const Offset(0, 0.05), duration: 400.ms, curve: Curves.easeOut),
      ],
      child: card,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: AppRadius.roundXL,
        border: Border.all(color: L.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: medColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24)),
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
                    style: AppTypography.titleLarge.copyWith(
                        fontSize: 17,
                        color: L.text,
                        letterSpacing: -0.5,
                        overflow: TextOverflow.ellipsis)),
                Text(
                    '${med.dose}${count > 0 ? " · $count schedule${count != 1 ? "s" : ""}" : " · No schedules"}',
                    style: AppTypography.bodySmall.copyWith(fontSize: 13, color: L.sub, fontWeight: FontWeight.w500)),
              ])),
          GestureDetector(
              onTap: () {
                HapticEngine.selection();
                onAdd();
              },
              child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: L.primary, shape: BoxShape.circle),
                  child: Icon(Icons.add_rounded,
                      color: L.onPrimary, size: 20))),
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
                  color: L.fill.withValues(alpha: 0.4),
                  borderRadius: AppRadius.roundM,
                  border: Border.all(color: L.border.withValues(alpha: 0.3))),
              child: Row(children: [
                Text(fmtTime(s.h, s.m, context),
                    style: AppTypography.displaySmall.copyWith(
                        fontSize: 16,
                        color: s.enabled ? L.text : L.sub,
                        letterSpacing: -0.5)),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(s.label,
                        style: AppTypography.bodySmall.copyWith(
                            fontSize: 13,
                            color: L.sub,
                            fontWeight: FontWeight.w600))),
                AppToggle(
                    value: s.enabled,
                    onChanged: (v) => state.toggleSchedule(med.id, idx)),
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
  return PremiumEmptyState(
    title: 'No reminders yet',
    subtitle: state.meds.isEmpty
        ? 'Scan a medicine first, then come back to set your daily reminders.'
        : 'Set reminders for your medicines to keep track of your doses.',
    icon: Icons.notifications_active_rounded,
    actionLabel: state.meds.isEmpty ? 'Scan Medicine' : null,
    onAction: state.meds.isEmpty ? () {
      // This is a placeholder since the navigation to scan is handled in AppShell
      // But we can trigger a toast or common action if needed.
    } : null,
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

class _AddAlarmSheetState extends State<_AddAlarmSheet> {
  int _h = 8, _m = 0;
  String _label = 'Morning';
  final Set<int> _days = {1, 2, 3, 4, 5, 6, 0};
  String _intake = 'None';

  @override
  void initState() {
    super.initState();
    _intake = widget.med.intakeInstructions.isEmpty ? 'None' : widget.med.intakeInstructions;
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final state = context.read<AppState>();

    return RefinedSheetWrapper(
      title: 'Add Reminder',
      icon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: L.green.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(Icons.alarm_add_rounded, color: L.green, size: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select a time and frequency for ${widget.med.name}.',
              style: TextStyle(color: L.sub, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          
          // Time Selector
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
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: L.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: L.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('REMINDER TIME',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: L.sub,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 4),
                      Text(fmtTime(_h, _m, context),
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: L.text,
                              letterSpacing: -1.0)),
                    ],
                  ),
                  Icon(Icons.access_time_filled_rounded, color: L.green, size: 32),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Label Input
          Text('LABEL',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: L.sub,
                  letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: L.fill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: L.border),
            ),
            child: TextField(
              onChanged: (v) => _label = v,
              style: TextStyle(color: L.text, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'e.g. Morning, After Lunch',
                hintStyle: TextStyle(color: L.sub.withValues(alpha: 0.5)),
                border: InputBorder.none,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Days Selector
          Text('REPEAT ON',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: L.sub,
                  letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].asMap().entries.map((e) {
              final isSel = _days.contains(e.key);
              return GestureDetector(
                onTap: () {
                  HapticEngine.selection();
                  setState(() {
                    if (isSel) {
                      if (_days.length > 1) _days.remove(e.key);
                    } else {
                      _days.add(e.key);
                    }
                  });
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSel ? L.text : L.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: isSel ? L.text : L.border, width: 1.0),
                  ),
                  child: Center(
                    child: Text(e.value,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isSel ? L.bg : L.text)),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 40),
          
          // Save Button
          GestureDetector(
            onTap: () {
              HapticEngine.success();
              if (_intake != widget.med.intakeInstructions) {
                state.updateMed(widget.med.id, intakeInstructions: _intake, updateNotifs: false);
              }
              state.addSchedule(
                  widget.med.id,
                  ScheduleEntry(
                    h: _h,
                    m: _m,
                    label: _label,
                    days: _days.toList()..sort(),
                  ));
              widget.onClose();
            },
            child: Container(
              height: 64,
              width: double.infinity,
              decoration: BoxDecoration(
                color: L.text,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: L.text.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text('Set Reminder',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: L.bg)),
              ),
            ),
          ),
        ],
      ),
    );
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
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.snooze_rounded,
                size: 12, color: L.text),
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
