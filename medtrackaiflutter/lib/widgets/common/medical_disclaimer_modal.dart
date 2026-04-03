import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';

/// Medical disclaimer modal — shown once on first app launch.
/// Required for legal compliance in all markets.
class MedicalDisclaimerModal extends StatelessWidget {
  final VoidCallback onAccept;

  const MedicalDisclaimerModal({super.key, required this.onAccept});

  static const String _acceptedKey = 'medai_disclaimer_accepted';

  /// Check if disclaimer has been accepted.
  static Future<bool> hasAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_acceptedKey) ?? false;
  }

  /// Show the disclaimer if it hasn't been accepted yet.
  static Future<void> showIfNeeded(BuildContext context) async {
    final accepted = await hasAccepted();
    if (!accepted && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: AppColors.black.withValues(alpha: 0.95),
        builder: (context) => MedicalDisclaimerModal(
          onAccept: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_acceptedKey, true);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: L.border, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: L.onBg.withValues(alpha: 0.3),
              blurRadius: 40,
              offset: const Offset(0, 20),
              spreadRadius: -10,
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shield icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: L.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: L.secondary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Center(
                    child: Text('⚕️',
                        style:
                            AppTypography.displayLarge.copyWith(fontSize: 36))),
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .fadeIn(),

              const SizedBox(height: 24),

              Text(
                'Important Health Notice',
                textAlign: TextAlign.center,
                style: AppTypography.headlineLarge.copyWith(
                  color: L.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 16),

              // Disclaimer items
              _DisclaimerItem(
                icon: Icons.medical_services_rounded,
                text:
                    'Med AI is a medication tracking and information tool. It does not provide medical diagnoses or treatment recommendations.',
                L: L,
                delay: 200,
              ),
              _DisclaimerItem(
                icon: Icons.person_rounded,
                text:
                    'Always consult your doctor, pharmacist, or qualified healthcare professional before starting, changing, or stopping any medication.',
                L: L,
                delay: 300,
              ),
              _DisclaimerItem(
                icon: Icons.warning_amber_rounded,
                text:
                    'AI-generated insights are for informational purposes only and may contain inaccuracies. Do not rely on them for medical decisions.',
                L: L,
                delay: 400,
              ),
              _DisclaimerItem(
                icon: Icons.emergency_rounded,
                text:
                    'In case of a medical emergency, call your local emergency number immediately (e.g., 911, 999, 112).',
                L: L,
                delay: 500,
                isEmergency: true,
              ),

              const SizedBox(height: 28),

              // Accept button
              GestureDetector(
                onTap: () {
                  HapticEngine.selection();
                  onAccept();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: L.text,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: L.text.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'I Understand & Accept',
                      style: AppTypography.labelLarge.copyWith(
                        color: L.bg,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(
                      delay: 700.ms, duration: 400.ms, curve: Curves.elasticOut)
                  .fadeIn(),

              const SizedBox(height: 12),

              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: L.sub,
                  fontSize: 11,
                  height: 1.4,
                ),
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).scale(
            begin: const Offset(0.92, 0.92),
            curve: Curves.easeOutBack,
          ),
    );
  }
}

class _DisclaimerItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final AppThemeColors L;
  final int delay;
  final bool isEmergency;

  const _DisclaimerItem({
    required this.icon,
    required this.text,
    required this.L,
    required this.delay,
    this.isEmergency = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isEmergency ? L.error : L.sub;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(icon, size: 18, color: accentColor),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: isEmergency ? L.error : L.text,
                fontSize: 13,
                fontWeight: isEmergency ? FontWeight.w700 : FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1, end: 0);
  }
}
