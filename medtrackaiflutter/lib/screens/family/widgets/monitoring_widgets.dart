import 'package:flutter/material.dart';
import '../../../providers/app_state.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../services/auth_service.dart';
import './caregiver_widgets.dart';
import '../../../widgets/common/unified_header.dart';
import '../../../core/utils/haptic_engine.dart';

class PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onTap;
  const PatientCard({super.key, required this.patient, required this.state, required this.L, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Medicine>>(
      stream: state.getPatientMeds(patient['uid']),
      builder: (context, medSnap) {
        return StreamBuilder<Map<String, List<DoseEntry>>>(
          stream: state.getPatientHistory(patient['uid']),
          builder: (context, historySnap) {
            final history = historySnap.data ?? {};
            
            // Calculate today's adherence for this patient
            final dateKey = DateTime.now().toIso8601String().substring(0, 10);
            final entries = history[dateKey] ?? [];
            final taken = entries.where((e) => e.taken).length;
            final total = entries.length;
            final adherence = total == 0 ? 1.0 : (taken / total);

            return GestureDetector(
              onTap: () {
                HapticEngine.light();
                onTap();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.m),
                decoration: BoxDecoration(
                  color: L.card,
                  borderRadius: AppRadius.roundL,
                  border: Border.all(color: L.border),
                  boxShadow: L.shadowSoft,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.l),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: L.fill,
                              borderRadius: BorderRadius.circular(AppRadius.m),
                              border: Border.all(color: L.border),
                            ),
                            child: Center(
                              child: Text(patient['avatar'] ?? '👤', style: const TextStyle(fontSize: 28)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(patient['name'] ?? 'Unknown',
                                    style: AppTypography.titleLarge.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: L.text)),
                                const SizedBox(height: 4),
                                Text(
                                  '$total doses scheduled · $taken taken',
                                  style: AppTypography.bodySmall.copyWith(
                                      fontSize: 12,
                                      color: L.sub,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${(adherence * 100).toInt()}%',
                                  style: AppTypography.displayLarge.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: adherence >= 0.8 ? L.secondary : L.warning)),
                              Text('TODAY',
                                  style: AppTypography.labelLarge.copyWith(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: L.sub,
                                      letterSpacing: 0.5)),
                                ],
                              ),
                              const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              state.nudgePatient(patient['uid']);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: L.fill,
                                shape: BoxShape.circle,
                                border: Border.all(color: L.border.withValues(alpha: 0.1)),
                              ),
                              child: Icon(Icons.notifications_active_outlined, size: 20, color: L.sub),
                            ),
                          ),
                        ],
                      ),
                    ),
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
  const WeeklyAdherenceChart({super.key, required this.meds, required this.history, required this.L});

  @override
  Widget build(BuildContext context) {
    // Generate last 7 days data
    final Map<String, double> weekData = {};
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final dayLabel =
          ['Mn', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'][date.weekday - 1];

      final doses = history[dateStr] ?? [];
      final sysExpected = meds
          .where((m) => m.schedule
              .any((s) => s.enabled && s.days.contains(date.weekday % 7)))
          .length;

      double score = 0.0;
      if (sysExpected > 0) {
        final taken = doses.where((d) => d.taken).length;
        score = (taken / sysExpected).clamp(0.0, 1.0);
      } else if (doses.isNotEmpty) {
        score = 1.0;
      }
      weekData[dayLabel] = score;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
          color: L.card,
          borderRadius: AppRadius.roundL,
          border: Border.all(color: L.border),
          boxShadow: L.shadowSoft),
      child: Column(
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
              Icon(Icons.bar_chart_rounded, color: L.sub, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekData.entries.map((e) {
                final pct = e.value;
                final height = 10.0 + (pct * 60.0);
                final color = pct >= 0.8
                    ? L.secondary
                    : pct > 0.0
                        ? L.warning
                        : L.bg;
            
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: height,
                        decoration: BoxDecoration(
                          color: pct == 0.0 ? L.border : color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(e.key,
                          style: AppTypography.labelLarge.copyWith(
                              fontSize: 11,
                              color: L.sub,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
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
              streak: 0, // Streak calculation for patient needs history traversal
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
    // Dose calculation logic
    final doses = <DoseItem>[];
    for (final med in meds) {
      for (final s in med.schedule) {
        doses.add(DoseItem(
          med: med,
          sched: s,
          key: '${med.id}-${s.label}',
        ));
      }
    }
    
    final dateKey = DateTime.now().toIso8601String().substring(0, 10);
    final historyEntries = history[dateKey] ?? [];
    
    // Status helper
    String getStatusText(DoseItem d) {
       final match = historyEntries.where((e) => e.medId == d.med.id && e.label == d.sched.label).firstOrNull;
       if (match != null && match.taken) return 'Taken ✓';
       // simplified logic for protector mode
       return 'Upcoming';
    }

    return Scaffold(
      backgroundColor: L.bg,
      appBar: UnifiedHeader(
        leading: HeaderActionBtn(
          onTap: onBack,
          child: Icon(Icons.arrow_back_ios_new_rounded, color: L.sub, size: 18),
        ),
        title: 'Protector Insights',
        subtitle: 'Monitoring ${cg.name}\'s adherence',
        backgroundColor: Colors.transparent,
        blurred: false,
        showBorder: false,
      ),
      body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, AppSpacing.screenPadding),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                          color: L.card,
                          borderRadius: BorderRadius.circular(AppRadius.l),
                          border: Border.all(color: L.border, width: 1.0)),
                      child: Row(children: [
                        Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                                color: L.fill,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: L.border.withValues(alpha: 0.1))),
                            child: Center(
                                child: Text(cg.avatar,
                                    style: const TextStyle(fontSize: 34)))),
                        const SizedBox(width: 18),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(cg.name,
                                  style: AppTypography.titleLarge.copyWith(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: L.text,
                                      letterSpacing: -0.5)),
                              Text(
                                  '${cg.relation} Connected · Since ${cg.addedAt}',
                                  style: AppTypography.bodySmall.copyWith(
                                      fontSize: 13,
                                      color: L.sub,
                                      fontWeight: FontWeight.w500)),
                            ])),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    CardBtn(
                      label: 'Nudge ${cg.name}',
                      icon: Icons.notifications_active_rounded,
                      onTap: () => state.nudgePatient(cg.patientUid),
                      bg: L.text.withValues(alpha: 0.05),
                      textColor: L.text,
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                          child: FamStatJSX(
                              emoji: '📈',
                              label: 'Adherence',
                              value: (meds.isEmpty ? 100 : (historyEntries.where((e) => e.taken).length / historyEntries.length.clamp(1, 1000)) * 100).toInt(),
                              color: L.green)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: FamStatJSX(
                              emoji: '🔥',
                              label: 'Streak',
                              value: streak,
                              color: const Color(0xFFF97316))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: FamStatJSX(
                              emoji: '💊',
                              label: 'Active Meds',
                              value: meds.length,
                              color: L.text)),
                    ]),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: L.card,
                        borderRadius: BorderRadius.circular(AppRadius.l),
                        border: Border.all(color: L.border, width: 1.0),
                      ),
                      child: WeeklyAdherenceChart(meds: meds, history: history, L: L),
                    ),
                    const SizedBox(height: 24),

                    const SizedBox(height: 32),
                    Text('REAL-TIME STATUS',
                        style: AppTypography.labelLarge.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: L.sub,
                            letterSpacing: 1.0)),
                    const SizedBox(height: 12),
                    ...doses.map((d) {
                      final statusLabel = getStatusText(d);
                      final isTaken = statusLabel.contains('✓');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: L.card,
                          borderRadius: AppRadius.roundL,
                          border: Border.all(color: L.border),
                          boxShadow: L.shadowSoft,
                        ),
                        child: Row(children: [
                          Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                  color: (isTaken
                                          ? L.secondary
                                          : L.sub)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.m)),
                              child: Center(
                                  child: Text(
                                      isTaken
                                          ? '✅'
                                          : '⏳',
                                      style: const TextStyle(fontSize: 18)))),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(d.med.name,
                                    style: AppTypography.titleLarge.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: L.text)),
                                Text(
                                    '${fmtTime(d.sched.h, d.sched.m, context)} · ${d.sched.label}',
                                    style: AppTypography.bodySmall.copyWith(
                                        fontSize: 12,
                                        color: L.sub,
                                        fontWeight: FontWeight.w500)),
                              ])),
                          Text(statusLabel,
                              style: AppTypography.labelLarge.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isTaken ? L.secondary : L.sub))
                        ]),
                      );
                    }),
                    const SizedBox(height: 40),
                  ]))),
    );
  }
}
