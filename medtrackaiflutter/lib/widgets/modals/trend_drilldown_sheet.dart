import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../common/refined_sheet_wrapper.dart';
import 'daily_log_sheet.dart';

class TrendDrilldownSheet extends StatelessWidget {
  final AppState state;
  final AppThemeColors L;

  const TrendDrilldownSheet({super.key, required this.state, required this.L});

  @override
  Widget build(BuildContext context) {
    final trendData = state.getTrendData();
    final avgAdherence = state.getAdherenceScore();

    return RefinedSheetWrapper(
      title: 'Health Trends',
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('30-DAY PERFORMANCE',
                  style: AppTypography.labelSmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: L.sub,
                      letterSpacing: 1.2)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppShadows.neumorphic,
                ),
                child: Text('${(avgAdherence * 100).round()}% AVG',
                    style: AppTypography.labelMedium.copyWith(
                        color: L.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // --- CHART ---
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: trendData.asMap().entries.map((entry) {
                final i = entry.key;
                final d = entry.value;
                final value = d['value'] as double;
                final height = (value * 140).clamp(6.0, 140.0);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticEngine.selection();
                            // Could show a tooltip here
                          },
                          child: Container(
                            width: double.infinity,
                            height: height,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  value >= 0.8
                                      ? L.green
                                      : (value > 0.4 ? L.amber : L.red),
                                  value >= 0.8
                                      ? L.green.withValues(alpha: 0.6)
                                      : (value > 0.4
                                          ? L.amber.withValues(alpha: 0.6)
                                          : L.red.withValues(alpha: 0.6)),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ).animate().scaleY(
                                begin: 0,
                                end: 1,
                                duration: 600.ms,
                                delay: (i * 20).ms,
                                curve: Curves.easeOutBack,
                              ),
                        ),
                        if (i % 7 == 0 || i == trendData.length - 1) ...[
                          const SizedBox(height: 8),
                          Text(d['date'].toString().split('-')[2],
                              style: AppTypography.labelSmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: L.sub)),
                        ] else ...[
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 32),

          // --- TREND SUMMARY ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppShadows.neumorphic,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: L.purple, size: 18),
                    const SizedBox(width: 10),
                    Text('PATIENT INSIGHT',
                        style: AppTypography.labelSmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: L.purple,
                            letterSpacing: 0.5)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  avgAdherence >= 0.9
                      ? "Exceptional consistency! Your 30-day streak is helping stabilize your therapy efficacy. Keep maintaining this rhythmic intake."
                      : avgAdherence >= 0.7
                          ? "Stable progress detected. You've been most consistent on weekdays. Try setting deeper reminders for weekends to hit 90%+."
                          : "Irregular patterns identified. Consistency is key for medication bioavailability. Consider using the 'Refill Alert' to avoid gaps.",
                  style: AppTypography.bodyMedium.copyWith(
                    color: L.text,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1, end: 0),

          const SizedBox(height: 32),

          // --- LINK TO DAILY LOG ---
          GestureDetector(
            onTap: () {
              HapticEngine.selection();
              DailyLogSheet.show(context, date: DateTime.now());
            },
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.neumorphic,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 18, color: L.text),
                  const SizedBox(width: 10),
                  Text('VIEW DETAILED DAILY LOG',
                      style: AppTypography.labelLarge.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }
}
