import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';

class HomeInsightCard extends StatelessWidget {
  final AppState state;
  final VoidCallback onLoadInsight;

  const HomeInsightCard({
    super.key,
    required this.state,
    required this.onLoadInsight,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final insight = state.healthInsights;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: L.border.withValues(alpha: 0.1), width: 1.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: L.text.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.auto_awesome_rounded, color: L.text, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text('AI HEALTH INSIGHT',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: L.sub,
                                letterSpacing: 0.5)),
                      ],
                    ),
                    if (insight != null)
                      IconButton(
                        onPressed: onLoadInsight,
                        icon: Icon(Icons.refresh_rounded, color: L.sub.withValues(alpha: 0.4), size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (insight == null)
                  Center(
                    child: TextButton(
                      onPressed: onLoadInsight,
                      child: Text('Generate Insights', 
                        style: TextStyle(color: L.text, fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  )
                else
                  Text(
                    insight,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: L.text,
                      height: 1.5,
                      letterSpacing: -0.1,
                    ),
                  ),
              ],
            ),
          ),
        ),
    ).animate().fade().slideY(begin: 0.05, end: 0);
  }
}
