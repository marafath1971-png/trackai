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

  @override
  Widget build(BuildContext context) {
    final doses = context.select<AppState, List<DoseItem>>((s) => s.getDoses());
    final streak = context.select<AppState, int>((s) => s.getStreak());
    final takenToday =
        context.select<AppState, Map<String, bool>>((s) => s.takenToday);
    final meds = context.select<AppState, List<Medicine>>((s) => s.meds);

    final takenCount = doses.where((d) => takenToday[d.key] == true).length;
    final remaining = doses.length - takenCount;
    final dosePct = doses.isNotEmpty ? takenCount / doses.length : 0.0;

    final L = context.L;

    final mainContent = Scaffold(
      backgroundColor: L.meshBg, // Neumorphic: meshBg texture foundation
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              HapticEngine.selection();
              await context.read<AppState>().loadFromStorage();
            },
            displacement: 110,
            color: L.text,
            backgroundColor: Colors.white,
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
                        height: MediaQuery.of(context).padding.top + 76),
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

                  // --- WEEK STRIP ---
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                    sliver: SliverToBoxAdapter(
                      child: HomeWeekStrip(
                        state: context.read<AppState>(),
                      ).animate().fadeIn(duration: 600.ms).slideY(
                          begin: 0.05, end: 0, curve: Curves.easeOutCubic),
                    ),
                  ),

                  // --- FAST TRACKING BENTO (3 stat cards) ---
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverToBoxAdapter(
                      child: _FastTrackingBento(
                        doses: doses,
                        takenCount: takenCount,
                        remaining: remaining,
                        dosePct: dosePct,
                        streak: streak,
                      )
                          .animate()
                          .fadeIn(duration: 700.ms, delay: 100.ms)
                          .slideY(
                              begin: 0.04, end: 0, curve: Curves.easeOutExpo),
                    ),
                  ),

                  // --- ADHERENCE SCORE CARD ---
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverToBoxAdapter(
                      child: _AdherenceScoreCard(
                        dosePct: dosePct,
                        doses: doses,
                        takenCount: takenCount,
                      )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 150.ms)
                          .slideY(
                              begin: 0.04, end: 0, curve: Curves.easeOutExpo),
                    ),
                  ),

                  // --- NEXT DOSE CAROUSEL ---
                  if (doses.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverToBoxAdapter(
                        child: _NextDoseCarousel(
                          doses: doses,
                          takenToday: takenToday,
                          state: context.read<AppState>(),
                          onView: (med) => setState(() {
                            _viewingMed = med;
                            _startInEditMode = false;
                          }),
                        )
                            .animate()
                            .fadeIn(duration: 700.ms, delay: 200.ms)
                            .slideY(
                                begin: 0.04, end: 0, curve: Curves.easeOutExpo),
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
          
          const VoiceAssistantOverlay(),
        ],
      ),
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
// FAST TRACKING BENTO — 3 circular stat cards (Cal AI style)
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
    final skipped = noDoses ? 0 : doses.length - takenCount;
    final streakEmoji = streak > 10 ? '🔥' : (streak > 0 ? '✨' : '❄️');

    return Row(
      children: [
        Expanded(
            child: _TrackCard(
          emoji: '💊',
          topValue: noDoses ? '--' : '$takenCount',
          topUnit: 'taken',
          label: 'Doses\ntaken',
          ringPct: dosePct,
          ringColor: const Color(0xFF8B5CF6),
          ringTrack: const Color(0xFFEDE9FE),
        )),
        const SizedBox(width: 10),
        Expanded(
            child: _TrackCard(
          emoji: '⏳',
          topValue: noDoses ? '--' : '$skipped',
          topUnit: 'left',
          label: 'Doses\nleft',
          ringPct: noDoses ? 0 : (skipped / doses.length).clamp(0, 1),
          ringColor: const Color(0xFFEC4899),
          ringTrack: const Color(0xFFFCE7F3),
        )),
        const SizedBox(width: 10),
        Expanded(
            child: _TrackCard(
          emoji: streakEmoji,
          topValue: '$streak',
          topUnit: 'd',
          label: 'Day\nstreak',
          ringPct: (streak / 30).clamp(0, 1),
          ringColor: const Color(0xFFF59E0B),
          ringTrack: const Color(0xFFFEF3C7),
        )),
      ],
    );
  }
}

class _TrackCard extends StatelessWidget {
  final String emoji;
  final String topValue;
  final String topUnit;
  final String label;
  final double ringPct;
  final Color ringColor;
  final Color ringTrack;

