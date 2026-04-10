// ignore_for_file: unused_local_variable, unused_import
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../core/utils/haptic_engine.dart';
import '../../models/constants.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../core/utils/date_formatter.dart';

// ══════════════════════════════════════════════════════
// MED AI — 2026 ONBOARDING
// Single-CTA, gesture-first, interactive, conversion-focused
// ══════════════════════════════════════════════════════

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  late AnimationController _fadeCtrl;
  late AnimationController _bgCtrl;
  late Animation<double> _bgPulse;

  final Map<String, dynamic> _form = {
    'name': '',
    'goal': '',
    'target_user': '',
    'med_count': '',
    'pain_points': <String>[],
    'forget_freq': '',
    'wakeTime': {'h': 7, 'm': 0},
    'sleepTime': {'h': 22, 'm': 0},
    'notifPerm': false,
    'avatar': '👤',
    'country': '',
  };

  String _paywallPlan = 'annual';
  int _paywallStep = 0;

  List<_OBStep> get _steps => [
        const _OBStep(id: 'splash', type: 'splash'),
        const _OBStep(
            id: 'goal',
            type: 'single',
            emoji: '🛡️',
            title: "What's your main\nhealth goal?",
            subtitle: 'This shapes your entire AI experience',
            field: 'goal',
            options: kHealthGoals),
        const _OBStep(
            id: 'target_user',
            type: 'single',
            emoji: '🎯',
            title: "Who are you\ntracking for?",
            subtitle: 'You can add family members later',
            field: 'target_user',
            options: kTrackingTargets),
        const _OBStep(
            id: 'name',
            type: 'text',
            emoji: '🤝',
            title: "What's your name?",
            subtitle: "We'll personalise everything for you",
            field: 'name',
            placeholder: 'Your first name'),
        const _OBStep(
            id: 'med_count',
            type: 'single',
            emoji: '💊',
            title: "How many medications\ndo you take?",
            subtitle: 'This helps our AI tailor your schedule',
            field: 'med_count',
            options: kMedCounts),
        const _OBStep(
            id: 'pain_points',
            type: 'multi',
            emoji: '📉',
            title: "Your biggest\nmedication struggle?",
            subtitle: 'Med AI solves all of these for you',
            field: 'pain_points',
            options: kPainPoints),
        const _OBStep(
            id: 'forget_freq',
            type: 'single',
            emoji: '⏰',
            title: "How often do you\nforget a dose?",
            subtitle: "Be honest — no judgment here",
            field: 'forget_freq',
            options: kForgetFreq),
        const _OBStep(id: 'loading_analysis', type: 'loading_analysis'),
        const _OBStep(
            id: 'data_graph',
            type: 'data_graph',
            title: 'Your Adherence Journey',
            subtitle: 'See what Med AI will do for you'),
        const _OBStep(
            id: 'wake_time',
            type: 'time',
            emoji: '☀️',
            title: 'When do you\nwake up?',
            subtitle: 'Used as anchor for your daily tracking',
            field: 'wakeTime'),
        const _OBStep(
            id: 'sleep_time',
            type: 'time',
            emoji: '🌙',
            title: 'When do you\ngo to bed?',
            subtitle: "We won't disturb you while you sleep",
            field: 'sleepTime'),
        const _OBStep(id: 'plan', type: 'plan'),
        const _OBStep(id: 'social_proof', type: 'social_proof'),
        const _OBStep(id: 'notif', type: 'notif'),
        const _OBStep(id: 'paywall', type: 'paywall'),
      ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat(reverse: true);
    _bgPulse = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _steps.length - 1) {
      HapticEngine.selection();
      setState(() => _step++);
      if (_steps[_step].id == 'paywall') {
        context.read<AppState>().logPaywallEvent('paywall_viewed');
      }
      _fadeCtrl.forward(from: 0);
    } else {
      _complete();
    }
  }

  void _back() {
    if (_step > 0 && _steps[_step].type != 'loading_analysis') {
      HapticEngine.selection();
      setState(() => _step--);
      _fadeCtrl.forward(from: 0);
    }
  }

  void _complete() {
    final profile = UserProfile(
      name: _form['name'] ?? '',
      goal: _form['goal'] ?? '',
      targetUser: _form['target_user'] ?? '',
      wakeTime: Map<String, int>.from(_form['wakeTime'] ?? {'h': 7, 'm': 0}),
      sleepTime: Map<String, int>.from(_form['sleepTime'] ?? {'h': 22, 'm': 0}),
      notifPerm: _form['notifPerm'] ?? false,
      avatar: _form['avatar'] ?? '👤',
      country: _form['country'] ?? '',
      promoCode: null,
      appliedPromo: null,
    );
    context.read<AppState>().completeOnboarding(profile);
  }

  bool _canContinue(_OBStep step) {
    if (step.type == 'splash' ||
        step.type == 'social_proof' ||
        step.type == 'notif' ||
        step.type == 'plan' ||
        step.type == 'data_graph' ||
        step.type == 'health_sync') {
      return true;
    }
    if (step.type == 'paywall') return true;
    if (step.field == null) return true;
    final v = _form[step.field!];
    if (v == null) return false;
    if (v is String) return v.isNotEmpty;
    if (v is List) return v.isNotEmpty;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    final isPaywall = step.type == 'paywall';
    final isSplash = step.type == 'splash';
    final isLoading = step.type == 'loading_analysis';
    final progress = (_step + 1) / _steps.length;
    final L = context.L;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: L.bg,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Column(children: [
            // ── Top Bar (hidden on splash, paywall, loading)
            if (!isSplash && !isPaywall && !isLoading)
              _TopBar(
                step: _step,
                total: _steps.length,
                progress: progress,
                onBack: _step > 0 ? _back : null,
              ),

            // ── Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeCtrl,
                child: _buildStep(step, L),
              ),
            ),

            // ── Bottom CTA (only visible on non-auto-advancing steps)
            if (!isPaywall && !isSplash && !isLoading && step.type != 'data_graph')
              _BottomCTA(
                step: step,
                canGo: _canContinue(step),
                onTap: () async {
                  if (step.type == 'notif') {
                    final granted =
                        await NotificationService.requestPermission();
                    setState(() => _form['notifPerm'] = granted);
                  }
                  _next();
                },
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildStep(_OBStep step, AppThemeColors L) {
    switch (step.type) {
      case 'splash':
        return _SplashStep(onNext: _next, pulse: _bgPulse);
      case 'text':
        return _TextStep(
            step: step,
            form: _form,
            onChanged: (k, v) => setState(() => _form[k] = v),
            onNext: _next);
      case 'single':
        return _SingleStep(
            step: step,
            form: _form,
            onSelect: (k, v) {
              setState(() => _form[k] = v);
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted && _canContinue(step)) _next();
              });
            });
      case 'multi':
        return _MultiStep(
            step: step,
            form: _form,
            onSelect: (k, v) => setState(() => _form[k] = v));
      case 'time':
        return _TimeStep(
            step: step,
            form: _form,
            onChanged: (k, v) => setState(() => _form[k] = v));
      case 'notif':
        return _NotifStep(
            form: _form,
            onChanged: (k, v) => setState(() => _form[k] = v));
      case 'plan':
        return _PlanReadyStep(form: _form);
      case 'paywall':
        return _PaywallStep(
          form: _form,
          plan: _paywallPlan,
          paywallStep: _paywallStep,
          onPlanToggle: (p) => setState(() => _paywallPlan = p),
          onNextStep: () => setState(() => _paywallStep++),
          onComplete: _complete,
          onAuth: _next,
        );
      case 'social_proof':
        return _SocialProofStep(form: _form);
      case 'loading_analysis':
        return _LoadingAnalysisStep(onNext: _next);
      case 'data_graph':
        return _DataGraphStep(
            step: step, form: _form, onNext: _next);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DATA MODELS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _OBStep {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String emoji;
  final String? field;
  final String? placeholder;
  final List<Map<String, String>>? options;

  const _OBStep({
    required this.id,
    required this.type,
    this.title = '',
    this.subtitle = '',
    this.emoji = '',
    this.field,
    this.placeholder,
    this.options,
  });
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TOP BAR
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _TopBar extends StatelessWidget {
  final int step, total;
  final double progress;
  final VoidCallback? onBack;

  const _TopBar(
      {required this.step,
      required this.total,
      required this.progress,
      this.onBack});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: AnimatedOpacity(
              opacity: onBack != null ? 1.0 : 0.0,
              duration: 200.ms,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: L.fill,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: L.text, size: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: L.sub.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: v,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: L.text,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: L.text.withValues(alpha: 0.3),
                            blurRadius: 4,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${step + 1}/$total',
            style: AppTypography.labelSmall.copyWith(
              color: L.sub,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BOTTOM CTA — single button, no duplication
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _BottomCTA extends StatelessWidget {
  final _OBStep step;
  final bool canGo;
  final VoidCallback? onTap;

  const _BottomCTA(
      {required this.step, required this.canGo, required this.onTap});

  String get _label {
    switch (step.type) {
      case 'notif':
        return 'Allow Notifications';
      case 'plan':
        return 'See My Plan →';
      case 'social_proof':
        return 'Continue';
      default:
        return 'Continue';
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTap: canGo ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: AnimatedContainer(
          duration: 250.ms,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 19),
          decoration: BoxDecoration(
            color: canGo ? L.text : L.sub.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(32),
            boxShadow: canGo ? AppShadows.glow(L.text, intensity: 0.12) : null,
          ),
          child: Builder(
            builder: (context) {
              final textWidget = Text(
                _label,
                textAlign: TextAlign.center,
                style: AppTypography.labelLarge.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: canGo ? L.bg : L.sub.withValues(alpha: 0.4),
                  letterSpacing: 0.2,
                ),
              );

              if (canGo) {
                return textWidget.animate(onPlay: (c) => c.repeat(reverse: false))
                    .shimmer(duration: 2500.ms, delay: 1000.ms, color: Colors.white54);
              }
              return textWidget;
            },
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STEP HEADER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _StepHeader extends StatelessWidget {
  final String emoji, title, subtitle;

  const _StepHeader({
    required this.title,
    this.subtitle = '',
    this.emoji = '',
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (emoji.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(emoji,
                style: AppTypography.displayLarge.copyWith(
                    fontSize: 44, height: 1.0)),
          ),
        Text(title,
            style: AppTypography.displayLarge.copyWith(
                fontSize: 30,
                color: L.text,
                letterSpacing: -0.8,
                fontWeight: FontWeight.w800,
                height: 1.2)),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(subtitle,
              style: AppTypography.bodyMedium.copyWith(
                  fontSize: 15,
                  color: L.sub,
                  height: 1.5,
                  fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SPLASH — Full-screen brand intro, single tap to start
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _SplashStep extends StatefulWidget {
  final VoidCallback onNext;
  final Animation<double> pulse;
  const _SplashStep({required this.onNext, required this.pulse});

  @override
  State<_SplashStep> createState() => _SplashStepState();
}

class _SplashStepState extends State<_SplashStep>
    with TickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late Animation<double> _float;
  late AnimationController _shimCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat(reverse: true);
    _float = Tween(begin: 0.0, end: -8.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _shimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final isDark = context.isDark;

    return GestureDetector(
      onTap: widget.onNext,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Animated orb background
          AnimatedBuilder(
            animation: widget.pulse,
            builder: (_, __) {
              return Positioned.fill(
                child: CustomPaint(
                  painter: _OrbPainter(
                    progress: widget.pulse.value,
                    color: isDark
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFE8E8E8),
                  ),
                ),
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Logo + App name
                AnimatedBuilder(
                  animation: _float,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _float.value),
                    child: child,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: L.bg,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                              color: L.sub.withValues(alpha: 0.12), width: 1),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Center(
                          child: Image.asset('assets/images/app_logo.png',
                              width: 60, height: 60,
                              errorBuilder: (c, e, s) =>
                                  const Text('💊', style: TextStyle(fontSize: 40))),
                        ),
                      ),
                      const SizedBox(height: 20),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AppTypography.displayLarge.copyWith(
                              fontSize: 38,
                              letterSpacing: -1.2,
                              height: 1.0,
                              fontWeight: FontWeight.w900),
                          children: [
                            TextSpan(
                                text: 'Med',
                                style: TextStyle(color: L.text)),
                            TextSpan(
                                text: ' AI',
                                style: TextStyle(
                                    color: L.text,
                                    fontWeight: FontWeight.w200)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your intelligent medicine companion',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                            fontSize: 15,
                            color: L.sub,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 700.ms,
                          curve: Curves.easeOutCubic),
                ),

                const SizedBox(height: 48),

                // 3 Value props — horizontal cards
                ...[
                  (
                    '🔍',
                    'AI Scan',
                    'Instant medicine identification'
                  ),
                  (
                    '⚡',
                    'Smart Reminders',
                    'Perfectly timed, never annoying'
                  ),
                  (
                    '📈',
                    '98% Adherence',
                    'Average after 30 days with Med AI'
                  ),
                ].asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: L.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: L.glassBorder, width: 1),
                    ),
                    child: Row(children: [
                      Text(item.$1,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$2,
                              style: AppTypography.labelLarge
                                  .copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: L.text)),
                          const SizedBox(height: 2),
                          Text(item.$3,
                              style: AppTypography.bodySmall
                                  .copyWith(
                                      fontSize: 12,
                                      color: L.sub)),
                        ],
                      )),
                    ]),
                  )
                      .animate(delay: (400 + 100 * i).ms)
                      .fadeIn(duration: 400.ms)
                      .slideX(
                          begin: 0.08,
                          end: 0,
                          curve: Curves.easeOutCubic);
                }),

                const Spacer(),

                // Primary CTA — full-width, single
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: L.text,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: AppShadows.glow(L.text, intensity: 0.15),
                  ),
                  child: Text(
                    'Get Started Free →',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelLarge.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: L.bg,
                      letterSpacing: 0.2,
                    ),
                  ),
                )
                    .animate(delay: 800.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(
                        begin: 0.3,
                        end: 0,
                        curve: Curves.easeOutBack),

                const SizedBox(height: 16),
                Text(
                  'Free to start · No credit card required',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                      fontSize: 11, color: L.sub.withValues(alpha: 0.6)),
                ).animate(delay: 900.ms).fadeIn(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Animated orb background painter
class _OrbPainter extends CustomPainter {
  final double progress;
  final Color color;

  _OrbPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.8;
    final cy = size.height * 0.15 + progress * 20;
    final r = size.width * 0.6;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.6), color.withValues(alpha: 0)],
        radius: 0.8,
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    canvas.drawCircle(Offset(cx, cy), r, paint);

    final cx2 = size.width * 0.1;
    final cy2 = size.height * 0.7 - progress * 15;
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0)],
        radius: 0.8,
      ).createShader(
          Rect.fromCircle(center: Offset(cx2, cy2), radius: r * 0.7));
    canvas.drawCircle(Offset(cx2, cy2), r * 0.7, paint2);
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) =>
      old.progress != progress;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TEXT STEP
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _TextStep extends StatefulWidget {
  final _OBStep step;
  final Map<String, dynamic> form;
  final Function(String, String) onChanged;
  final VoidCallback onNext;

  const _TextStep(
      {required this.step,
      required this.form,
      required this.onChanged,
      required this.onNext});

  @override
  State<_TextStep> createState() => _TextStepState();
}

