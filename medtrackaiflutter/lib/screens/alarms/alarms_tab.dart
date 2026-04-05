import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../domain/entities/entities.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/color_utils.dart';
import '../../widgets/common/modern_time_picker.dart';
import '../../core/utils/date_formatter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/common/refined_sheet_wrapper.dart';
import '../../widgets/common/bouncing_button.dart';
import '../../core/utils/haptic_engine.dart';

// ══════════════════════════════════════════════════════════════════════
// ALARMS TAB — Cal AI Industrial Authority
// ══════════════════════════════════════════════════════════════════════

class AlarmsTab extends StatefulWidget {
  const AlarmsTab({super.key});

  @override
  State<AlarmsTab> createState() => _AlarmsTabState();
}

class _AlarmsTabState extends State<AlarmsTab> {
  Medicine? _addingFor;
  int? _editingIdx;
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
    if (scrolled != _isScrolled) setState(() => _isScrolled = scrolled);
  }

  void _showAddAlarmSheet(BuildContext context, Medicine med, {int? idx}) {
    HapticEngine.selection();
    setState(() {
      _addingFor = med;
      _editingIdx = idx;
    });
  }

  void _showMedPicker(BuildContext context, List<Medicine> meds, AppThemeColors L) {
    HapticEngine.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MedPickerSheet(
        meds: meds,
        L: L,
        onPick: (med) {
          Navigator.pop(context);
          _showAddAlarmSheet(context, med);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSchedules = context.select<AppState, List<({Medicine med, ScheduleEntry sched, int idx})>>(
        (s) => s.getAllSchedules());
    final meds = context.select<AppState, List<Medicine>>((s) => s.meds);
    final L = context.L;
    final activeCount = allSchedules.where((x) => x.sched.enabled).length;

    final activeSchedules = allSchedules.where((x) => x.sched.enabled).toList()
      ..sort((a, b) => (a.sched.h * 60 + a.sched.m).compareTo(b.sched.h * 60 + b.sched.m));
    final inactiveSchedules = allSchedules.where((x) => !x.sched.enabled).toList();

    final now = DateTime.now();
    final nowM = now.hour * 60 + now.minute;
    final nextDose = activeSchedules
            .where((s) => (s.sched.h * 60 + s.sched.m) > nowM)
            .firstOrNull ??
        (activeSchedules.isNotEmpty ? activeSchedules.first : null);

    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          // ── MAIN SCROLL CONTENT ──
          RefreshIndicator(
            onRefresh: () async {
              HapticEngine.selection();
              await context.read<AppState>().loadFromStorage();
            },
            displacement: 100,
            color: L.text,
            backgroundColor: L.bg,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: 110 + MediaQuery.of(context).padding.top),
                ),

                // ── NEXT DOSE HERO ──
                if (nextDose != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: _NextDoseHero(sch: nextDose, L: L)
                          .animate()
                          .fadeIn(duration: 700.ms)
                          .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                    ),
                  ),

                // ── SEPARATOR ──
                if (activeSchedules.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 36, 24, 16),
                      child: Row(
                        children: [
                          Text(
                            'ALL REMINDERS',
                            style: AppTypography.labelSmall.copyWith(
                              color: L.sub.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Container(height: 0.5, color: L.border.withValues(alpha: 0.1))),
                          const SizedBox(width: 12),
                          _CountPill(count: activeCount, L: L),
                        ],
                      ),
                    ),
                  ),

                // ── ACTIVE ALARMS LIST ──
                if (activeSchedules.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, idx) {
                          final sch = activeSchedules[idx];
                          final isNext = nextDose != null &&
                              sch.med.id == nextDose.med.id &&
                              sch.idx == nextDose.idx;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _AlarmCard(
                              sch: sch,
                              L: L,
                              isNext: isNext,
                              onToggle: () => context.read<AppState>().toggleSchedule(sch.med.id, sch.idx),
                              onRemove: () {
                                HapticEngine.heavyImpact();
                                final state = context.read<AppState>();
                                final removedSch = sch;
                                
                                state.removeSchedule(sch.med.id, sch.idx);

                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Alarm for ${sch.med.name} removed'),
                                    duration: const Duration(seconds: 3),
                                    action: SnackBarAction(
                                      label: 'UNDO',
                                      textColor: L.primary,
                                      onPressed: () {
                                        state.addSchedule(removedSch.med.id, removedSch.sched);
                                      },
                                    ),
                                  ),
                                );
                              },
                              onEdit: () => _showAddAlarmSheet(context, sch.med, idx: sch.idx),
                            ).animate(delay: (idx * 60).ms).fadeIn(duration: 500.ms).slideX(begin: 0.04, end: 0, curve: Curves.easeOutCubic),
                          );
                        },
                        childCount: activeSchedules.length,
                      ),
                    ),
                  ),

                // ── EMPTY STATE ──
                if (activeSchedules.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                      child: _EmptyAlarmsState(
                        L: L,
                        hasMeds: meds.isNotEmpty,
                        onSetFirst: meds.isNotEmpty ? () => _showMedPicker(context, meds, L) : null,
                      ).animate().fadeIn(duration: 600.ms),
                    ),
                  ),

                // ── PAUSED SECTION ──
                if (inactiveSchedules.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
                      child: Row(
                        children: [
                          Text(
                            'PAUSED',
                            style: AppTypography.labelSmall.copyWith(
                              color: L.sub.withValues(alpha: 0.4),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Container(height: 0.5, color: L.border.withValues(alpha: 0.1))),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, idx) {
                          final sch = inactiveSchedules[idx];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AlarmCard(
                              sch: sch,
                              L: L,
                              isNext: false,
                              onToggle: () => context.read<AppState>().toggleSchedule(sch.med.id, sch.idx),
                              onRemove: () {
                                HapticEngine.heavyImpact();
                                final state = context.read<AppState>();
                                final removedSch = sch;
                                
                                state.removeSchedule(sch.med.id, sch.idx);

                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Alarm for ${sch.med.name} removed'),
                                    duration: const Duration(seconds: 3),
                                    action: SnackBarAction(
                                      label: 'UNDO',
                                      textColor: L.primary,
                                      onPressed: () {
                                        state.addSchedule(removedSch.med.id, removedSch.sched);
                                      },
                                    ),
                                  ),
                                );
                              },
                              onEdit: () => _showAddAlarmSheet(context, sch.med, idx: sch.idx),
                            ).animate(delay: (idx * 50).ms).fadeIn(),
                          );
                        },
                        childCount: inactiveSchedules.length,
                      ),
                    ),
                  ),
                ],

                // ── QUICK ADD FROM MEDS (only when no active alarms) ──
                if (meds.isNotEmpty && activeSchedules.isEmpty && inactiveSchedules.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                      child: _QuickAddSection(meds: meds, L: L, onAdd: (med) => _showAddAlarmSheet(context, med)),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
          ),

          // ── ADD ALARM SHEET OVERLAY ──
          AnimatedSwitcher(
            duration: 400.ms,
            child: _addingFor != null
                ? _AddAlarmSheet(
                    key: ValueKey('alarm_${_addingFor!.id}_$_editingIdx'),
                    med: _addingFor!,
                    scheduleIndex: _editingIdx,
                    onClose: () => setState(() {
                      _addingFor = null;
                      _editingIdx = null;
                    }),
                  )
                : const SizedBox.shrink(key: ValueKey('empty_alarm')),
          ),

          // ── FROSTED HEADER ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _AlarmsHeader(
              isScrolled: _isScrolled,
              activeCount: activeCount,
              L: L,
              onAdd: () {
                if (meds.isNotEmpty) {
                  _showMedPicker(context, meds, L);
                } else {
                  HapticEngine.selection();
                  context.read<AppState>().showToast('Add a medicine from the Home tab first');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// HEADER
// ══════════════════════════════════════════════════════════════════════
class _AlarmsHeader extends StatelessWidget {
  final bool isScrolled;
  final int activeCount;
  final AppThemeColors L;
  final VoidCallback? onAdd;
  const _AlarmsHeader({required this.isScrolled, required this.activeCount, required this.L, this.onAdd});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AnimatedContainer(
          duration: 250.ms,
          padding: EdgeInsets.fromLTRB(24, topPad + 12, 20, 16),
          decoration: BoxDecoration(
            color: isScrolled ? L.bg.withValues(alpha: 0.92) : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isScrolled ? L.border.withValues(alpha: 0.08) : Colors.transparent,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SCHEDULE',
                      style: AppTypography.labelSmall.copyWith(
                        color: L.sub.withValues(alpha: 0.4),
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Reminders',
                      style: AppTypography.headlineMedium.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              if (onAdd != null)
                BouncingButton(
                  onTap: onAdd!,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.read<AppState>().meds.isEmpty ? L.text.withValues(alpha: 0.15) : L.text,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_rounded, color: L.bg, size: 26),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// COUNT PILL
// ══════════════════════════════════════════════════════════════════════
class _CountPill extends StatelessWidget {
  final int count;
  final AppThemeColors L;
  const _CountPill({required this.count, required this.L});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: L.text,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$count',
        style: AppTypography.labelSmall.copyWith(
          color: L.bg,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// NEXT DOSE HERO CARD
// ══════════════════════════════════════════════════════════════════════
class _NextDoseHero extends StatefulWidget {
  final dynamic sch;
  final AppThemeColors L;
  const _NextDoseHero({required this.sch, required this.L});

  @override
  State<_NextDoseHero> createState() => _NextDoseHeroState();
}

class _NextDoseHeroState extends State<_NextDoseHero> {
  late String _diffStr;
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    _update();
    // update every minute
    Stream.periodic(const Duration(minutes: 1)).listen((_) {
      if (mounted) setState(_update);
    });
  }

  void _update() {
    final now = DateTime.now();
    final s = widget.sch.sched as ScheduleEntry;
    var target = DateTime(now.year, now.month, now.day, s.h, s.m);
    if (target.isBefore(now)) target = target.add(const Duration(days: 1));
    final diff = target.difference(now);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    _diffStr = h > 0 ? '${h}h ${m}m away' : '${m}m away';
  }

  @override
  Widget build(BuildContext context) {
    final med = widget.sch.med as Medicine;
    final s = widget.sch.sched as ScheduleEntry;
    final L = widget.L;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: L.text,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: badge + time ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: L.bg.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(color: L.bg, shape: BoxShape.circle),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(duration: 1500.ms, begin: const Offset(0.8, 0.8), end: const Offset(1.3, 1.3)),
                      const SizedBox(width: 6),
                      Text(
                        'NEXT DOSE',
                        style: AppTypography.labelSmall.copyWith(
                          color: L.bg,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  fmtTime(s.h, s.m, context).toUpperCase(),
                  style: AppTypography.labelMedium.copyWith(
                    color: L.bg.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Main content: name + countdown ──
            if (_recorded)
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: L.bg.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: L.bg, size: 48)
                        .animate()
                        .scale(duration: 400.ms, curve: Curves.easeOutBack)
                        .fadeIn(),
                    const SizedBox(height: 12),
                    Text(
                      'RECORDED',
                      style: AppTypography.labelMedium.copyWith(
                        color: L.bg,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: AppTypography.headlineMedium.copyWith(
                            color: L.bg,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${med.dose.toUpperCase()} · ${s.label.toUpperCase()}',
                          style: AppTypography.labelSmall.copyWith(
                            color: L.bg.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _diffStr,
                          style: AppTypography.titleMedium.copyWith(
                            color: L.bg.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // med icon circle
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: L.bg.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(Icons.medication_rounded, color: L.bg, size: 28),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // ── Swipe to record dose ──
            if (!_recorded)
              _SwipeToConfirm(
                onConfirmed: () {
                  HapticEngine.success();
                  context.read<AppState>().takeDose(widget.sch.med.id, widget.sch.idx);
                  setState(() => _recorded = true);
                  Future.delayed(3.seconds, () {
                    if (mounted) setState(() => _recorded = false);
                  });
                },
                L: L,
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// SWIPE-TO-CONFIRM DOSE BUTTON
// ══════════════════════════════════════════════════════════════════════
class _SwipeToConfirm extends StatefulWidget {
  final VoidCallback onConfirmed;
  final AppThemeColors L;
  const _SwipeToConfirm({required this.onConfirmed, required this.L});

  @override
  State<_SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<_SwipeToConfirm> {
  double _offset = 0;
  bool _confirmed = false;
  static const double _knobSize = 52;
  static const double _trackPad = 4;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxOffset = constraints.maxWidth - _knobSize - _trackPad * 2;
        final progress = (_offset / maxOffset).clamp(0.0, 1.0);

        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: widget.L.bg.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Stack(
            children: [
              // fill progress bar
              AnimatedContainer(
                duration: 50.ms,
                height: 60,
                width: _knobSize + _offset + _trackPad,
                decoration: BoxDecoration(
                  color: widget.L.bg.withValues(alpha: progress * 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              // label
              Center(
                child: AnimatedOpacity(
                  duration: 150.ms,
                  opacity: _confirmed ? 0 : (1.0 - progress * 1.6).clamp(0, 1.0),
                  child: Text(
                    'Slide to record dose →',
                    style: AppTypography.labelMedium.copyWith(
                      color: widget.L.bg.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              // confirmed label
              if (_confirmed)
                Center(
                  child: Text(
                    '✓ Dose Recorded',
                    style: AppTypography.labelMedium.copyWith(
                      color: widget.L.bg,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                ),
              // knob
              if (!_confirmed)
                Positioned(
                  left: _trackPad + _offset,
                  top: _trackPad,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (d) {
                      setState(() {
                        _offset = (_offset + d.delta.dx).clamp(0, maxOffset);
                      });
                    },
                    onHorizontalDragEnd: (_) {
                      if (_offset >= maxOffset * 0.88) {
                        setState(() {
                          _offset = maxOffset;
                          _confirmed = true;
                        });
                        widget.onConfirmed();
                      } else {
                        setState(() => _offset = 0);
                      }
                    },
                    child: AnimatedContainer(
                      duration: 150.ms,
                      width: _knobSize,
                      height: _knobSize,
                      decoration: BoxDecoration(
                        color: widget.L.bg,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(Icons.chevron_right_rounded, color: widget.L.text, size: 26),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// ALARM CARD (with swipe-to-delete)
// ══════════════════════════════════════════════════════════════════════
class _AlarmCard extends StatelessWidget {
  final dynamic sch;
  final AppThemeColors L;
  final bool isNext;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  const _AlarmCard({
    required this.sch,
    required this.L,
    this.isNext = false,
    required this.onToggle,
    required this.onRemove,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final med = sch.med as Medicine;
    final s = sch.sched as ScheduleEntry;
    final isEnabled = s.enabled;
    // ignore: unused_local_variable
    final medColor = hexToColor(med.color);

    return Dismissible(
      key: Key('alarm_${med.id}_${sch.idx}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        HapticEngine.heavyImpact();
        return true;
      },
      onDismissed: (_) {
        onRemove();
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Reminder for ${med.name} deleted'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                context.read<AppState>().addSchedule(
                  med.id,
                  s.copyWith(),
                );
              },
            ),
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: L.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(Icons.delete_outline_rounded, color: L.error, size: 24),
      ),
      child: BouncingButton(
        onTap: onEdit,
        child: AnimatedContainer(
          duration: 300.ms,
          decoration: BoxDecoration(
            color: isEnabled
                ? (isNext ? L.text.withValues(alpha: 0.04) : L.fill.withValues(alpha: 0.08))
                : L.fill.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isNext ? L.text.withValues(alpha: 0.15) : L.border.withValues(alpha: 0.08),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                // ── TIME BLOCK ──
                AnimatedContainer(
                  duration: 300.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  decoration: BoxDecoration(
                    color: isEnabled ? L.text : L.text.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fmtTime(s.h, s.m, context).split(' ')[0],
                        style: AppTypography.displaySmall.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isEnabled ? L.bg : L.sub,
                          fontSize: 20,
                          height: 1.0,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        fmtTime(s.h, s.m, context).split(' ').length > 1
                            ? fmtTime(s.h, s.m, context).split(' ').last.toUpperCase()
                            : '',
                        style: AppTypography.labelSmall.copyWith(
                          color: isEnabled ? L.bg.withValues(alpha: 0.55) : L.sub.withValues(alpha: 0.4),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // ── MED INFO ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isEnabled ? L.text : L.sub,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${med.dose} · ${s.label.toUpperCase()}',
                            style: AppTypography.labelSmall.copyWith(
                              color: L.sub.withValues(alpha: isEnabled ? 0.6 : 0.4),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      if (isNext && isEnabled) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: L.text,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'NEXT UP',
                            style: AppTypography.labelSmall.copyWith(
                              color: L.bg,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // ── TOGGLE ──
                GestureDetector(
                  onTap: () {
                    HapticEngine.selection();
                    onToggle();
                  },
                  child: AnimatedContainer(
                    duration: 300.ms,
                    width: 50,
                    height: 30,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isEnabled ? L.text : L.text.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: AnimatedAlign(
                      duration: 300.ms,
                      curve: Curves.easeOutBack,
                      alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: L.bg,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ══════════════════════════════════════════════════════════════════════
class _EmptyAlarmsState extends StatelessWidget {
  final AppThemeColors L;
  final bool hasMeds;
  final VoidCallback? onSetFirst;
  const _EmptyAlarmsState({required this.L, required this.hasMeds, this.onSetFirst});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      decoration: BoxDecoration(
        color: L.fill.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: L.border.withValues(alpha: 0.06), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: L.text.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(Icons.notifications_none_rounded, color: L.text, size: 32)),
          ),
          const SizedBox(height: 24),
          Text(
            'No reminders yet',
            style: AppTypography.titleMedium.copyWith(
              color: L.text,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hasMeds
                ? 'Set reminders to never miss a dose again. Tap + to get started.'
                : 'Add your medications first, then come back to set reminders.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: L.sub.withValues(alpha: 0.7),
              height: 1.6,
              fontSize: 14,
            ),
          ),
          if (onSetFirst != null) ...[
            const SizedBox(height: 32),
            BouncingButton(
              onTap: onSetFirst!,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: L.text,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Set first reminder',
                  style: AppTypography.labelLarge.copyWith(
                    color: L.bg,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// QUICK ADD SECTION (when no alarms yet)
// ══════════════════════════════════════════════════════════════════════
class _QuickAddSection extends StatelessWidget {
  final List<Medicine> meds;
  final AppThemeColors L;
  final void Function(Medicine) onAdd;
  const _QuickAddSection({required this.meds, required this.L, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('YOUR MEDICINES', style: AppTypography.labelSmall.copyWith(
            color: L.sub.withValues(alpha: 0.5), fontWeight: FontWeight.w900, letterSpacing: 2.0, fontSize: 10)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 0.5, color: L.border.withValues(alpha: 0.1))),
        ]),
        const SizedBox(height: 16),
        ...meds.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _MedAlarmTile(med: e.value, L: L, onAdd: () => onAdd(e.value))
              .animate(delay: (e.key * 60).ms).fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0),
        )),
      ],
    );
  }
}

class _MedAlarmTile extends StatelessWidget {
  final Medicine med;
  final AppThemeColors L;
  final VoidCallback onAdd;
  const _MedAlarmTile({required this.med, required this.L, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: L.fill.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: L.border.withValues(alpha: 0.06), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: L.text.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Icon(Icons.medication_rounded, color: L.text, size: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(med.name, style: AppTypography.titleMedium.copyWith(
                color: L.text, fontWeight: FontWeight.w900, fontSize: 15)),
              Text(med.dose.toUpperCase(), style: AppTypography.labelSmall.copyWith(
                color: L.sub.withValues(alpha: 0.5), letterSpacing: 0.5, fontSize: 11)),
            ],
          )),
          BouncingButton(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: L.text, shape: BoxShape.circle),
              child: Icon(Icons.add_rounded, color: L.bg, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// MED PICKER SHEET (bottom sheet to choose which med to schedule)
// ══════════════════════════════════════════════════════════════════════
class _MedPickerSheet extends StatelessWidget {
  final List<Medicine> meds;
  final AppThemeColors L;
  final void Function(Medicine) onPick;
  const _MedPickerSheet({required this.meds, required this.L, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: L.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 14),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: L.border.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              Text('SET REMINDER FOR',
                  style: AppTypography.labelSmall.copyWith(
                    color: L.sub.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    fontSize: 10,
                  )),
            ]),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              itemCount: meds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final med = meds[i];
                return BouncingButton(
                  onTap: () => onPick(med),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: L.fill.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: L.border.withValues(alpha: 0.06), width: 1.5),
                    ),
                    child: Row(children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: L.text.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Center(child: Icon(Icons.medication_rounded, color: L.text, size: 20)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(med.name, style: AppTypography.labelLarge.copyWith(
                            color: L.text, fontWeight: FontWeight.w900)),
                          Text(med.dose.toUpperCase(), style: AppTypography.labelSmall.copyWith(
                            color: L.sub.withValues(alpha: 0.5), fontSize: 11, letterSpacing: 0.5)),
                        ],
                      )),
                      Icon(Icons.chevron_right_rounded, color: L.sub.withValues(alpha: 0.3), size: 20),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// ADD ALARM SHEET
// ══════════════════════════════════════════════════════════════════════
class _AddAlarmSheet extends StatefulWidget {
  final Medicine med;
  final int? scheduleIndex;
  final VoidCallback onClose;
  const _AddAlarmSheet({super.key, required this.med, this.scheduleIndex, required this.onClose});

  @override
  State<_AddAlarmSheet> createState() => _AddAlarmSheetState();
}

class _AddAlarmSheetState extends State<_AddAlarmSheet> {
  late TimeOfDay _time;
  late String _label;

  @override
  void initState() {
    super.initState();
    if (widget.scheduleIndex != null && widget.scheduleIndex! < widget.med.schedule.length) {
      final s = widget.med.schedule[widget.scheduleIndex!];
      _time = TimeOfDay(hour: s.h, minute: s.m);
      _label = s.label;
    } else {
      _time = TimeOfDay.now();
      _label = 'Daily Dose';
    }
  }

  static const List<String> _quickLabels = ['Morning', 'Afternoon', 'Evening', 'Night', 'Daily Dose'];

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return RefinedSheetWrapper(
      title: widget.scheduleIndex != null ? 'Edit Reminder' : 'New Reminder',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── For which med ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: L.fill.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: L.border.withValues(alpha: 0.06)),
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: L.text.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Icon(Icons.medication_rounded, color: L.text, size: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.med.name,
                    style: AppTypography.labelLarge.copyWith(color: L.text, fontWeight: FontWeight.w900)),
                Text(widget.med.dose.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                        color: L.sub.withValues(alpha: 0.5), fontSize: 11)),
              ])),
            ]),
          ),

          const SizedBox(height: 24),

          // ── Time picker ──
          ModernTimePicker(
            initialTime: _time,
            onTimeChanged: (t) => setState(() => _time = t),
          ),

          const SizedBox(height: 24),

          // ── Quick label chips ──
          Text('LABEL', style: AppTypography.labelSmall.copyWith(
            color: L.sub.withValues(alpha: 0.5), fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 10)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickLabels.map((label) {
              final selected = _label == label;
              return BouncingButton(
                onTap: () {
                  HapticEngine.selection();
                  setState(() => _label = label);
                },
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? L.text : L.fill.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: selected ? L.text : L.border.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      color: selected ? L.bg : L.sub,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // ── Save button ──
          BouncingButton(
            onTap: () {
              HapticEngine.success();
              if (widget.scheduleIndex != null) {
                context.read<AppState>().updateSchedule(
                  widget.med.id,
                  widget.scheduleIndex!,
                  ScheduleEntry(
                    h: _time.hour,
                    m: _time.minute,
                    label: _label,
                    days: widget.med.schedule[widget.scheduleIndex!].days,
                    enabled: widget.med.schedule[widget.scheduleIndex!].enabled,
                  ),
                );
              } else {
                context.read<AppState>().addSchedule(
                  widget.med.id,
                  ScheduleEntry(
                    h: _time.hour,
                    m: _time.minute,
                    label: _label,
                    days: const [1, 2, 3, 4, 5, 6, 0],
                    enabled: true,
                  ),
                );
              }
              widget.onClose();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: L.text,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  widget.scheduleIndex != null ? 'SAVE CHANGES' : 'ADD REMINDER',
                  style: AppTypography.titleMedium.copyWith(
                    color: L.bg,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