  const _TrackCard({
    required this.emoji,
    required this.topValue,
    required this.topUnit,
    required this.label,
    required this.ringPct,
    required this.ringColor,
    required this.ringTrack,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return BouncingButton(
      onTap: () {
        HapticEngine.selection();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: L.border.withValues(alpha: 0.15), width: 1.5),
          boxShadow: AppShadows.glow(ringColor, intensity: 0.12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // ── Animated emoji ──
          Text(emoji, style: const TextStyle(fontSize: 22))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.2, 1.2),
                duration: 1800.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 8),
          // ── Value + unit ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(topValue,
                  style: AppTypography.displaySmall.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: L.text,
                    letterSpacing: -0.5,
                  )),
              const SizedBox(width: 2),
              Text(topUnit,
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 10,
                    color: L.sub.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 10.5,
                color: L.sub.withValues(alpha: 0.45),
                fontWeight: FontWeight.w500,
                height: 1.3,
              )),
          const SizedBox(height: 12),
          // ── Ring chart with % inside ──
          Center(
            child: SizedBox(
              width: 52,
              height: 52,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ringPct),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutExpo,
                builder: (ctx, val, _) => CustomPaint(
                  painter: _MiniRingPainter(
                    pct: val,
                    color: ringColor,
                    track: ringTrack,
                  ),
                  child: Center(
                    child: Text(
                      '${(ringPct * 100).round()}%',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: ringColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ));
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
// ADHERENCE SCORE CARD — Cal AI "Health Score" card
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
    final noDoses = doses.isEmpty;
    final moodEmoji = noDoses
        ? '💊'
        : dosePct == 1.0
            ? '🎯'
            : dosePct >= 0.8
                ? '😊'
                : dosePct >= 0.5
                    ? '😐'
                    : '😔';

    final msg = noDoses
        ? 'Add your medications to start tracking adherence and get AI insights.'
        : dosePct == 1.0
            ? "\uD83C\uDF89 Perfect score! All doses taken today. Incredible consistency!"
            : dosePct >= 0.8
                ? "Great job \u2014 you're nearly perfect. Don't miss your remaining doses."
                : dosePct >= 0.5
                    ? "You're making progress. Take your remaining doses for full adherence."
                    : "Your adherence is low today. Focus on your scheduled doses to improve.";

    return BouncingButton(
      onTap: () => HapticEngine.selection(),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: L.border.withValues(alpha: 0.15), width: 1.5),
          boxShadow: AppShadows.glow(L.success, intensity: dosePct > 0.8 ? 0.1 : 0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(moodEmoji, style: const TextStyle(fontSize: 22))
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.2, 1.2),
                        duration: 2000.ms,
                        curve: Curves.easeInOut,
                      ),
                  const SizedBox(width: 8),
                  Text('Adherence Score',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: L.text,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      )),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: L.text.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$score/10',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w900,
                      color: L.text,
                      fontSize: 13,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Gradient progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: dosePct),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutExpo,
              builder: (ctx, val, _) {
                return Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: L.fill.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: noDoses ? 0 : val,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: dosePct >= 0.8
                                ? [
                                    const Color(0xFFD4F544),
                                    const Color(0xFFE8F000)
                                  ]
                                : dosePct >= 0.5
                                    ? [Colors.orange.shade300, Colors.orange]
                                    : [Colors.red.shade300, Colors.red],
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(msg,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: L.sub.withValues(alpha: 0.65),
                fontSize: 12.5,
                height: 1.5,
              )),
        ],
      ),
    ));
  }
}

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
    // Find upcoming (untaken) doses, fall back to all
    final upcoming = doses.where((d) => takenToday[d.key] != true).toList();
    final toShow =
        upcoming.isEmpty ? doses.take(3).toList() : upcoming.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recently scheduled',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: context.L.text,
                    letterSpacing: -0.2,
                  )),
              if (upcoming.isEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.L.greenLight,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text('All done ✓',
                      style: AppTypography.labelSmall.copyWith(
                        color: context.L.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      )),
                ),
            ],
          ),
        ),
        ...toShow.map((d) {
          final isTaken = takenToday[d.key] == true;
          final timeStr =
              '${d.sched.h.toString().padLeft(2, '0')}:${d.sched.m.toString().padLeft(2, '0')}';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: BouncingButton(
              onTap: () => onView(d.med),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.L.card,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: context.L.shadowSoft,
                  border: Border.all(
                      color: context.L.border.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isTaken ? context.L.greenLight : context.L.fill,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Icon(
                          isTaken
                              ? Icons.check_rounded
                              : Icons.medication_rounded,
                          color: isTaken ? context.L.green : context.L.sub,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.med.name,
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: context.L.text,
                                fontSize: 14,
                              )),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.medication_liquid_outlined,
                                  size: 12, color: context.L.sub),
                              const SizedBox(width: 4),
                              Text(d.med.dose,
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 11,
                                    color: context.L.sub,
                                    fontWeight: FontWeight.w500,
                                  )),
                              const SizedBox(width: 10),
                              Icon(Icons.schedule_outlined,
                                  size: 12, color: context.L.sub),
                              const SizedBox(width: 4),
                              Text(timeStr,
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 11,
                                    color: context.L.sub,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Time badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isTaken ? context.L.greenLight : context.L.text,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        isTaken ? 'Taken' : timeStr,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 11,
                          color: isTaken ? context.L.green : context.L.bg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
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
      // Progress arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
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
