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

import '../../core/utils/haptic_engine.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'widgets/home_meds_section.dart';
import 'widgets/med_card.dart';
import 'widgets/home_dose_section.dart';

import '../../widgets/common/premium_empty_state.dart';
import '../../widgets/common/mesh_gradient.dart';
import '../../widgets/common/bouncing_button.dart';
import '../../widgets/modals/daily_log_sheet.dart';


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
  void _openSettings() => setState(() => _showSettings = true);

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
        body: Stack(
      children: [
        // ── MESH GRADIENT BACKGROUND ──
        Positioned.fill(
          child: MeshGradient(
            colors: [
              L.primary.withValues(alpha: 0.08),
              L.bg,
              const Color(0xFFF0F4FF), // Subtle cool tint
              L.primary.withValues(alpha: 0.03),
            ],
          ),
        ),

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
                // --- 0. HEADER SPACER (SUMMARIZED) ---
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.of(context).padding.top + 150),
                ),

                // --- 1. MINIMALIST BENTO HEADER ---
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 8, AppSpacing.screenPadding, 12),
                  sliver: SliverToBoxAdapter(
                    child: _HomeBentoHeader(
                      state: context.read<AppState>(),
                      doses: doses,
                      takenCount: takenCount,
                      remaining: remaining,
                      dosePct: dosePct,
                      ringCol: ringCol,
                      L: L,
                    )
                        .animate()
                        .fadeIn(duration: 800.ms)
                        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuart),
                  ),
                ),

                // --- 2. CONSOLIDATED ALERTS (SMART TRIGGER) ---
                _sliverStaggerDown([
                  if (context.select<AppState, bool>((s) => s.missedAlerts.any((a) => !a.seen)) ||
                      context.select<AppState, String?>((s) => s.interactionWarning) != null ||
                      context.select<AppState, List<Medicine>>((s) => s.getLowMeds()).where((m) => m.count < 3).isNotEmpty ||
                      context.select<AppState, int>((s) => s.getStreak()) == 0)
                    _HomeAlertHub(state: context.read<AppState>(), L: L, onScrollToMeds: _scrollToMeds, onOpenStreak: _openStreak),
                ], delay: 150.ms),

                // --- 4. WELLNESS SNAPSHOT ---
                _sliverStaggerDown([
                  _WellnessSnapshot(state: context.read<AppState>(), L: L),
                ], delay: 400.ms),

                // --- 5. QUICK ACTIONS ---
                _sliverStaggerDown([
                  _QuickActionRow(
                    onLogSymptom: () => DailyLogSheet.show(context),
                    onAddDose: () => DailyLogSheet.show(context),
                    onViewReports: () => widget.onSwitchTab?.call(2),
                  ),
                ], delay: 450.ms),

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
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
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

// ─────────────────────────────────────────────────────────────
// HOME BENTO HEADER (Minimalist Stats)
// ─────────────────────────────────────────────────────────────
class _HomeBentoHeader extends StatelessWidget {
  final AppState state;
  final List<DoseItem> doses;
  final int takenCount;
  final int remaining;
  final double dosePct;
  final Color ringCol;
  final AppThemeColors L;

  const _HomeBentoHeader({
    required this.state,
    required this.doses,
    required this.takenCount,
    required this.remaining,
    required this.dosePct,
    required this.ringCol,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    final streak = state.getStreak();
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
                children: [
                  // ── MAIN PROGRESS CARD ──
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: L.text,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(color: L.text.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 20))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TREATMENT ADHERENCE',
                                style: AppTypography.labelSmall.copyWith(color: L.bg.withValues(alpha: 0.5), letterSpacing: 1.5, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${(dosePct * 100).toInt()}% Done',
                                  style: AppTypography.displaySmall.copyWith(color: L.bg, fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -1.0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: _SmallDoseIndicator(count: takenCount, label: 'Taken', color: L.bg, L: L)),
                              const SizedBox(width: 12),
                              Expanded(child: _SmallDoseIndicator(count: remaining, label: 'Remaining', color: L.bg.withValues(alpha: 0.4), L: L)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ── STREAK & STATS COLUMN ──
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _BentoMiniCard(
                          title: 'STREAK',
                          value: '$streak',
                          icon: '🔥',
                          color: Colors.orange.withValues(alpha: 0.1),
                          textColor: Colors.orange.shade800,
                          L: L,
                        ),
                        const SizedBox(height: 12),
                        _BentoMiniCard(
                          title: 'HEALTH',
                          value: '98%',
                          icon: '✨',
                          color: Colors.blue.withValues(alpha: 0.1),
                          textColor: Colors.blue.shade800,
                          L: L,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _BentoMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final String icon;
  final Color color;
  final Color textColor;
  final AppThemeColors L;

  const _BentoMiniCard({required this.title, required this.value, required this.icon, required this.color, required this.textColor, required this.L});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Text(title, style: AppTypography.labelSmall.copyWith(color: L.sub, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTypography.titleLarge.copyWith(color: L.text, fontWeight: FontWeight.w900, fontSize: 20)),
          ),
        ],
      ),
    );
  }
}

class _SmallDoseIndicator extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final AppThemeColors L;

