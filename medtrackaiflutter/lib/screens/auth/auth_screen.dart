import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_loading_indicator.dart';
import '../../widgets/shared/shared_widgets.dart';

// ══════════════════════════════════════════════
// AUTH SCREEN — Sign In / Sign Up
// ══════════════════════════════════════════════

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;
  bool _showPass = false;
  bool _loadingApple = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      if (_isSignUp) {
        await AuthService.signUpWithEmail(
            _emailCtrl.text.trim(), _passCtrl.text);
      } else {
        await AuthService.signInWithEmail(
            _emailCtrl.text.trim(), _passCtrl.text);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await AuthService.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } catch (e) {
      setState(() => _error = 'Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _appleSignIn() async {
    setState(() {
      _error = null;
      _loadingApple = true;
    });
    try {
      await AuthService.signInWithApple();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } catch (e) {
      // User cancelled is a normal case — don't show error
      final msg = e.toString();
      if (!msg.contains('AuthorizationErrorCode.canceled') &&
          !msg.contains('com.apple.AuthenticationServices') &&
          !msg.contains('canceled')) {
        setState(() => _error = 'Apple sign-in failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loadingApple = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter your email first');
      return;
    }
    await AuthService.sendPasswordResetEmail(_emailCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent ✓')),
      );
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with that email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with that email';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'invalid-email':
        return 'Please enter a valid email';
      case 'network-request-failed':
        return 'No internet connection';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final topPad = MediaQuery.of(context).padding.top;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: L.bg,
        body: SafeArea(
          child: Scrollbar(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: topPad + 40),

                  // ── Logo ───────────────────────────────────────────────
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppShadows.neumorphic,
                    ),
                    child: const Center(
                        child: Image(
                      image: AssetImage('assets/images/home_logo.png'),
                      width: 44,
                      height: 44,
                    )),
                  ),
                  const SizedBox(height: 24),

                  RichText(
                      text: TextSpan(
                    style: AppTypography.displayLarge.copyWith(
                        fontSize: 32,
                        color: L.text,
                        letterSpacing: -1.0,
                        fontWeight: FontWeight.w900),
                    children: [
                      TextSpan(
                          text: _isSignUp
                              ? 'Create\nyour '
                              : 'Welcome\nback to '),
                      TextSpan(
                          text: 'Med ',
                          style: AppTypography.displayLarge.copyWith(
                              fontSize: 32,
                              color: L.text,
                              fontWeight: FontWeight.w900)),
                      TextSpan(
                          text: 'Ai',
                          style: AppTypography.displayLarge.copyWith(
                              fontSize: 32,
                              color: L.success,
                              fontWeight: FontWeight.w900)),
                    ],
                  )),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp
                        ? 'Sign up to sync your medicines across all devices.'
                        : 'Sign in to access your medicine data.',
                    style: AppTypography.bodySmall
                        .copyWith(fontSize: 15, color: L.sub, height: 1.5),
                  ),
                  const SizedBox(height: 36),

                  // ── Apple Sign In (App Store Requirement to be above others) ──
                  _AppleBtn(onTap: _appleSignIn, loading: _loadingApple),
                  const SizedBox(height: 12),
                  // ── Google Sign In ─────────────────────────────────────
                  _GoogleBtn(onTap: _googleSignIn, loading: _loading),

                  const SizedBox(height: 20),

                  // ── Divider ────────────────────────────────────────────
                  Row(children: [
                    Expanded(child: Divider(color: L.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style: AppTypography.bodySmall
                              .copyWith(fontSize: 13, color: L.sub)),
                    ),
                    Expanded(child: Divider(color: L.border)),
                  ]),
                  const SizedBox(height: 20),

                  // ── Email ──────────────────────────────────────────────
                  _AuthField(
                    controller: _emailCtrl,
                    label: 'Email address',
                    keyboardType: TextInputType.emailAddress,
                    L: L,
                  ),
                  const SizedBox(height: 12),

                  // ── Password ───────────────────────────────────────────
                  _AuthField(
                    controller: _passCtrl,
                    label: 'Password',
                    obscure: !_showPass,
                    suffix: GestureDetector(
                      onTap: () => setState(() => _showPass = !_showPass),
                      child: Icon(
                          _showPass
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: L.sub,
                          size: 18),
                    ),
                    L: L,
                  ),

                  // ── Forgot password ────────────────────────────────────
                  if (!_isSignUp) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: BouncingButton(
                        onTap: _forgotPassword,
                        scaleFactor: 0.95,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Forgot password?',
                              style: AppTypography.labelLarge.copyWith(
                                  fontSize: 13,
                                  color: L.text.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ],

                  // ── Error ──────────────────────────────────────────────
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          color: L.redLight, borderRadius: AppRadius.roundM),
                      child: Row(children: [
                        Icon(Icons.error_outline_rounded,
                            color: L.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_error!,
                                style: AppTypography.bodySmall
                                    .copyWith(fontSize: 13, color: L.red))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // ── Submit Button ──────────────────────────────────────
                  _PrimaryBtn(
                    label: _isSignUp ? 'Create Account' : 'Sign In',
                    loading: _loading,
                    onTap: _submit,
                  ),
                  const SizedBox(height: 20),

                  // ── Toggle ─────────────────────────────────────────────
                  Center(
                    child: BouncingButton(
                      onTap: () => setState(() {
                        _isSignUp = !_isSignUp;
                        _error = null;
                      }),
                      scaleFactor: 0.95,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: RichText(
                            text: TextSpan(
                          style: AppTypography.bodySmall
                              .copyWith(fontSize: 14, color: L.sub),
                          children: [
                            TextSpan(
                                text: _isSignUp
                                    ? 'Already have an account? '
                                    : "Don't have an account? "),
                            TextSpan(
                              text: _isSignUp ? 'Sign In' : 'Sign Up',
                              style: AppTypography.bodySmall.copyWith(
                                  fontSize: 14,
                                  color: L.text,
                                  fontWeight: FontWeight.w900,
                                  decoration: TextDecoration.underline),
                            ),
                          ],
                        )),
                      ),
                    ),
                  ),

                  // ── Skip / Continue without account ───────────────────
                  const SizedBox(height: 16),
                  Center(
                    child: BouncingButton(
                      onTap: () {
                        context.read<AppState>().skipAuth();
                      },
                      scaleFactor: 0.95,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Continue without account →',
                            style: AppTypography.bodySmall
                                .copyWith(fontSize: 13, color: L.sub)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────

class _GoogleBtn extends StatelessWidget {
  final VoidCallback onTap;
  final bool loading;
  const _GoogleBtn({required this.onTap, required this.loading});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return BouncingButton(
      onTap: loading ? () {} : onTap,
      scaleFactor: 0.98,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.neumorphic,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          loading
              ? const AppLoadingIndicator(size: 20)
              : Image.asset(
                  'assets/images/google_logo.png',
                  width: 20,
                  height: 20,
                ),
          const SizedBox(width: 12),
          Text('Continue with Google',
              style: AppTypography.titleLarge.copyWith(
                  fontSize: 15, fontWeight: FontWeight.w700, color: L.text)),
        ]),
      ),
    );
  }
}