class _TextStepState extends State<_TextStep> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.form[widget.step.field!]?.toString() ?? '');
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final hasVal = _ctrl.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _StepHeader(
              emoji: widget.step.emoji,
              title: widget.step.title,
              subtitle: widget.step.subtitle),
          const SizedBox(height: 32),
          AnimatedContainer(
            duration: 200.ms,
            decoration: BoxDecoration(
              color: L.fill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: hasVal ? L.text : L.sub.withValues(alpha: 0.15),
                  width: 1.5),
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: AppTypography.displayLarge.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: L.text,
                  letterSpacing: -0.3),
              onChanged: (v) => widget.onChanged(widget.step.field!, v),
              onSubmitted: (_) {
                if (hasVal) widget.onNext();
              },
              decoration: InputDecoration(
                hintText: widget.step.placeholder,
                hintStyle: AppTypography.displayLarge.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    color: L.sub.withValues(alpha: 0.35),
                    letterSpacing: -0.3),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.04, end: 0),
        ]),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SINGLE SELECT STEP
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _SingleStep extends StatelessWidget {
  final _OBStep step;
  final Map<String, dynamic> form;
  final Function(String, String) onSelect;

  const _SingleStep(
      {required this.step, required this.form, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final selected = form[step.field!]?.toString() ?? '';
    final isGrid = (step.options?.length ?? 0) > 4;

    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeader(
                emoji: step.emoji,
                title: step.title,
                subtitle: step.subtitle),
            const SizedBox(height: 24),
            if (isGrid)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.15,
                children: step.options!.map((opt) {
                  final val = opt['c'] ?? opt['v']!;
                  return _OptionCard(
                      opt: opt,
                      isSelected: selected == val,
                      isGrid: true,
                      onTap: () => onSelect(step.field!, val));
                }).toList(),
              )
            else
              ...step.options!.asMap().entries.map((e) {
                final i = e.key;
                final opt = e.value;
                final val = opt['c'] ?? opt['v']!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OptionCard(
                    opt: opt,
                    isSelected: selected == val,
                    isGrid: false,
                    onTap: () => onSelect(step.field!, val),
                  ),
                )
                    .animate(delay: (i * 50).ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.04, end: 0);
              }),
          ]),
    );
  }
}

