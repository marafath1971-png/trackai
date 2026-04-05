import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_state.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/shared/shared_widgets.dart';
import 'package:provider/provider.dart';

class TrialCountdownCard extends StatelessWidget {
  const TrialCountdownCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final profile = state.profile;

    // Only show for free-tier users
    if (profile == null || profile.isPremium) return const SizedBox.shrink();

    final scansUsed = profile.scansUsed;
    final remaining = (3 - scansUsed).clamp(0, 3);
    final isExhausted = scansUsed >= 3;
    final L = context.L;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: BouncingButton(
        onTap: () {
          HapticEngine.selection();
          state.purchasePremium('annual');
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isExhausted
                  ? L.text.withValues(alpha: 0.3)
                  : L.border.withValues(alpha: 0.5),
            ),
            boxShadow: isExhausted
                ? [
                    BoxShadow(
                      color: L.text.withValues(alpha: 0.08),
                      blurRadius: 30,
                      spreadRadius: 2,
                    )
                  ]
                : AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Row ───────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: L.text.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: L.text.withValues(alpha: 0.1)),
                    ),
                    child: Center(
                      child: Icon(Icons.document_scanner_rounded,
                          color: L.text, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isExhausted
                              ? 'Free Scans Exhausted'
                              : 'Free AI Scans',
                          style: AppTypography.titleMedium.copyWith(
                            color: L.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isExhausted
                              ? 'Upgrade to unlock unlimited scanning'
                              : '$remaining of 3 free scans remaining',
                          style: AppTypography.bodySmall.copyWith(
                            color: L.sub,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // CTA pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: L.text,
                      borderRadius: BorderRadius.circular(AppRadius.max),
                      boxShadow: [
                        BoxShadow(
                          color: L.text.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Text(
                      'GO PRO',
                      style: AppTypography.labelMedium.copyWith(
                        color: L.bg,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(
                          begin: 1.0,
                          end: 1.04,
                          duration: 1800.ms,
                          curve: Curves.easeInOut),
                ],
              ),

              const SizedBox(height: 18),

              // ── Scan counter dots ────────────────────────────────────
              Row(
                children: List.generate(3, (i) {
                  final used = i < scansUsed;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      child: AnimatedContainer(
                        duration: 600.ms,
                        curve: Curves.easeOutQuart,
                        height: 8,
                        decoration: BoxDecoration(
                          color: used
                              ? (isExhausted
                                  ? L.error.withValues(alpha: 0.7)
                                  : L.text)
                              : L.fill.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: used && !isExhausted
                              ? [
                                  BoxShadow(
                                    color: L.text
                                        .withValues(alpha: 0.15),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              if (isExhausted) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: L.text.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: L.text.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star_rounded,
                          color: L.text, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Unlock unlimited scans, interaction checks & more with PRO.',
                          style: AppTypography.bodySmall.copyWith(
                            color: L.sub,
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutQuart);
  }
}
