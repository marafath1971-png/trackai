import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../providers/app_state.dart';
import '../../../../theme/app_theme.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../core/utils/refill_helper.dart';
import 'settings_shared.dart';
import '../../../../widgets/common/bouncing_button.dart';

class StatsTab extends StatelessWidget {
  final AppState state;
  final AppThemeColors L;

  const StatsTab({
    super.key,
    required this.state,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    // Select only what we need for bulk calculations if necessary,
    // but better to use cached getters if we added them.
    // We already have getStreak() and getAdherenceScore().

    final overallAdh =
        (context.select<AppState, double>((s) => s.getAdherenceScore()) * 100)
            .round();
    final streak = context.select<AppState, int>((s) => s.getStreak());

    // For the rest, we still need some history data.
    // Let's select the history keys to react to history changes.
    final historyKeys =
        context.select<AppState, List<String>>((s) => s.history.keys.toList());
    final daysTracked = historyKeys.length;

    // We still need the full history for the complex week and total counts.
    // To be truly granular, we should probably add getters to AppState for these too.
    // For now, let's select the whole history but at least we're using select.
    final history = context
        .select<AppState, Map<String, List<DoseEntry>>>((s) => s.history);

    final allEntries = history.values.expand((e) => e).toList();
    final taken = allEntries.where((e) => e.taken).length;
    final total = allEntries.length;

    // Last 7-day adherence
    final today = DateTime.now();
    final last7Keys = List.generate(
        7,
        (i) => today
            .subtract(Duration(days: i))
            .toIso8601String()
            .substring(0, 10));
    final last7Entries = last7Keys.expand((k) => history[k] ?? []).toList();
    final last7Adh = last7Entries.isNotEmpty
        ? (last7Entries.where((e) => e.taken).length *
            100 ~/
            last7Entries.length)
        : 0;

    final weekData = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      final k = d.toIso8601String().substring(0, 10);
      final ds = history[k] ?? [];
      final rate =
          ds.isEmpty ? 0.0 : ds.where((x) => x.taken).length / ds.length;
      return {
        'day': ['S', 'M', 'T', 'W', 'T', 'F', 'S'][d.weekday % 7],
        'rate': rate
      };
    });

    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      child: Column(children: [
        // Adherence Hero
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(24)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('OVERALL ADHERENCE',
                style: AppTypography.labelLarge.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.45),
                    letterSpacing: 0.8)),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$overallAdh%',
                  style: AppTypography.displayLarge.copyWith(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -3,
                      height: 1.0)),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                    overallAdh >= 80
                        ? 'EXCELLENT'
                        : (overallAdh >= 60 ? 'STABLE' : 'KEEP GOING'),
                    style: AppTypography.labelLarge.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: overallAdh >= 80
                            ? const Color(0xFF34C759)
                            : (overallAdh >= 60
                                ? const Color(0xFFFF9500)
                                : const Color(0xFFFF453A)))),
              ),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                  value: overallAdh / 100.0,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  color: overallAdh >= 80
                      ? const Color(0xFF34C759)
                      : (overallAdh >= 60
                          ? const Color(0xFFFF9500)
                          : const Color(0xFFFF453A))),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.4,
          children: [
            SettingsStatCard(
                    label: 'Doses Taken',
                    val: '$taken',
                    sub: 'of $total total',
                    emoji: '✅',
                    L: L)
                .animate()
                .fade(delay: 100.ms)
                .slideY(begin: 0.2, end: 0),
            SettingsStatCard(
                    label: '7-Day Rate',
                    val: '$last7Adh%',
                    sub: 'Last 7 days',
                    emoji: '📈',
                    L: L)
                .animate()
                .fade(delay: 200.ms)
                .slideY(begin: 0.2, end: 0),
            SettingsStatCard(
                    label: 'Current Streak',
                    val: '${streak}d',
                    sub: 'days in a row',
                    emoji: '🔥',
                    L: L)
                .animate()
                .fade(delay: 300.ms)
                .slideY(begin: 0.2, end: 0),
            SettingsStatCard(
                    label: 'Days Tracked',
                    val: '$daysTracked',
                    sub: 'days of data',
                    emoji: '📅',
                    L: L)
                .animate()
                .fade(delay: 400.ms)
                .slideY(begin: 0.2, end: 0),
          ],
        ),
        const SizedBox(height: 16),

        // Weekly Bar Chart
        SettingsSection(
            title: 'This Week',
            child: Container(
              padding: const EdgeInsets.all(16),
              color: L.card,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: weekData.map((w) {
                  final rate = w['rate'] as double;
                  return Expanded(
                    child: Column(children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: (rate * 60).clamp(8, 60),
                        decoration: BoxDecoration(
                            color: rate >= 0.8
                                ? const Color(0xFF111111)
                                : (rate > 0 ? const Color(0xFFFF9500) : L.fill),
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      const SizedBox(height: 6),
                      Text(w['day'] as String,
                          style: AppTypography.labelLarge.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: L.sub)),
                    ]),
                  );
                }).toList(),
              ),
            )),
        const SizedBox(height: 16),

        // Symptom Trends (Phase 13: Live Integration)
        SettingsSection(
            title: 'Health Story',
            child: state.symptoms.isEmpty
                ? Container(
                    height: 100,
                    width: double.infinity,
                    color: L.card,
                    child: Center(
                      child: Text('No symptoms recorded',
                          style: AppTypography.labelMedium.copyWith(color: L.sub)),
                    ),
                  )
                : Column(
                    children: state.symptoms.reversed.take(5).map((s) {
                      final isHigh = s.severity >= 7;
                      final isLow = s.severity <= 3;
                      final color =
                          isHigh ? L.red : (isLow ? L.success : L.warning);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: L.card,
                          border: Border(
                              bottom: BorderSide(
                                  color: L.border.withValues(alpha: 0.5),
                                  width: 1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  shape: BoxShape.circle),
                              child: Center(
                                child: Text('${s.severity}',
                                    style: AppTypography.labelSmall.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: color)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name,
                                        style: AppTypography.labelLarge
                                            .copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: L.text)),
                                    if (s.notes != null &&
                                        s.notes!.isNotEmpty)
                                      Text(s.notes!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.labelSmall
                                              .copyWith(color: L.sub)),
                                  ]),
                            ),
                            const SizedBox(width: 8),
                            Text(s.timestamp.toIso8601String().substring(5, 10),
                                style: AppTypography.labelSmall
                                    .copyWith(color: L.sub, fontSize: 10)),
                          ],
                        ),
                      );
                    }).toList(),
                  )),
        const SizedBox(height: 16),

        // Inventory Forecast (Phase 14: Stock Integration)
        SettingsSection(
            title: 'Inventory Forecast',
            child: state.meds.isEmpty
                ? Container(
                    height: 100,
                    width: double.infinity,
                    color: L.card,
                    child: Center(
                      child: Text('No medications tracked',
                          style: AppTypography.labelMedium.copyWith(color: L.sub)),
                    ),
                  )
                : Column(
                    children: state.getRefillForecast().take(3).map((m) {
                      final isLow = RefillHelper.isCriticallyLow(m);
                      final status = RefillHelper.getExhaustionStatus(m);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: L.card,
                          border: Border(
                              bottom: BorderSide(
                                  color: L.border.withValues(alpha: 0.5),
                                  width: 1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                  color: isLow
                                      ? L.red.withValues(alpha: 0.1)
                                      : L.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Center(
                                child: Icon(
                                  isLow
                                      ? Icons.warning_rounded
                                      : Icons.check_circle_outline_rounded,
                                  size: 16,
                                  color: isLow ? L.red : L.success,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.name,
                                        style: AppTypography.labelLarge
                                            .copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: L.text)),
                                    Text(status,
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                                color: isLow ? L.red : L.sub,
                                                fontWeight: isLow
                                                    ? FontWeight.w700
                                                    : FontWeight.w500)),
                                  ]),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text('${m.count}',
                                            style: AppTypography.labelLarge
                                                .copyWith(
                                                    fontWeight: FontWeight.w900,
                                                    color: L.text)),
                                        Text('left',
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                                    color: L.sub, fontSize: 9)),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    BouncingButton(
                                      onTap: () =>
                                          state.refillMedication(m.id),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color:
                                              L.text.withValues(alpha: 0.05),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: L.text
                                                  .withValues(alpha: 0.1)),
                                        ),
                                        child: Text(
                                          'REFILL',
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                            color: L.text,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 9,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )),
        const SizedBox(height: 120),
      ]),
    );
  }
}
