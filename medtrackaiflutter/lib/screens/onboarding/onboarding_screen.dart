import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../domain/entities/entities.dart';
import '../../core/utils/haptic_engine.dart';
import '../../models/constants.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../core/utils/date_formatter.dart';
import '../../l10n/app_localizations.dart';

// ══════════════════════════════════════════════
// ONBOARDING SCREEN
// Manages 22-step onboarding flow
// ══════════════════════════════════════════════

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  late PageController _pageCtrl;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // Form state
  final Map<String, dynamic> _form = {
    'name': '',
    'age': '',
    'gender': '',
    'goal': '',
    'conditions': <String>[],
    'medCount': '',
    'forgetting': '',
    'wakeTime': {'h': 7, 'm': 0},
    'breakfastTime': {'h': 8, 'm': 0},
    'lunchTime': {'h': 12, 'm': 0},
    'dinnerTime': {'h': 19, 'm': 0},
    'sleepTime': {'h': 22, 'm': 0},
    'doctorVisits': '',
    'support': '',
    'challenge': '',
    'prevApp': '',
    'motivation': <String>[],
    'reminderStyle': '',
    'notifPerm': false,
    'avatar': '😊',
    'country': '',
  };

  String _paywallPlan = 'annual'; // 'annual' or 'monthly'
  int _paywallStep = 0; // 0=Features, 1=Trust, 2=Timeline

  // Step definitions matching OB_STEPS in JSX
  List<_OBStep> get _steps => [
        const _OBStep(id: 'splash', type: 'splash'),
        const _OBStep(
            id: 'name',
            type: 'text',
            emoji: '👋',
            title: "What's your name?",
            subtitle: "We'll personalise everything for you",
            field: 'name',
            placeholder: 'Your first name'),
        _OBStep(
            id: 'country',
            type: 'single',
            emoji: '🌍',
            title: AppLocalizations.of(context)?.countrySelectionTitle ??
                'Where are you located?',
            subtitle: AppLocalizations.of(context)?.countrySelectionSubtitle ??
                'Helps us identify local medicine brands',
            field: 'country',
            options: kCountries),
        const _OBStep(
            id: 'goal',
            type: 'single',
            emoji: '🎯',
            title: "What's your main health goal?",
            subtitle: 'This shapes your entire experience',
            field: 'goal',
            options: kHealthGoals),
        const _OBStep(
            id: 'conditions',
            type: 'multi',
            emoji: '🩺',
            title: 'Any health conditions?',
            subtitle: 'Select all that apply — helps us customise',
            field: 'conditions',
            options: kConditions),
        const _OBStep(
            id: 'scan_demo',
            type: 'scan_demo',
            emoji: '✨',
            title: 'The Magic of Med AI',
            subtitle: 'Never type a medicine name again. Just scan the box.'),
        const _OBStep(
            id: 'medCount',
            type: 'single',
            emoji: '💊',
            title: 'How many medications do you take?',
            subtitle: 'Include vitamins, supplements & prescriptions',
            field: 'medCount',
            options: kMedCounts),
        const _OBStep(id: 'notif', type: 'notif'),
        const _OBStep(id: 'plan', type: 'plan'),
        const _OBStep(id: 'paywall', type: 'paywall'),
        const _OBStep(id: 'celebration', type: 'celebration'),
      ];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _steps.length - 1) {
      if (_steps[_step].id == 'paywall') {
        // We'll advance to celebration from within Paywall if needed,
        // but here we just increment the main step
      }
      setState(() => _step++);
      if (_steps[_step].id == 'paywall') {
        context.read<AppState>().logPaywallEvent('paywall_viewed');
      }
      _animCtrl.forward(from: 0);
    }
  }

  void _back() {
    if (_step > 0 && _steps[_step].id != 'celebration') {
      setState(() => _step--);
      _animCtrl.forward(from: 0);
    }
  }

  void _complete() {
    final profile = UserProfile(
      name: _form['name'] ?? '',
      age: _form['age'] ?? '',
      gender: _form['gender'] ?? '',
      goal: _form['goal'] ?? '',
      conditions: List<String>.from(_form['conditions'] ?? []),
      medCount: _form['medCount'] ?? '',
      forgetting: _form['forgetting'] ?? '',
      wakeTime: Map<String, int>.from(_form['wakeTime'] ?? {'h': 7, 'm': 0}),
      breakfastTime:
          Map<String, int>.from(_form['breakfastTime'] ?? {'h': 8, 'm': 0}),
      lunchTime: Map<String, int>.from(_form['lunchTime'] ?? {'h': 12, 'm': 0}),
      dinnerTime:
          Map<String, int>.from(_form['dinnerTime'] ?? {'h': 19, 'm': 0}),
      sleepTime: Map<String, int>.from(_form['sleepTime'] ?? {'h': 22, 'm': 0}),
      doctorVisits: _form['doctorVisits'] ?? '',
      support: _form['support'] ?? '',
      challenge: _form['challenge'] ?? '',
      prevApp: _form['prevApp'] ?? '',
      motivation: List<String>.from(_form['motivation'] ?? []),
      reminderStyle: _form['reminderStyle'] ?? '',
      notifPerm: _form['notifPerm'] ?? false,
      avatar: _form['avatar'] ?? '😊',
      country: _form['country'] ?? '',
      promoCode: null,
      appliedPromo: null,
    );
    context.read<AppState>().completeOnboarding(profile);
  }

  bool _canContinue(_OBStep step) {
    if (step.type == 'splash' ||
        step.type == 'notif' ||
        step.type == 'plan' ||
        step.type == 'scan_demo') {
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
    final L = context.L;

    final oBg = L.bg;
    final oText = L.text;
    final oSub = L.sub;
    final oLime = L.green;
    final oCard = L.card;

    final progress = (_step + 1) / _steps.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: oBg,
        body: SafeArea(
          child: Column(children: [
            // ── Progress bar (not on splash/paywall)
            if (step.type != 'splash' && step.type != 'paywall')
              Container(
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppGradients.main,
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.grey900.withValues(alpha: 0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // ── Back button
            if (_step > 0 && step.type != 'paywall')
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _back,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF8080A0), size: 18),
                ),
              ),

            // ── Step content
            Expanded(
              child: Scrollbar(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildStep(step, oText, oSub, oLime, oCard, oBg)
                      .animate(key: ValueKey(_step))
                      .slideY(
                          begin: 0.05,
                          end: 0,
                          duration: 400.ms,
                          curve: Curves.easeOutQuart),
                ),
              ),
            ),

            // ── CTA
            if (!isPaywall) _buildCTA(step, oLime, oText),
          ]),
        ),
      ),
    );
  }

  Widget _buildStep(_OBStep step, Color oText, Color oSub, Color oLime,
      Color oCard, Color oBg) {
    switch (step.type) {
      case 'splash':
        return _SplashStep(onNext: _next);
      case 'text':
        return _TextStep(
            step: step,
            form: _form,
            onChanged: (k, v) => setState(() => _form[k] = v),
            onNext: _next,
            oText: oText,
            oSub: oSub,
            oCard: oCard,
            oLime: oLime);
      case 'single':
        return _SingleStep(
            step: step,
            form: _form,
            onSelect: (k, v) {
              setState(() => _form[k] = v);
              Future.delayed(const Duration(milliseconds: 350), () {
                if (mounted && _canContinue(step)) _next();
              });
            },
            oText: oText,
            oSub: oSub,
            oCard: oCard,
            oLime: oLime);
      case 'multi':
        return _MultiStep(
            step: step,
            form: _form,
            onSelect: (k, v) => setState(() => _form[k] = v),
            oText: oText,
            oSub: oSub,
            oCard: oCard,
            oLime: oLime);
      case 'time':
        return _TimeStep(
            step: step,
            form: _form,
            onChanged: (k, v) => setState(() => _form[k] = v),
            oText: oText,
            oSub: oSub,
            oCard: oCard,
            oLime: oLime);
      case 'notif':
        return _NotifStep(
            form: _form,
            onChanged: (k, v) => setState(() => _form[k] = v),
            onNext: _next,
            oText: oText,
            oSub: oSub,
            oCard: oCard,
            oLime: oLime);
      case 'plan':
        return _PlanReadyStep(
            form: _form, oText: oText, oSub: oSub, oCard: oCard, oLime: oLime);
      case 'paywall':
        return _PaywallStep(
          form: _form,
          plan: _paywallPlan,
          paywallStep: _paywallStep,
          onPlanToggle: (p) => setState(() => _paywallPlan = p),
          onNextStep: () => setState(() => _paywallStep++),
          onComplete: _complete,
          onAuth: _next,
          oText: oText,
          oSub: oSub,
          oCard: oCard,
          oLime: oLime,
        );
      case 'celebration':
        return _CelebrationStep(
            onComplete: _complete,
            oLime: oLime,
            oText: oText,
            oSub: oSub,
            oCard: oCard);
      case 'scan_demo':
        return _ScanDemoStep(
            step: step, oText: oText, oSub: oSub, oCard: oCard, oLime: oLime);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCTA(_OBStep step, Color oLime, Color oText) {
    final canGo = _canContinue(step);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: GestureDetector(
        onTap: canGo
            ? () async {
                if (step.type == 'notif') {
                  final granted = await NotificationService.requestPermission();
                  setState(() => _form['notifPerm'] = granted);
                  _next();
                } else {
                  _next();
                }
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: canGo
                ? AppGradients.main
                : LinearGradient(colors: [
                    Colors.white.withValues(alpha: 0.02),
                    Colors.white.withValues(alpha: 0.02)
                  ]),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: canGo
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
            ),
            boxShadow: canGo ? AppShadows.glow(oLime, intensity: 0.25) : null,
          ),
          child: Text(
            step.type == 'plan'
                ? 'See My Plan →'
                : (step.type == 'notif' ? 'Allow Notifications' : 'Continue →'),
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(
              fontSize: 17,
              color: canGo ? Colors.white : const Color(0xFF404050),
              letterSpacing: -0.3,
            ),
          ),
        )
            .animate(target: canGo ? 1 : 0)
            .shimmer(duration: 2.seconds, curve: Curves.easeInOut),
      ),
    );
  }
}