class _AppleBtn extends StatelessWidget {
  final VoidCallback onTap;
  final bool loading;
  const _AppleBtn({required this.onTap, required this.loading});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return BouncingButton(
      onTap: loading ? () {} : onTap,
      scaleFactor: 0.98,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.neumorphic,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          loading
              ? const AppLoadingIndicator(size: 20)
              : Icon(Icons.apple_rounded, size: 22, color: L.text),
          const SizedBox(width: 12),
          Text('Continue with Apple',
              style: AppTypography.titleLarge.copyWith(
                  fontSize: 15, fontWeight: FontWeight.w700, color: L.text)),
        ]),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final AppThemeColors L;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.L,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.neumorphic,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: AppTypography.bodyLarge
            .copyWith(fontSize: 15, color: L.text, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTypography.bodySmall.copyWith(
              fontSize: 14, color: L.sub, fontWeight: FontWeight.w600),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          suffixIcon: suffix != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 16), child: suffix)
              : null,
          suffixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _PrimaryBtn(
      {required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return BouncingButton(
      onTap: loading ? () {} : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Center(
          child: loading
              ? const AppLoadingIndicator(size: 24)
              : Text(label.toUpperCase(),
                  style: AppTypography.titleLarge.copyWith(
                      fontSize: 14,
                      color: L.bg,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
        ),
      ),
    );
  }
}
