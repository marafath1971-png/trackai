import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../services/notification_service.dart';

/// Shows smart guidance when a dose is overdue.
/// Options: Take Now, Skip, Smart Advice.
class MissedDoseProtocolSheet extends StatelessWidget {
  final DoseItem dose;
  final int minutesLate;

  const MissedDoseProtocolSheet({
    super.key,
    required this.dose,
    required this.minutesLate,
  });

  static Future<void> show(
      BuildContext context, DoseItem dose, int minutesLate) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          MissedDoseProtocolSheet(dose: dose, minutesLate: minutesLate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final L = context.L;
    final hoursLate = minutesLate ~/ 60;
    final minsLate = minutesLate % 60;

    // Compute next dose minutes for secondary advice

    return Container(
      margin: EdgeInsets.only(
        top: 60,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: [
           BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, -10), spreadRadius: -10),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 24),
                decoration: BoxDecoration(
                  color: L.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Icon + Title
            Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.max),
                  boxShadow: AppShadows.subtle,
                ),
                child: const Icon(Icons.access_time_rounded,
                    color: Color(0xFFF59E0B), size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                      'Missed Dose',
                      style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: L.text,
                          letterSpacing: -0.4),
                    ),
                    Text(
                      '${dose.med.name} · ${dose.sched.label}',
                      style: AppTypography.bodySmall.copyWith(color: L.sub),
                    ),
                  ])),
            ]),

            const SizedBox(height: 20),

            // Late duration chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: L.fill.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.l),
                border: Border.all(color: L.border.withValues(alpha: 0.05)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFF59E0B), size: 18),
                const SizedBox(width: 10),
                Text(
                  hoursLate > 0
                      ? 'You are $hoursLate h ${minsLate}m late'
                      : 'You are ${minsLate}m late',
                  style: AppTypography.labelLarge
                      .copyWith(fontWeight: FontWeight.w600, color: L.text),
                ),
              ]),
            ),

            const SizedBox(height: 20),

            // Smart guidance text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: minutesLate < 120
                    ? const Color(0xFF10B981).withValues(alpha: 0.08)
                    : minutesLate < 360
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
                        : const Color(0xFFEF4444).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.l),
                border: Border.all(
                  color: minutesLate < 120
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : minutesLate < 360
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                          : const Color(0xFFEF4444).withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: AppShadows.subtle,
              ),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(
                  minutesLate < 120
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: minutesLate < 120
                      ? const Color(0xFF10B981)
                      : minutesLate < 360
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFEF4444),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                  state.getDoseGuidance(dose.med),
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: minutesLate < 120
                        ? const Color(0xFF10B981)
                        : minutesLate < 360
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFEF4444),
                    height: 1.5,
                  ),
                )),
              ]),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            if (minutesLate < 360) ...[
              _ActionBtn(
                label: minutesLate > 60 ? 'Take It Late Now' : 'Take Now',
                icon: Icons.medication_rounded,
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.pop(context);
                  state.toggleDose(dose);
                },
              ),
              const SizedBox(height: 12),
            ],

            // Re-schedule concept (simulated via snooze logic for demonstration, matching plan requirements)
            _ActionBtn(
              label: 'Remind Me Later',
              icon: Icons.snooze_rounded,
              color: const Color(0xFF8B5CF6), // Purple for rescheduling
              onTap: () {
                Navigator.pop(context);
                // We trigger the exact same snooze logic as the notification action
                final payloadForSnooze =
                    'take|${dose.med.id}|${dose.sched.h}|${dose.sched.m}|${dose.sched.label}';
                NotificationService.scheduleOneOffReminder(
                  id: dose.med.id + 500000,
                  title: '⏰ Rescheduled: ${dose.med.name}',
                  body: 'You asked me to remind you again later.',
                  scheduledDate: DateTime.now().add(const Duration(hours: 1)),
                  payload: payloadForSnooze,
                );
                state.showToast('I will remind you again in 1 hour',
                    type: 'info');
              },
            ),
            const SizedBox(height: 12),

            _ActionBtn(
              label: 'Skip Today',
              icon: Icons.skip_next_rounded,
              color: const Color(0xFF6B7280),
              onTap: () {
                Navigator.pop(context);
                state.skipDose(dose);
              },
            ),
            const SizedBox(height: 12),
            _ActionBtn(
              label: 'Dismiss',
              icon: Icons.close_rounded,
              color: L.sub,
              outlined: true,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.max),
          border: Border.all(
              color: outlined ? L.border.withValues(alpha: 0.2) : color.withValues(alpha: 0.15),
              width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: outlined ? L.sub : color),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: outlined ? L.sub : color,
            ),
          ),
        ]),
      ),
    );
  }
}
