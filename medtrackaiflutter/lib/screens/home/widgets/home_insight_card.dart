import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../domain/entities/entities.dart';
import '../../../widgets/modals/ask_ai_sheet.dart';
import '../../../widgets/common/paywall_sheet.dart';
import '../../../core/utils/haptic_engine.dart';
import 'dart:ui';

class HomeInsightCard extends StatefulWidget {
  final AppState state;
  final VoidCallback onLoadInsight;

  const HomeInsightCard({
    super.key,
    required this.state,
    required this.onLoadInsight,
  });

  @override
  State<HomeInsightCard> createState() => _HomeInsightCardState();
}

class _HomeInsightCardState extends State<HomeInsightCard> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showAskAi(BuildContext context, List<HealthInsight> insights) {
    HapticEngine.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AskAiSheet(contextInsights: insights),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final onLoadInsight = widget.onLoadInsight;
    final L = context.L;
    final List<HealthInsight> insights = state.healthInsights;
    final isPremium = state.profile?.isPremium ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: AppRadius.roundL,
          border: Border.all(color: L.border.withValues(alpha: 0.1), width: 1.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // ── Main Content ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
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
                            Expanded(
                              child: Row(
                                children: [
                                  Text('AI HEALTH COACH',
                                      style: AppTypography.labelMedium.copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: L.sub,
                                          letterSpacing: 0.5)),
                                  if (!isPremium) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.lime.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        "PRO",
                                        style: TextStyle(
                                          color: AppColors.lime,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (insights.isNotEmpty && isPremium)
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: TextButton.icon(
                                  onPressed: () => _showAskAi(context, insights),
                                  icon: Icon(Icons.chat_bubble_outline_rounded, color: L.text, size: 14),
                                  label: Text('Ask AI',
                                      style: TextStyle(color: L.text, fontSize: 11, fontWeight: FontWeight.w800)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    minimumSize: const Size(0, 32),
                                    backgroundColor: L.text.withValues(alpha: 0.05),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(color: L.text.withValues(alpha: 0.1))),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: onLoadInsight,
                              icon: Icon(Icons.refresh_rounded, color: L.sub.withValues(alpha: 0.4), size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (insights.isEmpty)
                    Center(
                      child: TextButton(
                        onPressed: isPremium ? onLoadInsight : null,
                        child: Text(isPremium ? 'Generate insights' : 'Premium feature',
                            style: AppTypography.labelLarge.copyWith(color: L.text, fontSize: 13)),
                      ),
                    )
                  else
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        SizedBox(
                          height: 140, // Reduced from 250 to fit better
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (i) => setState(() => _currentIndex = i),
                            itemCount: insights.length,
                            itemBuilder: (context, index) {
                              final item = insights[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.labelMedium.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: L.sub,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.body,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: L.text,
                                      height: 1.4,
                                      letterSpacing: -0.1,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.steps.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: item.steps.take(2).map((step) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: L.text.withValues(alpha: 0.03),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: L.border.withValues(alpha: 0.05)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check_circle_outline_rounded, color: L.green, size: 12),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    step,
                                                    style: TextStyle(
                                                        color: L.text, fontSize: 11, fontWeight: FontWeight.w600),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )).toList(),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                        if (insights.length > 1)
                          Positioned(
                            bottom: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                  insights.length,
                                  (i) => AnimatedContainer(
                                        duration: 300.ms,
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                        width: _currentIndex == i ? 12 : 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: _currentIndex == i ? L.text : L.sub.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      )),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),

            // ── Premium Gate Overlay ────────────────────────────────────────
            if (!isPremium)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: AppRadius.roundL,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: L.card.withValues(alpha: 0.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: L.secondary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.lock_rounded, color: L.secondary, size: 24),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Unlock AI Health Insights',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Get personalised analysis of your health data',
                            style: AppTypography.bodySmall.copyWith(color: L.sub),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              HapticEngine.selection();
                              PaywallSheet.show(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: L.secondary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Upgrade to Pro 💎'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fade().slideY(begin: 0.05, end: 0);
  }
}
