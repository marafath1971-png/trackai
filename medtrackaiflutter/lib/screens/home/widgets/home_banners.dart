import 'package:flutter/material.dart';
import '../../../core/utils/haptic_engine.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_state.dart';

class HomeMissedAlertsBanner extends StatelessWidget {
  final AppState state;
  final AppThemeColors L;

  const HomeMissedAlertsBanner({
    super.key,
    required this.state,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticEngine.alertWarning();
        state.markAlertsAsSeen();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: L.text,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            ...L.shadowSoft,
            BoxShadow(
              color: L.onBg.withValues(alpha: 0.1),
              blurRadius: 40,
              offset: const Offset(0, 20),
              spreadRadius: -10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: L.bg.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_active_rounded,
                  color: L.bg, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MISSED DOSES',
                    style: AppTypography.labelLarge.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: L.bg.withValues(alpha: 0.6),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to clear recent alerts',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: L.bg,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: L.bg.withValues(alpha: 0.4)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0);
  }
}

class HomeLowStockBanner extends StatelessWidget {
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onTap;

  const HomeLowStockBanner({
    super.key,
    required this.state,
    required this.L,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lowMeds = state.getLowMeds();
    if (lowMeds.isEmpty) return const SizedBox();

    return GestureDetector(
      onTap: () {
        HapticEngine.alertWarning();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.neumorphic,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: L.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inventory_2_rounded, color: L.red, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REFILL NEEDED',
                    style: AppTypography.labelLarge.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: L.red,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${lowMeds.length} items running low',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: L.text,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: L.sub.withValues(alpha: 0.3)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}
