import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../smoothing_text.dart';
import '../../core/utils/haptic_engine.dart';
import '../../theme/app_theme.dart';

class DoseCelebrationModal extends StatelessWidget {
  final String medName;
  final String message;

  const DoseCelebrationModal({
    super.key,
    required this.medName,
    this.message = "Great job! Staying consistent is the key to a healthier you.",
  });

  static void show(BuildContext context, String medName) {
    HapticEngine.successScan(); // Use rhythmic success haptic
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => DoseCelebrationModal(medName: medName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // --- PARTICLE BURST (FAKE) ---
          ...List.generate(12, (i) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: 800.ms,
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                final dist = 40 + (value * 120);
                return Transform.translate(
                  offset: Offset(
                    dist * (i % 2 == 0 ? 1 : -1) * (i < 6 ? 1 : 0.5), 
                    -dist * (i % 3 == 0 ? 1 : 0.8)
                  ),
                  child: Opacity(
                    opacity: (1.0 - value).clamp(0.0, 1.0),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i % 2 == 0 ? L.green : L.purple,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // --- MAIN CONTENT ---
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: L.border, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: L.green.withValues(alpha: 0.1),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: L.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: L.green.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: const Text('💊', style: TextStyle(fontSize: 44))
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 800.ms),
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut).shimmer(delay: 600.ms),
                
                const SizedBox(height: 28),
                
                Text(
                  "$medName Logged",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: L.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Inter',
                    letterSpacing: -1.0,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  child: SmoothingText(
                    text: message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: L.sub,
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),
                
                const SizedBox(height: 36),
                
                GestureDetector(
                  onTap: () {
                    HapticEngine.selection();
                    Navigator.pop(context);
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
                        "Awesome! ⚡",
                        style: TextStyle(
                          color: L.bg,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ).animate().scale(delay: 800.ms, duration: 400.ms, curve: Curves.elasticOut),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
        ],
      ),
    );
  }
}
