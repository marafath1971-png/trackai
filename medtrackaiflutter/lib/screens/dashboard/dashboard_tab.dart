import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/unified_header.dart';
import '../../widgets/modals/trend_drilldown_sheet.dart';
import '../../core/utils/haptic_engine.dart';
import '../../services/report_service.dart';
import '../../widgets/common/paywall_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/shimmer_loader.dart';
import '../../widgets/modals/daily_log_sheet.dart';
import '../home/widgets/streak_modal.dart';
import 'widgets/dashboard_widgets.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _isScrolled = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Refresh insights when entering the tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchHealthInsights();
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
      backgroundColor: L.bg,
      body: Stack(children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              color: L.bg,
              border: Border(bottom: BorderSide(color: L.border.withValues(alpha: 0.5))),
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
          backgroundColor: L.bg,
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
                          '${(adherence * 100).round()}%',
                          Icons.insights_rounded,
                          L.secondary,
                          onTap: () => _showTrendDrilldown(context, state, L),
                        ),
                        const SizedBox(width: 12),
                        _buildSummaryCard(
                          context,
                          s.streakLabel.toUpperCase(),
                          '${streak}D',
                          Icons.local_fire_department_rounded,
                          L.warning,
                          onTap: () => StreakModal.show(context, state),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
                  const SizedBox(height: 24),

                  // --- QUICK ACTIONS ---
                  _DashboardQuickActionRow(
                    onLogSymptom: () => DailyLogSheet.show(context),
                    onShareReport: () {
                      HapticEngine.selection();
                      final state = context.read<AppState>();
                      final s = AppLocalizations.of(context)!;
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
                      );
                    },
                  ).animate(delay: 100.ms).fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutExpo),
                  const SizedBox(height: 32),

                  // --- 30-DAY ADHERENCE TREND ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    child: Column(
                      children: [
                        AdherenceTrendChart(trendData: trendData, L: L),
                        const SizedBox(height: 24),
                        InventoryStatusCard(meds: meds, L: L)
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutExpo),
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
                      decoration: ShapeDecoration(
                        shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        gradient: AppGradients.main,
                        shadows: [
                          BoxShadow(
                            color: L.secondary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
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
                          );
                        },
                        scaleFactor: 0.95,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.picture_as_pdf_rounded,
                                  color: Colors.black, size: 20),
                              const SizedBox(width: 8),
                              Text(s.generateClinicalReport,
                                  style: AppTypography.labelLarge.copyWith(
                                      color: Colors.black,
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

                  const SizedBox(height: AppSpacing.xxl),

                  // --- FOOTER INFO ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: ShapeDecoration(
                        color: L.fill,
                        shape: ContinuousRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(color: L.border),
                        ),
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

                  const SizedBox(height: 180), // Expanded clear area for the detached Cal AI FAB
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: UnifiedHeader(
            isScrolled: _isScrolled,
            title: s.insightsTitle,
            subtitle: s.insightsSubtitle,
          ),
        ),
      ]),
    );
  }

  void _showTrendDrilldown(BuildContext context, AppState state, AppThemeColors L) {
    HapticEngine.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TrendDrilldownSheet(state: state, L: L),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String label, String value,
      IconData icon, Color color, {VoidCallback? onTap}) {
    final L = context.L;
    return Expanded(
      child: BouncingButton(
        onTap: onTap,
        scaleFactor: 0.95,
        child: SquircleCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: ShapeDecoration(
                      color: L.text.withValues(alpha: 0.05),
                      shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Icon(icon, color: L.text, size: 18),
                  ),
                  Text(label,
                      style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          color: L.sub,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
                ],
              ),
              const SizedBox(height: 24),
              Text(value,
                  style: AppTypography.displayLarge.copyWith(
                      fontSize: 34,
                      color: L.text,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0)),
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
          decoration: ShapeDecoration(
            color: L.card,
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: L.border, width: 1.5),
            ),
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
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------
// DASHBOARD QUICK ACTIONS
// ------------------------------------------------------------------
class _DashboardQuickActionRow extends StatelessWidget {
  final VoidCallback onLogSymptom;
  final VoidCallback onShareReport;

  const _DashboardQuickActionRow({
    required this.onLogSymptom,
    required this.onShareReport,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              icon: Icons.edit_note_rounded,
              label: 'Log Symptom',
              subtitle: 'Track your wellbeing',
              onTap: onLogSymptom,
              L: L,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.picture_as_pdf_rounded,
              label: 'Share Report',
              subtitle: 'Export clinical PDF',
              onTap: onShareReport,
              L: L,
            ),
          ),
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
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: L.card,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: BorderSide(color: L.border.withValues(alpha: 0.15)),
          ),
          shadows: L.shadowSoft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: ShapeDecoration(
                color: L.text.withValues(alpha: 0.07),
                shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Icon(icon, size: 18, color: L.text),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: L.text,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: L.sub,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
