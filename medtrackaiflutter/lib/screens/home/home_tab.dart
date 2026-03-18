import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/home_insight_card.dart';
import '../../providers/app_state.dart';
import '../../domain/entities/entities.dart';
import '../../theme/app_theme.dart';
import '../medicine/medicine_detail_screen.dart';
import 'widgets/streak_modal.dart';
import 'widgets/settings_modal_new.dart';
import 'widgets/home_header.dart';
import 'widgets/home_stats_grid.dart';
import 'widgets/home_banners.dart';
import 'widgets/home_dose_section.dart';
import 'widgets/home_meds_section.dart';
import 'widgets/med_card.dart';
import 'widgets/missed_dose_sheet.dart';
import '../../widgets/modals/dose_celebration_modal.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/haptic_engine.dart';

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

  void _scrollToMeds() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: 600.ms,
      curve: Curves.easeOutBack,
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: 600.ms,
      curve: Curves.easeOutQuart,
    );
    HapticEngine.selection();
  }

  @override
  Widget build(BuildContext context) {
    final doses = context.select<AppState, List<DoseItem>>((s) => s.getDoses());
    final streak = context.select<AppState, int>((s) => s.getStreak());
    final takenToday = context.select<AppState, Map<String, bool>>((s) => s.takenToday);
    final meds = context.select<AppState, List<Medicine>>((s) => s.meds);
    final L = context.L;

    final takenCount = doses.where((d) => takenToday[d.key] == true).length;
    final remaining = doses.length - takenCount;
    final dosePct = doses.isNotEmpty ? takenCount / doses.length : 0.0;
    final ringCol =
        dosePct == 1.0 ? L.text : (dosePct > 0.0 ? L.text.withValues(alpha: 0.5) : L.border);

    final mainContent = Scaffold(
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
          child: Scrollbar(
            controller: _scrollController,
            child: CustomScrollView(
              controller: _scrollController,
              key: const PageStorageKey('home_scroll'),
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: 210 + MediaQuery.of(context).padding.top),
              ),

              // --- 1. MISSED ALERTS ---
              if (context.select<AppState, bool>((s) => s.missedAlerts.any((a) => !a.seen)))
                SliverPadding(
                  padding: const EdgeInsets.only(left: AppSpacing.screenPadding, right: AppSpacing.screenPadding, bottom: AppSpacing.s),
                  sliver: SliverToBoxAdapter(
                    child: HomeMissedAlertsBanner(state: context.read<AppState>(), L: L),
                  ),
                ),

              // --- 2. LOW STOCK ALERTS ---
              if (context.select<AppState, List<Medicine>>((s) => s.getLowMeds()).isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.only(left: AppSpacing.screenPadding, right: AppSpacing.screenPadding, bottom: AppSpacing.m),
                  sliver: SliverToBoxAdapter(
                    child: HomeLowStockBanner(
                        state: context.read<AppState>(), L: L, onTap: _scrollToMeds),
                  ),
                ),

              // --- 3. STATS & ADHERENCE (NOW AT TOP) ---
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.s),
                sliver: SliverToBoxAdapter(
                  child: HomeStatsGrid(
                    state: context.read<AppState>(),
                    doses: doses,
                    takenCount: takenCount,
                    remaining: remaining,
                    dosePct: dosePct,
                    ringCol: ringCol,
                  ),
                ),
              ),

              // --- 3.1 AI HEALTH INSIGHTS ---
              SliverToBoxAdapter(
                child: HomeInsightCard(
                  state: context.read<AppState>(),
                  onLoadInsight: () => context.read<AppState>().refreshHealthInsights(),
                ),
              ),

              // --- 4. TODAY'S DOSES & NEXT DOSE (Timeline) ---
              if (doses.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.only(
                      left: AppSpacing.screenPadding, right: AppSpacing.screenPadding, top: AppSpacing.l, bottom: AppSpacing.xs),
                  sliver: SliverToBoxAdapter(
                    child: Text("Today's Schedule",
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: L.text,
                            letterSpacing: -0.5)),
                  ),
                ),
                ..._buildGroupedTimelineSlivers(context, doses, takenToday, context.read<AppState>(), L),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.l)),
              ],

              // --- MEDS SECTION ---
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: HomeMedsHeader(onAdd: widget.onScan),
                  ),
                ),
              ),
              if (meds.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                  sliver: SliverToBoxAdapter(
                    child: HomeMedsEmptyState(onAdd: widget.onScan),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final med = meds[index];
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
                      childCount: meds.length,
                    ),
                  ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: HomeHeader(
            state: context.read<AppState>(),
            streak: streak,
            isScrolled: _isScrolled,
            onTap: _scrollToTop,
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
                  history: context.select<AppState, Map<String, List<DoseEntry>>>((s) => s.history),
                  streakData: context.select<AppState, StreakData>((s) => s.streakData),
                  onClose: () => setState(() => _showStreak = false),
                  onFreeze: () => context.read<AppState>().useStreakFreeze())
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

  List<Widget> _buildGroupedTimelineSlivers(BuildContext context, List<DoseItem> doses,
      Map<String, bool> takenToday, AppState state, AppThemeColors L) {
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
      final taken = takenToday[d.key] ?? false;
      return !taken && m >= (nowM - 5); // Allow a tiny 5m grace window
    }).firstOrNull;

    final List<Widget> slivers = [];

    groups.forEach((period, periodDoses) {
      if (periodDoses.isEmpty) return;

      final isCurrent = period == currentPeriod;

      slivers.add(SliverPadding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 4),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Text(period.toUpperCase(),
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isCurrent ? L.text : L.sub.withValues(alpha: 0.5),
                      letterSpacing: 1.2)),
              if (isCurrent) ...[
                const SizedBox(width: 6),
                Container(
                    width: 3,
                    height: 3,
                    decoration:
                        BoxDecoration(color: L.text, shape: BoxShape.circle)),
              ],
            ],
          ),
        ),
      ));

      slivers.add(SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final d = periodDoses[index];
              final taken = takenToday[d.key] ?? false;
              final schedM = d.sched.h * 60 + d.sched.m;
              final overdue = !taken && nowM > schedM + 5;
              final isLast = index == periodDoses.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                                ? L.text
                                : (overdue ? L.text : L.border),
                            shape: BoxShape.circle,
                            border: taken
                                ? null
                                : Border.all(
                                    color: overdue
                                        ? L.text
                                        : L.sub.withValues(alpha: 0.3),
                                    width: 1.0),
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 1,
                            color: taken
                                ? L.text.withValues(alpha: 0.3)
                                : L.border.withValues(alpha: 0.1),
                            height: 60, // Fixed height for timeline line
                          ),
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
                      onTake: () {
                        if (!taken) {
                          state.toggleDose(d);
                          DoseCelebrationModal.show(context, d.med.name);
                        }
                      },
                      onSnooze: () {
                        if (!taken) {
                          MissedDoseProtocolSheet.show(
                              context, d, (nowM - schedM).toInt());
                        }
                      },
                      onTap: () {
                        if (overdue) {
                          MissedDoseProtocolSheet.show(
                              context, d, (nowM - schedM).toInt());
                        } else {
                          final wasTaken = takenToday[d.key] ?? false;
                          state.toggleDose(d);
                          if (!wasTaken) {
                            DoseCelebrationModal.show(context, d.med.name);
                          }
                        }
                      },
                    ),
                  ),
                ],
              );
            },
            childCount: periodDoses.length,
          ),
        ),
      ));
    });

    return slivers;
  }

  int nowMins() => DateTime.now().hour * 60 + DateTime.now().minute;
}
