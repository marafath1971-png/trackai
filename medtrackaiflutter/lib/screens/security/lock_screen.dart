import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../services/biometric_service.dart';
import '../../widgets/common/app_loading_indicator.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Add small delay to ensure the UI frame is stable before the OS prompt appears
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (!mounted) return;
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final success = await BiometricService.authenticate();
      if (mounted) {
        setState(() => _isAuthenticating = false);
        if (success) {
          HapticEngine.success();
          context.read<AppState>().unlockApp();
        } else {
          HapticEngine.error();
          setState(() => _errorMessage = 'Authentication failed. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _errorMessage = 'An error occurred during authentication.';
        });
      }
    }
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: AppShadows.neumorphic,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: L.text.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _isAuthenticating 
                        ? const AppLoadingIndicator(size: 32)
                        : Icon(
                            _errorMessage != null ? Icons.error_outline_rounded : Icons.lock_person_rounded,
                            color: _errorMessage != null ? L.error : L.text,
                            size: 40,
                          ),
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 24),
                  Text(
                    _isAuthenticating ? 'Authenticating...' : 'App Locked',
                    style: AppTypography.displaySmall.copyWith(
                      fontWeight: FontWeight.w900,
                      color: L.text,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage ?? 'Please authenticate to access your sensitive health data and medication history.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: _errorMessage != null ? L.error : L.sub,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 32),
                  if (!_isAuthenticating)
                    BouncingButton(
                      onTap: () {
                        HapticEngine.selection();
                        _authenticate();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _errorMessage != null ? 'TRY AGAIN' : 'UNLOCK NOW',
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w900,
                              color: L.bg,
                              letterSpacing: 1.5,
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
