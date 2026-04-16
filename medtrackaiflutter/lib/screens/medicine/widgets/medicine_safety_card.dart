import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_state.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/common/app_loading_indicator.dart';
import '../../../widgets/shared/shared_widgets.dart';

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
      if (result.isFailure) {
        setState(() => _errorMessage = result.failure.toString());
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: L.border.withValues(alpha: 0.1)),
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
                    color: L.text.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.security_rounded, color: L.text, size: 18),
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
                    color: L.text,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    s.verified.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: L.bg,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1.0,
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
    // 2026 Viral premium colors
    final Color colorToUse = isAha
        ? const Color(0xFFA855F7) // Purple for Aha
        : isDanger
            ? const Color(0xFFEF4444) // Red for Danger
            : const Color(0xFF34D399); // Teal/Green for normal (food rules)

    // Remove emoji from title if it exists to replace with pure text
    String cleanTitle = title.replaceAll(RegExp(r'[^\w\s&]'), '').trim();

    final section = Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: L.card,
        gradient: isAha
            ? LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.15),
                  const Color(0xFFA855F7).withValues(alpha: 0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: colorToUse.withValues(alpha: isAha ? 0.3 : 0.15),
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colorToUse.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          if (isDanger)
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.15),
              blurRadius: 40,
              spreadRadius: -5,
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: colorToUse.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: colorToUse.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: -2)
                    ]),
                child: Text(
                  isAha ? "💡" : (isDanger ? "⚠️" : "🍏"),
                  style: const TextStyle(fontSize: 22),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(
                        begin: 1.0,
                        end: 1.08,
                        duration: 1.5.seconds,
                        curve: Curves.easeInOut),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  cleanTitle.toUpperCase(),
                  style: AppTypography.labelLarge.copyWith(
                    color: colorToUse,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              if (isDanger)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Text("🛑", style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Text(
                        "DANGER",
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(duration: 1.seconds, color: Colors.white54),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isAha ? Colors.transparent : L.meshBg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: isAha
                      ? Colors.transparent
                      : L.border.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6, right: 14),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorToUse,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: AppTypography.bodyMedium.copyWith(
                            color: L.text.withValues(alpha: 0.95),
                            height: 1.6,
                            fontWeight: isDanger ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );

    return section.animate().fadeIn(duration: 600.ms).slideY(
        begin: 0.1, end: 0, curve: Curves.easeOutQuart);
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
    ).animate().fadeIn(duration: 600.ms).shake(duration: 400.ms, curve: Curves.easeInOut);
  }

  Widget _buildScanPrompt(AppThemeColors L, AppLocalizations s) {
    return BouncingButton(
      onTap: _isLoading ? null : _runScan,
      scaleFactor: 0.95,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: L.card,
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6366F1).withValues(alpha: 0.1),
              const Color(0xFFA855F7).withValues(alpha: 0.05)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              blurRadius: 40,
              spreadRadius: -10,
              offset: const Offset(0, 10)
            )
          ]
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFA855F7).withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: -5),
                ],
              ),
              child: _isLoading
                  ? const AppLoadingIndicator(size: 32)
                  : const Text("✨", style: TextStyle(fontSize: 32))
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(
                          begin: 1,
                          end: 1.15,
                          duration: 1.5.seconds,
                          curve: Curves.easeInOut),
            ),
            const SizedBox(height: 24),
            Text(
              _isLoading ? s.analyzingClinicalLimits : s.generateSafetyProfile,
              style: AppTypography.titleLarge.copyWith(
                color: L.text,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isLoading ? s.safetyLoadingSubtitle : "Tap to unlock deep clinical insights, potential side-effects, and AHA moments.",
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: L.text.withValues(alpha: 0.8),
                height: 1.6,
                fontWeight: FontWeight.w600
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart);
  }
}