// ── Step data model ──────────────────────────────────────────────────
class _OBStep {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String emoji;
  final String? field;
  final String? placeholder;
  final List<Map<String, String>> options;

  const _OBStep({
    required this.id,
    required this.type,
    this.title = '',
    this.subtitle = '',
    this.emoji = '',
    this.field,
    this.placeholder,
    this.options = const [],
  });
}

// ════════════════════════════════════════
// STEP HEADER (Standard for most steps)
// ════════════════════════════════════════
class _StepHeader extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color oText, oSub;
  const _StepHeader(
      {required this.emoji,
      required this.title,
      required this.subtitle,
      required this.oText,
      required this.oSub});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (emoji.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(emoji,
              style: AppTypography.displayLarge
                  .copyWith(fontSize: 48, height: 1.0)),
        ),
      Text(title,
          style: AppTypography.displayLarge.copyWith(
              fontSize: 26, color: oText, letterSpacing: -0.5, height: 1.2)),
      if (subtitle.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(subtitle,
            style: AppTypography.bodySmall
                .copyWith(fontSize: 14, color: oSub, height: 1.4)),
      ],
    ]);
  }
}

// ════════════════════════════════════════
// SPLASH STEP
// ════════════════════════════════════════

class _SplashStep extends StatelessWidget {
  final VoidCallback onNext;
  const _SplashStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final oLime = L.green;
    final oText = L.text;
    final oSub = L.sub;
    final oCard = L.card;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Floating logo + title ──────────────────────────
                  _AnimatedFloatWidget(
                    child: Column(children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.grey900.withValues(alpha: 0.1),
                          borderRadius: AppRadius.roundXL,
                          border:
                              Border.all(color: oLime.withValues(alpha: 0.3)),
                          boxShadow: AppShadows.glow(oLime, intensity: 0.2),
                        ),
                        child: Center(
                            child: Image.asset('assets/images/app_logo.png',
                                width: 60, height: 60)),
                      ),
                      const SizedBox(height: 20),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AppTypography.displayLarge.copyWith(
                              fontSize: 36, letterSpacing: -1.0, height: 1.6),
                          children: [
                            TextSpan(
                                text: 'Med ',
                                style: AppTypography.displayLarge.copyWith(
                                    fontSize: 36,
                                    color: const Color(0xFFF0F0F5))),
                            TextSpan(
                                text: 'AI',
                                style: AppTypography.displayLarge
                                    .copyWith(fontSize: 36, color: oLime)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your intelligent medicine tracker.\nScan, track, and never miss a dose again.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall
                            .copyWith(fontSize: 16, color: oSub, height: 1.6),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 32),

                  // ── 3 Feature cards ───────────────────────────────
                  ...[
                    ('🔍 Scan', 'AI identifies any medicine instantly'),
                    ('⏰ Remind', 'Smart reminders built around your life'),
                    ('📈 Track', 'Monitor adherence & streak progress'),
                  ].asMap().entries.map((entry) {
                    final int idx = entry.key;
                    final f = entry.value;
                    final parts = f.$1.split(' ');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: oCard,
                        borderRadius: AppRadius.roundL,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: oLime.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Text(parts[0],
                                style: AppTypography.displayLarge
                                    .copyWith(fontSize: 20)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(parts[1],
                                    style: AppTypography.titleLarge
                                        .copyWith(fontSize: 15, color: oText)),
                                const SizedBox(height: 2),
                                Text(f.$2,
                                    style: AppTypography.bodySmall
                                        .copyWith(fontSize: 13, color: oSub)),
                              ])),
                        ]),
                      ),
                    )
                        .animate(delay: (400 + (100 * idx)).ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack);
                  }),
                  const SizedBox(height: 32),

                  const SizedBox(height: 32),
                  Text('Free to start · No credit card required',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall
                          .copyWith(fontSize: 12, color: oSub)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Floating up/down animation wrapper
class _AnimatedFloatWidget extends StatefulWidget {
  final Widget child;
  const _AnimatedFloatWidget({required this.child});
  @override
  State<_AnimatedFloatWidget> createState() => _AnimatedFloatWidgetState();
}

class _AnimatedFloatWidgetState extends State<_AnimatedFloatWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.0, end: -6.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) =>
          Transform.translate(offset: Offset(0, _anim.value), child: child),
      child: widget.child,
    );
  }
}

