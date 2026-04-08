import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../theme/app_theme.dart';
import '../../widgets/modals/trend_drilldown_sheet.dart';
import '../../core/utils/haptic_engine.dart';
import '../../services/report_service.dart';
import '../../widgets/common/paywall_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/shimmer_loader.dart';
import '../../widgets/modals/daily_log_sheet.dart';
import '../home/widgets/streak_modal.dart';
import 'widgets/dashboard_widgets.dart';
import '../home/widgets/voice_assistant_overlay.dart';
import '../../services/voice_service.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _isScrolled = false;
  bool _showVoiceAssistant = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Refresh insights when entering the tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchHealthInsights();
      VoiceService.init();
    });
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
    final L = context.L;
    final s = AppLocalizations.of(context)!;
    final state = context.read<AppState>();
    // Granular selection
    final latency = context.select<AppState, List<Map<String, dynamic>>>(
        (s) => s.getLatencyData());
    final trendData = context
        .select<AppState, List<Map<String, dynamic>>>((s) => s.getTrendData());
    final adherence =
        context.select<AppState, double>((s) => s.getAdherenceScore());
    final streak = context.select<AppState, int>((s) => s.getStreak());
    final loadingInsight =
        context.select<AppState, bool>((s) => s.loadingInsight);
    final meds = context.select<AppState, List<Medicine>>((s) => s.meds);
    final healthInsights =
        context.select<AppState, List<HealthInsight>>((s) => s.healthInsights);

    return Scaffold(
      backgroundColor: L.meshBg, // Cal AI Texture foundation
      body: Stack(children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              color: L.meshBg,
            ),
          ),
        ),
        RefreshIndicator(
          onRefresh: () async {
            HapticEngine.selection();
            final state = context.read<AppState>();
            await state.loadFromStorage();
            await state.fetchHealthInsights();
          },
          displacement: 100,
          color: L.text,
          backgroundColor: L.meshBg,
          child: Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              child: Column(
                children: [
                  SizedBox(height: 110 + MediaQuery.of(context).padding.top),
                  const SizedBox(height: AppSpacing.l),

                  // --- SUMMARY STATS (Bento) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildSummaryCard(
                          context,
                          s.adherenceLabel.toUpperCase(),
                          adherence * 100,
                          '%',
                          '📊',
                          L.secondary,
                          onTap: () => _showTrendDrilldown(context, state, L),
                        ),
                        const SizedBox(width: 16),
                        _buildSummaryCard(
                          context,
                          s.streakLabel.toUpperCase(),
                          streak.toDouble(),
                          'D',
                          '🔥',
                          L.warning,
                          onTap: () => StreakModal.show(context, state),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
                  const SizedBox(height: 16),

                  // --- BIOMETRIC BENTO (Task 1) ---
                  _buildBiometricBento(context, state, L, s),
                  const SizedBox(height: 32),

                  // --- TIMELINE PILL SELECTOR ---
                  Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 24),
                    child: TimelinePillSelector(
                      selectedIndex: 0,
                      onSelect: (idx) {},
                      L: L,
                    ),
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 600.ms)
                      .slideX(begin: 0.1, end: 0),

                  // --- 30-DAY ADHERENCE TREND ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    child: Column(
                      children: [
                        AdherenceTrendChart(trendData: trendData, L: L)
                            .animate(delay: 150.ms)
                            .fadeIn(duration: 600.ms)
                            .slideY(
                                begin: 0.1, end: 0, curve: Curves.easeOutExpo),
                        const SizedBox(height: 24),
                        InventoryStatusCard(meds: meds, L: L)
                            .animate(delay: 200.ms)
                            .fadeIn(duration: 600.ms)
                            .slideY(
                                begin: 0.1, end: 0, curve: Curves.easeOutExpo),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // --- LATENCY HEATMAP ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    child: LatencyHeatmap(latencyData: latency, L: L)
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutExpo),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // --- AI HEALTH COACH ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    child: loadingInsight
                        ? _buildLoadingInsights(L, s)
                        : HealthCoachCard(
                            insights: healthInsights,
                            L: L,
                            onRetry: () =>
                                context.read<AppState>().fetchHealthInsights(),
                          ).animate().fadeIn(duration: 800.ms),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // --- EXPORT PDF BUTTON (PREMIUM) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    child: Container(
                      width: double.infinity,
                      height: 60,
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
                      child: BouncingButton(
                        onTap: () {
                          HapticEngine.selection();
                          final state = context.read<AppState>();
                          if (!state.isPremium) {
                            PaywallSheet.show(context);
                            return;
                          }
                          ReportService.generateAndShareReport(
                            s: s,
                            userName: state.profile?.name ?? s.greetingHero,
                            adherence: adherence,
                            meds: state.meds,
                            symptoms: state.symptoms,
                            history: state.history,
                            avgHeartRate: state.healthHeartRate,
                            avgSteps: state.healthSteps,
                            currentStreak: streak,
                            trendData: trendData,
                          );
                        },
                        scaleFactor: 0.95,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.picture_as_pdf_rounded,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(s.generateClinicalReport,
                                  style: AppTypography.labelLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutExpo),

                  const SizedBox(height: 16),

                  // --- EXPORT CSV BUTTON ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    child: TextButton(
                      onPressed: () {
                        HapticEngine.selection();
                        final state = context.read<AppState>();
                        ReportService.generateAndShareCSV(
                          meds: state.meds,
                          history: state.history,
                        );
                      },
                      child: Text('EXPORT DATA AS CSV',
                          style: AppTypography.labelSmall.copyWith(
                              color: L.sub,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0)),
                    ),
                  )
                      .animate(delay: 150.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: AppSpacing.xxl),

                  // --- FOOTER INFO ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: L.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: L.border.withValues(alpha: 0.07),
                            width: 0.5),
                        boxShadow: AppShadows.neumorphic,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: L.sub, size: 20),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              s.aiCoachDisclaimer,
                              style: AppTypography.bodySmall.copyWith(
                                  color: L.sub, fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate(delay: 150.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutExpo),

                  const SizedBox(
                      height: 180), // Expanded clear area for the FAB
                ],
              ),
            ),
          ),
        ),
        if (_showVoiceAssistant)
          VoiceAssistantOverlay(
            onDismiss: () => setState(() => _showVoiceAssistant = false),
          ),
      ]),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_showVoiceAssistant) 
            FloatingActionButton(
              onPressed: () {
                HapticEngine.selection();
                setState(() => _showVoiceAssistant = true);
              },
              backgroundColor: L.secondary,
              mini: true,
              child: const Icon(Icons.mic_rounded, color: Colors.white),
            ).animate().slideY(begin: 1, end: 0, curve: Curves.easeOutExpo),
          const SizedBox(height: 12),
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: L.text,
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: L.text.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: FloatingActionButton(
              onPressed: () => DailyLogSheet.show(context),
              backgroundColor: Colors.transparent,
              highlightElevation: 0,
              elevation: 0,
              child: const Center(
                  child: Text('➕',
                      style: TextStyle(color: Colors.white, fontSize: 24))),
            ),
          ),
        ],
      ),
    );
  }

  void _showTrendDrilldown(
      BuildContext context, AppState state, AppThemeColors L) {
    HapticEngine.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TrendDrilldownSheet(state: state, L: L),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String label, double numValue,
      String suffix, String emoji, Color color,
      {VoidCallback? onTap}) {
    final L = context.L;
    return Expanded(
      child: BouncingButton(
        onTap: onTap,
        scaleFactor: 0.95,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(28),
            border:
                Border.all(color: L.border.withValues(alpha: 0.08), width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.18, 1.18),
                    duration: 1800.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 10),
              Text(label,
                  style: AppTypography.labelMedium.copyWith(
                      color: L.sub,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0)),
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: numValue),
                duration: 1200.ms,
                curve: Curves.easeOutExpo,
                builder: (context, value, child) {
                  return Text('${value.round()}$suffix',
                      style: AppTypography.displayLarge.copyWith(
                          fontSize: 42,
                          color: L.text,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2.0));
                },
              ),
              const SizedBox(height: 8),
              Text('Goal 100%',
                  style: AppTypography.labelSmall
                      .copyWith(color: L.sub, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingInsights(AppThemeColors L, AppLocalizations s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.fetchingAiInsights.toUpperCase(),
            style: AppTypography.labelLarge.copyWith(
                fontSize: 10,
                color: L.sub,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: L.border.withValues(alpha: 0.08), width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerLoader(
                        width: 40,
                        height: 40,
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerLoader(width: 120, height: 12),
                        SizedBox(height: 6),
                        ShimmerLoader(width: 80, height: 10),
                      ],
                    )
                  ],
                ),
                SizedBox(height: 24),
                ShimmerLoader(width: double.infinity, height: 12),
                SizedBox(height: 10),
                ShimmerLoader(width: double.infinity, height: 12),
                SizedBox(height: 10),
                ShimmerLoader(width: 200, height: 12),
              ],
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 2000.ms, color: L.text.withValues(alpha: 0.05)),
      ],
    );
  }

  Widget _buildBiometricBento(BuildContext context, AppState state,
      AppThemeColors L, AppLocalizations s) {
    final connected = state.healthConnected;
    final steps = state.healthSteps;
    final hr = state.healthHeartRate;
    final syncing = state.healthSyncing;

    if (!connected) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: BouncingButton(
          onTap: () async {
            HapticEngine.selection();
            final ok = await state.connectHealth();
            if (ok) state.syncHealthData();
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: L.border.withValues(alpha: 0.08), width: 0.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: L.secondary.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: const Center(
                      child: Text('🫀', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CONNECT HEALTH DATA',
                          style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w900,
                              color: L.secondary,
                              letterSpacing: 1.0)),
                      const SizedBox(height: 4),
                      Text('Sync vitals to see how meds affect your heart.',
                          style: AppTypography.bodySmall.copyWith(
                              color: L.sub, fontSize: 12, height: 1.3)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: L.sub, size: 20),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildBentoCard(
              context,
              'STEPS',
              '${steps.toInt()}',
              '👞',
              L.secondary,
              syncing: syncing,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _buildBentoCard(
              context,
              'BPM',
              '${hr.toInt()}',
              '❤️',
              L.error,
              syncing: syncing,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildBentoCard(
      BuildContext context, String label, String value, String emoji, Color? c,
      {bool syncing = false}) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: L.border.withValues(alpha: 0.08), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              if (syncing)
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(L.sub),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
              style: AppTypography.displayLarge.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: L.text,
                  letterSpacing: -1.0)),
          const SizedBox(height: 4),
          Text(label,
              style: AppTypography.labelSmall.copyWith(
                  color: L.sub, fontWeight: FontWeight.w900, fontSize: 10)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// DASHBOARD QUICK ACTIONS
// ------------------------------------------------------------------
