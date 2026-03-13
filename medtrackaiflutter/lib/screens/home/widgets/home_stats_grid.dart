import 'package:flutter/material.dart';
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
    const adherence = 100;
    final adhColor = adherence >= 80
        ? L.green
        : adherence >= 50
            ? L.amber
            : L.red;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card 1: Daily Progress
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: L.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: L.border.withOpacity(0.5)),
                gradient: LinearGradient(
                  colors: [L.card, L.bg.withOpacity(0.5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('💊', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text('$takenCount',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: L.text,
                              letterSpacing: -1.0)),
                      Text('/${doses.length}',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: L.sub,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Doses today',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: L.sub,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  RingChart(
                    percent: dosePct,
                    size: 54,
                    strokeWidth: 6,
                    color: ringCol,
                    label: '${(dosePct * 100).round()}%',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Card 2: Adherence Score
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: L.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: L.border.withOpacity(0.5)),
                gradient: LinearGradient(
                  colors: [L.card, L.bg.withOpacity(0.5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('📈', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text('$adherence%',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: adhColor,
                              letterSpacing: -1.0)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Adherence (30d)',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: L.sub,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: L.border.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(99)),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: adherence / 100.0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            adhColor,
                            adhColor.withOpacity(0.7)
                          ]),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
