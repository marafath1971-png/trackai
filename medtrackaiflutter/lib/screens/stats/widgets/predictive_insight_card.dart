import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../domain/entities/predictive_insight.dart';
import '../../../theme/app_tokens.dart';

class PredictiveInsightCard extends StatelessWidget {
  final PredictiveInsight insight;

  const PredictiveInsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final color = _getColor(insight.type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(_getEmoji(insight.type), style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight.title,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.description,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.black.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Action button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text(
              'ADJUST NOTIFICATIONS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    )
    .animate(onPlay: (c) => c.repeat(reverse: true))
    .shimmer(duration: 3.seconds, color: color.withValues(alpha: 0.1))
    .animate()
    .fadeIn(duration: 600.ms)
    .slideY(begin: 0.1, end: 0);
  }

  Color _getColor(PredictiveType type) {
    switch (type) {
      case PredictiveType.eveningRisk: return Colors.indigo;
      case PredictiveType.weekendSlump: return Colors.orange;
      case PredictiveType.travelRisk: return Colors.cyan;
      case PredictiveType.heatWarning: return Colors.red;
    }
  }

  String _getEmoji(PredictiveType type) {
    switch (type) {
      case PredictiveType.eveningRisk: return '🌃';
      case PredictiveType.weekendSlump: return '⚖️';
      case PredictiveType.travelRisk: return '🌐';
      case PredictiveType.heatWarning: return '🌡️';
    }
  }
}
