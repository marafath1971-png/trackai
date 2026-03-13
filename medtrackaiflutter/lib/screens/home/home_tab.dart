import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../domain/entities/entities.dart';
import '../../theme/app_theme.dart';
import '../medicine/medicine_detail_screen.dart';
import 'widgets/streak_modal.dart';
import 'widgets/settings_modal_new.dart';
import 'widgets/home_header.dart';
import 'widgets/home_stats_grid.dart';
import 'widgets/home_dose_section.dart';
import 'widgets/home_meds_section.dart';
import 'widgets/med_card.dart';
import 'widgets/missed_dose_sheet.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback onScan;
  const HomeTab({super.key, required this.onScan});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _showStreak = false;
  bool _showSettings = false;
  Medicine? _viewingMed;
  bool _startInEditMode = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final L = context.L;

    // Computed values for stats
    final doses = state.getDoses();
    final streak = state.getStreak();
    final takenCount =
        doses.where((d) => state.takenToday[d.key] == true).length;
    final remaining = doses.length - takenCount;
    final dosePct = doses.isNotEmpty ? takenCount / doses.length : 0.0;
    final ringCol =
        dosePct == 1.0 ? L.green : (dosePct > 0.5 ? L.amber : L.blue);

    final mainContent = Scaffold(
      backgroundColor: L.bg,
      body: Stack(children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 140 + MediaQuery.of(context).padding.top),

              // --- 1. MISSED ALERTS ---
              if (state.missedAlerts.any((a) => !a.seen))
                Padding(
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 12),
                  child: _buildMissedAlertsBanner(state, L),
                ),

              // --- 2. LOW STOCK ALERTS ---
              if (state.getLowMeds().isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: _buildLowStockBanner(state, L),
                ),

              // --- 3. STATS & ADHERENCE (NOW AT TOP) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: HomeStatsGrid(
                  state: state,
                  doses: doses,
                  takenCount: takenCount,
                  remaining: remaining,
                  dosePct: dosePct,
                  ringCol: ringCol,
                ),
              ),

              // --- 4. TODAY'S DOSES & NEXT DOSE (Timeline) ---
              if (doses.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(
                      left: 20, right: 20, top: 24, bottom: 8),
                  child: Text("Today's Schedule",
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: L.text,
                          letterSpacing: -0.3)),
                ),
                ..._buildGroupedTimeline(context, doses, state, L),
                const SizedBox(height: 32),
              ],

              // --- MEDS SECTION ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: HomeMedsHeader(onAdd: widget.onScan),
                ),
              ),
              if (state.meds.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: HomeMedsEmptyState(onAdd: widget.onScan),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.meds.length,
                    itemBuilder: (context, index) {
                      final med = state.meds[index];
                      return MedCard(
                        med: med,
                        onView: () => setState(() {
                          _viewingMed = med;
                          _startInEditMode = false;
                        }),
                        onEdit: () => setState(() {
                          _viewingMed = med;
                          _startInEditMode = true;
                        }),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 120),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: HomeHeader(
            state: state,
            streak: streak,
            onOpenStreak: () => setState(() => _showStreak = true),
            onOpenSettings: () => setState(() => _showSettings = true),
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
          child: _showStreak
              ? StreakModal(
                  key: const ValueKey('streak'),
                  streak: streak,
                  history: state.history,
                  streakData: state.streakData,
                  onClose: () => setState(() => _showStreak = false),
                  onFreeze: () => state.useStreakFreeze())
              : const SizedBox.shrink(key: ValueKey('empty_streak')),
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
          child: _showSettings
              ? SettingsModal(
                  key: const ValueKey('settings'),
                  onClose: () => setState(() => _showSettings = false))
              : const SizedBox.shrink(key: ValueKey('empty_settings')),
        ),
      ]),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _viewingMed != null
          ? MedicineDetailScreen(
              key: ValueKey('med_detail_${_viewingMed!.id}'),
              medId: _viewingMed!.id,
              onBack: () => setState(() => _viewingMed = null),
              initialEditMode: _startInEditMode,
            )
          : Container(
              key: const ValueKey('home_main'),
              child: mainContent,
            ),
    );
  }

  List<Widget> _buildGroupedTimeline(BuildContext context, List<DoseItem> doses,
      AppState state, AppThemeColors L) {
    if (doses.isEmpty) return [];

    final Map<String, List<DoseItem>> groups = {
      'Morning': [],
      'Afternoon': [],
      'Evening': [],
      'Night': [],
    };

    for (final d in doses) {
      final m = d.sched.h * 60 + d.sched.m;
      if (m < 720) {
        groups['Morning']!.add(d);
      } else if (m < 1020) {
        groups['Afternoon']!.add(d);
      } else if (m < 1260) {
        groups['Evening']!.add(d);
      } else {
        groups['Night']!.add(d);
      }
    }

    final nowM = nowMins();
    String currentPeriod = 'Morning';
    if (nowM >= 720 && nowM < 1020) {
      currentPeriod = 'Afternoon';
    } else if (nowM >= 1020 && nowM < 1260) {
      currentPeriod = 'Evening';
    } else if (nowM >= 1260 || nowM < 300) {
      currentPeriod = 'Night';
    }

    final absoluteNextDose = doses.where((d) {
      final m = d.sched.h * 60 + d.sched.m;
      final taken = state.takenToday[d.key] ?? false;
      return !taken && m >= (nowM - 5); // Allow a tiny 5m grace window
    }).firstOrNull;

    final List<Widget> widgets = [];

    groups.forEach((period, periodDoses) {
      if (periodDoses.isEmpty) return;

      final isCurrent = period == currentPeriod;

      widgets.add(Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
        child: Row(
          children: [
            Text(period.toUpperCase(),
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isCurrent ? L.green : L.sub,
                    letterSpacing: 1.0)),
            if (isCurrent) ...[
              const SizedBox(width: 8),
              Container(
                  width: 4,
                  height: 4,
                  decoration:
                      BoxDecoration(color: L.green, shape: BoxShape.circle)),
            ],
          ],
        ),
      ));

      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: periodDoses.length,
          itemBuilder: (context, index) {
            final d = periodDoses[index];
            final taken = state.takenToday[d.key] ?? false;
            final schedM = d.sched.h * 60 + d.sched.m;
            final overdue = !taken && nowM > schedM + 5;
            final isLast = index == periodDoses.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 32,
                    child: Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: taken
                                ? L.green
                                : (overdue ? L.red : L.border),
                            shape: BoxShape.circle,
                            border: taken
                                ? null
                                : Border.all(
                                    color: overdue ? L.red : L.sub, width: 2),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                              child: Container(
                                  width: 2,
                                  color: taken
                                      ? L.green.withValues(alpha: 0.3)
                                      : L.border)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DoseCard(
                      dose: d,
                      taken: taken,
                      overdue: overdue,
                      isNext: d == absoluteNextDose,
                      L: L,
                      onTap: () {
                        if (overdue) {
                          MissedDoseProtocolSheet.show(
                              context, d, (nowM - schedM).toInt());
                        } else {
                          state.toggleDose(d);
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ));
    });

    return widgets;
  }

  int nowMins() => DateTime.now().hour * 60 + DateTime.now().minute;



  Widget _buildMissedAlertsBanner(AppState state, AppThemeColors L) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: L.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: L.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: L.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Unresolved missed doses!',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: L.text)),
          ),
          GestureDetector(
            onTap: () => state.markAlertsAsSeen(),
            child: Text('Clear',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: L.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockBanner(AppState state, AppThemeColors L) {
    final lowMeds = state.getLowMeds();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: L.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: L.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined, color: L.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${lowMeds.length} ${lowMeds.length == 1 ? 'medicine' : 'medicines'} running low',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: L.text),
            ),
          ),
        ],
      ),
    );
  }


}
