import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared/shared_widgets.dart';

class AlertLogCard extends StatelessWidget {
  final MissedAlert alert;
  final AppThemeColors L;
  final VoidCallback onTap;
  const AlertLogCard(
      {super.key, required this.alert, required this.L, required this.onTap});
  @override
  Widget build(BuildContext context) => BouncingButton(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.neumorphic,
              border: alert.seen ? null : Border.all(color: L.error.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: L.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(
                  child: Icon(Icons.error_outline_rounded,
                      color: L.error, size: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(alert.medName,
                      style: AppTypography.titleLarge.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: L.text),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                  const SizedBox(height: 2),
                  Text('Missed ${alert.doseLabel} at ${alert.time}',
                      style: AppTypography.bodySmall.copyWith(
                          color: L.sub, fontWeight: FontWeight.w900, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                ])),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!alert.seen)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: L.error, borderRadius: BorderRadius.circular(4)),
                    child: Text('NEW', style: TextStyle(color: L.card, fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                Text(alert.timestamp.split(',').first,
                    style: AppTypography.labelLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: L.sub.withValues(alpha: 0.6))),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: L.sub.withValues(alpha: 0.3), size: 18),
          ]),
        ),
      );
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
      backgroundColor: L.meshBg,
      appBar: AppBar(
        backgroundColor: L.meshBg,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: L.text, size: 18), onPressed: widget.onBack),
        title: Text('Escalation Protocol', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900, color: L.text, fontSize: 18)),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Safety simulation of how missed doses trigger household alerts.',
                        style: AppTypography.bodySmall
                            .copyWith(color: L.sub, fontSize: 14)),
                    const SizedBox(height: 32),
                    EscalationTimeline(activeStep: _step, L: L),
                    const SizedBox(height: 40),
                    Row(children: [
                      Expanded(
                          child: BouncingButton(
                        onTap: _step <= 1
                            ? null
                            : () => setState(() => _step--),
                        child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: _step <= 1 ? L.fill : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _step <= 1 ? null : AppShadows.neumorphic,
                            ),
                            child: Text('Previous',
                                style: AppTypography.labelLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: _step <= 1 ? L.sub : L.text))),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          flex: 2,
                          child: BouncingButton(
                        onTap: _step >= 4
                            ? null
                            : () {
                                setState(() => _step++);
                                if (_step == 4) {
                                  HapticFeedback.heavyImpact();
                                }
                              },
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: _step >= 4 ? L.fill : L.text,
                                borderRadius:
                                    BorderRadius.circular(16)),
                            child: Text(
                                _step >= 4
                                    ? 'Completed'
                                    : 'Next Step',
                                style: AppTypography.labelLarge
                                    .copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: _step >= 4
                                            ? L.sub
                                            : L.bg))),
                      )),
                    ]),
                    if (_step == 4) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: const Color(0xFF1C1917),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))
                            ]
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.campaign_rounded, color: Color(0xFFFCA5A5), size: 20),
                                  const SizedBox(width: 10),
                                  Text('CRITICAL ALERT SENT',
                                      style: AppTypography.labelLarge
                                          .copyWith(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFFFCA5A5),
                                              letterSpacing: 1.5)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                  'Sarah J. missed their Blood Pressure medication. Please check on them immediately.',
                                  style: AppTypography.bodySmall
                                      .copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white, height: 1.5)),
                            ]),
                      ).animate().scale(curve: Curves.easeOutBack),
                    ],
                  ]))),
    );
  }
}

class EscalationTimeline extends StatelessWidget {
  final int activeStep;
  final AppThemeColors L;
  const EscalationTimeline(
      {super.key, required this.activeStep, required this.L});
  @override
  Widget build(BuildContext context) {
    final steps = [
      {'title': 'Dose Scheduled', 'detail': 'System awaits confirmation', 'icon': '⏰', 'color': L.text},
      {'title': 'Dose Overdue', 'detail': 'User receives nudge', 'icon': '🔔', 'color': const Color(0xFFF59E0B)},
      {'title': 'Grace Period Ends', 'detail': '30 min monitoring window closed', 'icon': '⏳', 'color': const Color(0xFFF97316)},
      {'title': 'Household Alert', 'detail': 'Push notifications to guardians', 'icon': '📢', 'color': L.error},
    ];
    return Column(
      children: List.generate(steps.length, (i) {
        final isActive = activeStep > i;
        final isCurrent = activeStep == i + 1;
        final isLast = i == steps.length - 1;
        final color = steps[i]['color'] as Color;
        return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Column(children: [
              AnimatedContainer(
                duration: 400.ms,
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: isActive ? color : L.fill,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isCurrent ? color : (isActive ? color : L.border),
                        width: 2.5)),
                child: Center(
                    child: Text(steps[i]['icon'] as String,
                        style: const TextStyle(fontSize: 16))),
              ),
              if (!isLast)
                Expanded(
                    child: Container(
                        width: 2,
                        color:
                            isActive ? color.withValues(alpha: 0.4) : L.border,
                        margin: const EdgeInsets.symmetric(vertical: 4))),
            ]),
            const SizedBox(width: 18),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(steps[i]['title'] as String,
                          style: AppTypography.labelLarge.copyWith(
                              fontSize: 15,
                              fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                              color: isActive ? L.text : L.sub)),
                      const SizedBox(height: 2),
                      Text(steps[i]['detail'] as String,
                          style:
                              AppTypography.bodySmall.copyWith(color: L.sub, fontSize: 12)),
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
      backgroundColor: L.meshBg,
      appBar: AppBar(
        backgroundColor: L.meshBg, elevation: 0, leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: onBack),
        title: Text('Critical Alert', style: AppTypography.titleLarge.copyWith(fontSize: 18, fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    ...AppShadows.neumorphic,
                    BoxShadow(color: L.error.withValues(alpha: 0.05), blurRadius: 40, offset: const Offset(0, 20))
                  ],
                  border: Border.all(color: L.error.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(color: L.error.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Center(child: Icon(Icons.warning_rounded, color: L.error, size: 32)),
                  ),
                  const SizedBox(height: 20),
                  Text(alert.medName, style: AppTypography.displayLarge.copyWith(fontSize: 24, fontWeight: FontWeight.w900, color: L.text)),
                  const SizedBox(height: 4),
                  Text('Missed ${alert.doseLabel} at ${alert.time}', style: AppTypography.bodySmall.copyWith(fontSize: 15, color: L.sub, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _Badge(label: 'CRITICAL', color: L.error),
                    const SizedBox(width: 8),
                    _Badge(label: alert.timestamp.split(',').first, color: L.sub),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('SAFETY PROTOCOL', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, color: L.sub, letterSpacing: 1.0)),
            const SizedBox(height: 16),
            EscalationTimeline(activeStep: 4, L: L),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: AppTypography.labelLarge.copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
  );
}
