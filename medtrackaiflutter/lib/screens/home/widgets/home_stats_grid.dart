import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared/shared_widgets.dart';

class HomeStatsGrid extends StatelessWidget {
  final AppState state;
  final List<DoseItem> doses;
  final int takenCount;
  final int remaining;
  final double dosePct;
  final Color ringCol;

  const HomeStatsGrid({
    super.key,
    required this.state,
    required this.doses,
    required this.takenCount,
    required this.remaining,
    required this.dosePct,
    required this.ringCol,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final adherence = (state.getAdherenceScore() * 100).round();
    
    // Minimalist monochrome color selection
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card 1: Daily Progress
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: L.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: L.border.withValues(alpha: 0.1), width: 1.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('$takenCount',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: L.text,
                                  letterSpacing: -1.0)),
                          const SizedBox(width: 4),
                          Text('/${doses.length}',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: L.sub,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('Doses today',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: L.sub,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1)),
                      const SizedBox(height: 16),
                      RingChart(
                        percent: dosePct,
                        size: 48,
                        strokeWidth: 5,
                        color: L.text,
                        label: '${(dosePct * 100).round()}%',
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          ),
          const SizedBox(width: 12),
          // Card 2: Adherence Score
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: L.card,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: L.border.withValues(alpha: 0.1), width: 1.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                          Text('$adherence%',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: L.text,
                                  letterSpacing: -1.0)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('Adherence (30d)',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: L.sub,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1)),
                      const SizedBox(height: 20),
                      Container(
                        height: 5,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: L.fill.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: adherence / 100.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: L.text,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          ),
        ],
      ),
    );
  }
}
