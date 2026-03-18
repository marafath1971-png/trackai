import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';

class AlertLogCard extends StatelessWidget {
  final MissedAlert alert;
  final AppThemeColors L;
  final VoidCallback onTap;
  const AlertLogCard(
      {super.key, required this.alert, required this.L, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.m),
          decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(AppRadius.l),
              border: Border.all(
                  color: alert.seen ? L.border : L.error,
                  width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.l),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: L.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.m)),
                  child: Center(
                      child: Icon(Icons.warning_amber_rounded,
                          color: L.error, size: 28)),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(alert.medName,
                          style: AppTypography.titleLarge.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: L.text),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                      const SizedBox(height: 4),
                      Text('Missed ${alert.doseLabel} at ${alert.time}',
                          style: AppTypography.bodySmall.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: L.sub),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                      const SizedBox(height: 6),
                      Text(alert.timestamp,
                          style: AppTypography.labelLarge.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: L.sub.withValues(alpha: 0.6))),
                    ])),
                if (!alert.seen)
                  Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration:
                          BoxDecoration(color: L.red, shape: BoxShape.circle)),
                Icon(Icons.chevron_right_rounded,
                    color: L.sub.withValues(alpha: 0.5), size: 24),
              ]),
            ),
          ),
        ),
      ).animate().fade().slideY(begin: 0.1, end: 0);
}

class EscalationDemoView extends StatefulWidget {
  final AppThemeColors L;
  final VoidCallback onBack;
  const EscalationDemoView({super.key, required this.L, required this.onBack});

  @override
  State<EscalationDemoView> createState() => _EscalationDemoViewState();
}

class _EscalationDemoViewState extends State<EscalationDemoView> {
  int _step = 1;

  @override
  Widget build(BuildContext context) {
    final L = widget.L;

    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          SafeArea(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          GestureDetector(
                              onTap: widget.onBack,
                              child: Icon(Icons.arrow_back_ios_new_rounded,
                                  color: L.sub, size: 18)),
                          const SizedBox(width: 12),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Escalation Logic',
                                    style: AppTypography.titleLarge.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: L.text)),
                                Text(
                                    'How missed doses trigger caregiver alerts',
                                    style: AppTypography.bodySmall.copyWith(
                                        fontSize: 12,
                                        color: L.sub))
                              ])
                        ]),
                        const SizedBox(height: 32),
                        EscalationTimeline(activeStep: _step, L: L),
                        const SizedBox(height: 32),
                        Row(children: [
                          Expanded(
                              child: GestureDetector(
                            onTap: _step <= 1
                                ? null
                                : () => setState(() => _step--),
                            child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: _step <= 1 ? L.border : L.card,
                                    borderRadius: BorderRadius.circular(AppRadius.m)),
                                child: Text('← Back',
                                    style: AppTypography.labelLarge.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _step <= 1 ? L.sub : L.text))),
                          )),
                          const SizedBox(width: 10),
                          Expanded(
                              flex: 2,
                              child: GestureDetector(
                                onTap: _step >= 4
                                    ? null
                                    : () {
                                        setState(() => _step++);
                                        if (_step == 4) {
                                          // Show a snackbar as a "Mock Push Notification"
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              backgroundColor:
                                                  Colors.transparent,
                                              elevation: 0,
                                              duration:
                                                  const Duration(seconds: 4),
                                              content: Container(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF1C1917),
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  boxShadow: [
                                                    BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                                alpha: 0.3),
                                                        blurRadius: 10,
                                                        offset:
                                                            const Offset(0, 4))
                                                  ],
                                                ),
                                                child: Row(children: [
                                                  const Text('⚠️',
                                                      style: TextStyle(
                                                          fontSize: 24)),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                      child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                        Text('CRITICAL ALERT',
                                                            style: AppTypography.labelLarge.copyWith(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                                color: L.red,
                                                                letterSpacing:
                                                                    1.0)),
                                                        const Text(
                                                            'Sarah J. missed their BP medication. Please check on them immediately.',
                                                            style: TextStyle(
                                                                fontFamily:
                                                                    'Inter',
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .white)),
                                                      ])),
                                                ]),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: _step >= 4 ? L.border : L.secondary,
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.m)),
                                    child: Text(
                                        _step >= 4
                                            ? 'Full flow shown ✓'
                                            : 'Next step →',
                                        style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: _step >= 4
                                                ? L.sub
                                                : Colors.white))),
                              )),
                        ]),
                        if (_step == 4) ...[
                          const SizedBox(height: 16),
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 500),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, val, child) => Opacity(
                                opacity: val,
                                child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - val)),
                                    child: child)),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: L.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.l),
                                  border: Border.all(
                                      color: L.error.withValues(alpha: 0.3))),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('⚠️ Alert message sent:',
                                        style: AppTypography.titleLarge.copyWith(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: L.red)),
                                    const SizedBox(height: 6),
                                    RichText(
                                        text: TextSpan(
                                            style: AppTypography.bodySmall.copyWith(
                                                fontSize: 13,
                                                color: L.text,
                                                height: 1.5),
                                            children: const [
                                          TextSpan(
                                              text:
                                                  '"Your family member missed their '),
                                          TextSpan(
                                              text:
                                                  '8:00 PM blood pressure medicine',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700)),
                                          TextSpan(
                                              text:
                                                  '. Please check on them. 🙏"'),
                                        ])),
                                  ]),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                               color: L.card,
                               borderRadius: BorderRadius.circular(AppRadius.l)),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('⏱️ Default alert delay: 30 minutes',
                                    style: AppTypography.titleLarge.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: L.text)),
                                const SizedBox(height: 4),
                                Text(
                                    'Configurable per caregiver (0 min → 1 hour)',
                                    style: TextStyle(
                                        color: L.sub)),
                              ]),
                        )
                      ]))),
        ],
      ),
    );
  }
}

