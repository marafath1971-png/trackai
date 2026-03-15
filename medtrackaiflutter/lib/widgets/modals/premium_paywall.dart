import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class PremiumPaywall extends StatefulWidget {
  const PremiumPaywall({super.key});

  @override
  State<PremiumPaywall> createState() => _PremiumPaywallState();
}

class _PremiumPaywallState extends State<PremiumPaywall> {
  bool _isProcessing = false;

  Future<void> _handleUnlock(AppState state) async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await state.unlockPremium();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final state = Provider.of<AppState>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Icon/Celebration
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('💎', style: TextStyle(fontSize: 40)),
            ),
          ).animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 2.seconds, color: Colors.white.withValues(alpha: 0.3))
            .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1.seconds, curve: Curves.easeInOut),

          const SizedBox(height: 24),

          // Marketing Text
          const Text(
            "World's #1 Advanced AI Medication App",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFamily: 'Outfit',
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 12),

          Text(
            "Never miss a course again. Your healthy life, boosted with precision AI.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 40),

          // Benefits List
          _buildBenefit(Icons.auto_awesome_rounded, "Advanced AI Label Scanning", L),
          _buildBenefit(Icons.notifications_active_rounded, "Unlimited Smart Reminders", L),
          _buildBenefit(Icons.family_restroom_rounded, "Full Caregiver Monitoring", L),
          _buildBenefit(Icons.cloud_done_rounded, "Global Cloud Sync & Security", L),

          const SizedBox(height: 48),

          // Auth Buttons
          if (!AuthService.isLoggedIn) ...[
            _buildAuthBtn(
              "Continue with Google",
              "assets/images/google_logo.png",
              AuthService.signInWithGoogle,
              Colors.white,
              Colors.black,
            ),
            const SizedBox(height: 12),
            _buildAuthBtn(
              "Continue with Apple",
              null,
              AuthService.signInWithApple,
              Colors.white,
              Colors.black,
              icon: Icons.apple_rounded,
            ),
            const SizedBox(height: 24),
            const Text(
              "OR",
              style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 24),
          ],

          // Main Unlock Button
          GestureDetector(
            onTap: _isProcessing ? null : () => _handleUnlock(state),
            child: Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                      )
                    : const Text(
                        "Unlock Full Access",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ).animate().scale(delay: 800.ms, duration: 400.ms, curve: Curves.elasticOut),

          const SizedBox(height: 16),
          Text(
            "Start today and feel the smoothing difference.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text, AppThemeColors L) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthBtn(
    String label,
    String? asset,
    Future<dynamic> Function() onTap,
    Color bg,
    Color text, {
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: () async {
        try {
          await onTap();
          if (mounted) Navigator.pop(context);
        } catch (e) {
          debugPrint("Auth Error: $e");
        }
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (asset != null)
              Image.asset(asset, width: 20, height: 20, errorBuilder: (c, e, s) => const Icon(Icons.login, size: 20))
            else if (icon != null)
              Icon(icon, size: 22, color: text),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