// ════════════════════════════════════════
// SCAN DEMO STEP
// ════════════════════════════════════════

class _ScanDemoStep extends StatefulWidget {
  final _OBStep step;
  final Color oText, oSub, oCard, oLime;

  const _ScanDemoStep({
    required this.step,
    required this.oText,
    required this.oSub,
    required this.oCard,
    required this.oLime,
  });

  @override
  State<_ScanDemoStep> createState() => _ScanDemoStepState();
}

class _ScanDemoStepState extends State<_ScanDemoStep> {
  bool _isProcessing = false;
  bool _isComplete = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: widget.oLime.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
                child: Text(widget.step.emoji,
                    style: AppTypography.headlineLarge.copyWith(fontSize: 32))),
          ),
          const SizedBox(height: 24),
          Text(widget.step.title,
              textAlign: TextAlign.center,
              style: AppTypography.displayLarge
                  .copyWith(fontSize: 32, color: widget.oText)),
          const SizedBox(height: 12),
          Text(widget.step.subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: widget.oSub)),
          const SizedBox(height: 48),

          // Scan Demo UI
          Container(
            width: double.infinity,
            height: 320,
            decoration: BoxDecoration(
              color: widget.oCard,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: widget.oText.withValues(alpha: 0.05)),
              image: const DecorationImage(
                image: NetworkImage(
                    'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80'),
                fit: BoxFit.cover,
                opacity: 0.4,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Scanning Line
                if (_isProcessing)
                  Animate(
                    onPlay: (c) => c.repeat(),
                    child: Container(
                      width: double.infinity,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.oLime.withValues(alpha: 0),
                            widget.oLime,
                            widget.oLime.withValues(alpha: 0)
                          ],
                        ),
                      ),
                    ).animate().moveY(
                        begin: -140,
                        end: 140,
                        duration: 1.5.seconds,
                        curve: Curves.easeInOut),
                  ),

                // Center Icon / Overlay
                if (!_isProcessing && !_isComplete)
                  GestureDetector(
                    onTap: () async {
                      HapticEngine.selection();
                      setState(() => _isProcessing = true);
                      await Future.delayed(2.5.seconds);
                      if (mounted) {
                        setState(() {
                          _isProcessing = false;
                          _isComplete = true;
                        });
                        HapticEngine.success();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: widget.oLime,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: widget.oLime.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10))
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.camera_alt_rounded,
                              color: Color(0xFF1A2010), size: 20),
                          const SizedBox(width: 12),
                          Text('Test AI Scanner',
                              style: AppTypography.titleLarge.copyWith(
                                  fontSize: 16,
                                  color: const Color(0xFF1A2010))),
                        ],
                      ),
                    ),
                  ),

                // Success Result Overlay
                if (_isComplete)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: widget.oCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: widget.oLime.withValues(alpha: 0.3), width: 2),
                      boxShadow: AppShadows.glow(widget.oLime, intensity: 0.1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: widget.oLime.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: widget.oLime.withValues(alpha: 0.3)),
                              ),
                              child: Center(
                                  child: Text('💊',
                                      style: AppTypography.titleLarge
                                          .copyWith(fontSize: 26))),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Amoxicillin 500mg',
                                    style: AppTypography.titleLarge.copyWith(
                                        color: widget.oText, fontSize: 18)),
                                const SizedBox(height: 2),
                                Text('Capsule • Verified by AI',
                                    style: AppTypography.bodySmall.copyWith(
                                        color: widget.oSub,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ))
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Text(
                            'AI detected dosage, expiry, and safety instructions for your region (UK).',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall
                                .copyWith(color: Colors.black, height: 1.4)),
                      ],
                    ),
                  )
                      .animate()
                      .scale(duration: 400.ms, curve: Curves.easeOutBack),
              ],
            ),
          ),

          const SizedBox(height: 40),
          if (!_isComplete && !_isProcessing)
            Text('Try the power of our real-time AI\non a medicine pack.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: widget.oSub)),

          if (_isComplete)
            Text('That\'s the power of Med AI.\nSetup your full schedule next.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                    color: widget.oLime, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════
// NOTIFICATION STEP
// ════════════════════════════════════════

class _TextStep extends StatefulWidget {
  final _OBStep step;
  final Map<String, dynamic> form;
  final Function(String, String) onChanged;
  final VoidCallback onNext;
  final Color oText, oSub, oCard, oLime;
  const _TextStep(
      {required this.step,
      required this.form,
      required this.onChanged,
      required this.onNext,
      required this.oText,
      required this.oSub,
      required this.oCard,
      required this.oLime});

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
    final val = _ctrl.text.trim();
    final hasVal = val.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        // Large emoji
        Text(widget.step.emoji,
            style: AppTypography.displayLarge.copyWith(fontSize: 52)),
        const SizedBox(height: 16),
        Text(widget.step.title,
            style: AppTypography.displayLarge.copyWith(
                fontSize: 28,
                color: widget.oText,
                letterSpacing: -0.5,
                height: 1.2)),
        const SizedBox(height: 8),
        Text(widget.step.subtitle,
            style: AppTypography.bodySmall
                .copyWith(fontSize: 14, color: widget.oSub)),
        const SizedBox(height: 32),
        // Input — border turns lime when filled
        TextField(
          controller: _ctrl,
          autofocus: true,
          keyboardType: widget.step.id == 'age'
              ? TextInputType.number
              : TextInputType.text,
          style: AppTypography.bodySmall.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: widget.oText,
              letterSpacing: -0.2),
          onChanged: (v) => widget.onChanged(widget.step.field!, v),
          onSubmitted: (_) {
            if (hasVal) widget.onNext();
          },
          inputFormatters: widget.step.id == 'age'
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            hintText: widget.step.placeholder,
            hintStyle: AppTypography.bodySmall
                .copyWith(color: widget.oSub.withValues(alpha: 0.5)),
            filled: true,
            fillColor: widget.oText.withValues(alpha: 0.03),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.roundXL,
              borderSide: BorderSide(
                  color: widget.oText.withValues(alpha: 0.08), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.roundXL,
              borderSide: BorderSide(color: widget.oLime, width: 2.0),
            ),
          ),
        ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05, end: 0),
        const Spacer(),
      ]),
    );
  }
}

