import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-trigger unlock after a small delay for smooth transition
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<AppState>().unlockApp();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Scaffold(
      body: Stack(
        children: [
          // Background (solid)
          Container(
            decoration: BoxDecoration(
              color: L.bg,
            ),
          ),

          // Solid Overlay
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: ShapeDecoration(
                color: L.bg.withValues(alpha: 0.95),
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1.0),
                ),
                shadows: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: L.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.lock_person_rounded,
                        color: L.green,
                        size: 40,
                      ),
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 24),
                  Text(
                    'App Locked',
                    style: AppTypography.displaySmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: L.text,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please authenticate to access your sensitive health data and medication history.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: L.sub,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 32),
                  BouncingButton(
                    onTap: () {
                      HapticEngine.selection();
                      context.read<AppState>().unlockApp();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: ShapeDecoration(
                        color: L.green,
                        shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        shadows: [
                          BoxShadow(
                            color: L.green.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Unlock Now',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .slideY(begin: 0.2, end: 0, delay: 400.ms)
                      .fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 500.ms),
        ],
      ),
    );
  }
}
