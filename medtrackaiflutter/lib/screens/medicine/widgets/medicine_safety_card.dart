import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../domain/entities/entities.dart';
import '../../../providers/app_state.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/common/app_loading_indicator.dart';
import '../../../widgets/common/bouncing_button.dart';

import '../../../l10n/app_localizations.dart';

class MedicineSafetyCard extends StatefulWidget {
  final Medicine med;

  const MedicineSafetyCard({super.key, required this.med});

  @override
  State<MedicineSafetyCard> createState() => _MedicineSafetyCardState();
}

class _MedicineSafetyCardState extends State<MedicineSafetyCard> {
  bool _isLoading = false;
  String? _errorMessage;

  void _runScan() async {
    HapticEngine.selection();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result =
        await context.read<AppState>().analyzeMedicineSafety(widget.med);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result is Error) {
        setState(() => _errorMessage = (result as Error).error.toString());
        HapticEngine.heavyImpact();
      } else {
        HapticEngine.success();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final s = AppLocalizations.of(context)!;
    final profile = widget.med.aiSafetyProfile;

    if (profile == null) {
      if (_errorMessage != null) {
        return _buildErrorState(L, s);
      }
      return _buildScanPrompt(L, s);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.border, width: 1.5),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: L.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.shield_rounded, color: L.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.aiSafetyProfile,
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: L.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    s.verified,
                    style: AppTypography.labelSmall.copyWith(
                      color: L.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(height: 1, color: L.border.withValues(alpha: 0.5)),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile.warnings.isNotEmpty)
                  _buildSection(L, '🚨 ${s.criticalWarnings}', profile.warnings,
                      isDanger: true),
                if (profile.interactions.isNotEmpty)
                  _buildSection(
                      L, '💊 ${s.drugInteractions}', profile.interactions,
                      isDanger: true),
                if (profile.foodRules.isNotEmpty)
                  _buildSection(
                      L, '🍏 ${s.dietaryLifestyleRules}', profile.foodRules,
                      isDanger: false),
                if (profile.ahaMoments.isNotEmpty)
                  _buildSection(L, '💡 ${s.ahaInsight}', profile.ahaMoments,
                      isDanger: false, isAha: true),
                if (profile.warnings.isEmpty &&
                    profile.interactions.isEmpty &&
                    profile.foodRules.isEmpty &&
                    profile.ahaMoments.isEmpty)
                  Text(
                    'No special safety alerts found for this medication.',
                    style: AppTypography.bodyMedium.copyWith(color: L.sub),
                  ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, curve: Curves.easeOutQuart);
  }

  Widget _buildSection(AppThemeColors L, String title, List<String> items,
      {bool isDanger = false, bool isAha = false}) {
    Color iconColor;
    if (isAha) {
      iconColor = const Color(0xFFF59E0B);
    } else if (isDanger) {
      iconColor = L.error;
    } else {
      iconColor = L.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: isAha
                  ? const Color(0xFFD97706)
                  : (isDanger ? L.error : L.text),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 12),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTypography.bodyMedium.copyWith(
                          color: L.sub,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppThemeColors L, AppLocalizations s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: L.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: L.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: L.bg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: L.error.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(Icons.error_outline_rounded, color: L.error, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            s.analysisFailed, // Ensure this key exists or use fallback
            style: AppTypography.titleMedium.copyWith(
              color: L.error,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? s.somethingWentWrong,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: L.sub,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          BouncingButton(
            onTap: _runScan,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: L.error,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                s.retry,
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().shake(duration: 400.ms, curve: Curves.easeInOut);
  }

  Widget _buildScanPrompt(AppThemeColors L, AppLocalizations s) {
    return BouncingButton(
      onTap: _isLoading ? null : _runScan,
      scaleFactor: 0.98,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              L.primary.withValues(alpha: 0.1),
              L.primary.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: L.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: L.bg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: L.primary.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: _isLoading
                  ? const AppLoadingIndicator(size: 28)
                  : Icon(Icons.auto_awesome_rounded, color: L.primary, size: 28)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(
                          begin: 1,
                          end: 1.1,
                          duration: 1.seconds,
                          curve: Curves.easeInOut),
            ),
            const SizedBox(height: 16),
            Text(
              _isLoading ? s.analyzingClinicalLimits : s.generateSafetyProfile,
              style: AppTypography.titleMedium.copyWith(
                color: L.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isLoading ? s.safetyLoadingSubtitle : s.safetyPromptSubtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: L.sub,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
