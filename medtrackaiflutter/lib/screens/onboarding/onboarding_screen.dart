import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import '../../models/constants.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../widgets/common/modern_time_picker.dart';

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
    'promoCode': null,
    'appliedPromo': null,
  };

  String _paywallPlan = 'annual'; // 'annual' or 'monthly'
  int _paywallStep = 0; // 0=Features, 1=Trust, 2=Timeline
  String _promoInput = '';
  bool _promoError = false;
  Map<String, dynamic>? _appliedPromo;

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
        const _OBStep(
            id: 'age',
            type: 'text',
            emoji: '🎂',
            title: 'How old are you?',
            subtitle: 'Helps tailor health insights',
            field: 'age',
            placeholder: 'e.g. 35',
            isNum: true),
        const _OBStep(
            id: 'gender',
            type: 'single',
            emoji: '🧬',
            title: 'How do you identify?',
            subtitle: 'For personalised health guidance',
            field: 'gender',
            options: kGenders),
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
            id: 'medCount',
            type: 'single',
            emoji: '💊',
            title: 'How many medications do you take?',
            subtitle: 'Include vitamins, supplements & prescriptions',
            field: 'medCount',
            options: kMedCounts),
        const _OBStep(
            id: 'forgetting',
            type: 'single',
            emoji: '🧠',
            title: 'When do you most forget to take meds?',
            subtitle: "We'll build reminders around this",
            field: 'forgetting',
            options: kForgetPatterns),
        const _OBStep(
            id: 'wakeTime',
            type: 'time',
            emoji: '⏰',
            title: 'What time do you wake up?',
            subtitle: "We'll schedule your morning reminder",
            field: 'wakeTime'),
        const _OBStep(
            id: 'breakfastTime',
            type: 'time',
            emoji: '🍳',
            title: 'When do you usually have breakfast?',
            subtitle: 'Some meds are best taken with food',
            field: 'breakfastTime'),
        const _OBStep(
            id: 'lunchTime',
            type: 'time',
            emoji: '🥗',
            title: 'What time is your lunch break?',
            subtitle: "We'll set your midday check-in",
            field: 'lunchTime'),
        const _OBStep(
            id: 'dinnerTime',
            type: 'time',
            emoji: '🍽️',
            title: 'When do you have dinner?',
            subtitle: 'Evening meds work best with your meal',
            field: 'dinnerTime'),
        const _OBStep(
            id: 'sleepTime',
            type: 'time',
            emoji: '😴',
            title: 'What time do you usually sleep?',
            subtitle: "We'll send a last reminder before bed",
            field: 'sleepTime'),
        const _OBStep(
            id: 'doctorVisits',
            type: 'single',
            emoji: '👨‍⚕️',
            title: 'How often do you see your doctor?',
            subtitle: 'Helps us remind you before appointments',
            field: 'doctorVisits',
            options: kDoctorVisits),
        const _OBStep(
            id: 'support',
            type: 'single',
            emoji: '🤝',
            title: 'Do you have someone who helps you with medication?',
            subtitle: "We'll tailor reminders accordingly",
            field: 'support',
            options: kSupport),
        const _OBStep(
            id: 'challenge',
            type: 'single',
            emoji: '😤',
            title: "What's your biggest medication challenge?",
            subtitle: "Let's solve it together",
            field: 'challenge',
            options: kChallenges),
        const _OBStep(
            id: 'prevApp',
            type: 'single',
            emoji: '📱',
            title: 'Have you tried a medication app before?',
            subtitle: "We'll show you what makes us different",
            field: 'prevApp',
            options: kPrevApp),
        const _OBStep(
            id: 'motivation',
            type: 'multi',
            emoji: '💪',
            title: 'What motivates you to stay healthy?',
            subtitle: "We'll personalise your encouragement",
            field: 'motivation',
            options: kMotivation),
        const _OBStep(
            id: 'reminderStyle',
            type: 'single',
            emoji: '🔔',
            title: 'How should we remind you?',
            subtitle: 'Pick the style that works for you',
            field: 'reminderStyle',
            options: kReminderStyles),
        const _OBStep(id: 'notif', type: 'notif'),
        const _OBStep(id: 'plan', type: 'plan'),
        const _OBStep(id: 'paywall', type: 'paywall'),
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
      setState(() => _step++);
      _animCtrl.forward(from: 0);
    }
  }

  void _back() {
    if (_step > 0) {
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
      promoCode: _appliedPromo != null ? _promoInput : null,
      appliedPromo: _appliedPromo,
    );
    context.read<AppState>().completeOnboarding(profile);
  }

  void _applyPromo() {
    final code = _promoInput.trim().toUpperCase();
    if (kPromoCodes.containsKey(code)) {
      setState(() {
        _appliedPromo = kPromoCodes[code];
        _promoError = false;
      });
    } else {
      setState(() {
        _promoError = true;
      });
    }
  }

  bool _canContinue(_OBStep step) {
    if (step.type == 'splash' || step.type == 'notif' || step.type == 'plan') {
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
    const oBg = AppColors.oBg;
    const oText = AppColors.oText;
    const oSub = AppColors.oSub;
    const oLime = AppColors.oLime;
    const oCard = AppColors.oCard;

    final progress = (_step + 1) / _steps.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: oBg,
        body: SafeArea(
          child: Column(children: [
            // ── Progress bar (not on splash/paywall)
            if (step.type != 'splash' && step.type != 'paywall')
              Container(
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2A),
                    borderRadius: BorderRadius.circular(99)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [oLime, AppColors.oGreen]),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
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
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _buildStep(step, oText, oSub, oLime, oCard, oBg),
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
            oCard: oCard);
      case 'single':
        return _SingleStep(
            step: step,
            form: _form,
            onSelect: (k, v) => setState(() => _form[k] = v),
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
          promoInput: _promoInput,
          appliedPromo: _appliedPromo,
          promoError: _promoError,
          onPlanToggle: (p) => setState(() => _paywallPlan = p),
          onPromoChange: (v) => setState(() {
            _promoInput = v;
            _promoError = false;
          }),
          onApplyPromo: _applyPromo,
          onNextStep: () => setState(() => _paywallStep++),
          onComplete: _complete,
          oText: oText,
          oSub: oSub,
          oCard: oCard,
          oLime: oLime,
        );
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
            color: canGo ? oLime : const Color(0xFF1E1E2A),
            borderRadius: BorderRadius.circular(16),
            boxShadow: canGo
                ? [
                    BoxShadow(
                        color: oLime.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ]
                : null,
          ),
          child: Text(
            step.type == 'plan'
                ? 'See My Plan →'
                : (step.type == 'notif' ? 'Allow Notifications' : 'Continue →'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: canGo ? const Color(0xFF1A2010) : const Color(0xFF404050),
              letterSpacing: -0.3,
            ),
          ),
        ),
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
  final bool isNum;
  final List<Map<String, String>> options;

  const _OBStep({
    required this.id,
    required this.type,
    this.title = '',
    this.subtitle = '',
    this.emoji = '',
    this.field,
    this.placeholder,
    this.isNum = false,
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
          child: Text(emoji, style: const TextStyle(fontSize: 48, height: 1.0)),
        ),
      Text(title,
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: oText,
              letterSpacing: -0.5,
              height: 1.2)),
      if (subtitle.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(subtitle,
            style: TextStyle(
                fontFamily: 'Inter', fontSize: 14, color: oSub, height: 1.4)),
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
    const oLime = AppColors.oLime;
    const oText = AppColors.oText;
    const oSub = AppColors.oSub;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(minHeight: MediaQuery.of(context).size.height),
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
                      color: const Color(0x1FA3E635),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0x33A3E635)),
                    ),
                    child: Center(
                        child: Image.asset('assets/images/app_logo.png',
                            width: 60, height: 60)),
                  ),
                  const SizedBox(height: 20),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.0,
                          height: 1.1),
                      children: [
                        TextSpan(
                            text: 'Med ',
                            style: TextStyle(color: Color(0xFFF0F0F5))),
                        TextSpan(text: 'Ai', style: TextStyle(color: oLime)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your intelligent medicine tracker.\nScan, track, and never miss a dose again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: oSub,
                        height: 1.6),
                  ),
                ]),
              ),
              const SizedBox(height: 32),

              // ── 3 Feature cards ───────────────────────────────
              ...[
                ('🔍 Scan', 'AI identifies any medicine instantly'),
                ('⏰ Remind', 'Smart reminders built around your life'),
                ('📈 Track', 'Monitor adherence & streak progress'),
              ].map((f) {
                final parts = f.$1.split(' ');
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.oCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.oBorder, width: 0.5),
                  ),
                  child: Row(children: [
                    Text(parts[0], style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(parts[1],
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: oText)),
                          Text(f.$2,
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: oSub)),
                        ])),
                  ]),
                );
              }),
              const SizedBox(height: 32),

              const SizedBox(height: 32),
              const Text('Free to start · No credit card required',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Inter', fontSize: 12, color: oSub)),
            ],
          ),
        ),
      ),
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
// TEXT STEP
// ════════════════════════════════════════

