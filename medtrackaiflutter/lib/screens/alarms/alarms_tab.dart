import 'dart:math' as math;

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
import '../../widgets/common/mesh_gradient.dart';
import '../../core/utils/haptic_engine.dart';

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
        (s) => s.getAllSchedules());
    final meds = context.select<AppState, List<Medicine>>((s) => s.meds);
    final L = context.L;
    final activeCount = allSchedules.where((x) => x.sched.enabled).length;

    final activeSchedules = allSchedules.where((x) => x.sched.enabled).toList();
    final inactiveSchedules = allSchedules.where((x) => !x.sched.enabled).toList();

    final now = DateTime.now();
    final nowM = now.hour * 60 + now.minute;
    final nextDose = activeSchedules.where((s) => (s.sched.h * 60 + s.sched.m) > nowM).firstOrNull ??
        (activeSchedules.isNotEmpty ? activeSchedules.first : null);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        // Clean Minimalist Background
        Positioned.fill(child: Container(color: Colors.white)),


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
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 120 + MediaQuery.of(context).padding.top),


                // ── REFINED HERO SECTION ──
                if (nextDose != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _NextReminderHero(sch: nextDose, L: L)
                        .animate()
                        .fadeIn(duration: 800.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                  ),

                const SizedBox(height: 32),

                // ── UPCOMING ALARMS SECTION ──
                if (activeSchedules.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'UPCOMING',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.black.withValues(alpha: 0.4),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            fontSize: 10,
                          ),
                        ),
                        _CountBadge(count: activeCount, L: L),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._buildGroupedAlarmsList(activeSchedules, context.read<AppState>(), L, nextDose),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildEmptyState(context, L).animate().fadeIn(),
                  ),
                ],



                // ── PAUSED REMINDERS ──
                if (inactiveSchedules.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
                    child: Text(
                      'Paused',
                      style: AppTypography.titleLarge.copyWith(
                          color: L.text, fontWeight: FontWeight.w800, letterSpacing: -0.5, fontSize: 18),
                    ),
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
                        return _ProfessionalAlarmCard(
                          sch: sch,
                          state: context.read<AppState>(),
                          L: L,
                          isNext: false,
                          onToggle: () => context.read<AppState>().toggleSchedule(sch.med.id, sch.idx),
                          onRemove: () => context.read<AppState>().removeSchedule(sch.med.id, sch.idx),
                          onEdit: () {
                            HapticEngine.selection();
                          },
                        ).animate().fadeIn(delay: (idx * 50).ms);

                      },
                    ),
                  ),
                ],

                // ── QUICK ADD FROM MEDICINES ──
                if (meds.isNotEmpty && activeSchedules.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
                    child: Text(
                      'Your Medicines',
                      style: AppTypography.titleLarge.copyWith(
                          color: L.text, fontWeight: FontWeight.w800, letterSpacing: -0.5, fontSize: 18),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                ],
                const SizedBox(height: 140),
              ],
            ),
          ),
        ),

        // ── ADD ALARM SHEET ──
        AnimatedSwitcher(
          duration: 400.ms,
          child: _addingFor != null
              ? _AddAlarmSheet(
                  key: const ValueKey('add_alarm'),
                  med: _addingFor!,
                  onClose: () => setState(() => _addingFor = null))
              : const SizedBox.shrink(key: ValueKey('empty_alarm')),
        ),

        // ── PREMIUM HEADER ──
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _AlarmsHeader(
            isScrolled: _isScrolled,
            activeCount: activeCount,
            L: L,
          ),
        ),
      ]),
    );
  }

  List<Widget> _buildGroupedAlarmsList(
      List schedules, AppState state, AppThemeColors L, dynamic nextDose) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: schedules.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, idx) {
            final sch = schedules[idx];
            final isNext = nextDose != null &&
                sch.med.id == nextDose.med.id &&
                sch.idx == nextDose.idx;
            return _ProfessionalAlarmCard(
              sch: sch,
              state: state,
              L: L,
              isNext: isNext,
              onToggle: () => state.toggleSchedule(sch.med.id, sch.idx),
              onRemove: () => state.removeSchedule(sch.med.id, sch.idx),
              onEdit: () {
                HapticEngine.selection();
                // Future implementation: Add Edit functionality
              },
            )
                .animate(delay: (idx * 50).ms)
                .fadeIn(duration: 600.ms)
                .slideX(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
          },
        ),
      ),
    ];
  }

  Widget _buildEmptyState(BuildContext context, AppThemeColors L) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      decoration: BoxDecoration(
        color: L.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: L.border.withValues(alpha: 0.3)),

        boxShadow: [
          BoxShadow(
            color: L.secondary.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: L.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded, color: L.secondary, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            'Keep your health on track',
            style: AppTypography.titleMedium.copyWith(
              color: L.text,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Schedule reminders for your medications. We\'ll help you stay consistent with your doses.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: L.sub.withValues(alpha: 0.7),
              height: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          BouncingButton(
            onTap: () {}, // Noop for now, link to add flow
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: L.text,
                borderRadius: BorderRadius.circular(AppRadius.m),
              ),
              child: Text(
                'Set your first alarm',
                style: AppTypography.labelLarge.copyWith(
                  color: L.bg,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// COUNT BADGE
// ─────────────────────────────────────────────────────────────
class _CountBadge extends StatelessWidget {
  final int count;
  final AppThemeColors L;
  const _CountBadge({required this.count, required this.L});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: L.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: L.secondary.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$count',
        style: AppTypography.labelMedium.copyWith(
          color: L.secondary,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PREMIUM ALARM CARD
// ─────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────
// PROFESSIONAL ALARM CARD
// ─────────────────────────────────────────────────────────────
class _ProfessionalAlarmCard extends StatelessWidget {
  final dynamic sch;
  final AppState state;
  final AppThemeColors L;
  final bool isNext;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  const _ProfessionalAlarmCard({
    required this.sch,
    required this.state,
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
    final medColor = hexToColor(med.color);
    final isEnabled = s.enabled;

    return Container(
      decoration: BoxDecoration(
        color: isNext ? Colors.black.withValues(alpha: 0.02) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNext ? Colors.black : Colors.black.withValues(alpha: 0.1),
          width: isNext ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onEdit,
            onLongPress: () {
              HapticEngine.heavyImpact();
            },

            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // ── TIME BLOCK ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isEnabled ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fmtTime(s.h, s.m, context).split(' ')[0],
                          style: AppTypography.displaySmall.copyWith(
                            fontWeight: FontWeight.w900,
                            color: isEnabled ? Colors.white : Colors.black.withValues(alpha: 0.3),
                            fontSize: 22,
                            height: 1.0,
                            letterSpacing: -1.0,
                          ),
                        ),
                        Text(
                          fmtTime(s.h, s.m, context).split(' ').last.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: isEnabled ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.3),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  // ── MEDICATION INFO ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          med.name,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            fontSize: 18,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 1.5,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                              ),
                            ),

                            const SizedBox(width: 8),
                            Text(
                              '${med.dose} · ${s.label.toUpperCase()}',
                              style: AppTypography.labelMedium.copyWith(
                                color: Colors.black.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),

                          ],
                        ),
                        if (isNext)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: medColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'NEXT UP',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.black,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),

                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── PRECISE TOGGLE ──
                  GestureDetector(
                    onTap: () {
                      HapticEngine.selection();
                      onToggle();
                    },
                    child: AnimatedContainer(
                      duration: 300.ms,
                      width: 52,
                      height: 32,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isEnabled ? Colors.black : Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: AnimatedAlign(
                        duration: 300.ms,
                        alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
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
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// ALARMS HEADER
// ─────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────
// ALARMS HEADER (Premium Navigation)
// ─────────────────────────────────────────────────────────────
class _AlarmsHeader extends StatelessWidget {
  final bool isScrolled;
  final int activeCount;
  final AppThemeColors L;
  const _AlarmsHeader({required this.isScrolled, required this.activeCount, required this.L});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: 300.ms,
          padding: EdgeInsets.fromLTRB(24, topPad + 12, 24, 16),
          decoration: BoxDecoration(
            color: isScrolled ? L.bg.withValues(alpha: 0.85) : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isScrolled ? L.border.withValues(alpha: 0.3) : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SCHEDULE',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.black.withValues(alpha: 0.4),
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Reminders',
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                    ),
                  ),

                ],
              ),
              BouncingButton(
                onTap: () {
                  HapticEngine.selection();
                  // Open Add Alarm selector logic here
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                ),

              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// CIRCULAR COUNTDOWN DIAL
// ─────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────
// SOPHISTICATED NEXT REMINDER HERO
// ─────────────────────────────────────────────────────────────
class _NextReminderHero extends StatelessWidget {
  final dynamic sch;
  final AppThemeColors L;
  const _NextReminderHero({required this.sch, required this.L});

  @override
  Widget build(BuildContext context) {
    final med = sch.med as Medicine;
    final s = sch.sched as ScheduleEntry;
    final medColor = hexToColor(med.color);

    final now = DateTime.now();
    final schedTime = DateTime(now.year, now.month, now.day, s.h, s.m);
    var target = schedTime;
    if (target.isBefore(now)) target = target.add(const Duration(days: 1));

    final diff = target.difference(now);
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    final diffStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Padding(

        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PENDING DOSE',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'AT ${fmtTime(s.h, s.m, context).toUpperCase()}',
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.black.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready in $diffStr',
                        style: AppTypography.displaySmall.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${med.name} · ${med.dose.toUpperCase()}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.black.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                  ),
                  child: const Center(
                    child: Icon(Icons.medication_rounded, color: Colors.black, size: 28),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _SwipeConfirmButton(
              label: 'Slide to record dose',
              onConfirmed: () {
                HapticEngine.success();
                context.read<AppState>().takeDose(sch.med.id, sch.idx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Recorded dose for ${med.name}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              L: L,
              baseColor: Colors.black.withValues(alpha: 0.05),
            ),
          ],
        ),
      ),
    );
  }
}





// ─────────────────────────────────────────────────────────────
// ADD ALARM SHEET
// ─────────────────────────────────────────────────────────────
class _AddAlarmSheet extends StatefulWidget {
  final Medicine med;
  final VoidCallback onClose;
  const _AddAlarmSheet({super.key, required this.med, required this.onClose});

  @override
  State<_AddAlarmSheet> createState() => _AddAlarmSheetState();
}

class _AddAlarmSheetState extends State<_AddAlarmSheet> {
  TimeOfDay _time = TimeOfDay.now();
  String _label = 'Daily Dose';

  @override
  Widget build(BuildContext context) {
    return RefinedSheetWrapper(
      title: 'New Reminder',
      child: Column(
        children: [
          ModernTimePicker(
              initialTime: _time, onTimeChanged: (t) => setState(() => _time = t)),
          const SizedBox(height: 24),
          TextField(
            decoration: InputDecoration(
              labelText: 'LABEL',
              labelStyle: AppTypography.labelSmall.copyWith(color: Colors.black.withValues(alpha: 0.4), fontWeight: FontWeight.w900),
              hintText: 'e.g., Morning Dose',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.1))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
            ),
            onChanged: (v) => _label = v,
          ),
          const SizedBox(height: 32),
          BouncingButton(
            onTap: () {
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
              widget.onClose();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
              child: Center(
                child: Text('ADD REMINDER', style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// MED ALARM CONTAINER (Quick Add)
// ─────────────────────────────────────────────────────────────
class _MedAlarmContainer extends StatelessWidget {
  final Medicine med;
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onAdd;

  const _MedAlarmContainer({required this.med, required this.state, required this.L, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Icon(Icons.medication_rounded, color: Colors.black, size: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(med.name, style: AppTypography.titleMedium.copyWith(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
              Text(med.dose.toUpperCase(), style: AppTypography.labelSmall.copyWith(color: Colors.black.withValues(alpha: 0.4), letterSpacing: 0.5)),
            ]),
          ),
          BouncingButton(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// SWIPE CONFIRM BUTTON (Interactive Action)
// ─────────────────────────────────────────────────────────────
class _SwipeConfirmButton extends StatefulWidget {
  final String label;
  final VoidCallback onConfirmed;
  final AppThemeColors L;
  final Color baseColor;

  const _SwipeConfirmButton({required this.label, required this.onConfirmed, required this.L, required this.baseColor});

  @override
  State<_SwipeConfirmButton> createState() => _SwipeConfirmButtonState();
}

class _SwipeConfirmButtonState extends State<_SwipeConfirmButton> with SingleTickerProviderStateMixin {
  double _offset = 0.0;
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    const double width = 300.0;
    const double knobSize = 56.0;
    const maxOffset = width - knobSize - 8.0;

    return Container(
      width: width,
      height: 64,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: widget.baseColor, borderRadius: BorderRadius.circular(32)),
      child: Stack(
        children: [
          Center(
            child: Opacity(
              opacity: (1.0 - (_offset / maxOffset)).clamp(0.2, 1.0),
              child: Text(
                _confirmed ? 'RECORDED' : widget.label.toUpperCase(),
                style: AppTypography.labelLarge.copyWith(
                    color: Colors.black.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.0),
              ),
            ),
          ),

          Positioned(
            left: _offset,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (_confirmed) return;
                setState(() {
                  _offset = (_offset + details.delta.dx).clamp(0.0, maxOffset);
                });
              },
              onHorizontalDragEnd: (details) {
                if (_offset >= maxOffset * 0.9) {
                  setState(() {
                    _offset = maxOffset;
                    _confirmed = true;
                  });
                  widget.onConfirmed();
                } else {
                  setState(() => _offset = 0.0);
                }
              },
              child: Container(
                width: knobSize,
                height: knobSize,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),

                child: Center(
                  child: Icon(
                      _confirmed
                          ? Icons.check_rounded
                        : Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 20),

                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
