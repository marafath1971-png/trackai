import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../core/utils/haptic_engine.dart';
import 'widgets/home_meds_section.dart';
import 'widgets/med_card.dart';

import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/common/premium_empty_state.dart';
import 'widgets/home_header.dart';
import 'widgets/streak_modal.dart';
import 'widgets/settings_modal_new.dart';
import '../medicine/medicine_detail_screen.dart';


class HomeTab extends StatefulWidget {
  final VoidCallback onScan;
  final ValueChanged<int>? onSwitchTab;
  const HomeTab({super.key, required this.onScan, this.onSwitchTab});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _showStreak = false;
  bool _showSettings = false;
  Medicine? _viewingMed;
  bool _startInEditMode = false;
  double _scrollOffset = 0;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _medsHeaderKey = GlobalKey();
  final GlobalKey _medsEmptyKey = GlobalKey();

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
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  void _openStreak() => setState(() => _showStreak = true);

  void _scrollToMeds() {
    final state = context.read<AppState>();
    final targetKey = state.meds.isEmpty ? _medsEmptyKey : _medsHeaderKey;
    final contextObj = targetKey.currentContext;

    if (contextObj != null) {
      Scrollable.ensureVisible(
        contextObj,
        duration: 800.ms,
        curve: Curves.easeOutQuart,
        alignment: 0.1,
      );
    } else {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: 600.ms,
        curve: Curves.easeOutQuart,
      );
    }
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
        body: Stack(
      children: [
          RefreshIndicator(
          onRefresh: () async {
            HapticEngine.selection();
            await context.read<AppState>().loadFromStorage();
          },
          displacement: 110,
          color: L.text,
          backgroundColor: L.bg,
          child: Scrollbar(
            controller: _scrollController,
            child: CustomScrollView(
              controller: _scrollController,
              key: const PageStorageKey('home_scroll'),
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                // -- TOP SPACER --
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.of(context).padding.top + 76),
                ),

                // --- WEEK STRIP ---
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: HomeWeekStrip(
                      state: context.read<AppState>(),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
                  ),
                ),

                // --- HERO STAT CARD ---
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: _HeroProgressCard(
                      doses: doses,
                      takenCount: takenCount,
                      remaining: remaining,
                      dosePct: dosePct,
                      ringCol: ringCol,
                      streak: streak,
                      medsCount: meds.length,
                      L: L,
                    )
                        .animate()
                        .fadeIn(duration: 700.ms, delay: 100.ms)
                        .slideY(begin: 0.04, end: 0, curve: Curves.easeOutExpo),
                  ),
                ),

