import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../../services/share_service.dart';

/// A branded, Instagram-story-style achievement card with share CTA.
/// Used for streaks, adherence milestones, and scan achievements.
class ShareAchievementCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? badgeLabel;
  final VoidCallback? onShare;
  final VoidCallback? onDismiss;

  const ShareAchievementCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.badgeLabel,
    this.onShare,
    this.onDismiss,
  });

  /// Show as a dialog overlay.
  static void show(
    BuildContext context, {
    required String emoji,
    required String title,
    required String subtitle,
    String? badgeLabel,
  }) {
    HapticEngine.successScan();
    showDialog(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.92),
      builder: (context) => ShareAchievementCard(
        emoji: emoji,
        title: title,
        subtitle: subtitle,
        badgeLabel: badgeLabel,
        onShare: () {
          HapticEngine.selection();
          ShareService.shareAchievement(
            title: title,
            subtitle: subtitle,
            emoji: emoji,
          );
        },
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  L.bg,
                  L.card2,
                  L.secondary.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: L.onBg.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: L.secondary.withValues(alpha: 0.15),
                  blurRadius: 50,
                  offset: const Offset(0, 25),
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge label
                if (badgeLabel != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: L.onBg.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: L.onBg.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      badgeLabel!.toUpperCase(),
                      style: AppTypography.labelLarge.copyWith(
                        color: L.onBg.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.3, end: 0),
                  const SizedBox(height: 24),
                ],

                // Big emoji
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: L.onBg.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: L.onBg.withValues(alpha: 0.1),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(emoji,
                        style:
                            AppTypography.displayLarge.copyWith(fontSize: 52)),
                  ),
                )
                    .animate()
                    .scale(
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                        begin: const Offset(0.3, 0.3))
                    .fadeIn(),
                const SizedBox(height: 28),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.displayMedium.copyWith(
                    color: L.onBg,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                    height: 1.1,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: L.onBg.withValues(alpha: 0.6),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 350.ms),

                const SizedBox(height: 32),

                // Branding footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: L.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Med AI',
                      style: AppTypography.labelSmall.copyWith(
                        color: L.onBg.withValues(alpha: 0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: L.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).scale(
              begin: const Offset(0.88, 0.88), curve: Curves.easeOutBack),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              // Dismiss
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticEngine.selection();
                    if (onDismiss != null) onDismiss!();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Close',
                        style: AppTypography.labelLarge.copyWith(
                          color: L.onBg.withValues(alpha: 0.7),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Share
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: onShare,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.share_rounded,
                            color: AppColors.black, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Share Achievement',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(delay: 600.ms, duration: 400.ms)
              .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }
}
