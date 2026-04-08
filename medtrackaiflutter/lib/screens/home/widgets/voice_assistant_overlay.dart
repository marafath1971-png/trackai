import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../theme/app_theme.dart';

class VoiceAssistantOverlay extends StatelessWidget {
  final VoidCallback? onDismiss;
  const VoiceAssistantOverlay({super.key, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.isVoiceActive) return const SizedBox.shrink();

    final L = context.L;

    return Stack(
      children: [
        // 1. Frosted Backdrop
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ).animate().fadeIn(duration: 400.ms),
        ),

        // 2. Content Container
        Positioned.fill(
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(),
                
                // Pulsing Mic Icon
                _buildAnimatedMic(state, L),
                
                const SizedBox(height: 48),

                // Transcribed Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    state.voiceTranscript,
                    textAlign: TextAlign.center,
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ).animate().slideY(begin: 0.2, duration: 400.ms).fadeIn(),

                const SizedBox(height: 16),

                // AI Feedback / Confirmation
                if (state.voiceFeedback.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      state.voiceFeedback,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms),

                const Spacer(),

                // Close Button
                IconButton(
                  onPressed: () {
                    HapticEngine.selection();
                    state.closeVoiceAssistant();
                    if (onDismiss != null) onDismiss!();
                  },
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(12),
                  ),
                ).animate().fadeIn(delay: 1.seconds),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedMic(AppState state, AppThemeColors L) {
    IconData icon = Icons.mic_rounded;
    Color color = Colors.white;
    bool isThinking = state.voiceStatus == 'thinking';
    bool isSuccess = state.voiceStatus == 'success';
    bool isError = state.voiceStatus == 'error';

    if (isThinking) icon = Icons.auto_awesome;
    if (isSuccess) {
      icon = Icons.check_circle_rounded;
      color = Colors.greenAccent;
    }
    if (isError) {
      icon = Icons.error_outline_rounded;
      color = Colors.redAccent;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing background rings (only when listening)
        if (state.voiceStatus == 'listening')
          ...[1.0, 1.3, 1.6].map((scale) => Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                ),
              ).animate(onPlay: (c) => c.repeat())
               .scale(begin: const Offset(1, 1), end: Offset(scale, scale), duration: 2.seconds)
               .fadeOut(duration: 2.seconds)),

        // Main Mic Circle
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: Icon(icon, color: color, size: 48),
        )
        .animate(onPlay: (c) => isThinking ? c.repeat() : null)
        .shimmer(duration: isThinking ? 1.5.seconds : 0.ms, color: Colors.white12)
        .shake(hz: isError ? 4 : 0, duration: 400.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 400.ms, curve: Curves.elasticOut),
      ],
    );
  }
}
