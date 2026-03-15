import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'widgets/dashboard_widgets.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    // Refresh insights when entering the tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchHealthInsights();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final L = context.L;
    final latency = state.getLatencyData();
    final adherence = state.getAdherenceScore();
    final streak = state.getStreak();

    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          Scrollbar(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              child: Column(
                children: [
                SizedBox(height: 120 + MediaQuery.of(context).padding.top),
                
                // --- SUMMARY STATS ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildStatCard(
                        context,
                        'ADHERENCE',
                        '${(adherence * 100).round()}%',
                        Icons.analytics_rounded,
                        L.green,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        context,
                        'STREAK',
                        '$streak Days',
                        Icons.local_fire_department_rounded,
                        L.amber,
                      ),
                    ],
                  ),
                ),
    

            const SizedBox(height: 32),

            // --- LATENCY HEATMAP ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LatencyHeatmap(latencyData: latency, L: L)
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.1, end: 0),
            ),

            const SizedBox(height: 32),

            // --- AI HEALTH COACH ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: state.loadingInsight 
                ? _buildLoadingInsights(L)
                : HealthCoachCard(
                    insightJson: state.healthInsights, 
                    L: L,
                    onRetry: () => state.fetchHealthInsights(),
                  ).animate().fadeIn(duration: 800.ms),
            ),

            const SizedBox(height: 48),

            // --- FOOTER INFO ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: L.fill,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: L.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: L.sub, size: 20),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'This dashboard uses AI to analyze patterns. Always consult your doctor for medical advice.',
                        style: TextStyle(color: L.sub, fontSize: 12, height: 1.4),
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

        // --- FLOATING HEADER ---
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(24, 60 + MediaQuery.of(context).padding.top, 24, 20),
            decoration: BoxDecoration(
              color: L.bg,
              border: Border(
                bottom: BorderSide(color: L.border, width: 1.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text('Health Insights',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: L.text,
                        letterSpacing: -1.2)),
                const SizedBox(height: 4),
                Text('Clinical overview & AI coaching',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: L.sub)),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final L = context.L;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: L.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(label, 
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11, 
                        fontWeight: FontWeight.w900, 
                        color: L.sub, 
                        letterSpacing: 0.8
                      )),
                  ],
                ),
                const SizedBox(height: 16),
                Text(value, 
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28, 
                    fontWeight: FontWeight.w900, 
                    color: L.text,
                    letterSpacing: -1.0
                  )),
              ],
            ),
          ),
    );
  }

  Widget _buildLoadingInsights(AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FETCHING AI INSIGHTS...',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: L.sub,
                letterSpacing: 1.0)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(
            color: L.fill,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: L.border),
          ),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(L.green),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
