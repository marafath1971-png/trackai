import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/utils/haptic_engine.dart';
import '../../theme/app_theme.dart';
import '../../services/share_service.dart';
import '../../services/review_service.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class DoseCelebrationModal extends StatelessWidget {
  final String medName;
  final String message;

  const DoseCelebrationModal({
    super.key,
    required this.medName,
    this.message =
        "Great job! Staying consistent is the key to a healthier you.",
  });

  static void show(BuildContext context, String medName) {
    HapticEngine.successScan();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => DoseCelebrationModal(medName: medName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── Particle burst ──────────────────────────────────────────
          ...List.generate(16, (i) {
            final angle = (i / 16) * 2 * 3.14159;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 600 + (i % 4) * 100),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                final dist = 60 + value * 100;
                final dx = dist * (0.6 + (i % 3) * 0.2) * (angle < 3.14 ? 1 : -1);
                final dy = -(dist * (0.5 + (i % 5) * 0.1));
                final color = [
                  L.text,
                  AppColors.success,
                  L.text.withValues(alpha: 0.5),
                  const Color(0xFF1F2937),
                ][i % 4];
                return Transform.translate(
                  offset: Offset(dx * value, dy * value),
                  child: Opacity(
                    opacity: (1.0 - value * 0.9).clamp(0.0, 1.0),
                    child: Container(
                      width: 7 + (i % 3) * 2.0,
                      height: 7 + (i % 3) * 2.0,
                      decoration: BoxDecoration(
                        color: color,
                        shape: i % 3 == 0 ? BoxShape.circle : BoxShape.rectangle,
                        borderRadius:
                            i % 3 != 0 ? BorderRadius.circular(2) : null,
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // ── Main card ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.12),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon ──────────────────────────────────────────────
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.2),
                        width: 1.5),
                  ),
                  child: Center(
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 52,
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(
                            begin: 1.0,
                            end: 1.08,
                            duration: 900.ms,
                            curve: Curves.easeInOut),
                  ),
                )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut),

                const SizedBox(height: 24),

                // ── Med name ──────────────────────────────────────────
                Text(
                  medName,
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineLarge.copyWith(
                    color: L.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 4),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.max),
                  ),
                  child: Text(
                    'DOSE LOGGED ✓',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 16),

                // ── Message ───────────────────────────────────────────
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge.copyWith(
                    color: L.sub,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 350.ms),

                const SizedBox(height: 32),

                // ── Actions ───────────────────────────────────────────
                Row(
                  children: [
                    // Share
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticEngine.selection();
                          ShareService.shareAchievement(
                            title: '$medName Logged',
                            subtitle:
                                'Staying consistent with my medication! 💪',
                            emoji: '💊',
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: L.fill.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: L.border.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.ios_share_rounded,
                                  color: L.text, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Share',
                                style: AppTypography.labelLarge.copyWith(
                                  color: L.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Close / Awesome
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          HapticEngine.selection();
                          final state =
                              Provider.of<AppState>(context, listen: false);
                          final dosesMarked = state.profile?.dosesMarked ?? 0;
                          if (dosesMarked == 7 ||
                              dosesMarked == 14 ||
                              dosesMarked == 50) {
                            ReviewService.requestReview();
                          }
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: L.text,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: L.text.withValues(alpha: 0.15),
                                blurRadius: 40,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Awesome! ⚡',
                              style: AppTypography.titleLarge.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().scale(
                    delay: 700.ms,
                    duration: 400.ms,
                    curve: Curves.elasticOut),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .scale(
                  begin: const Offset(0.85, 0.85),
                  curve: Curves.easeOutBack,
                  duration: 450.ms),
        ],
      ),
    );
  }
}