class _OptionCard extends StatefulWidget {
  final Map<String, String> opt;
  final bool isSelected, isGrid;
  final VoidCallback onTap;

  const _OptionCard(
      {required this.opt,
      required this.isSelected,
      required this.isGrid,
      required this.onTap});

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticEngine.selection();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: 150.ms,
        child: AnimatedContainer(
          duration: 200.ms,
          width: double.infinity,
          padding: EdgeInsets.symmetric(
              horizontal: widget.isGrid ? 12 : 20, vertical: 16),
          decoration: BoxDecoration(
            color: widget.isSelected ? L.text : L.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: widget.isSelected
                    ? L.text
                    : L.sub.withValues(alpha: 0.14),
                width: 1.5),
          ),
          child: widget.isGrid
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.opt['e'] != null)
                      Text(widget.opt['e']!,
                          style: const TextStyle(fontSize: 28)),
                    if (widget.opt['e'] != null) const SizedBox(height: 10),
                    Text(widget.opt['v']!,
                        textAlign: TextAlign.center,
                        style: AppTypography.labelLarge.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: widget.isSelected ? L.bg : L.text)),
                  ],
                )
              : Row(children: [
                  if (widget.opt['e'] != null)
                    Text(widget.opt['e']!,
                        style: const TextStyle(fontSize: 22)),
                  if (widget.opt['e'] != null) const SizedBox(width: 14),
                  Expanded(
                      child: Text(widget.opt['v']!,
                          style: AppTypography.bodyMedium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color:
                                  widget.isSelected ? L.bg : L.text))),
                  if (widget.isSelected)
                    Icon(Icons.check_circle_rounded,
                            color: L.bg, size: 18)
                        .animate()
                        .scale(duration: 200.ms, curve: Curves.easeOutBack),
                ]),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MULTI SELECT STEP
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _MultiStep extends StatelessWidget {
  final _OBStep step;
  final Map<String, dynamic> form;
  final Function(String, List<String>) onSelect;

  const _MultiStep(
      {required this.step, required this.form, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final selected = List<String>.from(form[step.field!] ?? []);
    final L = context.L;

    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _StepHeader(
            emoji: step.emoji,
            title: step.title,
            subtitle: step.subtitle),
        const SizedBox(height: 24),
        ...(step.options ?? []).asMap().entries.map((e) {
          final i = e.key;
          final opt = e.value;
          final isSel = selected.contains(opt['v']!);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MultiOptionRow(
              opt: opt,
              isSelected: isSel,
              onTap: () {
                HapticEngine.selection();
                final newSel = isSel
                    ? (selected..remove(opt['v']!))
                    : [...selected, opt['v']!];
                onSelect(step.field!, newSel);
              },
            ),
          )
              .animate(delay: (i * 50).ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.04, end: 0);
        }),
      ]),
    );
  }
}

class _MultiOptionRow extends StatefulWidget {
  final Map<String, String> opt;
  final bool isSelected;
  final VoidCallback onTap;

  const _MultiOptionRow(
      {required this.opt,
      required this.isSelected,
      required this.onTap});

  @override
  State<_MultiOptionRow> createState() => _MultiOptionRowState();
}

