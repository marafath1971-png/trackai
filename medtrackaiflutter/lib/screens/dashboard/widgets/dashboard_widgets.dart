import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
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
        Text('TIMING CONSISTENCY (7D)',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: L.sub,
                letterSpacing: 1.2)),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: 160,
            padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: L.card,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: L.border, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                      spreadRadius: -5,
                    ),
                  ]),
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
                                width: 1.5,
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
                                final bottomPos =
                                    ((latency + 60) / 120 * 100).clamp(0.0, 100.0);

                                return Positioned(
                                  bottom: bottomPos,
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                    },
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border:
                                              Border.all(color: Colors.white, width: 2.5),
                                          boxShadow: [
                                            BoxShadow(
                                                color: color.withValues(alpha: 0.5),
                                                blurRadius: 10,
                                                spreadRadius: 2)
                                          ]),
                                    ),
                                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                                      begin: const Offset(1, 1),
                                      end: const Offset(1.15, 1.15),
                                      duration: 1500.ms,
                                      delay: (i * 150).ms,
                                      curve: Curves.easeInOut).shimmer(
                                      duration: 3.seconds,
                                      color: Colors.white.withValues(alpha: 0.3)),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                            ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'][date.weekday % 7],
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: L.sub,
                                letterSpacing: 0.8)),
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
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: L.sub,
                letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: L.fill,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: L.border),
          ),
          child: Center(
            child: Text('Start taking doses to see trends',
                style: TextStyle(color: L.sub, fontSize: 13, fontWeight: FontWeight.w600)),
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
                    fontWeight: FontWeight.w900,
                    color: L.sub,
                    letterSpacing: 1.2)),
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
          final cat = (ins['category'] as String? ?? 'General').toLowerCase();
          final color = (cat.contains('safe') || cat.contains('warn') || cat.contains('caution')) 
              ? L.red 
              : (cat.contains('adh') || cat.contains('hab') || cat.contains('pro')) 
                  ? L.green 
                  : L.purple;

          return ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: L.card,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: L.border, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
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
                          style: TextStyle(
                              fontFamily: 'Inter',
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ins['title'] ?? 'Insight',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: L.text,
                                  letterSpacing: -0.3)),
                          const SizedBox(height: 6),
                          SmoothingText(
                            text: ins['body'] ?? '',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: L.sub, 
                              fontSize: 13, 
                              height: 1.5,
                              fontWeight: FontWeight.w500
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
