import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../widgets/common/paywall_sheet.dart';
import '../../../widgets/common/bouncing_button.dart';
import 'ai_protector_card.dart';

int _calculateStreak(
    Map<String, List<DoseEntry>> history, List<Medicine> meds) {
  if (history.isEmpty) return 0;
  final sortedKeys = history.keys.toList()..sort((a, b) => b.compareTo(a));
  int streak = 0;
  final now = DateTime.now();
  final yesterdayKey =
      now.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
  final todayKey = now.toIso8601String().substring(0, 10);

  if (sortedKeys.isNotEmpty &&
      sortedKeys[0] != todayKey &&
      sortedKeys[0] != yesterdayKey) {
    return 0;
  }

  for (final key in sortedKeys) {
    final date = DateTime.parse(key);
    final dayIdx = date.weekday % 7;
    final medsScheduledThisDay = meds
        .where(
            (m) => m.schedule.any((s) => s.enabled && s.days.contains(dayIdx)))
        .toList();
    final expectedCount = medsScheduledThisDay.length;
    final entries = history[key] ?? [];
    final takenCount = entries.where((e) => e.taken).length;

    if (expectedCount > 0 && takenCount >= expectedCount) {
      streak++;
    } else if (expectedCount > 0) {
      break;
    }
  }
  return streak;
}

class PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onTap;
  const PatientCard(
      {super.key,
      required this.patient,
      required this.state,
      required this.L,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Medicine>>(
      stream: state.getPatientMeds(patient['uid']),
      builder: (context, medSnap) {
        return StreamBuilder<Map<String, List<DoseEntry>>>(
          stream: state.getPatientHistory(patient['uid']),
          builder: (context, historySnap) {
            final history = historySnap.data ?? {};
            final dateKey = DateTime.now().toIso8601String().substring(0, 10);
            final entries = history[dateKey] ?? [];
            final medsSnapshot = medSnap.data ?? [];
            
            // Calculate effective progress for the day
            final sysExpected = medsSnapshot
                .where((m) => m.schedule.any((s) => s.enabled && s.days.contains(DateTime.now().weekday % 7)))
                .length;
            final taken = entries.where((e) => e.taken).length;
            final adherence = sysExpected == 0 ? 1.0 : (taken / sysExpected).clamp(0.0, 1.0);
            final color = adherence >= 0.85 
                ? const Color(0xFF10B981) 
                : adherence >= 0.65 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);

            return BouncingButton(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.p16),
                margin: const EdgeInsets.only(bottom: AppSpacing.p12),
                decoration: BoxDecoration(
                  color: L.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: L.border.withValues(alpha: 0.5), width: 1.0),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                            border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
                          ),
                          child: Center(
                            child: Text(patient['avatar'] ?? '👤',
                                style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(patient['name'] ?? 'Patient',
                                  style: AppTypography.titleLarge.copyWith(
                                      color: L.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5)),
                              const SizedBox(height: 2),
                              Text('${patient['relation']} · Progress Today',
                                  style: AppTypography.bodySmall.copyWith(
                                      color: L.sub.withValues(alpha: 0.5),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                        BouncingButton(
                          onTap: () {
                            HapticEngine.selection();
                            state.nudgePatient(patient['uid']);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: L.fill.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.notifications_active_rounded,
                                size: 16, color: L.text),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    
                    // Adherence Progress Bar (Flat Cal Style)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: L.fill.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: 800.ms,
                                      curve: Curves.easeOutQuart,
                                      height: 4,
                                      width: constraints.maxWidth * adherence,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('${(adherence * 100).toInt()}%',
                            style: AppTypography.labelLarge.copyWith(
                                color: color,
                                fontWeight: FontWeight.w900,
                                fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class WeeklyAdherenceChart extends StatelessWidget {
  final List<Medicine> meds;
  final Map<String, List<DoseEntry>> history;
  final AppThemeColors L;
  const WeeklyAdherenceChart(
      {super.key, required this.meds, required this.history, required this.L});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> weekData = {};
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final dayLabel = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1];
      final doses = history[dateStr] ?? [];
      final sysExpected = meds
          .where((m) => m.schedule
              .any((s) => s.enabled && s.days.contains(date.weekday % 7)))
          .length;
      double score = sysExpected == 0 ? (doses.isNotEmpty ? 1.0 : 0.0) : (doses.where((d) => d.taken).length / sysExpected).clamp(0.0, 1.0);
      weekData['$i-$dayLabel'] = score;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Weekly Adherence',
                style: AppTypography.titleLarge.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: L.text)),
            const Spacer(),
            Text('Last 7 Days',
                style: AppTypography.labelSmall.copyWith(
                    color: L.sub.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                    letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: AppSpacing.p24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: weekData.entries.map((e) {
            final pct = e.value;
            final height = 15.0 + (pct * 55.0);
            final color = pct >= 0.85 
                ? const Color(0xFF10B981) 
                : pct >= 0.6 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);

            return Column(
              children: [
                AnimatedContainer(
                  duration: 600.ms,
                  width: 24,
                  height: height,
                  decoration: BoxDecoration(
                    color: pct == 0.0 ? L.fill : color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    boxShadow: [
                      if (pct > 0.0)
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.p12),
                Text(e.key.split('-')[1],
                    style: AppTypography.labelSmall.copyWith(
                        color: L.sub, fontWeight: FontWeight.w700, fontSize: 10)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ProtectorInsights extends StatelessWidget {
  final Caregiver cg;
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onBack;
  const ProtectorInsights(
      {super.key,
      required this.cg,
      required this.state,
      required this.L,
      required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isMe = cg.patientUid.isEmpty || cg.patientUid == AuthService.uid;
    if (!isMe && !(state.profile?.isPremium ?? false)) {
      return PaywallScreen(onBack: onBack, L: L);
    }
    if (isMe) {
      return InsightsContent(
        cg: cg,
        meds: state.activeMeds,
        history: state.history,
        streak: state.getStreak(),
        L: L,
        onBack: onBack,
        state: state,
      );
    }
    return StreamBuilder<List<Medicine>>(
      stream: state.getPatientMeds(cg.patientUid),
      builder: (context, medSnap) {
        final meds = medSnap.data ?? [];
        return StreamBuilder<Map<String, List<DoseEntry>>>(
          stream: state.getPatientHistory(cg.patientUid),
          builder: (context, historySnap) {
            final history = historySnap.data ?? {};
            return InsightsContent(
              cg: cg,
              meds: meds,
              history: history,
              streak: _calculateStreak(history, meds),
              L: L,
              onBack: onBack,
              state: state,
            );
          },
        );
      },
    );
  }
}

class PaywallScreen extends StatelessWidget {
  final VoidCallback onBack;
  final AppThemeColors L;
  const PaywallScreen({super.key, required this.onBack, required this.L});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: L.bg,
    appBar: AppBar(
      backgroundColor: L.bg, elevation: 0,
      leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: L.text), onPressed: onBack),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 80, height: 80, decoration: BoxDecoration(color: L.secondary.withValues(alpha: 0.1), shape: BoxShape.circle), child: Center(child: Icon(Icons.lock_person_rounded, color: L.secondary, size: 40))),
            const SizedBox(height: 24),
            Text('Pro Feature', style: AppTypography.displayLarge.copyWith(fontSize: 24, color: L.text, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text('Remote monitoring requires a Pro subscription.', textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(fontSize: 15, color: L.sub, height: 1.5)),
            const SizedBox(height: 32),
            BouncingButton(
              onTap: () => PaywallSheet.show(context),
              child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16), alignment: Alignment.center, decoration: BoxDecoration(color: L.primary, borderRadius: BorderRadius.circular(20)), child: Text('Upgrade to Pro', style: AppTypography.labelLarge.copyWith(color: L.onPrimary, fontSize: 15, fontWeight: FontWeight.w800))),
            ),
          ],
        ),
      ),
    ),
  );
}

class InsightsContent extends StatelessWidget {
  final Caregiver cg;
  final List<Medicine> meds;
  final Map<String, List<DoseEntry>> history;
  final int streak;
  final AppThemeColors L;
  final VoidCallback onBack;
  final AppState state;

  const InsightsContent({
    super.key,
    required this.cg,
    required this.meds,
    required this.history,
    required this.streak,
    required this.L,
    required this.onBack,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    state.fetchProtectorInsight(cg, meds, history);
    final dateKey = DateTime.now().toIso8601String().substring(0, 10);
    final historyEntries = history[dateKey] ?? [];
    
    return Scaffold(
      backgroundColor: L.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: L.bg,
            elevation: 0,
            pinned: true,
            leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: L.text, size: 18), onPressed: onBack),
            centerTitle: true,
            title: Text(cg.name, style: AppTypography.titleLarge.copyWith(fontSize: 18, fontWeight: FontWeight.w800, color: L.text)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Health Score Hero (Simplified for monitoring)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: L.card,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: L.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(color: L.fill, shape: BoxShape.circle),
                              child: Center(child: Text(cg.avatar, style: const TextStyle(fontSize: 30))),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(cg.name, style: AppTypography.headlineMedium.copyWith(fontSize: 22, fontWeight: FontWeight.w900, color: L.text)),
                              Text('${cg.relation} · Monitoring Active', style: AppTypography.bodySmall.copyWith(color: L.sub, fontWeight: FontWeight.w500)),
                            ])),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: _CompactStat(label: 'Adherence', value: meds.isEmpty ? '100%' : '${((historyEntries.where((e) => e.taken).length / (historyEntries.length.clamp(1, 1000))) * 100).toInt()}%', color: const Color(0xFF10B981), L: L)),
                            const SizedBox(width: 12),
                            Expanded(child: _CompactStat(label: 'Streak', value: '$streak days', color: const Color(0xFFF97316), L: L)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  BouncingButton(
                    onTap: () => state.nudgePatient(cg.patientUid),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: L.text, borderRadius: BorderRadius.circular(16)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Text('Nudge ${cg.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      ]),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: L.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: L.border)),
                    child: WeeklyAdherenceChart(meds: meds, history: history, L: L),
                  ),
                  
                  const SizedBox(height: 20),
                  AIProtectorCard(cg: cg, state: state),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final AppThemeColors L;
  const _CompactStat({required this.label, required this.value, required this.color, required this.L});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: L.fill.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTypography.labelSmall.copyWith(color: L.sub, fontWeight: FontWeight.w600, fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: AppTypography.titleLarge.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
    ]),
  );
}