// ════════════════════════════════════════
// SINGLE SELECT STEP
// ════════════════════════════════════════

class _SingleStep extends StatelessWidget {
  final _OBStep step;
  final Map<String, dynamic> form;
  final Function(String, String) onSelect;
  final Color oText, oSub, oCard, oLime;
  const _SingleStep(
      {required this.step,
      required this.form,
      required this.onSelect,
      required this.oText,
      required this.oSub,
      required this.oCard,
      required this.oLime});

  @override
  Widget build(BuildContext context) {
    final selected = form[step.field!]?.toString() ?? '';
    final isGrid = step.options.length > 4;

    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _StepHeader(
            emoji: step.emoji,
            title: step.title,
            subtitle: step.subtitle,
            oText: oText,
            oSub: oSub),
        const SizedBox(height: 24),
        if (isGrid)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
            children: step.options
                .map((opt) => _buildOption(opt, selected == opt['v'], true))
                .toList(),
          )
        else
          Column(
            children: step.options
                .map((opt) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildOption(opt, selected == opt['v'], false),
                    ))
                .toList(),
          ),
      ]),
    );
  }

  Widget _buildOption(Map<String, String> opt, bool isSelected, bool isGrid) {
    bool isPressed = false;
    return StatefulBuilder(builder: (context, setState) {
      return GestureDetector(
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) => setState(() => isPressed = false),
        onTapCancel: () => setState(() => isPressed = false),
        onTap: () {
          HapticEngine.selection();
          onSelect(step.field!, opt['v']!);
        },
        child: AnimatedScale(
          scale: isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            padding: EdgeInsets.symmetric(
                horizontal: isGrid ? 12 : 18, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? oLime.withValues(alpha: 0.15) : oCard,
              borderRadius: AppRadius.roundXL,
              border: Border.all(
                  color: isSelected
                      ? oLime.withValues(alpha: 0.6)
                      : oText.withValues(alpha: 0.08),
                  width: isSelected ? 2.0 : 1.0),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: oLime.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 10))
                    ]
                  : (isPressed ? AppShadows.subtle : AppShadows.soft),
            ),
            child: isGrid
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (opt['e'] != null)
                        Text(opt['e']!,
                            style: AppTypography.displayLarge
                                .copyWith(fontSize: 28)),
                      if (opt['e'] != null) const SizedBox(height: 12),
                      Text(opt['v']!,
                          textAlign: TextAlign.center,
                          style: AppTypography.labelLarge.copyWith(
                              fontSize: 13, color: isSelected ? oLime : oText)),
                    ],
                  )
                : Row(children: [
                    if (opt['e'] != null)
                      Text(opt['e']!,
                          style: AppTypography.displayLarge
                              .copyWith(fontSize: 24, height: 1.0)),
                    if (opt['e'] != null) const SizedBox(width: 14),
                    Expanded(
                        child: Text(opt['v']!,
                            style: AppTypography.bodySmall.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? oLime : oText))),
                    if (isSelected)
                      Container(
                        width: 24,
                        height: 24,
                        decoration:
                            BoxDecoration(color: oLime, shape: BoxShape.circle),
                        child: const Center(
                            child: Icon(Icons.check,
                                color: Color(0xFF0A0A0F), size: 16)),
                      )
                          .animate()
                          .scale(duration: 250.ms, curve: Curves.easeOutBack),
                  ]),
          ),
        ),
      );
    });
  }
}

// ════════════════════════════════════════
// MULTI SELECT STEP
// ════════════════════════════════════════

class _MultiStep extends StatelessWidget {
  final _OBStep step;
  final Map<String, dynamic> form;
  final Function(String, List<String>) onSelect;
  final Color oText, oSub, oCard, oLime;
  const _MultiStep(
      {required this.step,
      required this.form,
      required this.onSelect,
      required this.oText,
      required this.oSub,
      required this.oCard,
      required this.oLime});

  @override
  Widget build(BuildContext context) {
    final selected = List<String>.from(form[step.field!] ?? []);
    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _StepHeader(
            emoji: step.emoji,
            title: step.title,
            subtitle: step.subtitle,
            oText: oText,
            oSub: oSub),
        const SizedBox(height: 24),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: step.options.map((opt) {
              final isSelected = selected.contains(opt['v']!);
              bool isPressed = false;
              return StatefulBuilder(builder: (context, setState) {
                return GestureDetector(
                  onTapDown: (_) => setState(() => isPressed = true),
                  onTapUp: (_) => setState(() => isPressed = false),
                  onTapCancel: () => setState(() => isPressed = false),
                  onTap: () {
                    HapticEngine.selection();
                    final newSel = isSelected
                        ? (selected..remove(opt['v']!))
                        : [...selected, opt['v']!];
                    onSelect(step.field!, newSel);
                  },
                  child: AnimatedScale(
                    scale: isPressed ? 0.94 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutCubic,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? oLime.withValues(alpha: 0.15) : oCard,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                            color: isSelected
                                ? oLime.withValues(alpha: 0.6)
                                : oText.withValues(alpha: 0.08),
                            width: isSelected ? 2.0 : 1.0),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                    color: oLime.withValues(alpha: 0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5))
                              ]
                            : (isPressed ? AppShadows.subtle : AppShadows.soft),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (opt['e'] != null)
                          Text(opt['e']!,
                              style: AppTypography.bodySmall
                                  .copyWith(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(opt['v']!,
                            style: AppTypography.labelLarge.copyWith(
                                fontSize: 14,
                                color: isSelected ? oLime : oText)),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.check_circle_rounded,
                                  color: oLime, size: 16)
                              .animate()
                              .scale(
                                  duration: 200.ms, curve: Curves.easeOutBack),
                        ],
                      ]),
                    ),
                  ),
                );
              });
            }).toList()),
      ]),
    );
  }
}

// ════════════════════════════════════════
// TIME PICKER STEP
// ════════════════════════════════════════