                // --- HEALTH SNAPSHOT ---
                if (context.select<AppState, bool>((s) => s.health.isConnected))
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: _HealthSnapshotCard(
                      steps: context.select<AppState, double>((s) => s.health.steps),
                      heartRate: context.select<AppState, double>((s) => s.health.heartRate),
                      isSyncing: context.select<AppState, bool>((s) => s.health.isSyncing),
                      L: L,
                    )
                        .animate()
                        .fadeIn(duration: 700.ms, delay: 120.ms)
                        .slideY(begin: 0.04, end: 0, curve: Curves.easeOutExpo),
                  ),
                ),

                // --- SMART ALERTS ---
                if (context.read<AppState>().missedAlerts.any((a) => !a.seen) ||
                      context.read<AppState>().interactionWarning != null ||
                      context.read<AppState>().getLowMeds().where((m) => m.count < 3).isNotEmpty ||
                      context.read<AppState>().getStreak() == 0)
                _sliverStaggerDown([
                    _HomeAlertHub(state: context.read<AppState>(), L: L, onScrollToMeds: _scrollToMeds, onOpenStreak: _openStreak),
                ], delay: 150.ms),

                // --- TODAY'S SCHEDULE ---
                if (doses.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding,
                        AppSpacing.l, AppSpacing.screenPadding, AppSpacing.s),
                    sliver: SliverToBoxAdapter(
                      child: Text('Today\'s schedule',
                          style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: L.sub.withValues(alpha: 0.55),
                              letterSpacing: 0,
                              fontSize: 13)),
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
                        title: 'All caught up',
                        subtitle:
                            'No scheduled doses remaining for today.',
                        icon: Icons.check_circle_outline_rounded,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.l)),
                ],

                // --- MEDICINE LIST ---
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: HomeMedsHeader(
                          key: _medsHeaderKey,
                          onAdd: widget.onScan,
                        )),
                  ),
                ),
                if (meds.isEmpty)
                  SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding),
                      sliver: SliverToBoxAdapter(
                          child: HomeMedsEmptyState(
                        key: _medsEmptyKey,
                        onAdd: widget.onScan,
                      )))
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
                const SliverToBoxAdapter(child: SizedBox(height: 180)),
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
            scrollOffset: _scrollOffset,
            onTap: _scrollToTop,
            onOpenStreak: () => setState(() => _showStreak = true),
            onOpenSettings: () => setState(() => _showSettings = true),
          ),
        ),

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
      switchInCurve: Curves.easeOutExpo,
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
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOutExpo),
          childCount: validChildren.length,
        ),
      ),
    );
  }

  Widget _buildOverlay(bool visible, String key, Widget child) {
    return AnimatedSwitcher(
      duration: 350.ms,
      switchInCurve: Curves.easeOutExpo,
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
              globalNextEntryKey: doses.firstWhere((d) => takenToday[d.key] != true, orElse: () => doses.last).key,
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

// ─────────────────────────────────────────────────────────────
// HERO PROGRESS CARD — Single focused metric
// ─────────────────────────────────────────────────────────────
class _HeroProgressCard extends StatelessWidget {
  final List<DoseItem> doses;
  final int takenCount;
  final int remaining;
  final double dosePct;
  final Color ringCol;
  final int streak;
  final int medsCount;
  final AppThemeColors L;

  const _HeroProgressCard({
    required this.doses,
    required this.takenCount,
    required this.remaining,
    required this.dosePct,
    required this.ringCol,
    required this.streak,
    required this.medsCount,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = doses.isEmpty
        ? 'No doses today'
        : dosePct == 1.0
            ? 'All caught up'
            : remaining == 1
                ? '1 dose pending'
                : '$remaining doses pending';

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doses.isEmpty
                          ? 'Today'
                          : '$takenCount of ${doses.length} taken',
                      style: AppTypography.displaySmall.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statusLabel.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: L.sub.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              RingChart(
                percent: dosePct,
                size: 80,
                color: dosePct == 1.0 ? L.success : L.text,
                label: doses.isEmpty ? '—' : '${(dosePct * 100).toInt()}%',
                sub: 'DOSE',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _MetaItem(
                icon: Icons.local_fire_department_rounded,
                label: 'Streak',
                value: '$streak',
                L: L,
              ),
              const SizedBox(width: 28),
              _MetaItem(
                icon: Icons.medication_rounded,
                label: 'Meds',
                value: '$medsCount',
                L: L,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppThemeColors L;
  const _MetaItem({required this.icon, required this.label, required this.value, required this.L});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: L.fill.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 14, color: L.sub.withValues(alpha: 0.65)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.labelSmall.copyWith(color: L.sub.withValues(alpha: 0.45), fontSize: 10, fontWeight: FontWeight.w700)),
            Text(value, style: AppTypography.labelMedium.copyWith(color: L.text, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: -0.2)),
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------
// SMART ALERT HUB
// ------------------------------------------------------------------
class _HomeAlertHub extends StatelessWidget {
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onScrollToMeds;
  final VoidCallback onOpenStreak;

  const _HomeAlertHub({
    required this.state,
    required this.L,
    required this.onScrollToMeds,
    required this.onOpenStreak,
  });

  @override
  Widget build(BuildContext context) {
    final missed = state.missedAlerts.where((a) => !a.seen).toList();
    final lowMeds = state.getLowMeds().where((m) => m.count < 3).toList();
    final interaction = state.interactionWarning;

    return Column(
      children: [
        if (interaction != null)
          _AlertTile(
            title: 'Drug interaction detected',
            content: interaction,
            icon: Icons.warning_amber_rounded,
            color: L.error,
            L: L,
            onTap: () => HapticEngine.selection(),
          ),
        if (missed.isNotEmpty)
          _AlertTile(
            title: 'Missed doses',
            content: missed.length == 1
                ? 'You have 1 dose pending review.'
                : 'You have ${missed.length} doses pending review.',
            icon: Icons.history_rounded,
            color: L.error,
            L: L,
            onTap: onScrollToMeds,
          ),
        if (lowMeds.isNotEmpty)
          _AlertTile(
            title: 'Low supply',
            content: lowMeds.length == 1
                ? '${lowMeds.first.name} is almost empty.'
                : '${lowMeds.length} medicines need a refill.',
            icon: Icons.inventory_2_rounded,
            color: L.warning,
            L: L,
            onTap: onScrollToMeds,
          ),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;
  final AppThemeColors L;
  final VoidCallback onTap;

  const _AlertTile({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
    required this.L,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SquircleCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      content,
                      style: AppTypography.bodyMedium.copyWith(
                        color: L.text.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: L.sub.withValues(alpha: 0.3), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HEALTH SNAPSHOT CARD — Steps, Heart Rate, etc.
// ─────────────────────────────────────────────────────────────
class _HealthSnapshotCard extends StatelessWidget {
  final double steps;
  final double heartRate;
  final bool isSyncing;
  final AppThemeColors L;

  const _HealthSnapshotCard({
    required this.steps,
    required this.heartRate,
    required this.isSyncing,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HEALTH SNAPSHOT',
                style: AppTypography.labelSmall.copyWith(
                  color: L.sub.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 10,
                ),
              ),
              if (isSyncing)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
                )
              else
                Icon(Icons.sync_rounded, size: 14, color: L.sub.withValues(alpha: 0.3)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HealthMetric(
                  icon: Icons.directions_run_rounded,
                  label: 'Steps',
                  value: steps.toInt().toString(),
                  unit: 'today',
                  color: const Color(0xFF34C759),
                  L: L,
                ),
              ),
              Container(width: 1, height: 40, color: L.border.withValues(alpha: 0.1)),
              Expanded(
                child: _HealthMetric(
                  icon: Icons.favorite_rounded,
                  label: 'Heart Rate',
                  value: heartRate > 0 ? heartRate.toInt().toString() : '--',
                  unit: 'bpm',
                  color: const Color(0xFFFF2D55),
                  L: L,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final AppThemeColors L;

  const _HealthMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label, style: AppTypography.labelSmall.copyWith(color: L.sub.withValues(alpha: 0.45), fontSize: 10, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppTypography.displaySmall.copyWith(color: L.text, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5)),
              const SizedBox(width: 4),
              Text(unit, style: AppTypography.bodySmall.copyWith(color: L.sub.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DOSE GROUP — grouped timeline section
// ─────────────────────────────────────────────────────────────
class HomeDoseGroup extends StatefulWidget {
  final String title;
  final List<DoseItem> doses;
  final Map<String, bool> takenToday;
  final String? globalNextEntryKey;
  final AppState state;
  final Function(Medicine) onView;
  final Function(Medicine) onEdit;
  final Duration delayOffset;

  const HomeDoseGroup({
    super.key,
    required this.title,
    required this.doses,
    required this.takenToday,
    this.globalNextEntryKey,
    required this.state,
    required this.onView,
    required this.onEdit,
    this.delayOffset = Duration.zero,
  });

  @override
  State<HomeDoseGroup> createState() => _HomeDoseGroupState();
}

class _HomeDoseGroupState extends State<HomeDoseGroup> {
  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final now = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            widget.title,
            style: AppTypography.labelMedium.copyWith(
              color: L.sub.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              fontSize: 13,
            ),
          ),
        ),
        ...widget.doses.asMap().entries.map((entry) {
          final idx = entry.key;
          final d = entry.value;
          final isTaken = widget.takenToday[d.key] == true;
          final doseMins = d.sched.h * 60 + d.sched.m;
          final isOverdue = !isTaken && doseMins < nowMins;
          final isActualNext = d.key == widget.globalNextEntryKey;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DoseCard(
              med: d.med,
              sched: d.sched,
              taken: isTaken,
              overdue: isOverdue,
              isNext: isActualNext && !isTaken,
              onTake: () {
                widget.state.toggleDose(d);
                _showUndoSnackbar(context, d);
              },
              onSnooze: () => widget.state.snoozeDose(d, 30),
              onTap: () => widget.onView(d.med),
            )
                .animate(delay: widget.delayOffset + (idx * 50).ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
          );
        }),
      ],
    );
  }

  void _showUndoSnackbar(BuildContext context, DoseItem d) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${d.med.name} marked as taken'),
        showCloseIcon: true,
        closeIconColor: Colors.white70,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => widget.state.toggleDose(d),
          textColor: context.L.primary,
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      ),
    );
  }
}