class _TextStep extends StatefulWidget {
  final _OBStep step;
  final Map<String, dynamic> form;
  final Function(String, String) onChanged;
  final VoidCallback onNext;
  final Color oText, oSub, oCard;
  const _TextStep(
      {required this.step,
      required this.form,
      required this.onChanged,
      required this.onNext,
      required this.oText,
      required this.oSub,
      required this.oCard});

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
    const oLime = AppColors.oLime;
    final val = _ctrl.text.trim();
    final hasVal = val.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        // Large emoji
        Text(widget.step.emoji, style: const TextStyle(fontSize: 52)),
        const SizedBox(height: 16),
        Text(widget.step.title,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: widget.oText,
                letterSpacing: -0.5,
                height: 1.2)),
        const SizedBox(height: 8),
        Text(widget.step.subtitle,
            style: TextStyle(
                fontFamily: 'Inter', fontSize: 14, color: widget.oSub)),
        const SizedBox(height: 32),
        // Input — border turns lime when filled
        TextField(
          controller: _ctrl,
          autofocus: true,
          keyboardType:
              widget.step.isNum ? TextInputType.number : TextInputType.text,
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: widget.oText),
          onChanged: (v) => widget.onChanged(widget.step.field!, v),
          onSubmitted: (_) {
            if (hasVal) widget.onNext();
          },
          inputFormatters: widget.step.isNum
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          decoration: InputDecoration(
            hintText: widget.step.placeholder,
            hintStyle: TextStyle(color: widget.oSub, fontFamily: 'Inter'),
            filled: true,
            fillColor: widget.oCard,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: hasVal ? oLime : AppColors.oBorder,
                  width: hasVal ? 1.5 : 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: hasVal ? oLime : AppColors.oBorder, width: 1.5),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
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
    return GestureDetector(
      onTap: () => onSelect(step.field!, opt['v']!),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding:
            EdgeInsets.symmetric(horizontal: isGrid ? 12 : 18, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x1FA3E635) : const Color(0x12FFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected
                  ? oLime.withValues(alpha: 0.4)
                  : const Color(0x14FFFFFF),
              width: 1.0),
        ),
        child: isGrid
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (opt['e'] != null)
                    Text(opt['e']!, style: const TextStyle(fontSize: 28)),
                  if (opt['e'] != null) const SizedBox(height: 12),
                  Text(opt['v']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? oLime : oText)),
                ],
              )
            : Row(children: [
                if (opt['e'] != null)
                  Text(opt['e']!,
                      style: const TextStyle(fontSize: 24, height: 1.0)),
                if (opt['e'] != null) const SizedBox(width: 14),
                Expanded(
                    child: Text(opt['v']!,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? oLime : oText))),
                if (isSelected)
                  Container(
                    width: 20,
                    height: 20,
                    decoration:
                        BoxDecoration(color: oLime, shape: BoxShape.circle),
                    child: const Center(
                        child: Icon(Icons.check,
                            color: Color(0xFF0A0A0F), size: 13)),
                  ),
              ]),
      ),
    );
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
              return GestureDetector(
                onTap: () {
                  final newSel = isSelected
                      ? (selected..remove(opt['v']!))
                      : [...selected, opt['v']!];
                  onSelect(step.field!, newSel);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0x1FA3E635) : oCard,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                        color: isSelected ? oLime : AppColors.oBorder,
                        width: isSelected ? 1.5 : 0.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (opt['e'] != null)
                      Text(opt['e']!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(opt['v']!,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? oLime : oText)),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.check_circle_rounded, color: oLime, size: 15)
                    ],
                  ]),
                ),
              );
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
                color: isActive ? oLime.withValues(alpha: 0.15) : oCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isActive ? oLime : AppColors.oBorder,
                    width: isActive ? 1.5 : 0.5),
              ),
              child: Column(children: [
                Text(qt['emoji'] as String,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 2),
                Text(qt['label'] as String,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isActive ? oLime : oSub)),
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
                  oCard: oCard)),
          Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(':',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: oSub))),
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
                  oCard: oCard)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                  color: oCard, borderRadius: BorderRadius.circular(12)),
              child: Text(h >= 12 ? 'PM' : 'AM',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: oText)),
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
  final Color oText, oSub, oCard;
  const _TimeInput(
      {required this.label,
      required this.value,
      required this.onChanged,
      required this.oText,
      required this.oSub,
      required this.oCard});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label.toUpperCase(),
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: oSub)),
      const SizedBox(height: 6),
      TextField(
        controller: TextEditingController(text: value),
        keyboardType: TextInputType.number,
        maxLength: 2,
        textAlign: TextAlign.center,
        onChanged: onChanged,
        style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: oText),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: oCard,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.oBorder, width: 0.5)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.oBorder, width: 0.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.oLime, width: 1.5)),
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
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: oLime.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(child: Icon(Icons.notifications_active_rounded, color: oLime, size: 40)),
        ),
        const SizedBox(height: 32),
        Text('Enable Reminders',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: oText,
                letterSpacing: -0.6)),
        const SizedBox(height: 12),
        Text(
            'Get notified when it\'s time to take your medicine. You can always change this later.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Inter', fontSize: 15, color: oSub, height: 1.5)),
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
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
              color: const Color(0x1FA3E635),
              borderRadius: BorderRadius.circular(28)),
          child:
              const Center(child: Text('🎯', style: TextStyle(fontSize: 48))),
        ),
        const SizedBox(height: 24),
        Text('Your plan is ready${name.isNotEmpty ? ", $name" : ""}!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: oText,
                letterSpacing: -1.0,
                height: 1.1)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
              color: oLime.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16)),
          child: Text(
            _generateNarrative(name, goal, wakeTime, motivation),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: oLime,
                height: 1.4),
          ),
        ),
        const SizedBox(height: 32),
        ...highlights.map((h) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                  color: oCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.oBorder, width: 0.5)),
              child: Row(children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                      color: oLime.withValues(alpha: 0.12),
                      shape: BoxShape.circle),
                  child: Icon(Icons.check, size: 14, color: oLime),
                ),
                const SizedBox(width: 14),
                Expanded(
                    child: Text(h,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: oText))),
              ]),
            )),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: oLime.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: oLime.withValues(alpha: 0.2))),
          child: Column(children: [
            Text('94%',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: oLime)),
            const SizedBox(height: 4),
            Text('of users like you improved adherence in 2 weeks',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: oSub,
                    height: 1.4)),
          ]),
        ),
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
  final String promoInput;
  final Map<String, dynamic>? appliedPromo;
  final bool promoError;
  final Function(String) onPlanToggle;
  final Function(String) onPromoChange;
  final VoidCallback onApplyPromo;
  final VoidCallback onNextStep;
  final VoidCallback onComplete;
  final Color oText, oSub, oCard, oLime;

  const _PaywallStep({
    required this.form,
    required this.plan,
    required this.paywallStep,
    required this.promoInput,
    required this.appliedPromo,
    required this.promoError,
    required this.onPlanToggle,
    required this.onPromoChange,
    required this.onApplyPromo,
    required this.onNextStep,
    required this.onComplete,
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
        promoInput: promoInput,
        appliedPromo: appliedPromo,
        promoError: promoError,
        onApply: onApplyPromo,
        onPromoChange: onPromoChange,
        onSkip: onComplete,
        onNext: onNextStep,
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
        appliedPromo: appliedPromo,
        onComplete: onComplete,
        oText: oText,
        oSub: oSub,
        oCard: oCard,
        oLime: oLime);
  }
}

