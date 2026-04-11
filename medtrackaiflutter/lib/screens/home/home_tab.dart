import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../core/utils/haptic_engine.dart';
import 'widgets/home_meds_section.dart';
import 'widgets/med_card.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'widgets/home_header.dart';
import 'widgets/streak_modal.dart';
import 'widgets/settings_modal_new.dart';
import 'widgets/profile_selector_ribbon.dart';
import 'widgets/voice_assistant_overlay.dart';
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
  DateTime _selectedDate = DateTime.now();
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

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: 800.ms,
      curve: Curves.easeOutQuart,
    );
    HapticEngine.selection();
  }

  void _setDate(DateTime date) {
    if (date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day) {
      return;
    }
    HapticEngine.selection();
    setState(() => _selectedDate = date);
  }

  Widget _buildMainDashboard(
    BuildContext context,
    AppThemeColors L,
    List<DoseItem> doses,
    int streak,
    Map<String, bool> takenMap,
    List<Medicine> meds,
    int takenCount,
    int remaining,
    double dosePct,
  ) {
    return Stack(
      children: [
        // ── CLINICAL BASE ──
        Container(color: L.meshBg),
        Positioned.fill(
          child: RefreshIndicator(
            onRefresh: () async {
              HapticEngine.selection();
              await context.read<AppState>().loadFromStorage();
            },
            displacement: 110,
            color: L.bg,
            backgroundColor: L.text,
            strokeWidth: 2.5,
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
                    child: SizedBox(
                        height: MediaQuery.of(context).padding.top + 50),
                  ),

                  // --- FAMILY PROFILE RIBBON ---
                  SliverToBoxAdapter(
                    child: const ProfileSelectorRibbon()
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .scale(
                            begin: const Offset(0.98, 0.98),
                            end: const Offset(1, 1),
                            curve: Curves.easeOutCubic),
                  ),

                  // --- DAY TOGGLE (Today | Yesterday) ---
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    sliver: SliverToBoxAdapter(
                      child: _DayToggle(
                        selectedDate: _selectedDate,
                        onChanged: _setDate,
                      ),
                    ),
                  ),

                  // --- MAIN PROGRESS BENTO (Large Card) ---
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    sliver: SliverToBoxAdapter(
                      child: _MainProgressCard(
                        remaining: remaining,
                        dosePct: dosePct,
                      ).animate().fadeIn(duration: 800.ms).slideY(
                          begin: 0.08, end: 0, curve: Curves.easeOutExpo),
                    ),
                  ),

                  // --- STAT CARDS ROW ---
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    sliver: SliverToBoxAdapter(
                      child: _StatRow(
                        takenCount: takenCount,
                        remaining: remaining,
                        streak: streak,
                      )
                          .animate()
                          .fadeIn(duration: 800.ms, delay: 100.ms)
                          .slideY(
                              begin: 0.08, end: 0, curve: Curves.easeOutExpo),
                    ),
                  ),

                  // --- ADHERENCE SCORE CARD ---
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    sliver: SliverToBoxAdapter(
                      child: _AdherenceScoreCard(
                        dosePct: dosePct,
                        doses: doses,
                        takenCount: takenCount,
                      )
                          .animate()
                          .fadeIn(duration: 800.ms, delay: 200.ms)
                          .slideY(
                              begin: 0.08, end: 0, curve: Curves.easeOutExpo),
                    ),
                  ),

                  // --- DOSE TIMELINE ---
                  if (doses.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final groups = [
                              (
                                title: 'Morning',
                                items: doses
                                    .where(
                                        (d) => d.sched.h >= 5 && d.sched.h < 11)
                                    .toList()
                              ),
                              (
                                title: 'Afternoon',
                                items: doses
                                    .where((d) =>
                                        d.sched.h >= 11 && d.sched.h < 17)
                                    .toList()
                              ),
                              (
                                title: 'Evening',
                                items: doses
                                    .where((d) =>
                                        d.sched.h >= 17 && d.sched.h < 21)
                                    .toList()
                              ),
                              (
                                title: 'Night',
                                items: doses
                                    .where(
                                        (d) => d.sched.h >= 21 || d.sched.h < 5)
                                    .toList()
                              ),
                            ].where((g) => g.items.isNotEmpty).toList();

                            if (index >= groups.length) return null;
                            final group = groups[index];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: HomeDoseGroup(
                                title: group.title,
                                doses: group.items,
                                takenToday: takenMap,
                                state: context.read<AppState>(),
                                selectedDate: _selectedDate,
                                onView: (med) => setState(() {
                                  _viewingMed = med;
                                  _startInEditMode = false;
                                }),
                                onEdit: (med) => setState(() {
                                  _viewingMed = med;
                                  _startInEditMode = true;
                                }),
                              ),
                            );
                          },
                          childCount: 4, // Max groups
                        ),
                      ),
                    ),

                  // --- NEXT DOSE CAROUSEL (Mini condensed preview) ---
                  if (doses.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverToBoxAdapter(
                        child: _NextDoseCarousel(
                          doses: doses,
                          takenToday: takenMap,
                          state: context.read<AppState>(),
                          onView: (med) => setState(() {
                            _viewingMed = med;
                            _startInEditMode = false;
                          }),
                        )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 300.ms)
                            .slideY(
                                begin: 0.08, end: 0, curve: Curves.easeOutExpo),
                      ),
                    ),

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
                              onView: () {
                                HapticEngine.selection();
                                setState(() {
                                  _viewingMed = med;
                                  _startInEditMode = false;
                                });
                              },
                              onEdit: () {
                                HapticEngine.selection();
                                setState(() {
                                  _viewingMed = med;
                                  _startInEditMode = true;
                                });
                              },
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

        const VoiceAssistantOverlay(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final doses = context.select<AppState, List<DoseItem>>(
        (s) => s.getDoses(date: _selectedDate));
    final streak = context.select<AppState, int>((s) => s.getStreak());
    final takenMap = context.select<AppState, Map<String, bool>>(
        (s) => s.getTakenMapForDate(_selectedDate));
    final meds = context.select<AppState, List<Medicine>>((s) => s.meds);

    final takenCount = doses.where((d) => takenMap[d.key] == true).length;
    final remaining = doses.length - takenCount;
    final dosePct = doses.isNotEmpty ? takenCount / doses.length : 0.0;

    final L = context.L;

    final mainContent = _buildMainDashboard(context, L, doses, streak, takenMap,
        meds, takenCount, remaining, dosePct);

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
}