class _TimeStep extends StatelessWidget {
  final _OBStep step;
  final Map<String, dynamic> form;
  final Function(String, Map<String, int>) onChanged;
  final Color oText, oSub, oCard, oLime;
  const _TimeStep(
      {required this.step,
      required this.form,
      required this.onChanged,
      required this.oText,
      required this.oSub,
      required this.oCard,
      required this.oLime});

  @override
  Widget build(BuildContext context) {
    final time = Map<String, int>.from(form[step.field!] ?? {'h': 8, 'm': 0});
    final h = time['h'] ?? 8;
    final m = time['m'] ?? 0;

    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _StepHeader(
            emoji: step.emoji,
            title: step.title,
            subtitle: step.subtitle,
            oText: oText,
            oSub: oSub),
        const SizedBox(height: 32),
        // Quick presets
        Row(
            children: kQuickTimes.map((qt) {
          final isActive = h == qt['h'] && m == qt['m'];
          return Expanded(
              child: GestureDetector(
            onTap: () => onChanged(
                step.field!, {'h': qt['h'] as int, 'm': qt['m'] as int}),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? oLime.withValues(alpha: 0.15)
                    : oText.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: isActive ? oLime : oText.withValues(alpha: 0.08),
                    width: isActive ? 2.0 : 1.0),
              ),
              child: Column(children: [
                Text(qt['emoji'] as String,
                    style: AppTypography.displayLarge.copyWith(fontSize: 18)),
                const SizedBox(height: 2),
                Text(qt['label'] as String,
                    style: AppTypography.labelSmall.copyWith(
                        fontSize: 10, color: isActive ? oLime : oSub)),
              ]),
            ),
          ));
        }).toList()),
        const SizedBox(height: 24),
        // H:M inputs
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
              child: _TimeInput(
                  label: 'Hour',
                  value: h.toString().padLeft(2, '0'),
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    if (n != null) {
                      onChanged(step.field!, {'h': n.clamp(0, 23), 'm': m});
                    }
                  },
                  oText: oText,
                  oSub: oSub,
                  oCard: oCard,
                  oLime: oLime)),
          Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(':',
                  style: AppTypography.displayLarge
                      .copyWith(fontSize: 36, color: oSub))),
          Expanded(
              child: _TimeInput(
                  label: 'Min',
                  value: m.toString().padLeft(2, '0'),
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    if (n != null) {
                      onChanged(step.field!, {'h': h, 'm': n.clamp(0, 59)});
                    }
                  },
                  oText: oText,
                  oSub: oSub,
                  oCard: oCard,
                  oLime: oLime)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: oCard,
                borderRadius: AppRadius.roundM,
                border: Border.all(
                    color: oText.withValues(alpha: 0.08), width: 1.5),
              ),
              child: Text(h >= 12 ? 'PM' : 'AM',
                  style: AppTypography.labelLarge.copyWith(
                      fontSize: 16, fontWeight: FontWeight.w800, color: oLime)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _TimeInput extends StatelessWidget {
  final String label, value;
  final ValueChanged<String> onChanged;
  final Color oText, oSub, oCard, oLime;
  const _TimeInput(
      {required this.label,
      required this.value,
      required this.onChanged,
      required this.oText,
      required this.oSub,
      required this.oCard,
      required this.oLime});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label.toUpperCase(),
          style: AppTypography.labelLarge
              .copyWith(fontSize: 10, letterSpacing: 1, color: oSub)),
      const SizedBox(height: 6),
      TextField(
        controller: TextEditingController(text: value),
        keyboardType: TextInputType.number,
        maxLength: 2,
        textAlign: TextAlign.center,
        onChanged: onChanged,
        style: AppTypography.displayLarge
            .copyWith(fontSize: 42, color: oText, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: oText.withValues(alpha: 0.03),
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
          enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.roundXL,
              borderSide:
                  BorderSide(color: oText.withValues(alpha: 0.08), width: 1.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.roundXL,
              borderSide: BorderSide(color: oLime, width: 2.5)),
        ),
      ),
    ]);
  }
}

// ════════════════════════════════════════
// NOTIFICATION PERMISSION STEP
// ════════════════════════════════════════

class _NotifStep extends StatelessWidget {
  final Map<String, dynamic> form;
  final Function(String, dynamic) onChanged;
  final VoidCallback onNext;
  final Color oText, oSub, oCard, oLime;
  const _NotifStep(
      {required this.form,
      required this.onChanged,
      required this.onNext,
      required this.oText,
      required this.oSub,
      required this.oCard,
      required this.oLime});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Column(children: [
        const SizedBox(height: 48),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: oLime.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: oLime.withValues(alpha: 0.1),
                  blurRadius: 40,
                  spreadRadius: 10)
            ],
          ),
          child: Center(
              child: Icon(Icons.notifications_active_rounded,
                  color: oLime, size: 48)),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            duration: 2.seconds,
            curve: Curves.easeInOutExpo),
        const SizedBox(height: 48),
        Text('Stay on Track',
            style: AppTypography.displayLarge.copyWith(
                fontSize: 32, color: oText, letterSpacing: -1.0, height: 1.1)),
        const SizedBox(height: 16),
        Text(
            'Smart reminders adapt to your schedule to ensure you never miss a dose.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall
                .copyWith(fontSize: 16, color: oSub, height: 1.6)),
        const Spacer(),
      ]),
    );
  }
}

// ════════════════════════════════════════
// PLAN READY STEP
// ════════════════════════════════════════

class _PlanReadyStep extends StatelessWidget {
  final Map<String, dynamic> form;
  final Color oText, oSub, oCard, oLime;
  const _PlanReadyStep(
      {required this.form,
      required this.oText,
      required this.oSub,
      required this.oCard,
      required this.oLime});