class _MultiOptionRowState extends State<_MultiOptionRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: 150.ms,
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: widget.isSelected ? L.text : L.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: widget.isSelected
                    ? L.text
                    : L.sub.withValues(alpha: 0.14),
                width: 1.5),
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: 200.ms,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isSelected ? L.bg : Colors.transparent,
                border: Border.all(
                    color: widget.isSelected
                        ? L.bg
                        : L.sub.withValues(alpha: 0.3),
                    width: 2),
              ),
              child: widget.isSelected
                  ? Icon(Icons.check_rounded, color: L.text, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            if (widget.opt['e'] != null)
              Text(widget.opt['e']!,
                  style: const TextStyle(fontSize: 20)),
            if (widget.opt['e'] != null) const SizedBox(width: 10),
            Expanded(
              child: Text(widget.opt['v']!,
                  style: AppTypography.bodyMedium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: widget.isSelected ? L.bg : L.text)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TIME STEP
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _TimeStep extends StatelessWidget {
  final _OBStep step;
  final Map<String, dynamic> form;
  final Function(String, Map<String, int>) onChanged;

  const _TimeStep(
      {required this.step,
      required this.form,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final time =
        Map<String, int>.from(form[step.field!] ?? {'h': 8, 'm': 0});
    final h = time['h'] ?? 8;
    final m = time['m'] ?? 0;

    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _StepHeader(
            emoji: step.emoji,
            title: step.title,
            subtitle: step.subtitle),
        const SizedBox(height: 32),

        // Quick time presets
        Row(children: kQuickTimes.map((qt) {
          final isActive = h == qt['h'] && m == qt['m'];
          return Expanded(
              child: GestureDetector(
            onTap: () {
              HapticEngine.selection();
              onChanged(step.field!, {
                'h': qt['h'] as int,
                'm': qt['m'] as int
              });
            },
            child: AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isActive ? L.text : L.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isActive
                        ? L.text
                        : L.sub.withValues(alpha: 0.12),
                    width: 1.5),
              ),
              child: Column(children: [
                Text(qt['emoji'] as String,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 4),
                Text(qt['label'] as String,
                    style: AppTypography.labelSmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? L.bg
                            : L.sub.withValues(alpha: 0.6))),
              ]),
            ),
          ));
        }).toList()),
        const SizedBox(height: 24),

        // Central time display — tappable wheel feel
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: L.sub.withValues(alpha: 0.1), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _TimeCounter(
                  value: h,
                  min: 0,
                  max: 23,
                  onChanged: (v) =>
                      onChanged(step.field!, {'h': v, 'm': m})),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(':',
                    style: AppTypography.displayLarge.copyWith(
                        fontSize: 36,
                        color: L.sub.withValues(alpha: 0.4))),
              ),
              _TimeCounter(
                  value: m,
                  min: 0,
                  max: 59,
                  onChanged: (v) =>
                      onChanged(step.field!, {'h': h, 'm': v})),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: L.fill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(h >= 12 ? 'PM' : 'AM',
                    style: AppTypography.labelLarge.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: L.text)),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _TimeCounter extends StatelessWidget {
  final int value, min, max;
  final ValueChanged<int> onChanged;

  const _TimeCounter(
      {required this.value,
      required this.min,
      required this.max,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Column(children: [
      GestureDetector(
        onTap: () {
          HapticEngine.selection();
          onChanged(value < max ? value + 1 : min);
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(Icons.keyboard_arrow_up_rounded,
              color: L.sub, size: 24),
        ),
      ),
      Text(value.toString().padLeft(2, '0'),
          style: AppTypography.displayLarge.copyWith(
              fontSize: 44,
              color: L.text,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5)),
      GestureDetector(
        onTap: () {
          HapticEngine.selection();
          onChanged(value > min ? value - 1 : max);
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(Icons.keyboard_arrow_down_rounded,
              color: L.sub, size: 24),
        ),
      ),
    ]);
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LOADING ANALYSIS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _LoadingAnalysisStep extends StatefulWidget {
  final VoidCallback onNext;
  const _LoadingAnalysisStep({required this.onNext});

  @override
  State<_LoadingAnalysisStep> createState() => _LoadingAnalysisStepState();
}

class _LoadingAnalysisStepState extends State<_LoadingAnalysisStep>
    with SingleTickerProviderStateMixin {
  int _idx = 0;
  double _manualProgress = 0;
  late AnimationController _spinCtrl;

  int _subIdx = 0;
  Timer? _subTimer;

  final List<String> _subStages = [
    'Scanning health records...',
    'Analyzing adherence vectors...',
    'Optimizing dosages...',
    'Calculating correlations...',
    'Evaluating interactions...',
    'Building safety profiles...',
    'Simulating 30-day outcomes...',
    'Finalizing recommendations...',
  ];

  final List<(String, String)> _stages = [
    ('🔍', 'Analyzing your health profile...'),
    ('📊', 'Calculating adherence patterns...'),
    ('🧠', 'Building AI recommendations...'),
    ('⚡', 'Optimizing your reminder schedule...'),
    ('🛡️', 'Generating your 30-day projection...'),
    ('✅', 'Your plan is ready!'),
  ];

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _subTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (mounted) setState(() => _subIdx = (_subIdx + 1) % _subStages.length);
    });
    _run();
  }

  Future<void> _run() async {
    final delays = [1200, 800, 1500, 1000, 1400, 600];
    for (int i = 0; i < _stages.length; i++) {
      await Future.delayed(Duration(milliseconds: delays[i]));
      if (!mounted) return;
      setState(() {
        _idx = i;
        _manualProgress = (i + 1) / _stages.length;
      });
    }
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) widget.onNext();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _subTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final stage = _stages[_idx];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated ring
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RotationTransition(
                  turns: _spinCtrl,
                  child: CustomPaint(
                    size: const Size(120, 120),
                    painter: _ArcPainter(
                        progress: _manualProgress, color: L.text),
                  ),
                ),
                Text(stage.$1, style: const TextStyle(fontSize: 36)),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 40),

          AnimatedSwitcher(
            duration: 400.ms,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero)
                    .animate(anim),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(_idx),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(stage.$2,
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineMedium.copyWith(
                        fontSize: 20,
                        color: L.text,
                        letterSpacing: -0.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (_idx < _stages.length - 1)
                  Text(_subStages[_subIdx],
                      style: AppTypography.bodySmall.copyWith(
                          fontSize: 12,
                          color: L.sub.withValues(alpha: 0.6),
                          letterSpacing: 0.2,
                          fontStyle: FontStyle.italic))
                      .animate(key: ValueKey(_subIdx))
                      .fadeIn(duration: 100.ms),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _manualProgress),
              duration: 800.ms,
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 3,
                backgroundColor: L.sub.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(L.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final bg = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, bg);

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        rect, -math.pi / 2, math.pi * 2 * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.progress != progress;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// INTERACTIVE DATA GRAPH STEP
// Shows before → after adherence with animated, touchable chart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _DataGraphStep extends StatefulWidget {
  final _OBStep step;
  final Map<String, dynamic> form;
  final VoidCallback onNext;

  const _DataGraphStep(
      {required this.step, required this.form, required this.onNext});

  @override
  State<_DataGraphStep> createState() => _DataGraphStepState();
}