// ─────────────────────────────────────────────────────────────
// FAST TRACKING BENTO — Cal AI 2026 Premium Bento Grid
// ─────────────────────────────────────────────────────────────
class _FastTrackingBento extends StatelessWidget {
  final List<DoseItem> doses;
  final int takenCount;
  final int remaining;
  final double dosePct;
  final int streak;

  const _FastTrackingBento({
    required this.doses,
    required this.takenCount,
    required this.remaining,
    required this.dosePct,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final noDoses = doses.isEmpty;
    final L = context.L;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            L.card,
            L.card.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: L.border.withValues(alpha: 0.08), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: noDoses ? '0' : '$takenCount',
                  label: 'Taken',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF10B981),
                  gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: noDoses ? '0' : '$remaining',
                  label: 'Remaining',
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFFF59E0B),
                  gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StreakCard(streak: streak),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final List<Color> gradient;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradient[0].withValues(alpha: 0.15),
            gradient[1].withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: gradient[0].withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: L.text,
                    height: 1,
                  ),
                ),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: L.sub.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final progress = (streak / 30).clamp(0.0, 1.0);
    final isOnFire = streak >= 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isOnFire
              ? [
                  const Color(0xFFEF4444).withValues(alpha: 0.15),
                  const Color(0xFFF59E0B).withValues(alpha: 0.05)
                ]
              : [L.card, L.card.withValues(alpha: 0.5)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnFire
              ? const Color(0xFFEF4444).withValues(alpha: 0.3)
              : L.border.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: L.border.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(
                      isOnFire
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF59E0B),
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Icon(
                  isOnFire
                      ? Icons.local_fire_department_rounded
                      : Icons.local_fire_department_outlined,
                  color: isOnFire
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFF59E0B),
                  size: 24,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$streak day${streak == 1 ? '' : 's'}',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: L.text,
                      ),
                    ),
                    if (isOnFire) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ON FIRE',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isOnFire
                      ? 'Amazing consistency! Keep it up!'
                      : '${30 - streak} days to badge milestone',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: L.sub.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: L.sub.withValues(alpha: 0.3),
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  final double pct;
  final Color color;
  final Color track;
  _MiniRingPainter(
      {required this.pct, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width - 7) / 2;
    final trackPaint = Paint()
      ..color = track
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx, cy), r, trackPaint);
    if (pct > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -3.14159 / 2,
        2 * 3.14159 * pct,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniRingPainter old) => old.pct != pct;
}

