import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';

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
    } finally {
      if (mounted) setState(() => _loading = false);
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

    return Scaffold(
      backgroundColor: L.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: topPad + 40),

              // ── Logo ───────────────────────────────────────────────
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: const Center(
                    child: Text('💊',
                        style: TextStyle(fontSize: 28, height: 1.0))),
              ),
              const SizedBox(height: 24),

              RichText(
                  text: TextSpan(
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: L.text,
                    letterSpacing: -0.8),
                children: [
                  TextSpan(
                      text: _isSignUp ? 'Create\nyour ' : 'Welcome\nback to '),
                  TextSpan(text: 'Med ', style: TextStyle(color: L.text)),
                  TextSpan(text: 'Ai', style: TextStyle(color: L.green)),
                ],
              )),
              const SizedBox(height: 8),
              Text(
                _isSignUp
                    ? 'Sign up to sync your medicines across all devices.'
                    : 'Sign in to access your medicine data.',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: L.sub,
                    height: 1.5),
              ),
              const SizedBox(height: 36),

              // ── Google Sign In ─────────────────────────────────────
              _GoogleBtn(onTap: _googleSignIn, loading: _loading),
              const SizedBox(height: 20),

              // ── Divider ────────────────────────────────────────────
              Row(children: [
                Expanded(child: Divider(color: L.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or',
                      style: TextStyle(
                          fontFamily: 'Inter', fontSize: 13, color: L.sub)),
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
                  child: GestureDetector(
                    onTap: _forgotPassword,
                    child: Text('Forgot password?',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: L.green,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],

              // ── Error ──────────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: L.redLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    Icon(Icons.error_outline_rounded, color: L.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: L.red))),
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
                child: GestureDetector(
                  onTap: () => setState(() {
                    _isSignUp = !_isSignUp;
                    _error = null;
                  }),
                  child: RichText(
                      text: TextSpan(
                    style: TextStyle(
                        fontFamily: 'Inter', fontSize: 14, color: L.sub),
                    children: [
                      TextSpan(
                          text: _isSignUp
                              ? 'Already have an account? '
                              : "Don't have an account? "),
                      TextSpan(
                        text: _isSignUp ? 'Sign In' : 'Sign Up',
                        style: TextStyle(
                            color: L.green, fontWeight: FontWeight.w700),
                      ),
                    ],
                  )),
                ),
              ),

              // ── Skip / Continue without account ───────────────────
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () {
                    context.read<AppState>().skipAuth();
                  },
                  child: Text('Continue without account →',
                      style: TextStyle(
                          fontFamily: 'Inter', fontSize: 13, color: L.sub)),
                ),
              ),
              const SizedBox(height: 40),
            ],
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
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: L.border),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Google G logo
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: const Text('G',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.red)),
          ),
          const SizedBox(width: 10),
          Text('Continue with Google',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: L.text)),
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
        color: L.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: L.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: L.text),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(fontFamily: 'Inter', fontSize: 14, color: L.sub),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: suffix != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12), child: suffix)
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
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(label,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
        ),
      ),
    );
  }
}
