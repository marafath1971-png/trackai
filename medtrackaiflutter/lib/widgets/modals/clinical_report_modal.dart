import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../common/refined_sheet_wrapper.dart';
import '../../services/report_service.dart';
import '../../l10n/app_localizations.dart';

class ClinicalReportModal extends StatelessWidget {
  final AppState state;
  final double adherence;
  final int streak;

  const ClinicalReportModal({
    super.key,
    required this.state,
    required this.adherence,
    required this.streak,
  });

  static void show(
      BuildContext context, AppState state, double adherence, int streak) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClinicalReportModal(
        state: state,
        adherence: adherence,
        streak: streak,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final s = AppLocalizations.of(context)!;

    return RefinedSheetWrapper(
      title: 'Value Realization',
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        children: [
          // Header Illustration/Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: L.text.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified_user_rounded, color: L.text, size: 48),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 2.seconds, color: L.text.withValues(alpha: 0.1))
              .scaleXY(
                  begin: 0.95,
                  end: 1.05,
                  duration: 2.seconds,
                  curve: Curves.easeInOut),

          const SizedBox(height: 24),
          Text(
            'Clinical Report Ready',
            style: AppTypography.titleLarge
                .copyWith(fontWeight: FontWeight.w900, color: L.text),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ve synthesized your last 30 days of medical data into a professional clinical summary.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: L.sub, height: 1.5),
          ),

          const SizedBox(height: 32),

          // Stats Bento Grid
          Row(
            children: [
              _buildStatCard(L, 'ADHERENCE', '${(adherence * 100).round()}%',
                  Icons.analytics_rounded),
              const SizedBox(width: 16),
              _buildStatCard(L, 'STREAK', '$streak DAYS',
                  Icons.local_fire_department_rounded),
            ],
          ),

          const SizedBox(height: 32),

          // Info List
          _buildInfoRow(L, Icons.medication_rounded,
              '${state.meds.length} active medications tracked'),
          _buildInfoRow(
              L, Icons.favorite_rounded, 'Biometric trends (Heart Rate, Steps)'),
          _buildInfoRow(L, Icons.assignment_turned_in_rounded,
              'Daily logging checklist & notes'),

          const SizedBox(height: 48),

          // Generate Button
          GestureDetector(
            onTap: () {
              HapticEngine.success();
              Navigator.pop(context);
              ReportService.generateAndShareReport(
                s: s,
                userName: state.profile?.name ?? s.greetingHero,
                adherence: adherence,
                meds: state.meds,
                symptoms: state.symptoms,
                history: state.history,
                avgHeartRate: state.healthHeartRate,
                avgSteps: state.healthSteps,
                currentStreak: streak,
                trendData: state.getTrendData(),
              );
            },
            child: Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: L.text,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: L.text.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'GENERATE PDF REPORT',
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().shimmer(
              delay: 1.seconds,
              duration: 2.seconds,
              color: Colors.white.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      AppThemeColors L, String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: L.border.withValues(alpha: 0.05)),
          boxShadow: AppShadows.neumorphic,
        ),
        child: Column(
          children: [
            Icon(icon, color: L.text, size: 20),
            const SizedBox(height: 12),
            Text(value,
                style: AppTypography.titleLarge
                    .copyWith(fontWeight: FontWeight.w900, color: L.text)),
            const SizedBox(height: 4),
            Text(label,
                style: AppTypography.labelSmall.copyWith(
                    fontSize: 10,
                    color: L.sub,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(AppThemeColors L, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: L.sub),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text,
                style: AppTypography.bodySmall
                    .copyWith(color: L.text, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