  @override
  Widget build(BuildContext context) {
    final name = form['name']?.toString() ?? '';
    final goal = form['goal']?.toString() ?? '';
    final conditions = List<String>.from(form['conditions'] ?? []);
    final wakeTime = form['wakeTime'] as Map<String, int>?;
    final style = form['reminderStyle']?.toString() ?? '';
    final motivation = List<String>.from(form['motivation'] ?? []);

    final highlights = [
      if (goal.isNotEmpty) 'Goal: $goal',
      if (conditions.isNotEmpty)
        'Conditions: ${conditions.take(2).join(", ")}${conditions.length > 2 ? " +${conditions.length - 2} more" : ""}',
      if (wakeTime != null)
        'Wake reminder: ${wakeTime['h'].toString().padLeft(2, '0')}:${wakeTime['m'].toString().padLeft(2, '0')}',
      if (style.isNotEmpty) 'Style: $style',
      if (motivation.isNotEmpty) 'Motivated by: ${motivation[0]}',
    ];

    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
              color: const Color(0x1FA3E635),
              borderRadius: BorderRadius.circular(28)),
          child: Center(
              child: Text('🎯',
                  style: AppTypography.displayLarge.copyWith(fontSize: 48))),
        ),
        const SizedBox(height: 24),
        Text('Your plan is ready${name.isNotEmpty ? ", $name" : ""}!',
            textAlign: TextAlign.center,
            style: AppTypography.displayLarge.copyWith(
                fontSize: 32, color: oText, letterSpacing: -1.0, height: 1.1)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: oLime.withValues(alpha: 0.1),
            borderRadius: AppRadius.roundL,
            border: Border.all(color: oLime.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Text(
            _generateNarrative(name, goal, wakeTime, motivation),
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(
                fontSize: 17,
                color: oLime,
                height: 1.5,
                fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 32),
        ...highlights.asMap().entries.map((entry) {
          final int idx = entry.key;
          final String h = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: oCard,
              borderRadius: AppRadius.roundL,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: oLime.withValues(alpha: 0.15),
                    shape: BoxShape.circle),
                child: Icon(Icons.check_rounded, size: 16, color: oLime),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(h,
                      style: AppTypography.bodySmall.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: oText))),
            ]),
          ).animate(delay: (200 * idx).ms).fadeIn().slideX(begin: 0.1, end: 0);
        }),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: oCard,
            borderRadius: AppRadius.roundL,
            border: Border.all(color: oLime.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Column(children: [
            Text('94%',
                style: AppTypography.displayLarge.copyWith(
                    fontSize: 48, color: oLime, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('of users like you improved adherence in 2 weeks',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                    fontSize: 16,
                    color: oSub,
                    height: 1.5,
                    fontWeight: FontWeight.w500)),
          ]),
        )
            .animate(delay: 1.seconds)
            .shimmer(duration: 2.seconds, color: oLime.withValues(alpha: 0.1)),
      ]),
    );
  }

  String _generateNarrative(String name, String goal,
      Map<String, int>? wakeTime, List<String> motivation) {
    String timeStr = 'your wake-up time';
    if (wakeTime != null) {
      final h = wakeTime['h'] ?? 8;
      final m = wakeTime['m'] ?? 0;
      timeStr =
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }

    final motiv =
        motivation.isNotEmpty ? motivation[0].toLowerCase() : 'health';

    return "${name.isNotEmpty ? "$name, we've" : "We've"} crafted a plan to help you $goal. "
        "Your first reminders are aligned with your $timeStr start. "
        "By staying consistent for your $motiv, you'll reach your peak adherence in no time!";
  }
}

// ════════════════════════════════════════
// PAYWALL (3 sub-steps)
// ════════════════════════════════════════

class _PaywallStep extends StatelessWidget {
  final Map<String, dynamic> form;
  final String plan;
  final int paywallStep;
  final Function(String) onPlanToggle;
  final VoidCallback onNextStep;
  final VoidCallback onComplete;
  final VoidCallback onAuth;
  final Color oText, oSub, oCard, oLime;

  const _PaywallStep({
    required this.form,
    required this.plan,
    required this.paywallStep,
    required this.onPlanToggle,
    required this.onNextStep,
    required this.onComplete,
    required this.onAuth,
    required this.oText,
    required this.oSub,
    required this.oCard,
    required this.oLime,
  });

  @override
  Widget build(BuildContext context) {
    if (paywallStep == 0) {
      return _PaywallFeatures(
        plan: plan,
        onToggle: onPlanToggle,
        onSkip: onComplete,
        onNext: onNextStep,
        onAuth: onAuth,
        oText: oText,
        oSub: oSub,
        oCard: oCard,
        oLime: oLime,
      );
    }
    if (paywallStep == 1) {
      return _PaywallTrust(
          onNext: onNextStep,
          oText: oText,
          oSub: oSub,
          oCard: oCard,
          oLime: oLime);
    }
    return _PaywallTimeline(
        plan: plan,
        appliedPromo: null,
        onComplete: onComplete,
        oText: oText,
        oSub: oSub,
        oCard: oCard,
        oLime: oLime);
  }
}

class _PaywallFeatures extends StatelessWidget {
  final String plan;
  final Function(String) onToggle;
  final VoidCallback onNext, onSkip, onAuth;
  final Color oText, oSub, oCard, oLime;

  const _PaywallFeatures({
    required this.plan,
    required this.onToggle,
    required this.onNext,
    required this.onSkip,
    required this.onAuth,
    required this.oText,
    required this.oSub,
    required this.oCard,
    required this.oLime,
  });

