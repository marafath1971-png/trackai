import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';

// ══════════════════════════════════════════════
// INTERACTION WARNING BANNER
// ══════════════════════════════════════════════
//
// Displayed after adding a medicine when Gemini detects a
// clinically significant drug-drug interaction.
// Dismissible with haptic feedback.

class InteractionWarningBanner extends StatelessWidget {
  const InteractionWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final warning = state.interactionWarning;
    final medName = state.interactionWarningMedName;

    if (warning == null) return const SizedBox.shrink();

    final L = context.L;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: L.amber.withValues(alpha: 0.08),
          borderRadius: AppRadius.roundM,
          border: Border.all(color: L.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: L.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child:
                    Icon(Icons.warning_amber_rounded, color: L.amber, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DRUG INTERACTION DETECTED',
                    style: AppTypography.labelMedium.copyWith(
                      fontSize: 9,
                      color: L.amber,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    warning,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13,
                      color: L.text,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Review with your doctor or pharmacist before taking ${medName ?? 'this medicine'}.',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      color: L.sub,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            // Dismiss button
            GestureDetector(
              onTap: () {
                HapticEngine.selection();
                context.read<AppState>().clearInteractionWarning();
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Icon(Icons.close_rounded, size: 18, color: L.sub),
              ),
            ),
          ],
        ),
      )
          .animate()
          .slideY(begin: -0.2, end: 0, duration: 400.ms, curve: Curves.easeOut)
          .fadeIn(duration: 300.ms),
    );
  }
}
