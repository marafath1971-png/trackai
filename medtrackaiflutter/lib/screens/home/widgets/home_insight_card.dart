import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/modals/ask_ai_sheet.dart';
import '../../../widgets/common/paywall_sheet.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../services/review_service.dart';
import '../../../widgets/shared/shared_widgets.dart';

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

    // Positive Milestone: User is actively engaging with AI Coaching
    ReviewService.requestReview();

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: AppShadows.neumorphic,
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
                                color: Colors.black.withValues(alpha: 0.03),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.auto_awesome_rounded,
                                  color: L.text, size: 18),
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
                                  if (state.hasNewDataForAI && isPremium) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: L.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: L.green
                                                .withValues(alpha: 0.3),
                                            width: 0.5),
                                      ),
                                      child: Text(
                                        "NEW DATA",
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          color: L.green,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                     .shimmer(duration: 2.seconds, color: L.green.withValues(alpha: 0.2))
                                     .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1.seconds),
                                  ],
                                  if (!isPremium) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: L.text.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "PRO",
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          color: L.text,
                                          fontSize: 11,
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
                            BouncingButton(
                              onTap: () => _showAskAi(context, insights),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chat_bubble_outline_rounded,
                                        color: L.text, size: 14),
                                    const SizedBox(width: 8),
                                    Text('Ask AI',
                                        style: AppTypography.labelMedium
                                            .copyWith(
                                                color: L.text,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            BouncingButton(
                              onTap: onLoadInsight,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Icon(Icons.refresh_rounded,
                                    color: L.sub.withValues(alpha: 0.4),
                                    size: 18),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (insights.isEmpty)
                    Center(
                      child: BouncingButton(
                        onTap: isPremium ? onLoadInsight : () => {},
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                              isPremium
                                  ? 'Generate insights'
                                  : 'Premium feature',
                              style: AppTypography.labelLarge
                                  .copyWith(color: L.text, fontSize: 13)),
                        ),
                      ),
                    )
                  else
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        SizedBox(
                          height: 140,
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (i) =>
                                setState(() => _currentIndex = i),
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
                                      children: item.steps
                                          .take(2)
                                          .map((step) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withValues(alpha: 0.02),
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                        Icons
                                                            .check_circle_outline_rounded,
                                                        color: L.green,
                                                        size: 12),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        step,
                                                        style: AppTypography
                                                            .bodySmall
                                                            .copyWith(
                                                                color: L.text,
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ))
                                          .toList(),
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
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 2),
                                        width: _currentIndex == i ? 12 : 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: _currentIndex == i
                                              ? L.text
                                              : L.sub.withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      )),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),

            // ── Premium Gate Solid Overlay ──────────────────────────────────
            if (!isPremium)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        L.card.withValues(alpha: 0.1),
                        L.card.withValues(alpha: 0.8),
                        L.card,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: L.secondary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.lock_rounded,
                            color: L.secondary, size: 24),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unlock AI Health Insights',
                        style: AppTypography.titleMedium
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get personalised analysis of your health data',
                        style: AppTypography.bodySmall.copyWith(color: L.sub),
                      ),
                      const SizedBox(height: 20),
                      BouncingButton(
                        onTap: () {
                          HapticEngine
                              .selection(); // Keeping explicit haptic for emphasis
                          PaywallSheet.show(context);
                        },
                        hapticEnabled: false,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: L.secondary,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: L.secondary.withValues(alpha: 0.4),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Upgrade to Pro 💎',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
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
      ),
    ).animate(target: state.hasNewDataForAI ? 1 : 0)
     .shimmer(duration: 3.seconds, color: L.text.withValues(alpha: 0.05))
     .fade()
     .slideY(begin: 0.05, end: 0);
  }
}
