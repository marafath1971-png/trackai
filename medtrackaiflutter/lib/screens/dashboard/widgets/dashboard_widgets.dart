import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/shared/shared_widgets.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/smoothing_text.dart';

class LatencyHeatmap extends StatelessWidget {
  final List<Map<String, dynamic>> latencyData;
  final AppThemeColors L;

  const LatencyHeatmap({super.key, required this.latencyData, required this.L});

  @override
  Widget build(BuildContext context) {
    if (latencyData.isEmpty) return _buildEmptyState(L);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TIMING_CONSISTENCY (7D)',
          style: AppTypography.labelSmall.copyWith(
            fontSize: 10,
            color: L.sub,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: SquircleCard(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final date = DateTime.now().subtract(Duration(days: 6 - i));
                final dateStr = date.toIso8601String().substring(0, 10);
                final dayLatency = latencyData.where((e) => e['date'] == dateStr).toList();

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 1.0,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, L.border.withValues(alpha: 0.1), Colors.transparent],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            ...dayLatency.map((d) {
                              final latency = (d['latency'] as int?) ?? 0;
                              final color = latency.abs() < 15 ? L.text : (latency.abs() < 60 ? L.sub : L.error);
                              final bottomPos = ((latency + 60) / 120 * 100).clamp(0.0, 100.0);

                              return Positioned(
                                bottom: bottomPos,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1),
                                    ],
                                  ),
                                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                                  begin: const Offset(1, 1),
                                  end: const Offset(1.2, 1.2),
                                  duration: 1500.ms,
                                  delay: (i * 100).ms,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'][date.weekday % 7],
                        style: AppTypography.labelSmall.copyWith(fontSize: 11, color: L.sub, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TIMING_CONSISTENCY',
            style: AppTypography.labelSmall.copyWith(fontSize: 10, color: L.sub, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: SquircleCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, color: L.sub.withValues(alpha: 0.2), size: 28),
                const SizedBox(height: 16),
                Text('Log doses to see timing patterns',
                    style: AppTypography.bodySmall.copyWith(color: L.sub, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HealthCoachCard extends StatelessWidget {
  final List<HealthInsight> insights;
  final AppThemeColors L;
  final VoidCallback onRetry;

  const HealthCoachCard(
      {super.key,
      required this.insights,
      required this.L,
      required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return _buildEmptyState(L);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: L.purple, size: 14),
                const SizedBox(width: 8),
                Text('AI_MEDICAL_BRIEFING',
                    style: AppTypography.labelSmall.copyWith(
                        fontSize: 10, color: L.purple, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
              ],
            ),
            BouncingButton(onTap: onRetry, child: Icon(Icons.refresh_rounded, size: 16, color: L.sub)),
          ],
        ),
        const SizedBox(height: 16),
        ...insights.map((ins) {
          final cat = ins.category.toLowerCase();
          final color = (cat.contains('safe') || cat.contains('warn')) ? L.error : (cat.contains('adh') ? L.text : L.purple);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SquircleCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(cat.toUpperCase(), style: AppTypography.labelSmall.copyWith(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(ins.title, style: AppTypography.titleMedium.copyWith(color: L.text, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SmoothingText(
                    text: ins.body,
                    style: AppTypography.bodySmall.copyWith(color: L.sub, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                  if (ins.steps.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ins.steps.map((step) => BouncingButton(
                        onTap: () => context.read<AppState>().executeStepAction(step, context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: L.text.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                          child: Text(step, style: AppTypography.labelSmall.copyWith(color: L.text, fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.05, end: 0);
        }),
      ],
    );
  }

  Widget _buildEmptyState(AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: L.purple, size: 14),
                  const SizedBox(width: 8),
                  Text('AI MEDICAL BRIEFING',
                      style: AppTypography.labelLarge.copyWith(
                          fontSize: 10, color: L.purple, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(32),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [L.purple.withValues(alpha: 0.05), L.fill],
            ),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: L.purple.withValues(alpha: 0.1), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: L.purple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.auto_awesome_rounded, color: L.purple, size: 28),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
                  duration: 2.seconds, color: L.purple.withValues(alpha: 0.2)),
              const SizedBox(height: 24),
              Text('Your AI Coach is ready',
                  style: AppTypography.titleLarge.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: L.text)),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Add your medications and log doses to receive personalized health insights and adherence tips.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                      color: L.sub,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      fontSize: 13),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.05, end: 0),
      ],
    );
  }
}

class AdherenceTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> trendData;
  final AppThemeColors L;

  const AdherenceTrendChart({super.key, required this.trendData, required this.L});

  @override
  Widget build(BuildContext context) {
    if (trendData.isEmpty) return _buildEmptyState(L);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ADHERENCE_TREND (30D)',
            style: AppTypography.labelSmall.copyWith(fontSize: 10, color: L.sub, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: SquircleCard(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: trendData.map((day) {
                      final val = day['value'] as double;
                      final scheduled = (day['scheduled'] as int?) ?? 0;
                      final color = scheduled == 0 ? L.fill : (val >= 0.8 ? L.text : (val >= 0.4 ? L.sub : L.error));

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: FractionallySizedBox(
                            heightFactor: scheduled == 0 ? 0.05 : val.clamp(0.1, 1.0),
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(100)),
                            ).animate().scaleY(begin: 0.0, end: 1.0, duration: 800.ms, curve: Curves.easeOutQuart),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('30D_AGO', style: AppTypography.labelSmall.copyWith(color: L.sub, fontSize: 10, fontWeight: FontWeight.w900)),
                    Text('CURRENT', style: AppTypography.labelSmall.copyWith(color: L.text, fontSize: 10, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ADHERENCE_TREND', style: AppTypography.labelSmall.copyWith(fontSize: 10, color: L.sub, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: SquircleCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.stacked_bar_chart_rounded, color: L.sub.withValues(alpha: 0.2), size: 32),
                const SizedBox(height: 16),
                Text('Trend data generating...', style: AppTypography.bodySmall.copyWith(color: L.sub, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


class InventoryStatusCard extends StatelessWidget {
  final List<Medicine> meds;
  final AppThemeColors L;
  const InventoryStatusCard({super.key, required this.meds, required this.L});

  @override
  Widget build(BuildContext context) {
    final trackedMeds = meds.where((m) => m.count > 0).toList();
    if (trackedMeds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SUPPLY_STATUS', style: AppTypography.labelSmall.copyWith(fontSize: 10, color: L.sub, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        SquircleCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: trackedMeds.map((med) {
              final isLow = med.count <= med.refillAt;
              final color = isLow ? L.error : L.text;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(med.name.toUpperCase(), style: AppTypography.labelSmall.copyWith(color: L.text, fontWeight: FontWeight.w900, fontSize: 10)),
                    ),
                    Expanded(
                      flex: 4,
                      child: _HighFidelityBar(pct: (med.count / 30).clamp(0.01, 1.0), color: color, L: L),
                    ),
                    const SizedBox(width: 16),
                    Text('${med.count}', style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: 10)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _HighFidelityBar extends StatelessWidget {
  final double pct;
  final Color color;
  final AppThemeColors L;
  const _HighFidelityBar({required this.pct, required this.color, required this.L});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(color: L.fill, borderRadius: BorderRadius.circular(100)),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: pct,
            child: Container(
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(100)),
            ),
          ),
        ],
      ),
    );
  }
}