  @override
  Widget build(BuildContext context) {
    const feats = [
      "AI Medicine Scanner",
      "Smart Reminders",
      "Streak Protection",
      "Unlimited Medicines",
      "Low Stock Alerts",
      "AI Health Insights",
      "Family Sharing",
      "Private & Secure"
    ];
    final plans = [
      {
        'id': 'annual',
        'label': 'Annual',
        'price': fmtCurrency(7.58, context),
        'period': '/mo',
        'total': 'Billed ${fmtCurrency(91.0, context)}/year',
        'badge': 'Best value · Save 24%'
      },
      {
        'id': 'monthly',
        'label': 'Monthly',
        'price': fmtCurrency(9.90, context),
        'period': '/mo',
        'total': 'Billed monthly',
        'badge': null
      },
    ];

    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header (no skip button here anymore)
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('MED AI PRO',
              style: AppTypography.labelLarge
                  .copyWith(fontSize: 11, color: oLime, letterSpacing: 1.2)),
          Text("World's #1 Advanced AI",
              style: AppTypography.displayLarge
                  .copyWith(fontSize: 26, color: oText, letterSpacing: -0.5)),
          Text("Start for free with 3 Scans",
              style: AppTypography.titleLarge
                  .copyWith(fontSize: 18, color: oSub, letterSpacing: -0.3)),
        ]),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3.0),
          itemCount: feats.length,
          itemBuilder: (c, i) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: oCard,
              borderRadius: AppRadius.roundM,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1), width: 1.5),
            ),
            child: Row(children: [
              Icon(Icons.check_circle_rounded, color: oLime, size: 14),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(feats[i],
                      style: AppTypography.labelLarge.copyWith(
                          fontSize: 12,
                          color: oText,
                          fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 24),
        ...plans.map((p) {
          final isSel = plan == p['id'];
          return GestureDetector(
            onTap: () {
              HapticEngine.selection();
              onToggle(p['id'] as String);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuart,
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSel ? oLime.withValues(alpha: 0.1) : oCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isSel ? oLime : Colors.white.withValues(alpha: 0.07),
                    width: isSel ? 2.5 : 1.5),
                boxShadow: isSel ? AppShadows.glow(oLime) : AppShadows.soft,
              ),
              child: Stack(clipBehavior: Clip.none, children: [
                if (p['badge'] != null && isSel)
                  Positioned(
                      top: -28,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: oLime,
                            borderRadius: BorderRadius.circular(99)),
                        child: Text(p['badge'] as String,
                            style: AppTypography.labelLarge.copyWith(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w800)),
                      )),
                Row(children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: isSel ? oLime : oSub, width: 2)),
                    child: isSel
                        ? Center(
                            child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                    color: oLime, shape: BoxShape.circle)))
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(p['label'] as String,
                            style: AppTypography.titleLarge.copyWith(
                                fontSize: 16, color: isSel ? oLime : oText)),
                        Text(p['total'] as String,
                            style: AppTypography.bodySmall
                                .copyWith(fontSize: 11, color: oSub)),
                      ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(p['price'] as String,
                        style: AppTypography.displayLarge.copyWith(
                            fontSize: 22, color: isSel ? oLime : oText)),
                    Text(p['period'] as String,
                        style: AppTypography.labelSmall
                            .copyWith(fontSize: 11, color: oSub)),
                  ]),
                ]),
              ]),
            ),
          );
        }),
        const SizedBox(height: 32),
        // ── Primary CTA
        GestureDetector(
          onTap: onNext,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: oLime,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.glow(oLime, intensity: 0.3),
            ),
            child: Text('Get MED AI PRO →',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge
                    .copyWith(fontSize: 17, color: const Color(0xFF1A2010))),
          ),
        ),
        const SizedBox(height: 10),
        Center(
            child: RichText(
                text: TextSpan(
                    style: AppTypography.bodySmall
                        .copyWith(fontSize: 12, color: oSub),
                    children: [
              TextSpan(
                  text: '3 Scans included for free',
                  style: AppTypography.bodySmall.copyWith(
                      fontSize: 12, color: oLime, fontWeight: FontWeight.w800)),
              const TextSpan(text: ' · Experience AI Power'),
            ]))),
        const SizedBox(height: 28),
        // ── Auth Buttons
        _AuthButtons(onAuth: onAuth),
        const SizedBox(height: 24),
        // ── Skip link — tiny and low-contrast at the very bottom
        Center(
          child: GestureDetector(
            onTap: () {
              context.read<AppState>().logPaywallEvent('paywall_skipped');
              onSkip();
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No thanks, continue for free',
                style: AppTypography.bodySmall
                    .copyWith(fontSize: 12, color: oSub.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
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
      _buildAuthBtn("Continue with Google", "assets/images/google_logo.png",
          () async {
        await AuthService.signInWithGoogle();
        onAuth();
      }, Colors.white, Colors.black),
      const SizedBox(height: 12),
      _buildAuthBtn("Continue with Apple", null, () async {
        await AuthService.signInWithApple();
        onAuth();
      }, Colors.white, Colors.black, icon: Icons.apple_rounded),
    ]);
  }

  Widget _buildAuthBtn(
      String label, String? asset, VoidCallback onTap, Color bg, Color text,
      {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (asset != null)
            Image.asset(asset,
                width: 20,
                height: 20,
                errorBuilder: (c, e, s) => const Icon(Icons.login, size: 20))
          else if (icon != null)
            Icon(icon, size: 22, color: text),
          const SizedBox(width: 12),
          Text(label,
              style: AppTypography.labelLarge.copyWith(
                  color: text, fontSize: 15, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _PaywallTrust extends StatelessWidget {
  final VoidCallback onNext;
  final Color oText, oSub, oCard, oLime;
  const _PaywallTrust(
      {required this.onNext,
      required this.oText,
      required this.oSub,
      required this.oCard,
      required this.oLime});

  @override
  Widget build(BuildContext context) {
    const trust = [
      {
        'e': '🔒',
        't': 'No charge today',
        'd': 'Your trial starts immediately, completely free'
      },
      {
        'e': '📨',
        't': 'Reminder 3 days before',
        'd': "We'll email you before anything charges"
      },
      {
        'e': '❌',
        't': 'Cancel any time',
        'd': 'Cancel in the app — no questions asked'
      },
      {
        'e': '🔐',
        't': 'Secure payment',
        'd': '256-bit encryption, trusted by thousands'
      },
    ];

    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        Text("We've got you covered",
            style: AppTypography.displayLarge
                .copyWith(fontSize: 32, color: oText, letterSpacing: -1.0)),
        const SizedBox(height: 8),
        Text("Your trust matters. Here's what happens next.",
            style: AppTypography.bodySmall.copyWith(fontSize: 16, color: oSub)),
        const SizedBox(height: 32),
        ...trust.asMap().entries.map((entry) {
          final int idx = entry.key;
          final t = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: oCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1), width: 1.5),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t['e']!,
                  style: AppTypography.displayLarge.copyWith(fontSize: 32)),
              const SizedBox(width: 18),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(t['t']!,
                        style: AppTypography.labelLarge.copyWith(
                            fontSize: 16,
                            color: oText,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(t['d']!,
                        style: AppTypography.bodySmall.copyWith(
                            fontSize: 14,
                            color: oSub,
                            height: 1.5,
                            fontWeight: FontWeight.w500)),
                  ])),
            ]),
          ).animate(delay: (100 * idx).ms).fadeIn().slideX(begin: 0.1, end: 0);
        }),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: oCard,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: oText.withValues(alpha: 0.08), width: 1.5),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                '"I haven\'t missed a single dose in 3 months. The reminders are perfectly timed."',
                style: AppTypography.bodySmall.copyWith(
                    fontSize: 15,
                    color: oText,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 14),
            Row(
              children: [
                Text('— Sarah K.',
                    style: AppTypography.labelLarge.copyWith(
                        fontSize: 14,
                        color: oText,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                const Text('⭐⭐⭐⭐⭐', style: TextStyle(fontSize: 12)),
              ],
            ),
          ]),
        ).animate(delay: 500.ms).fadeIn(),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: onNext,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: oLime,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.glow(oLime, intensity: 0.3),
            ),
            child: Text('I Understand, Continue →',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge
                    .copyWith(fontSize: 17, color: Colors.black)),
          ),
        ),
      ]),
    );
  }
}

class _PaywallTimeline extends StatelessWidget {
  final String plan;
  final Map<String, dynamic>? appliedPromo;
  final VoidCallback onComplete;
  final Color oText, oSub, oCard, oLime;
  const _PaywallTimeline(
      {required this.plan,
      required this.appliedPromo,
      required this.onComplete,
      required this.oText,
      required this.oSub,
      required this.oCard,
      required this.oLime});

