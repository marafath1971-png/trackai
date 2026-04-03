import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/home_insight_card.dart';

import 'widgets/trial_countdown_card.dart';
import '../../providers/app_state.dart';
import '../../domain/entities/entities.dart';
import '../../theme/app_theme.dart';
import '../medicine/medicine_detail_screen.dart';
import 'widgets/streak_modal.dart';
import 'widgets/settings_modal_new.dart';
import 'widgets/home_header.dart';
import 'widgets/home_stats_grid.dart';
import 'widgets/home_banners.dart';
import '../../core/utils/haptic_engine.dart';
import 'widgets/quick_log_symptom.dart';
import 'widgets/quick_log_prn.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'widgets/home_meds_section.dart';
import 'widgets/med_card.dart';
import '../../widgets/common/interaction_warning_banner.dart';
import '../../widgets/home/interactive_progress_ring.dart';
import '../../widgets/common/premium_empty_state.dart';

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
      duration: 800.ms,
      curve: Curves.easeOutQuart,
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: 800.ms,
      curve: Curves.easeOutQuart,
    );
    HapticEngine.selection();
  }

  @override
  Widget build(BuildContext context) {
    final doses = context.select<AppState, List<DoseItem>>((s) => s.getDoses());
    final streak = context.select<AppState, int>((s) => s.getStreak());
    final takenToday =
        context.select<AppState, Map<String, bool>>((s) => s.takenToday);
    final meds = context.select<AppState, List<Medicine>>((s) => s.meds);
    final L = context.L;

    final takenCount = doses.where((d) => takenToday[d.key] == true).length;
    final remaining = doses.length - takenCount;
    final dosePct = doses.isNotEmpty ? takenCount / doses.length : 0.0;
    final ringCol = dosePct == 1.0
        ? L.text
        : (dosePct > 0.0 ? L.text.withValues(alpha: 0.5) : L.border);

    final mainContent = Scaffold(
      backgroundColor: L.bg,
      body: Stack(children: [
        RefreshIndicator(
          onRefresh: () async {
            HapticEngine.selection();
            await context.read<AppState>().loadFromStorage();
          },
          displacement: 110,
          color: L.primary,
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
                  child: SizedBox(
                      height: 235 + MediaQuery.of(context).padding.top),
                ),

                // --- 1. CORE ALERTS & WARNINGS ---
                _sliverStaggerDown([
                  if (context.select<AppState, bool>(
                      (s) => s.missedAlerts.any((a) => !a.seen)))
                    HomeMissedAlertsBanner(
                        state: context.read<AppState>(), L: L),
                  if (context.select<AppState, String?>(
                          (s) => s.interactionWarning) !=
                      null)
                    const InteractionWarningBanner(),
                  if (context
                      .select<AppState, List<Medicine>>((s) => s.getLowMeds())
                      .isNotEmpty)
                    HomeLowStockBanner(
                        state: context.read<AppState>(),
                        L: L,
                        onTap: _scrollToMeds),
                ], delay: 0.ms),

                // --- 2. STATS & PROGRESS ---
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                      vertical: AppSpacing.s),
                  sliver: SliverToBoxAdapter(
                    child: HomeStatsGrid(
                      state: context.read<AppState>(),
                      doses: doses,
                      takenCount: takenCount,
                      remaining: remaining,
                      dosePct: dosePct,
                      ringCol: ringCol,
                    )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 600.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
                  ),
                ),

                // --- 3. ONBOARDING SYNC ---
                _sliverStaggerDown([
                  const TrialCountdownCard(),
                ], delay: 300.ms),

                // --- 4. QUICK ACTIONS ---
                _sliverStaggerDown([
                  const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.m),
                      child: QuickLogSymptom()),
                  const QuickLogPrnDose(),
                ], delay: 450.ms),

                // --- 5. INSIGHTS & VIRALITY ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    child: InteractiveProgressRing(
                      progress: dosePct,
                      label: 'Daily Progress',
                      valueText: '${(dosePct * 100).round()}% of doses taken',
                      onTap: () => widget.onScan(),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.m)),

                _sliverStaggerDown([
                  HomeInsightCard(
                    state: context.read<AppState>(),
                    onLoadInsight: () =>
                        context.read<AppState>().fetchHealthInsights(),
                  ),
                ], delay: 600.ms),

                // --- 6. TIMELINE ---
                if (doses.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                        AppSpacing.l, AppSpacing.screenPadding, AppSpacing.s),
                    sliver: SliverToBoxAdapter(
                      child: Text("Today's Schedule",
                          style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w900,
                              color: L.text,
                              letterSpacing: -0.8)),
                    ),
                  ),
                  ..._buildGroupedTimelineSlivers(
                      context, doses, takenToday, context.read<AppState>(), L),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.l)),
                ] else if (meds.isNotEmpty) ...[
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    sliver: SliverToBoxAdapter(
                      child: PremiumEmptyState(
                        title: 'All caught up! 🌟',
                        subtitle:
                            'You have no scheduled doses for the rest of today.',
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.l)),
                ],

                // --- 7. MEDICINE LIST ---
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: HomeMedsHeader(onAdd: widget.onScan)),
                  ),
                ),
                if (meds.isEmpty)
                  SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding),
                      sliver: SliverToBoxAdapter(
                          child: HomeMedsEmptyState(onAdd: widget.onScan)))
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
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
                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
          ),
        ),

        // --- FIXED HEADER ---
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

        // --- OVERLAY MODALS ---
        _buildOverlay(
            _showStreak,
            'streak',
            StreakModal(
              streak: streak,
              history: context.select<AppState, Map<String, List<DoseEntry>>>(
                  (s) => s.history),
              streakData:
                  context.select<AppState, StreakData>((s) => s.streakData),
              onClose: () => setState(() => _showStreak = false),
              onFreeze: () => context.read<AppState>().useStreakFreeze(),
            )),
        _buildOverlay(
            _showSettings,
            'settings',
            SettingsModal(
              onClose: () => setState(() => _showSettings = false),
            )),
      ]),
    );

    return AnimatedSwitcher(
      duration: 400.ms,
      switchInCurve: Curves.easeOutQuart,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
            position:
                Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
                    .animate(animation),
            child: child),
      ),
      child: _viewingMed != null
          ? MedicineDetailScreen(
              key: ValueKey('med_detail_${_viewingMed!.id}'),
              medId: _viewingMed!.id,
              onBack: () => setState(() => _viewingMed = null),
              initialEditMode: _startInEditMode)
          : Container(key: const ValueKey('home_main'), child: mainContent),
    );
  }

  Widget _sliverStaggerDown(List<Widget> children, {required Duration delay}) {
    final validChildren = children.where((c) => c is! SizedBox).toList();
    if (validChildren.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s),
            child: validChildren[index],
          )
              .animate()
              .fadeIn(delay: delay + (index * 100).ms, duration: 600.ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
          childCount: validChildren.length,
        ),
      ),
    );
  }

  Widget _buildOverlay(bool visible, String key, Widget child) {
    return AnimatedSwitcher(
      duration: 350.ms,
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
            position:
                Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
                    .animate(anim),
            child: child),
      ),
      child: visible
          ? SizedBox.expand(key: ValueKey(key), child: child)
          : const SizedBox.shrink(),
    );
  }

  List<Widget> _buildGroupedTimelineSlivers(
      BuildContext context,
      List<DoseItem> doses,
      Map<String, bool> takenToday,
      AppState state,
      AppThemeColors L) {
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

    final out = <Widget>[];
    int groupIdx = 0;
    groups.forEach((key, list) {
      if (list.isNotEmpty) {
        out.add(SliverPadding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding, vertical: 8),
          sliver: SliverToBoxAdapter(
            child: HomeDoseGroup(
              title: key,
              doses: list,
              takenToday: takenToday,
              state: state,
              onView: (med) => setState(() {
                _viewingMed = med;
                _startInEditMode = false;
              }),
              onEdit: (med) => setState(() {
                _viewingMed = med;
                _startInEditMode = true;
              }),
              delayOffset: (groupIdx * 150).ms,
            ),
          ),
        ));
        groupIdx++;
      }
    });
    return out;
  }
}

class HomeDoseGroup extends StatelessWidget {
  final String title;
  final List<DoseItem> doses;
  final Map<String, bool> takenToday;
  final AppState state;
  final Function(Medicine) onView;
  final Function(Medicine) onEdit;
  final Duration delayOffset;

  const HomeDoseGroup({
    super.key,
    required this.title,
    required this.doses,
    required this.takenToday,
    required this.state,
    required this.onView,
    required this.onEdit,
    this.delayOffset = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: L.sub,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ...doses.asMap().entries.map((entry) {
          final idx = entry.key;
          final d = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MedCard(
              med: d.med,
              onView: () => onView(d.med),
              onEdit: () => onEdit(d.med),
            )
                .animate(delay: delayOffset + (idx * 50).ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
          );
        }),
      ],
    );
  }
}
