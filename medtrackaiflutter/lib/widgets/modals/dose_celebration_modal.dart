import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../smoothing_text.dart';

class DoseCelebrationModal extends StatelessWidget {
  final String medName;
  final String message;

  const DoseCelebrationModal({
    super.key,
    required this.medName,
    this.message = "Great job! Staying consistent is the key to a healthier you.",
  });

  static void show(BuildContext context, String medName) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => DoseCelebrationModal(medName: medName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('💊', style: TextStyle(fontSize: 40)),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut).shimmer(delay: 600.ms),
            const SizedBox(height: 24),
            Text(
              "$medName Taken!",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontFamily: 'Inter',
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
            const SizedBox(height: 12),
            SmoothingText(
              text: message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  "Keep it up! ⚡",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ).animate().scale(delay: 1.seconds, duration: 400.ms, curve: Curves.elasticOut),
          ],
        ),
      ),
    );
  }
}
