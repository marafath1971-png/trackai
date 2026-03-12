import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../theme/app_theme.dart';

class LatencyHeatmap extends StatelessWidget {
  final List<Map<String, dynamic>> latencyData;
  final AppThemeColors L;

  const LatencyHeatmap({super.key, required this.latencyData, required this.L});

  @override
  Widget build(BuildContext context) {
    if (latencyData.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TIMING CONSISTENCY (7D)',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: L.sub,
                letterSpacing: 1.0)),
        const SizedBox(height: 12),
        Container(
          height: 110,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: L.border)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final date = DateTime.now()
                  .subtract(Duration(days: 6 - i))
                  .toIso8601String()
                  .substring(0, 10);
              final dayLatency =
                  latencyData.where((e) => e['date'] == date).toList();

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: dayLatency.map((d) {
                          final latency = (d['latency'] as int).abs();
                          final color = latency < 15
                              ? L.green
                              : (latency < 60 ? L.amber : L.red);
                          final bottomPos =
                              (latency.toDouble() / 120 * 60).clamp(0.0, 60.0);

                          return Positioned(
                            bottom: bottomPos,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: color.withValues(alpha: 0.3),
                                        blurRadius: 4)
                                  ]),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        ['S', 'M', 'T', 'W', 'T', 'F', 'S'][DateTime.now()
                                .subtract(Duration(days: 6 - i))
                                .weekday %
                            7],
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: L.sub)),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class HealthCoachCard extends StatelessWidget {
  final String? insightJson;
  final AppThemeColors L;
  final VoidCallback onRetry;

  const HealthCoachCard(
      {super.key,
      required this.insightJson,
      required this.L,
      required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (insightJson == null) return const SizedBox.shrink();

    List<dynamic> insights = [];
    try {
      // Find the JSON block if it's wrapped in text
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(insightJson!);
      final data =
          json.decode(jsonMatch != null ? jsonMatch.group(0)! : insightJson!);
      insights = data['insights'] ?? [];
    } catch (_) {
      // Fallback for non-json insights: split by lines or bullets if possible, otherwise one card
      final cleaned =
          insightJson!.replaceAll('```json', '').replaceAll('```', '').trim();
      insights = [
        {"category": "General", "title": "Health Coach Info", "body": cleaned}
      ];
    }

    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('AI HEALTH COACH',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: L.sub,
                    letterSpacing: 1.0)),
            GestureDetector(
              onTap: onRetry,
              child: Icon(Icons.refresh_rounded, size: 14, color: L.sub),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...insights.map((ins) {
          final cat = ins['category'] as String? ?? 'General';
          final color =
              cat == 'Safety' ? L.red : (cat == 'Adherence' ? L.blue : L.green);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: L.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(cat.toUpperCase(),
                      style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ins['title'] ?? 'Insight',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: L.text)),
                      const SizedBox(height: 4),
                      Text(ins['body'] ?? '',
                          style: TextStyle(
                              color: L.sub, fontSize: 13, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