// ─────────────────────────────────────────────────────────────
// ADHERENCE SCORE CARD — Cal AI 2026 Premium Health Score
// ─────────────────────────────────────────────────────────────
class _AdherenceScoreCard extends StatelessWidget {
  final double dosePct;
  final List<DoseItem> doses;
  final int takenCount;

  const _AdherenceScoreCard({
    required this.dosePct,
    required this.doses,
    required this.takenCount,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final score = doses.isEmpty ? 0 : (dosePct * 10).round();
    final isPerfect = dosePct >= 1.0;
    final isGood = dosePct >= 0.7;

    final Color accentColor;
    final List<Color> gradColors;
    final IconData statusIcon;
    final String statusLabel;
    final String message;

    if (doses.isEmpty) {
      accentColor = L.sub;
      gradColors = [L.card, L.card];
      statusIcon = Icons.add_circle_outline;
      statusLabel = 'Get Started';
      message = "Add medications to start tracking your health consistency.";
    } else if (isPerfect) {
      accentColor = const Color(0xFF10B981);
      gradColors = [const Color(0xFF10B981), const Color(0xFF059669)];
      statusIcon = Icons.health_and_safety_rounded;
      statusLabel = 'Excellent';
      message =
          "Perfect adherence! Your consistency is maintaining optimal treatment outcomes.";
    } else if (isGood) {
      accentColor = const Color(0xFFF59E0B);
      gradColors = [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      statusIcon = Icons.trending_up_rounded;
      statusLabel = 'Good';
      message =
          "Good progress! Keep focusing on timely medication for best results.";
    } else {
      accentColor = const Color(0xFFEF4444);
      gradColors = [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      statusIcon = Icons.warning_amber_rounded;
      statusLabel = 'Needs Work';
      message =
          "Some doses missed. Focus on consistency for effective treatment.";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: L.glassBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: gradColors[0].withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: gradColors[0].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: gradColors[0].withValues(alpha: 0.2), width: 0.5),
                ),
                child: Icon(statusIcon, color: gradColors[0], size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: gradColors[0],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: L.card,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: gradColors[0].withValues(alpha: 0.3), width: 2),
                ),
                child: Center(
                  child: Text(
                    '$score',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: gradColors[0],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: L.border.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: dosePct.clamp(0.01, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradColors),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: gradColors[0].withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(statusIcon, size: 16, color: L.sub.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(
                    color: L.sub.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NEXT DOSE CAROUSEL — Cal AI "Recently uploaded" style card
// ─────────────────────────────────────────────────────────────
// NEXT DOSE CAROUSEL — Cal AI "Recently uploaded" style card
// ─────────────────────────────────────────────────────────────
class _NextDoseCarousel extends StatelessWidget {
  final List<DoseItem> doses;
  final Map<String, bool> takenToday;
  final AppState state;
  final Function(Medicine) onView;

  const _NextDoseCarousel({
    required this.doses,
    required this.takenToday,
    required this.state,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final upcoming = doses.where((d) => takenToday[d.key] != true).toList();
    final toShow =
        upcoming.isEmpty ? doses.take(3).toList() : upcoming.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('Coming Up Next',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: L.text,
              )),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: toShow.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final d = toShow[index];
              final isTaken = takenToday[d.key] == true;
              final timeStr =
                  '${d.sched.h.toString().padLeft(2, '0')}:${d.sched.m.toString().padLeft(2, '0')}';

              return BouncingButton(
                onTap: () => onView(d.med),
                child: Container(
                  width: 240,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: L.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: L.text.withValues(alpha: 0.04), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: L.text,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text('💊', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(d.med.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: L.text,
                                  fontSize: 14,
                                )),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(timeStr,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: L.sub.withValues(alpha: 0.4),
                                      fontWeight: FontWeight.w800,
                                    )),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: L.text.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('UNTAKEN',
                                      style: AppTypography.labelSmall.copyWith(
                                        fontSize: 7,
                                        fontWeight: FontWeight.w900,
                                        color: L.sub.withValues(alpha: 0.3),
                                      )),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ANIMATED RING PAINTER — CustomPainter arc (kept for possible reuse)
// ─────────────────────────────────────────────────────────────
class _AnimatedRing extends StatefulWidget {
  final double percent;
  final Color color;
  final Color trackColor;
  final double size;
  final double strokeWidth;
  final Widget child;

  const _AnimatedRing({
    required this.percent,
    required this.color,
    required this.trackColor,
    required this.size,
    required this.strokeWidth,
    required this.child,
  });

  @override
  State<_AnimatedRing> createState() => _AnimatedRingState();
}

class _AnimatedRingState extends State<_AnimatedRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = Tween<double>(begin: 0, end: widget.percent)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedRing old) {
    super.didUpdateWidget(old);
    if (old.percent != widget.percent) {
      _anim = Tween<double>(begin: _anim.value, end: widget.percent)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _RingPainter(
              percent: _anim.value,
              color: widget.color,
              trackColor: widget.trackColor,
              strokeWidth: widget.strokeWidth,
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.percent,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -1.5707963267948966; // -π/2 (top)
    final sweepAngle = 2 * 3.14159265358979323846 * percent;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * 3.14159265358979323846,
      false,
      Paint()
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (percent > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);

      // Outer Glow
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..strokeWidth = strokeWidth + 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
      );

      // Progress arc
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.percent != percent || old.color != color;
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
  final DateTime selectedDate;
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
    required this.selectedDate,
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
                widget.state.toggleDose(d, date: widget.selectedDate);
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
          onPressed: () =>
              widget.state.toggleDose(d, date: widget.selectedDate),
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

class _IndustrialGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw some dots at intersections
    final dotPaint = Paint()..color = Colors.black;
    for (double i = 0; i < size.width; i += spacing * 2) {
      for (double j = 0; j < size.height; j += spacing * 2) {
        canvas.drawCircle(Offset(i, j), 1.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// DAY TOGGLE — Cal AI style segment control
// ─────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────
// MAIN PROGRESS CARD — Large industrial tracking unit
// ─────────────────────────────────────────────────────────────
class _MainProgressCard extends StatelessWidget {
  final int remaining;
  final double dosePct;

  const _MainProgressCard({required this.remaining, required this.dosePct});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      height: 160,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            L.card,
            L.card.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: L.glassBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: L.text.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$remaining',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: L.text,
                  height: 1,
                  letterSpacing: -3,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: L.text.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'DOSES REMAINING',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: L.sub.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          _AnimatedRing(
            percent: dosePct,
            color: const Color(0xFF1C1C1E),
            trackColor: L.text.withValues(alpha: 0.05),
            size: 100,
            strokeWidth: 12,
            child: Icon(
              Icons.local_fire_department_rounded,
              color: L.text,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STAT ROW — Row of 3 mini circular stat cards
// ─────────────────────────────────────────────────────────────
class _StatRow extends StatelessWidget {
  final int takenCount;
  final int remaining;
  final int streak;

  const _StatRow({
    required this.takenCount,
    required this.remaining,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            value: '$takenCount',
            label: 'Taken',
            icon: Icons.check_circle_outline_rounded,
            accent: const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatItem(
            value: '$remaining',
            label: 'Ready',
            icon: Icons.access_time_rounded,
            accent: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatItem(
            value: '$streak',
            label: 'Streak',
            icon: Icons.local_fire_department_rounded,
            accent: const Color(0xFF3B82F6),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color accent;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: L.glassBorder, width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.displayLarge.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: L.text,
              letterSpacing: -1,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: L.sub.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 14),
          _AnimatedRing(
            percent: 0.75, // Intentional visual baseline
            color: accent,
            trackColor: accent.withValues(alpha: 0.1),
            size: 36,
            strokeWidth: 4,
            child: Icon(icon, color: accent, size: 14),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DAY TOGGLE — Cal AI style switcher
// ─────────────────────────────────────────────────────────────
class _DayToggle extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  const _DayToggle({required this.selectedDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final isToday = selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: L.meshBg == Colors.white
            ? const Color(0xFFF3F4F6)
            : L.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border.withValues(alpha: 0.05), width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final halfWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: 350.ms,
                curve: Curves.easeOutBack,
                top: 4,
                bottom: 4,
                left: isToday ? 4 : halfWidth,
                width: halfWidth - 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: L.text,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticEngine.selection();
                        onChanged(today);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: 250.ms,
                          style: AppTypography.labelLarge.copyWith(
                            color:
                                isToday ? L.bg : L.text.withValues(alpha: 0.6),
                            fontWeight:
                                isToday ? FontWeight.w900 : FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          child: const Text('Today'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticEngine.selection();
                        onChanged(yesterday);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: 250.ms,
                          style: AppTypography.labelLarge.copyWith(
                            color:
                                !isToday ? L.bg : L.text.withValues(alpha: 0.6),
                            fontWeight:
                                !isToday ? FontWeight.w900 : FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          child: const Text('Yesterday'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.1, end: 0, curve: Curves.easeOutExpo);
  }
}