class _DataGraphStepState extends State<_DataGraphStep>
    with TickerProviderStateMixin {
  late AnimationController _lineCtrl;
  late AnimationController _shineCtrl;
  bool _showAfter = false;
  int? _hoveredIdx;

  // "Before" adherence curve (fragmented, low)
  final List<double> _before = [
    0.45, 0.62, 0.38, 0.55, 0.40, 0.70, 0.35, 0.60, 0.42, 0.65, 0.48, 0.72
  ];

  // "After" adherence curve (smooth rise to 98%)
  final List<double> _after = [
    0.55, 0.68, 0.72, 0.79, 0.82, 0.86, 0.88, 0.91, 0.94, 0.96, 0.97, 0.98
  ];

  @override
  void initState() {
    super.initState();
    _lineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _shineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _lineCtrl.forward();
  }

  @override
  void dispose() {
    _lineCtrl.dispose();
    _shineCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticEngine.selection();
    setState(() {
      _showAfter = !_showAfter;
      _hoveredIdx = null;
    });
    _lineCtrl.forward(from: 0);
  }

  List<double> get _data => _showAfter ? _after : _before;
  double get _avgAdherence {
    final avg =
        _data.fold(0.0, (a, b) => a + b) / _data.length;
    return avg * 100;
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final accentColor = _showAfter ? L.green : L.red;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle row — before/after switch
                Row(children: [
                  GestureDetector(
                    onTap: _showAfter ? _toggle : null,
                    child: AnimatedContainer(
                      duration: 250.ms,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: !_showAfter ? L.text : L.fill,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('Without Med AI',
                          style: AppTypography.labelLarge.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: !_showAfter
                                  ? L.bg
                                  : L.sub)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: !_showAfter ? _toggle : null,
                    child: AnimatedContainer(
                      duration: 250.ms,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _showAfter ? L.text : L.fill,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('With Med AI ✨',
                          style: AppTypography.labelLarge.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _showAfter ? L.bg : L.sub)),
                    ),
                  ),
                ]),

                const SizedBox(height: 20),

                // Big adherence number
                AnimatedSwitcher(
                  duration: 500.ms,
                  child: RichText(
                    key: ValueKey(_showAfter),
                    text: TextSpan(
                      style: AppTypography.displayLarge.copyWith(
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2,
                          height: 1.0),
                      children: [
                        TextSpan(
                            text: _avgAdherence.toStringAsFixed(0),
                            style: TextStyle(color: accentColor)),
                        TextSpan(
                            text: '%',
                            style: TextStyle(
                                color:
                                    accentColor.withValues(alpha: 0.5),
                                fontSize: 32)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: 300.ms,
                  child: Text(
                    _showAfter
                        ? 'Projected adherence with Med AI'
                        : 'Average adherence without a tracker',
                    key: ValueKey(_showAfter),
                    style: AppTypography.bodyMedium.copyWith(
                        fontSize: 13, color: L.sub),
                  ),
                ),

                const SizedBox(height: 24),

                // Interactive chart
                GestureDetector(
                  onHorizontalDragUpdate: (d) {
                    final w = context.size?.width ?? 300;
                    final relX = (d.localPosition.dx - 24).clamp(
                        0.0, w - 48);
                    final idx = ((relX / (w - 48)) * (_data.length - 1))
                        .round()
                        .clamp(0, _data.length - 1);
                    if (_hoveredIdx != idx) {
                      HapticEngine.selection();
                      setState(() => _hoveredIdx = idx);
                    }
                  },
                  onHorizontalDragEnd: (_) =>
                      setState(() => _hoveredIdx = null),
                  onTapDown: (d) {
                    final w = context.size?.width ?? 300;
                    final relX = (d.localPosition.dx - 24).clamp(
                        0.0, w - 48);
                    final idx = ((relX / (w - 48)) * (_data.length - 1))
                        .round()
                        .clamp(0, _data.length - 1);
                    setState(() => _hoveredIdx = idx);
                  },
                  onTapUp: (_) => setState(() => _hoveredIdx = null),
                  child: AnimatedBuilder(
                    animation: _lineCtrl,
                    builder: (_, __) => CustomPaint(
                      size: const Size(double.infinity, 180),
                      painter: _AdherenceChartPainter(
                        data: _data,
                        progress: _lineCtrl.value,
                        hoveredIdx: _hoveredIdx,
                        lineColor: accentColor,
                        fillColor:
                            accentColor.withValues(alpha: 0.12),
                        gridColor:
                            L.sub.withValues(alpha: 0.08),
                        textColor: L.sub,
                      ),
                    ),
                  ),
                ),

                // Month labels
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      6,
                      (i) => Text(months[i * 2],
                          style: AppTypography.labelSmall.copyWith(
                              fontSize: 10, color: L.sub)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Tooltip if hovered
                if (_hoveredIdx != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: L.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Text(months[_hoveredIdx!],
                          style: AppTypography.labelLarge
                              .copyWith(fontSize: 13, color: L.text)),
                      const Spacer(),
                      Text(
                          '${(_data[_hoveredIdx!] * 100).toStringAsFixed(0)}%',
                          style: AppTypography.labelLarge.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: accentColor)),
                    ]),
                  )
                      .animate()
                      .fadeIn(duration: 200.ms)
                      .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                // Stats row
                Row(children: [
                  Expanded(
                      child: _StatCard(
                    label: _showAfter ? 'Med AI Users' : 'Average User',
                    value: _showAfter ? '98%' : '52%',
                    suffix: 'adherence',
                    color: accentColor,
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _StatCard(
                    label: 'Improvement',
                    value: _showAfter ? '+46%' : '---',
                    suffix: 'in 30 days',
                    color: accentColor,
                  )),
                ]),

                const SizedBox(height: 16),

                // Insight text
                AnimatedSwitcher(
                  duration: 400.ms,
                  child: Container(
                    key: ValueKey(_showAfter),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: accentColor.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      _showAfter
                          ? '💡 People using Med AI reach 98% adherence within 30 days. Late doses dropped by 94% on average.'
                          : '⚠️ Without a tracker, most people only take 52% of medications correctly. This significantly impacts health outcomes.',
                      style: AppTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          color: L.text,
                          height: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom CTA — only one button here
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: GestureDetector(
            onTap: widget.onNext,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 19),
              decoration: BoxDecoration(
                color: L.text,
                borderRadius: BorderRadius.circular(32),
                boxShadow: AppShadows.glow(L.text, intensity: 0.12),
              ),
              child: Text(
                _showAfter
                    ? "I want this for myself →"
                    : "See what Med AI does →",
                textAlign: TextAlign.center,
                style: AppTypography.labelLarge.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: L.bg,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, suffix;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.suffix,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: L.glassBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: AppTypography.labelSmall
                .copyWith(fontSize: 10, color: L.sub, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value,
            style: AppTypography.displayLarge.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -1)),
        Text(suffix,
            style: AppTypography.bodySmall
                .copyWith(fontSize: 11, color: L.sub)),
      ]),
    );
  }
}

// Custom chart painter
class _AdherenceChartPainter extends CustomPainter {
  final List<double> data;
  final double progress;
  final int? hoveredIdx;
  final Color lineColor, fillColor, gridColor, textColor;

  _AdherenceChartPainter({
    required this.data,
    required this.progress,
    required this.hoveredIdx,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final n = data.length;

    // Grid lines
    for (int i = 0; i <= 4; i++) {
      final y = h - (h * (i / 4));
      final p = Paint()
        ..color = gridColor
        ..strokeWidth = 0.8;
      canvas.drawLine(Offset(0, y), Offset(w, y), p);
    }

    // Convert to screen points (only up to progress)
    final visibleCount = ((n - 1) * progress).ceil() + 1;
    final pts = List.generate(
        visibleCount.clamp(0, n),
        (i) => Offset(
              w * (i / (n - 1)),
              h - (h * data[i].clamp(0.0, 1.0) * 0.88 + h * 0.06),
            ));

    if (pts.length < 2) return;

    // Fill path
    final fillPath = Path()..moveTo(pts.first.dx, h);
    for (int i = 0; i < pts.length; i++) {
      if (i == 0) {
        fillPath.lineTo(pts[i].dx, pts[i].dy);
      } else {
        final prev = pts[i - 1];
        final cp1 = Offset((prev.dx + pts[i].dx) / 2, prev.dy);
        final cp2 = Offset((prev.dx + pts[i].dx) / 2, pts[i].dy);
        fillPath.cubicTo(
            cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i].dx, pts[i].dy);
      }
    }
    fillPath.lineTo(pts.last.dx, h);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    // Line path
    final linePath = Path();
    linePath.moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final cp1 = Offset((prev.dx + pts[i].dx) / 2, prev.dy);
      final cp2 = Offset((prev.dx + pts[i].dx) / 2, pts[i].dy);
      linePath.cubicTo(
          cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i].dx, pts[i].dy);
    }
    // Line path with Glow
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Outer Glow
    canvas.drawPath(
        linePath,
        Paint()
          ..color = lineColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0));

    canvas.drawPath(linePath, linePaint);

    // Hover indicator
    if (hoveredIdx != null && hoveredIdx! < pts.length) {
      final hpt = pts[hoveredIdx!];
      canvas.drawCircle(
          hpt,
          5,
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.fill);
      canvas.drawCircle(
          hpt,
          9,
          Paint()
            ..color = lineColor.withValues(alpha: 0.25)
            ..style = PaintingStyle.fill);
      // Vertical line
      canvas.drawLine(
          Offset(hpt.dx, 0),
          Offset(hpt.dx, h),
          Paint()
            ..color = lineColor.withValues(alpha: 0.25)
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _AdherenceChartPainter old) =>
      old.progress != progress ||
      old.hoveredIdx != hoveredIdx ||
      old.data != data;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NOTIF STEP
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _NotifStep extends StatelessWidget {
  final Map<String, dynamic> form;
  final Function(String, dynamic) onChanged;

  const _NotifStep(
      {required this.form, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: L.fill,
            shape: BoxShape.circle,
          ),
          child: const Center(
              child: Text('🔔', style: TextStyle(fontSize: 46))),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.06, 1.06),
                duration: 2.seconds,
                curve: Curves.easeInOut),
        const SizedBox(height: 36),
        Text('Never miss\na dose again',
            textAlign: TextAlign.center,
            style: AppTypography.displayLarge.copyWith(
                fontSize: 34,
                color: L.text,
                letterSpacing: -1.2,
                height: 1.1)),
        const SizedBox(height: 16),
        Text(
            'Smart reminders adapt to your schedule — morning, evening, or whenever you need.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
                fontSize: 15, color: L.sub, height: 1.6)),
        const SizedBox(height: 40),

        // Visual reminder preview
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: L.glassBorder),
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: L.fill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                  child: Text('💊',
                      style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Med AI Reminder',
                    style: AppTypography.labelLarge.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: L.text)),
                Text('Time to take your Aspirin 100mg',
                    style: AppTypography.bodySmall.copyWith(
                        fontSize: 12, color: L.sub)),
              ],
            )),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: L.text,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('Mark Done',
                  style: AppTypography.labelSmall.copyWith(
                      fontSize: 10, color: L.bg)),
            )
          ]),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
      ]),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PLAN READY STEP
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _PlanReadyStep extends StatelessWidget {
  final Map<String, dynamic> form;
  const _PlanReadyStep({required this.form});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final name = form['name']?.toString() ?? '';
    final goal = form['goal']?.toString() ?? '';
    final wt = form['wakeTime'] as Map<String, int>? ?? {'h': 7, 'm': 0};
    final st = form['sleepTime'] as Map<String, int>? ?? {'h': 22, 'm': 0};

    final items = [
      if (goal.isNotEmpty) ('🎯', 'Goal', goal),
      ('⏰', 'Wake reminder',
          '${wt['h'].toString().padLeft(2, '0')}:${wt['m'].toString().padLeft(2, '0')}'),
      ('🌙', 'Sleep mode',
          '${st['h'].toString().padLeft(2, '0')}:${st['m'].toString().padLeft(2, '0')}'),
      ('🧠', 'AI mode', 'Fully personalised'),
      ('🛡️', 'Streak tracking', 'Activated'),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          // Bursting icons
          ...['✨', '💊', '🎯', '🚀', '🔥'].asMap().entries.map((e) {
            final i = e.key;
            final icon = e.value;
            final double angle = (i * (360 / 5)) * (math.pi / 180);
            return Text(icon, style: const TextStyle(fontSize: 24))
                .animate(delay: 400.ms)
                .scale(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 400.ms)
                .move(
                    begin: Offset.zero,
                    end: Offset(math.cos(angle) * 80, math.sin(angle) * 80),
                    duration: 600.ms,
                    curve: Curves.easeOutCubic)
                .fadeOut(delay: 200.ms, duration: 400.ms);
          }),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: L.fill,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: context.isDark ? Colors.white10 : Colors.black12,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: const Center(child: Text('📊', style: TextStyle(fontSize: 40))),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        ]),
        const SizedBox(height: 20),
        Text(
          'Your plan is ready${name.isNotEmpty ? ", $name" : ""}!',
          textAlign: TextAlign.center,
          style: AppTypography.displayLarge.copyWith(
              fontSize: 30,
              color: L.text,
              letterSpacing: -1.0,
              height: 1.15),
        ),
        const SizedBox(height: 8),
        Text(
          'Based on your answers, we\'ve built the perfect AI track for you.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium
              .copyWith(fontSize: 14, color: L.sub, height: 1.5),
        ),
        const SizedBox(height: 24),

        ...items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: L.glassBorder),
            ),
            child: Row(children: [
              Text(item.$1, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(item.$2,
                      style: AppTypography.bodySmall.copyWith(
                          fontSize: 13, color: L.sub))),
              Text(item.$3,
                  style: AppTypography.labelLarge.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: L.text)),
            ]),
          )
              .animate(delay: (100 * i).ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.06, end: 0);
        }),

        const SizedBox(height: 20),

        // 94% stat
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: L.glassBorder),
          ),
          child: Column(children: [
            Text('94%',
                style: AppTypography.displayLarge.copyWith(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: L.text,
                    letterSpacing: -2)),
            const SizedBox(height: 6),
            Text('of similar users improved adherence in 2 weeks',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall
                    .copyWith(fontSize: 13, color: L.sub, height: 1.5)),
            const SizedBox(height: 20),
            // Bar chart
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [22.0, 34.0, 50.0, 72.0, 100.0]
                  .asMap()
                  .entries
                  .map((e) {
                final isLast = e.key == 4;
                return Flexible(
                  child: Container(
                    width: 24,
                    height: e.value,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: isLast ? L.text : L.sub.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  )
                      .animate()
                      .scaleY(
                          begin: 0,
                          end: 1,
                          alignment: Alignment.bottomCenter,
                          duration: 600.ms,
                          delay: (e.key * 80).ms,
                          curve: Curves.easeOutBack),
                );
              }).toList(),
            ),
          ]),
        ).animate(delay: 600.ms).fadeIn(duration: 400.ms),
      ]),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SOCIAL PROOF STEP
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _SocialProofStep extends StatelessWidget {
  final Map<String, dynamic> form;
  const _SocialProofStep({required this.form});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final name = form['name']?.toString() ?? '';

    final testimonials = [
      (
        'Sarah K.',
        '⭐⭐⭐⭐⭐',
        '"I haven\'t missed a single dose in 3 months. The AI reminders are perfectly timed."',
        '🧑‍💼'
      ),
      (
        'Marcus T.',
        '⭐⭐⭐⭐⭐',
        '"Finally an app that understands complex pill schedules. It changed my life."',
        '👨‍🔬'
      ),
      (
        'Aiko N.',
        '⭐⭐⭐⭐⭐',
        '"I manage meds for my mom. This app makes it stress-free and reliable."',
        '👩'
      ),
    ];

    final stats = [
      ('2.4M+', 'Active users'),
      ('98%', 'Avg adherence'),
      ('4.9★', 'App Store rating'),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isNotEmpty
                ? '$name, you\'re in great\ncompany'
                : 'You\'re joining\n2.4M+ people',
            style: AppTypography.displayLarge.copyWith(
                fontSize: 30,
                color: L.text,
                letterSpacing: -0.8,
                height: 1.2),
          ),
          const SizedBox(height: 8),
          Text('See what real users say about Med AI',
              style: AppTypography.bodyMedium
                  .copyWith(fontSize: 14, color: L.sub)),
          const SizedBox(height: 24),

          // Stats row
          Row(children: stats.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: L.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: L.glassBorder),
                ),
                child: Column(children: [
                  Text(s.$1,
                      style: AppTypography.displayLarge.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: L.text,
                          letterSpacing: -0.5)),
                  Text(s.$2,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall
                          .copyWith(fontSize: 10, color: L.sub)),
                ]),
              ),
            ).animate(delay: (i * 100).ms).fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
          }).toList()),

          const SizedBox(height: 20),

          ...testimonials.asMap().entries.map((e) {
            final i = e.key;
            final t = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: L.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: L.glassBorder),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(t.$4,
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.$1,
                                style: AppTypography.labelLarge
                                    .copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: L.text)),
                            Text(t.$2,
                                style: const TextStyle(fontSize: 11)),
                          ]),
                    ]),
                    const SizedBox(height: 12),
                    Text(t.$3,
                        style: AppTypography.bodyMedium.copyWith(
                            fontSize: 14,
                            color: L.text.withValues(alpha: 0.85),
                            fontStyle: FontStyle.italic,
                            height: 1.5)),
                  ]),
            )
                .animate(delay: (150 * i).ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.08, end: 0);
          }),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PAYWALL — streamlined conversion screen