  const _SmallDoseIndicator({required this.count, required this.label, required this.color, required this.L});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count',
          style: AppTypography.titleLarge.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: color.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w600),
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
    final streak = state.getStreak();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        children: [
          if (interaction != null)
            _ProfessionalAlertTile(
              title: 'Critical Warning',
              content: interaction,
              icon: Icons.warning_amber_rounded,
              color: L.error,
              L: L,
              onTap: () {},
            ),
          if (missed.isNotEmpty)
            _ProfessionalAlertTile(
              title: 'Missed Doses',
              content: 'You have ${missed.length} doses pending review. Tap to review.',
              icon: Icons.history_rounded,
              color: L.error,
              L: L,
              onTap: onScrollToMeds,
            ),
          if (lowMeds.isNotEmpty)
            _ProfessionalAlertTile(
              title: 'Low Supply',
              content: '${lowMeds.length} medications are almost empty.',
              icon: Icons.inventory_2_outlined,
              color: L.primary,
              L: L,
              onTap: onScrollToMeds,
            ),
        ],
      ),
    );
  }
}

class _ProfessionalAlertTile extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;
  final AppThemeColors L;
  final VoidCallback onTap;

  const _ProfessionalAlertTile({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
    required this.L,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: L.shadowSoft,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    content,
                    style: AppTypography.labelMedium.copyWith(
                      color: L.text.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: L.border, size: 20),
          ],
        ),
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final String label;
  final Color color;
  final AppThemeColors L;

  const _AlertItem({required this.label, required this.color, required this.L});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: L.text, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: L.sub.withValues(alpha: 0.3), size: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// QUICK ACTION ROW
// ─────────────────────────────────────────────────────────────
class _QuickActionRow extends StatelessWidget {
  final VoidCallback onLogSymptom;
  final VoidCallback onAddDose;
  final VoidCallback onViewReports;

  const _QuickActionRow({
    required this.onLogSymptom,
    required this.onAddDose,
    required this.onViewReports,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          _QuickActionButton(
            icon: Icons.edit_note_rounded,
            label: 'Log Symptom',
            subtitle: 'Track how you feel',
            onTap: onLogSymptom,
            L: L,
          ),
          const SizedBox(width: 12),
          _QuickActionButton(
            icon: Icons.medication_rounded,
            label: 'Extra Dose',
            subtitle: 'Log an unscheduled dose',
            onTap: onAddDose,
            L: L,
          ),
          const SizedBox(width: 12),
          _QuickActionButton(
            icon: Icons.bar_chart_rounded,
            label: 'Reports',
            subtitle: 'View analytics',
            onTap: onViewReports,
            L: L,
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final AppThemeColors L;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: L.border.withValues(alpha: 0.15)),
          boxShadow: L.shadowSoft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: L.text.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: L.text),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: L.text,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.labelSmall.copyWith(
                color: L.sub,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// WELLNESS SNAPSHOT
// ------------------------------------------------------------------
class _WellnessSnapshot extends StatelessWidget {
  final AppState state;
  final AppThemeColors L;

  const _WellnessSnapshot({required this.state, required this.L});

  @override
  Widget build(BuildContext context) {
    final streak = state.getStreak();
    final meds = state.meds;
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final todayEntries = state.history[todayKey] ?? [];
    final taken = todayEntries.where((d) => d.taken).length;
    final total = meds.fold<int>(0, (sum, m) => sum + m.schedule.where((s) => s.days.contains(today.weekday % 7)).length);
    final adherence = total > 0 ? (taken / total * 100).round() : 100;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          Expanded(child: _SnapTile(label: 'Adherence', value: '$adherence%', icon: Icons.show_chart_rounded, color: adherence >= 80 ? const Color(0xFF10B981) : L.warning, L: L)),
          const SizedBox(width: 10),
          Expanded(child: _SnapTile(label: 'Doses Left', value: '$total', icon: Icons.pending_actions_rounded, color: L.primary, L: L)),
          const SizedBox(width: 10),
          Expanded(child: _SnapTile(label: 'In Stock', value: '${meds.length}', icon: Icons.inventory_2_outlined, color: L.text.withValues(alpha: 0.7), L: L)),
        ],
      ),
    );
  }
}

class _SnapTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final AppThemeColors L;

  const _SnapTile({required this.label, required this.value, required this.icon, required this.color, required this.L});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: L.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w900,
              color: L.text,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: L.sub,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


class HomeDoseGroup extends StatefulWidget {
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
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            widget.title.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: L.sub,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ...widget.doses.asMap().entries.map((entry) {
          final idx = entry.key;
          final d = entry.value;
          final isTaken = widget.takenToday[d.key] == true;
          final doseMins = d.sched.h * 60 + d.sched.m;
          final isOverdue = !isTaken && doseMins < nowMins;
          
          final isNext = !isTaken && 
              !widget.doses.sublist(0, idx).any((prev) => widget.takenToday[prev.key] != true);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DoseCard(
              dose: d,
              taken: isTaken,
              overdue: isOverdue,
              isNext: isNext,
              L: L,
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
        action: SnackBarAction(
          label: 'UNDO',
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

