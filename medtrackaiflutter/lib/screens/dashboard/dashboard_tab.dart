import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../domain/entities/health_insight.dart';
import 'widgets/dashboard_widgets.dart';
import '../../widgets/common/unified_header.dart';
import '../../widgets/modals/trend_drilldown_sheet.dart';
import '../../widgets/common/app_loading_indicator.dart';
import '../../core/utils/haptic_engine.dart';
import '../../services/report_service.dart';
import '../../widgets/common/paywall_sheet.dart';

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
    // Granular selection
    final latency = context.select<AppState, List<Map<String, dynamic>>>((s) => s.getLatencyData());
    final trendData = context.select<AppState, List<Map<String, dynamic>>>((s) => s.getTrendData());
    final adherence = context.select<AppState, double>((s) => s.getAdherenceScore());
    final streak = context.select<AppState, int>((s) => s.getStreak());
    final loadingInsight = context.select<AppState, bool>((s) => s.loadingInsight);
    final healthInsights = context.select<AppState, List<HealthInsight>>((s) => s.healthInsights);

    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
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
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                  child: Row(
                    children: [
                      _buildStatCard(
                        context,
                        'ADHERENCE',
                        '${(adherence * 100).round()}%',
                        Icons.analytics_rounded,
                        L.secondary,
                      ),
                      const SizedBox(width: AppSpacing.m),
                      _buildStatCard(
                        context,
                        'STREAK',
                        '$streak Days',
                        Icons.local_fire_department_rounded,
                        L.warning,
                      ),
                    ],
                  ),
                ),
    

            const SizedBox(height: AppSpacing.xl),

            // --- 30-DAY ADHERENCE TREND ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: AdherenceTrendChart(trendData: trendData, L: L)
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.1, end: 0),
            ),

            const SizedBox(height: AppSpacing.xl),

            // --- LATENCY HEATMAP ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: LatencyHeatmap(latencyData: latency, L: L)
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.1, end: 0),
            ),

            const SizedBox(height: AppSpacing.xl),

            // --- AI HEALTH COACH ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: loadingInsight 
                ? _buildLoadingInsights(L)
                : HealthCoachCard(
                    insights: healthInsights, 
                    L: L,
                    onRetry: () => context.read<AppState>().fetchHealthInsights(),
                  ).animate().fadeIn(duration: 800.ms),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // --- EXPORT PDF BUTTON (PREMIUM) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticEngine.selection();
                    final state = context.read<AppState>();
                    if (!state.isPremium) {
                      PaywallSheet.show(context);
                      return;
                    }
                    ReportService.generateAndShareReport(
                      userName: state.profile?.name ?? 'User',
                      adherence: adherence,
                      meds: state.meds,
                      symptoms: state.symptoms,
                      history: state.history,
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                  label: const Text('GENERATE MEDICAL REPORT', 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: L.text,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.roundL),
                    elevation: 0,
                  ),
                ),
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: AppSpacing.xxl),

            // --- FOOTER INFO ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: L.fill,
                  borderRadius: AppRadius.roundL,
                  border: Border.all(color: L.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: L.sub, size: 20),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'This dashboard uses AI to analyze patterns. Always consult your doctor for medical advice.',
                        style: AppTypography.bodySmall.copyWith(color: L.sub, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 150.ms).fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),

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
            showBrand: true,
            isScrolled: _isScrolled,
            title: 'Insights',
            subtitle: 'Analytics & health patterns',
          ),
        ),
      ]),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final L = context.L;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticEngine.selection();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => TrendDrilldownSheet(state: context.read<AppState>(), L: L),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: AppRadius.roundL,
          border: Border.all(color: L.border, width: 1.0),
          boxShadow: L.shadowSoft,
        ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(label, 
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLarge.copyWith(
                          fontSize: 11, 
                          color: L.sub, 
                          letterSpacing: 0.8
                        )),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(value, 
                  style: AppTypography.displayMedium.copyWith(
                    fontSize: 28, 
                    color: L.text,
                    letterSpacing: -1.0
                  )),
              ],
            ),
          ),
      ),
    );
  }

  Widget _buildLoadingInsights(AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FETCHING AI INSIGHTS...',
            style: AppTypography.labelLarge.copyWith(
                fontSize: 11,
                color: L.sub,
                letterSpacing: 1.0)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: L.fill,
            borderRadius: AppRadius.roundL,
            border: Border.all(color: L.border),
          ),
          child: const Center(
            child: AppLoadingIndicator(size: 32),
          ),
        ),
      ],
    );
  }
}
