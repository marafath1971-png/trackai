import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../core/utils/haptic_engine.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/smoothing_text.dart';
import '../../../domain/entities/entities.dart';

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
        Text('TIMING CONSISTENCY (7D)',
            style: AppTypography.labelLarge
                .copyWith(fontSize: 11, color: L.sub, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: L.border, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final date = DateTime.now().subtract(Duration(days: 6 - i));
                final dateStr = date.toIso8601String().substring(0, 10);
                final dayLatency =
                    latencyData.where((e) => e['date'] == dateStr).toList();

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
                                  colors: [
                                    Colors.transparent,
                                    L.border.withValues(alpha: 0.2),
                                    Colors.transparent
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            ...dayLatency.map((d) {
                              final latency = (d['latency'] as int);
                              final color = latency.abs() < 15
                                  ? L.green
                                  : (latency.abs() < 60 ? L.amber : L.red);
                              final bottomPos = ((latency + 60) / 120 * 100)
                                  .clamp(0.0, 100.0);

                              return Positioned(
                                bottom: bottomPos,
                                child: GestureDetector(
                                  onTap: () {
                                    HapticEngine.selection();
                                  },
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2.0),
                                        boxShadow: [
                                          BoxShadow(
                                              color:
                                                  color.withValues(alpha: 0.5),
                                              blurRadius: 10,
                                              spreadRadius: 2)
                                        ]),
                                  ),
                                )
                                    .animate(
                                        onPlay: (c) => c.repeat(reverse: true))
                                    .scale(
                                        begin: const Offset(1, 1),
                                        end: const Offset(1.15, 1.15),
                                        duration: 1500.ms,
                                        delay: (i * 150).ms,
                                        curve: Curves.easeInOut)
                                    .shimmer(
                                        duration: 3.seconds,
                                        color: Colors.white
                                            .withValues(alpha: 0.3)),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                          [
                            'SUN',
                            'MON',
                            'TUE',
                            'WED',
                            'THU',
                            'FRI',
                            'SAT'
                          ][date.weekday % 7],
                          style: AppTypography.labelMedium.copyWith(
                              fontSize: 9, color: L.sub, letterSpacing: 0.8)),
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
        Text('TIMING CONSISTENCY',
            style: AppTypography.labelLarge
                .copyWith(fontSize: 11, color: L.sub, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [L.fill, L.card.withValues(alpha: 0.5)],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: L.border, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: L.border.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.history_rounded,
                    color: L.sub.withValues(alpha: 0.4), size: 24),
              ),
              const SizedBox(height: 16),
              Text('Log doses to see timing patterns',
                  style: AppTypography.bodySmall.copyWith(
                      color: L.sub.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(begin: const Offset(0.98, 0.98)),
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
            Expanded(
              child: Text('AI HEALTH COACH',
                  style: AppTypography.labelLarge.copyWith(
                      fontSize: 11, color: L.sub, letterSpacing: 1.2)),
            ),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: L.fill,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.refresh_rounded, size: 14, color: L.sub),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...insights.map((ins) {
          final cat = ins.category.toLowerCase();
          final color = (cat.contains('safe') ||
                  cat.contains('warn') ||
                  cat.contains('caution'))
              ? L.red
              : (cat.contains('adh') ||
                      cat.contains('hab') ||
                      cat.contains('pro'))
                  ? L.green
                  : L.purple;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: L.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: L.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(cat.toUpperCase(),
                        style: AppTypography.labelMedium.copyWith(
                            color: color, fontSize: 9, letterSpacing: 0.5)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ins.title,
                            style: AppTypography.titleLarge.copyWith(
                                fontSize: 15,
                                color: L.text,
                                letterSpacing: -0.3)),
                        const SizedBox(height: 6),
                        SmoothingText(
                          text: ins.body,
                          style: AppTypography.bodySmall.copyWith(
                              color: L.sub,
                              fontSize: 13,
                              height: 1.5,
                              fontWeight: FontWeight.w500),
                        ),
                        if (ins.steps.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ins.steps
                                .map((step) => GestureDetector(
                                      onTap: () => context
                                          .read<AppState>()
                                          .executeStepAction(step, context),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.05),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color:
                                                  color.withValues(alpha: 0.1)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                                Icons
                                                    .check_circle_outline_rounded,
                                                color: color,
                                                size: 10),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                step,
                                                style: AppTypography.labelMedium
                                                    .copyWith(
                                                        color: L.text,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        letterSpacing: 0.2),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.05, end: 0),
          );
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
              child: Text('AI HEALTH COACH',
                  style: AppTypography.labelLarge.copyWith(
                      fontSize: 11, color: L.sub, letterSpacing: 1.2)),
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
            borderRadius: BorderRadius.circular(32),
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

  const AdherenceTrendChart(
      {super.key, required this.trendData, required this.L});

  @override
  Widget build(BuildContext context) {
    if (trendData.isEmpty) return _buildEmptyState(L);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('30-DAY ADHERENCE TREND',
                style: AppTypography.labelLarge
                    .copyWith(fontSize: 11, color: L.sub, letterSpacing: 1.2)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: L.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'PRO',
                style: AppTypography.labelMedium
                    .copyWith(color: L.green, fontSize: 9, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: L.border, width: 1.5),
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: trendData.map((day) {
                    final val = day['value'] as double;
                    final scheduled = day['scheduled'] as int;

                    final isEmptyDay = scheduled == 0;
                    final color = isEmptyDay
                        ? L.border.withValues(alpha: 0.3)
                        : (val >= 0.8
                            ? L.green
                            : (val >= 0.4 ? L.amber : L.red));

                    final heightFactor = isEmptyDay ? 0.2 : val.clamp(0.1, 1.0);

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: FractionallySizedBox(
                          heightFactor: heightFactor,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ).animate(delay: 200.ms).scaleY(
                                begin: 0.0,
                                end: 1.0,
                                duration: 800.ms,
                                curve: Curves.easeOutBack,
                              ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('30 days ago',
                      style: AppTypography.labelMedium
                          .copyWith(color: L.sub, fontSize: 10)),
                  Text('Today',
                      style: AppTypography.labelMedium
                          .copyWith(color: L.sub, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppThemeColors L) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('30-DAY ADHERENCE TREND',
            style: AppTypography.labelLarge
                .copyWith(fontSize: 11, color: L.sub, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [L.fill, L.card.withValues(alpha: 0.3)],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: L.border, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stacked_bar_chart_rounded,
                  color: L.sub.withValues(alpha: 0.2), size: 40),
              const SizedBox(height: 16),
              Text('Trend data will appear here',
                  style: AppTypography.bodySmall.copyWith(
                      color: L.sub.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms),
      ],
    );
  }
}