class _PaywallFeatures extends StatelessWidget {
  final String plan;
  final String promoInput;
  final Map<String, dynamic>? appliedPromo;
  final bool promoError;
  final Function(String) onToggle;
  final Function(String) onPromoChange;
  final VoidCallback onApply, onNext, onSkip;
  final Color oText, oSub, oCard, oLime;

  const _PaywallFeatures({
    required this.plan,
    required this.promoInput,
    required this.appliedPromo,
    required this.promoError,
    required this.onToggle,
    required this.onPromoChange,
    required this.onApply,
    required this.onNext,
    required this.onSkip,
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
        'price': '\$2.99',
        'period': '/mo',
        'total': 'Billed \$35.88/year',
        'badge': 'Best value · Save 62%'
      },
      {
        'id': 'monthly',
        'label': 'Monthly',
        'price': '\$7.99',
        'period': '/mo',
        'total': 'Billed monthly',
        'badge': null
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MEDTRACK PRO',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: oLime,
                    letterSpacing: 1.2)),
            Text('Start your free trial',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: oText,
                    letterSpacing: -0.5)),
          ]),
          TextButton(
              onPressed: onSkip,
              child: Text('Skip',
                  style: TextStyle(
                      color: oSub, fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.2),
          itemCount: feats.length,
          itemBuilder: (c, i) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: oCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.oBorder)),
            child: Row(children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: oLime, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(feats[i],
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: oText),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        ...plans.map((p) {
          final isSel = plan == p['id'];
          return GestureDetector(
            onTap: () => onToggle(p['id'] as String),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isSel ? oLime.withValues(alpha: 0.08) : oCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isSel ? oLime : AppColors.oBorder, width: 2),
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
                            style: const TextStyle(
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
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isSel ? oLime : oText)),
                        Text(p['total'] as String,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: oSub)),
                      ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(p['price'] as String,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: isSel ? oLime : oText)),
                    Text(p['period'] as String,
                        style: TextStyle(
                            fontFamily: 'Inter', fontSize: 11, color: oSub)),
                  ]),
                ]),
              ]),
            ),
          );
        }),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: TextField(
            onChanged: onPromoChange,
            controller: TextEditingController(text: promoInput)
              ..selection = TextSelection.collapsed(offset: promoInput.length),
            style: TextStyle(
                color: oText, fontSize: 14, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Promo code (try WELCOME)',
              hintStyle: TextStyle(color: oSub, fontSize: 13),
              filled: true,
              fillColor: oCard,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: appliedPromo != null
                          ? oLime
                          : (promoError ? const Color(0xFFFF453A) : AppColors.oBorder))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: appliedPromo != null
                          ? oLime
                          : (promoError ? const Color(0xFFFF453A) : AppColors.oBorder))),
            ),
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onApply,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                  color: appliedPromo != null
                      ? oLime.withValues(alpha: 0.1)
                      : oCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: appliedPromo != null ? oLime : AppColors.oBorder)),
              child: Text(appliedPromo != null ? '✓' : 'Apply',
                  style: TextStyle(
                      color: appliedPromo != null ? oLime : oText,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
        if (promoError)
          const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('❌ Invalid promo code',
                      style: TextStyle(
                          color: AppColors.dRed,
                          fontSize: 12,
                          fontFamily: 'Inter')))),
        if (appliedPromo != null)
          Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text('🎉 ${appliedPromo!['label']} applied!',
                  style: TextStyle(
                      color: oLime,
                      fontSize: 12,
                      fontWeight: FontWeight.w700))),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: onNext,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
                color: oLime,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: oLime.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8))
                ]),
            child: const Text('Start 7-Day Free Trial →',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A2010))),
          ),
        ),
        const SizedBox(height: 12),
        Center(
            child: RichText(
                text: TextSpan(
                    style: TextStyle(
                        fontFamily: 'Inter', fontSize: 12, color: oSub),
                    children: [
              TextSpan(
                  text: 'No payment due now',
                  style: TextStyle(color: oLime, fontWeight: FontWeight.w800)),
              const TextSpan(text: ' · Cancel anytime'),
            ]))),
      ]),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        Text("We've got you covered",
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: oText,
                letterSpacing: -1.0)),
        const SizedBox(height: 8),
        Text("Your trust matters. Here's what happens next.",
            style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: oSub)),
        const SizedBox(height: 32),
        ...trust.map((t) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: oCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.oBorder)),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t['e']!, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(t['t']!,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: oText)),
                      const SizedBox(height: 4),
                      Text(t['d']!,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: oSub,
                              height: 1.4)),
                    ])),
              ]),
            )),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: oLime.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: oLime.withValues(alpha: 0.2))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                '"I haven\'t missed a single dose in 3 months. The reminders are perfectly timed."',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: oText,
                    fontStyle: FontStyle.italic,
                    height: 1.5)),
            const SizedBox(height: 10),
            Text('— Sarah K., managing Type 2 Diabetes ⭐⭐⭐⭐⭐',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: oSub,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: onNext,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
                color: oLime,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: oLime.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ]),
            child: const Text('I Understand, Continue →',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.black)),
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
    final trialDays = (appliedPromo?['type'] == 'trial')
        ? (appliedPromo!['label'].contains('30') ? 30 : 14)
        : 7;
    final today = DateTime.now();
    final trialEnd = today.add(Duration(days: trialDays));
    final reminderDate = trialEnd.subtract(const Duration(days: 3));
    String fmtDate(DateTime d) => '${_month(d.month)} ${d.day}';

    final timeline = [
      {
        'label': 'Today',
        'date': fmtDate(today),
        'desc': 'Start free trial',
        'icon': '🚀',
        'color': oLime
      },
      {
        'label': 'Day ${trialDays - 3}',
        'date': fmtDate(reminderDate),
        'desc': 'We email you a reminder',
        'icon': '📧',
        'color': Colors.orange
      },
      {
        'label': 'Day $trialDays',
        'date': fmtDate(trialEnd),
        'desc': plan == 'annual' ? '\$35.88 billed' : '\$7.99 billed',
        'icon': '💳',
        'color': Colors.blue
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        Text("Here's exactly what happens",
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: oText,
                letterSpacing: -1.0)),
        const SizedBox(height: 8),
        Text("No surprises. No confusion.",
            style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: oSub)),
        const SizedBox(height: 32),
        Stack(children: [
          Positioned(
              left: 20,
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
                          colors: [oLime, Colors.orange, Colors.blue]),
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == 0 ? color : oCard,
                      border: Border.all(color: color, width: 2)),
                  child: Center(
                      child: Text(t['icon'] as String,
                          style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: oCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: i == 0 ? color : AppColors.oBorder)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(t['label'] as String,
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: i == 0 ? color : oText)),
                              Text(t['date'] as String,
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: oSub)),
                            ]),
                        const SizedBox(height: 4),
                        Text(t['desc'] as String,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: i == 0 ? oText : oSub)),
                      ]),
                )),
              ]),
            );
          }).toList()),
        ]),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: oCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.oBorder)),
          child: Column(children: [
            _PriceRow(
                label: 'Free trial',
                value: '$trialDays days FREE',
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
                label: 'Then',
                value: plan == 'annual' ? '\$35.88/year' : '\$7.99/month',
                oText: oText,
                oSub: oSub),
          ]),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: onComplete,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
                color: oLime,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: oLime.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ]),
            child: Text('Start My $trialDays-Day Free Trial 🚀',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.black)),
          ),
        ),
        const SizedBox(height: 12),
        Center(
            child: Text(
                'Cancel any time before ${fmtDate(trialEnd)} to avoid being charged.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: oSub,
                    height: 1.4))),
      ]),
    );
  }

  String _month(int m) => [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m];
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
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: oText)),
      Expanded(
          child: Text(value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color ?? oSub))),
    ]);
  }
}