class EscalationTimeline extends StatelessWidget {
  final int activeStep;
  final AppThemeColors L;
  const EscalationTimeline({super.key, required this.activeStep, required this.L});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'title': 'Dose time arrives',
        'detail': '8:00 PM',
         'icon': '🔔',
        'color': L.warning
      },
      {
        'title': 'User snoozed',
        'detail': 'Snooze 10 min',
        'icon': '😴',
        'color': L.warning
      },
      {
        'title': 'No action taken',
        'detail': '30 min limit reached',
        'icon': '❌',
        'color': const Color(0xFFF97316)
      },
       {
        'title': 'Caregivers alerted',
        'detail': '⚠️ Alert delivered',
        'icon': '⚠️',
        'color': L.error
      },
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        final isActive = activeStep > i;
        final isLast = i == steps.length - 1;
        final color = steps[i]['color'] as Color;

        return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Column(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: isActive ? color.withValues(alpha: 0.15) : L.fill,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                        color:
                            isActive ? color.withValues(alpha: 0.3) : L.border,
                        width: 2)),
                child: Center(
                    child: Text(steps[i]['icon'] as String,
                        style: const TextStyle(fontSize: 14))),
              ),
              if (!isLast)
                Expanded(
                    child: Container(
                        width: 2,
                        color:
                            isActive ? color.withValues(alpha: 0.3) : L.border,
                        margin: const EdgeInsets.symmetric(vertical: 4))),
            ]),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(steps[i]['title'] as String,
                          style: AppTypography.labelLarge.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isActive ? L.text : L.sub)),
                      const SizedBox(height: 2),
                      Text(steps[i]['detail'] as String,
                          style: AppTypography.bodySmall.copyWith(fontSize: 13, color: L.sub)),
                    ]),
              ),
            ),
          ]),
        );
      }),
    );
  }
}

class AlertDetailView extends StatelessWidget {
  final MissedAlert alert;
  final AppThemeColors L;
  final VoidCallback onBack;
  const AlertDetailView(
      {super.key, required this.alert, required this.L, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: L.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Alert Detail',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: L.text,
                          letterSpacing: -0.3)),
                  IconButton(
                      onPressed: onBack,
                      icon: Icon(Icons.close_rounded, color: L.sub, size: 24)),
                ],
              ),
              const SizedBox(height: 20),
               Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                    color: L.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.l),
                    border: Border.all(color: L.error.withValues(alpha: 0.3), width: 1.0),
                    gradient: LinearGradient(
                      colors: [L.redLight, L.bg],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: L.red.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]),
                child: Row(children: [
                  const Text('⚠️', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(alert.medName,
                            style: AppTypography.titleLarge.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: L.red)),
                        Text('Missed ${alert.doseLabel} at ${alert.time}',
                            style: AppTypography.bodySmall.copyWith(
                                fontSize: 13,
                                color: L.sub)),
                      ])),
                ]),
              ),
              const SizedBox(height: 24),
              Text('ESCALATION PATH',
                  style: AppTypography.labelLarge.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: L.sub,
                      letterSpacing: 1.0)),
              const SizedBox(height: 12),
              EscalationTimeline(activeStep: 4, L: L),
              const SizedBox(height: 24),
              Text('CAREGIVERS NOTIFIED',
                  style: AppTypography.labelLarge.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: L.sub,
                      letterSpacing: 1.0)),
              const SizedBox(height: 12),
              ...alert.caregivers.map((cg) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                     decoration: BoxDecoration(
                        color: L.card,
                        borderRadius: BorderRadius.circular(AppRadius.m),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1))
                        ]),
                    child: Row(children: [
                      Text(cg.avatar, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(cg.name,
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: L.text)),
                            Text(
                                cg.contact.isNotEmpty
                                    ? cg.contact
                                    : cg.relation,
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: L.sub)),
                          ])),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: L.greenLight,
                            borderRadius: BorderRadius.circular(99)),
                        child: Text('SENT ✓',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: L.green,
                                letterSpacing: 0.04)),
                      ),
                    ]),
                  )),
              const SizedBox(height: 24),
              Text('MESSAGE SENT',
                  style: AppTypography.labelLarge.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: L.sub,
                      letterSpacing: 1.0)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFF1C1917),
                    borderRadius: BorderRadius.circular(24)),
                child: RichText(
                    text: TextSpan(
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Color(0xFFFEF2F2),
                            height: 1.7),
                        children: [
                      const TextSpan(text: '⚠️ '),
                      const TextSpan(
                          text: 'Sarah J.',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const TextSpan(text: ' missed their '),
                      TextSpan(
                          text: '${alert.doseLabel} dose of ${alert.medName}',
                          style: const TextStyle(
                              color: Color(0xFFFCA5A5),
                              fontWeight: FontWeight.w700)),
                      TextSpan(
                          text: ' at ${alert.time}.\nPlease check on them. 🙏'),
                    ])),
              ),
              const SizedBox(height: 16),
              Center(
                       child: Text(alert.timestamp,
                      style: AppTypography.bodySmall.copyWith(
                          fontSize: 12,
                          color: L.sub))),
            ],
          ),
        ),
      ),
    );
  }
}
