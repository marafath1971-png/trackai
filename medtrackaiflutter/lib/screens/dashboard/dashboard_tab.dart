import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../domain/entities/health_insight.dart';
import '../../domain/entities/medicine.dart';
import '../../widgets/common/unified_header.dart';
import '../../widgets/modals/trend_drilldown_sheet.dart';
import '../../core/utils/haptic_engine.dart';
import '../../services/report_service.dart';
import '../../widgets/common/paywall_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/bouncing_button.dart';
import '../../widgets/common/shimmer_loader.dart';
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
          color: L.secondary,
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

                  // --- SUMMARY STATS ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    child: Row(
                      children: [
                        _buildStatCard(
                          context,
                          s.adherenceLabel,
                          '${(adherence * 100).round()}%',
                          Icons.insights_rounded,
                          L.secondary,
                        ),
                        const SizedBox(width: AppSpacing.m),
                        _buildStatCard(
                          context,
                          s.streakLabel,
                          s.streakDays(streak),
                          Icons.local_fire_department_rounded,
                          L.warning,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: AppSpacing.xl),

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
                            .slideY(begin: 0.1, end: 0),
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
                        .slideY(begin: 0.1, end: 0),
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
                        borderRadius: AppRadius.roundL,
                        gradient: AppGradients.main,
                        boxShadow: [
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
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: AppSpacing.xxl),

                  // --- FOOTER INFO ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: L.fill,
                        borderRadius: AppRadius.roundL,
                        border: Border.all(color: L.border),
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
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 120),
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

  Widget _buildStatCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
    final L = context.L;
    return Expanded(
      child: BouncingButton(
        onTap: () {
          HapticEngine.selection();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) =>
                TrendDrilldownSheet(state: context.read<AppState>(), L: L),
          );
        },
        scaleFactor: 0.97,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: AppRadius.roundL,
            border: Border.all(color: L.border, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: color.withValues(alpha: 0.2), width: 1),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLarge.copyWith(
                            fontSize: 11,
                            color: L.sub,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(value,
                  style: AppTypography.displayLarge.copyWith(
                      fontSize: 32,
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
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: AppRadius.roundL,
            border: Border.all(color: L.border, width: 1.5),
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