  @override
  Widget build(BuildContext context) {
    final oLimeDark = oLime.withValues(alpha: 0.6);
    final timeline = [
      {
        'label': 'Step 1',
        'title': 'Med AI Activated',
        'desc': 'Instant access to 3 Free Pro Scans',
        'icon': '🚀',
        'color': oLime
      },
      {
        'label': 'Step 2',
        'title': 'Experience AI Power',
        'desc': 'Full Analysis & Ingredient Safety included',
        'icon': '📸',
        'color': oLime
      },
      {
        'label': 'Step 3',
        'title': 'Unlimited Protection',
        'desc': plan == 'annual'
            ? '${fmtCurrency(91.0, context)} billed after 3 scans'
            : '${fmtCurrency(9.90, context)} billed after 3 scans',
        'icon': '🛡️',
        'color': oLime
      },
    ];

    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        Text("Here's exactly what happens",
            style: AppTypography.displayLarge
                .copyWith(fontSize: 32, color: oText, letterSpacing: -1.0)),
        const SizedBox(height: 8),
        Text("No surprises. No confusion.",
            style: AppTypography.bodySmall.copyWith(fontSize: 16, color: oSub)),
        const SizedBox(height: 32),
        Stack(children: [
          Positioned(
              left: 23,
              top: 40,
              bottom: 40,
              child: Opacity(
                opacity: 0.3,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [oLime, oLimeDark, oLime]),
                      borderRadius: BorderRadius.circular(99)),
                ),
              )),
          Column(
              children: timeline.asMap().entries.map((e) {
            final i = e.key;
            final t = e.value;
            final color = t['color'] as Color;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == 0 ? color : oCard,
                      border: Border.all(color: color, width: 2.5),
                      boxShadow: i == 0
                          ? AppShadows.glow(color, intensity: 0.3)
                          : null),
                  child: Center(
                      child: Text(t['icon'] as String,
                          style: AppTypography.displayLarge
                              .copyWith(fontSize: 20))),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: oCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1.5),
                      boxShadow: i == 0
                          ? AppShadows.glow(oLime, intensity: 0.1)
                          : null,
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(t['label'] as String,
                                    style: AppTypography.labelLarge.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: i == 0 ? color : oText)),
                              ]),
                          const SizedBox(height: 6),
                          Text(t['title'] as String,
                              style: AppTypography.titleLarge.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: i == 0 ? color : oText)),
                          const SizedBox(height: 4),
                          Text(t['desc'] as String,
                              style: AppTypography.bodySmall.copyWith(
                                  fontSize: 13,
                                  color: i == 0 ? oText : oSub,
                                  fontWeight: i == 0
                                      ? FontWeight.w600
                                      : FontWeight.w400)),
                        ]),
                  ).animate(target: i == 0 ? 1 : 0).shimmer(
                      duration: 2.seconds, color: oLime.withValues(alpha: 0.1)),
                ),
              ]),
            );
          }).toList()),
        ]),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: oCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: oText.withValues(alpha: 0.1))),
          child: Column(children: [
            _PriceRow(
                label: '3 Scans included',
                value: 'FREE',
                color: oLime,
                oText: oText,
                oSub: oSub),
            if (appliedPromo != null) const SizedBox(height: 8),
            if (appliedPromo != null)
              _PriceRow(
                  label: 'Promo',
                  value: '🎉 ${appliedPromo!['label']}',
                  color: oLime,
                  oText: oText,
                  oSub: oSub),
            const SizedBox(height: 8),
            _PriceRow(
                label: 'Subscription',
                value: plan == 'annual'
                    ? '${fmtCurrency(91.0, context)}/year'
                    : '${fmtCurrency(9.90, context)}/month',
                oText: oText,
                oSub: oSub),
          ]),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () async {
            final state = context.read<AppState>();
            HapticEngine.selection();
            await state.purchasePremium(plan);
            // Even if purchase fails, they have 3 free scans, so let them in.
            onComplete();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: oLime,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.glow(oLime, intensity: 0.3),
            ),
            child: Text('Get Started with 3 Free Scans 🚀',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge
                    .copyWith(fontSize: 17, color: Colors.black)),
          ),
        ),
        const SizedBox(height: 12),
        Center(
            child: Text(
                'Unlock unlimited medicine tracking and AI safety analysis.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall
                    .copyWith(fontSize: 12, color: oSub, height: 1.4))),
      ]),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  final Color? color;
  final Color oText, oSub;
  const _PriceRow(
      {required this.label,
      required this.value,
      this.color,
      required this.oText,
      required this.oSub});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: AppTypography.labelLarge.copyWith(
              fontSize: 14, fontWeight: FontWeight.w700, color: oText)),
      Expanded(
          child: Text(value,
              textAlign: TextAlign.right,
              style: AppTypography.labelLarge.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color ?? oSub))),
    ]);
  }
}

class _CelebrationStep extends StatelessWidget {
  final VoidCallback onComplete;
  final Color oLime, oText, oSub, oCard;
  const _CelebrationStep(
      {required this.onComplete,
      required this.oLime,
      required this.oText,
      required this.oSub,
      required this.oCard});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: oLime.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: oLime.withValues(alpha: 0.1),
                    blurRadius: 60,
                    spreadRadius: 10)
              ],
            ),
            child: Center(
              child: Text('🎊',
                  style: AppTypography.displayLarge.copyWith(fontSize: 72)),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 2.seconds,
                  curve: Curves.easeInOutBack)
              .animate()
              .scale(duration: 800.ms, curve: Curves.elasticOut),
          const SizedBox(height: 48),
          Text(
            "MedTrack AI Activated!",
            textAlign: TextAlign.center,
            style: AppTypography.displayLarge.copyWith(
              color: oText,
              fontSize: 34,
              letterSpacing: -1.2,
              fontWeight: FontWeight.w900,
            ),
          )
              .animate()
              .fadeIn(delay: 300.ms)
              .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          Text(
            "Welcome to the next level of health tracking. Your personal AI assistant is ready.",
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: oSub,
              fontSize: 17,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 64),
          GestureDetector(
            onTap: () {
              HapticEngine.selection();
              onComplete();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                color: oCard,
                borderRadius: AppRadius.roundL,
                border: Border.all(color: oLime, width: 2),
                boxShadow: AppShadows.glow(oLime, intensity: 0.2),
              ),
              child: Text(
                "Enter Dashboard",
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(
                  color: oLime,
                  fontSize: 19,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ).animate().shimmer(
                delay: 1.2.seconds,
                duration: 2.seconds,
                color: oLime.withValues(alpha: 0.2)),
          )
              .animate()
              .scale(delay: 800.ms, duration: 500.ms, curve: Curves.elasticOut)
              .fadeIn(delay: 800.ms),
        ],
      ),
    );
  }
}
