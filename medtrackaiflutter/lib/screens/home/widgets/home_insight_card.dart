import 'package:flutter/material.dart';
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

    if (!state.loadingInsight && state.healthInsights == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        if (!state.loadingInsight && state.healthInsights == null) {
          onLoadInsight();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(11)),
              child: const Center(
                  child: Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 16)),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('AI Health Insight',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: L.text)),
                  if (state.healthInsights == null && !state.loadingInsight)
                    Text('Tap for a personalised tip ✨',
                        style: TextStyle(
                            fontFamily: 'Inter', fontSize: 11, color: L.sub)),
                ])),
            if (state.healthInsights != null)
              GestureDetector(
                onTap: onLoadInsight,
                child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: L.fill, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.refresh_rounded, size: 13, color: L.sub)),
              ),
          ]),
          if (state.loadingInsight) ...[
            const SizedBox(height: 10),
            Text('Thinking... ✨',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: L.sub,
                    fontStyle: FontStyle.italic)),
          ] else if (state.healthInsights != null) ...[
            const SizedBox(height: 10),
            Text(state.healthInsights!,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: L.text,
                    height: 1.6)),
          ],
        ]),
      ),
    );
  }
}