// No duplicate buttons, single clear CTA
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _PaywallStep extends StatelessWidget {
  final Map<String, dynamic> form;
  final String plan;
  final int paywallStep;
  final Function(String) onPlanToggle;
  final VoidCallback onNextStep;
  final VoidCallback onComplete;
  final VoidCallback onAuth;

  const _PaywallStep({
    required this.form,
    required this.plan,
    required this.paywallStep,
    required this.onPlanToggle,
    required this.onNextStep,
    required this.onComplete,
    required this.onAuth,
  });

  @override
  Widget build(BuildContext context) {
    if (paywallStep == 0) {
      return _PaywallMain(
        plan: plan,
        onToggle: onPlanToggle,
        onSkip: onComplete,
        onNext: onNextStep,
        onAuth: onAuth,
      );
    }
    return _PaywallTimeline(
      plan: plan,
      onComplete: onComplete,
    );
  }
}

class _PaywallMain extends StatelessWidget {
  final String plan;
  final Function(String) onToggle;
  final VoidCallback onNext, onSkip, onAuth;

  const _PaywallMain({
    required this.plan,
    required this.onToggle,
    required this.onNext,
    required this.onSkip,
    required this.onAuth,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    final features = [
      ('🔍', 'AI Medicine Scanner', 'Instant ID of any medicine'),
      ('⏰', 'Smart Reminders', 'Perfectly timed alerts'),
      ('📈', '98% Adherence', 'Clinically proven results'),
      ('🛡️', 'Streak Protection', 'Never lose your progress'),
      ('👪', 'Family Sharing', 'Manage meds for your family'),
      ('🔐', 'Private & Encrypted', 'Your data stays yours'),
    ];

    final plans = [
      {
        'id': 'annual',
        'label': 'Annual',
        'sub': 'Best value',
        'price': fmtCurrency(7.58, context),
        'per': '/month',
        'total': 'Billed ${fmtCurrency(91.0, context)}/year',
        'save': 'Save 24%',
      },
      {
        'id': 'monthly',
        'label': 'Monthly',
        'sub': 'Flexible',
        'price': fmtCurrency(9.90, context),
        'per': '/month',
        'total': 'Cancel anytime',
        'save': null,
      },
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: L.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text('MEDAI PRO',
              style: AppTypography.labelSmall.copyWith(
                  fontSize: 10,
                  color: L.green,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 10),
        Text("The most advanced\nmedication AI",
            style: AppTypography.displayLarge.copyWith(
                fontSize: 32,
                color: L.text,
                letterSpacing: -1.0,
                height: 1.1)),
        const SizedBox(height: 6),
        Text('Start with 3 free AI scans. No card needed.',
            style: AppTypography.bodyMedium.copyWith(
                fontSize: 14, color: L.sub)),

        const SizedBox(height: 24),

        // Features grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.8),
          itemCount: features.length,
          itemBuilder: (_, i) {
            final f = features[i];
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: L.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: L.glassBorder),
              ),
              child: Row(children: [
                Text(f.$1, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(f.$2,
                        style: AppTypography.labelLarge.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: L.text),
                        maxLines: 2)),
              ]),
            )
                .animate(delay: (50 * i).ms)
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.06, end: 0);
          },
        ),

        const SizedBox(height: 20),

        // Plan toggle
        Row(children: plans.map((p) {
          final isSel = plan == p['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticEngine.selection();
                onToggle(p['id'] as String);
              },
              child: AnimatedContainer(
                duration: 250.ms,
                margin: EdgeInsets.only(
                    right: p['id'] == 'annual' ? 8 : 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSel ? L.text : L.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: isSel
                          ? L.text
                          : L.sub.withValues(alpha: 0.15),
                      width: 1.5),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p['save'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSel
                                ? L.bg
                                : L.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(p['save']!,
                              style: AppTypography.labelSmall.copyWith(
                                  fontSize: 9,
                                  color: isSel ? L.text : L.green,
                                  fontWeight: FontWeight.w900)),
                        ),
                      if (p['save'] != null) const SizedBox(height: 4),
                      Text(p['price'] as String,
                          style: AppTypography.displayLarge.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color:
                                  isSel ? L.bg : L.text,
                              letterSpacing: -0.5)),
                      Text(p['per'] as String,
                          style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              color: isSel
                                  ? L.bg.withValues(alpha: 0.6)
                                  : L.sub)),
                      const SizedBox(height: 4),
                      Text(p['total'] as String,
                          style: AppTypography.bodySmall.copyWith(
                              fontSize: 10,
                              color: isSel
                                  ? L.bg.withValues(alpha: 0.6)
                                  : L.sub)),
                    ]),
              ),
            ),
          );
        }).toList()),

        const SizedBox(height: 20),

        // Primary CTA — single
        GestureDetector(
          onTap: onNext,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 19),
            decoration: BoxDecoration(
              color: L.text,
              borderRadius: BorderRadius.circular(32),
              boxShadow: AppShadows.glow(L.text, intensity: 0.15),
            ),
            child: Text('Start Free — 3 AI Scans',
                textAlign: TextAlign.center,
                style: AppTypography.labelLarge.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: L.bg,
                    letterSpacing: 0.2)),
          ),
        ),

        const SizedBox(height: 10),

        Center(
            child: Text('No charge today · Cancel anytime',
                style: AppTypography.bodySmall
                    .copyWith(fontSize: 12, color: L.sub))),

        const SizedBox(height: 20),

        // Auth options
        _AuthButtons(onAuth: onAuth),

        const SizedBox(height: 20),

        // Skip — very small, low contrast
        Center(
          child: GestureDetector(
            onTap: () {
              context.read<AppState>().logPaywallEvent('paywall_skipped');
              onSkip();
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('Continue with free plan',
                  style: AppTypography.bodySmall.copyWith(
                      fontSize: 12,
                      color: L.sub.withValues(alpha: 0.45),
                      decoration: TextDecoration.underline)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _AuthButtons extends StatelessWidget {
  final VoidCallback onAuth;
  const _AuthButtons({required this.onAuth});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildBtn(
          'Continue with Apple',
          null,
          () async {
            await AuthService.signInWithApple();
            onAuth();
          },
          icon: Icons.apple_rounded),
      const SizedBox(height: 10),
      _buildBtn('Continue with Google', 'assets/images/google_logo.png',
          () async {
        await AuthService.signInWithGoogle();
        onAuth();
      }),
    ]);
  }

  Widget _buildBtn(String label, String? asset, VoidCallback onTap,
      {IconData? icon}) {
    return Builder(builder: (context) {
      final L = context.L;
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.black.withValues(alpha: 0.08))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (asset != null)
              Image.asset(asset,
                  width: 18,
                  height: 18,
                  errorBuilder: (c, e, s) =>
                      const Icon(Icons.login, size: 18, color: Colors.black))
            else if (icon != null)
              Icon(icon, size: 20, color: Colors.black),
            const SizedBox(width: 10),
            Text(label,
                style: AppTypography.labelLarge.copyWith(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      );
    });
  }
}

class _PaywallTimeline extends StatelessWidget {
  final String plan;
  final VoidCallback onComplete;

  const _PaywallTimeline(
      {required this.plan, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    final steps = [
      ('🚀', 'Today', 'MedAI activated with 3 free AI scans'),
      ('📱', 'Day 7',
          'Your reminders adapt based on your real habits'),
      ('🛡️', plan == 'annual' ? 'After 3 Scans' : 'After 3 Scans',
          plan == 'annual'
              ? '${fmtCurrency(91.0, context)}/year billed'
              : '${fmtCurrency(9.90, context)}/month billed'),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Here's exactly\nwhat happens",
                style: AppTypography.displayLarge.copyWith(
                    fontSize: 32,
                    color: L.text,
                    letterSpacing: -1.0,
                    height: 1.1)),
            const SizedBox(height: 8),
            Text('No surprises. No confusion.',
                style: AppTypography.bodyMedium
                    .copyWith(fontSize: 14, color: L.sub)),
            const SizedBox(height: 32),

            // Timeline
            ...steps.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == 0 ? L.text : L.fill,
                        border: Border.all(
                            color: i == 0
                                ? L.text
                                : L.sub.withValues(alpha: 0.2),
                            width: 2),
                      ),
                      child: Center(
                          child: Text(s.$1,
                              style: const TextStyle(fontSize: 18))),
                    ),
                    if (i < steps.length - 1)
                      Container(
                        width: 2,
                        height: 60,
                        color: L.sub.withValues(alpha: 0.12),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                  ]),
                  const SizedBox(width: 16),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.$2,
                              style: AppTypography.labelLarge.copyWith(
                                  fontSize: 12,
                                  color: L.sub,
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text(s.$3,
                              style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: L.text)),
                        ]),
                  ),
                ],
              )
                  .animate(delay: (100 * i).ms)
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: 0.06, end: 0);
            }),

            const SizedBox(height: 32),

            // Trust badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ('🔒', 'Secure'),
                ('❌', 'Cancel anytime'),
                ('📨', 'Reminder before charge'),
              ].map((b) {
                return Column(children: [
                  Text(b.$1, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(b.$2,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                          fontSize: 10, color: L.sub)),
                ]);
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Final CTA
            GestureDetector(
              onTap: () async {
                HapticEngine.selection();
                await context.read<AppState>().purchasePremium(plan);
                onComplete();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 19),
                decoration: BoxDecoration(
                  color: L.text,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: AppShadows.glow(L.text, intensity: 0.15),
                ),
                child: Text('Start with 3 Free Scans 🚀',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelLarge.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: L.bg,
                        letterSpacing: 0.2)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                  'Unlock unlimited tracking and AI safety analysis.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall
                      .copyWith(fontSize: 12, color: L.sub, height: 1.5)),
            ),
          ]),
    );
  }
}
