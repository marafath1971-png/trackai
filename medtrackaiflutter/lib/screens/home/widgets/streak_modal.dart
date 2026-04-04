import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../services/share_service.dart';
import '../../../core/utils/haptic_engine.dart';

// ══════════════════════════════════════════════
// CONSISTENCY HUB (Cal AI Industrial Refined)
// ══════════════════════════════════════════════
import '../../../domain/entities/streak_data.dart';

class StreakModal extends StatelessWidget {
  final int streak;
  final Map<String, List<DoseEntry>> history;
  final StreakData streakData;
  final VoidCallback onClose;
  final VoidCallback onFreeze;

  const StreakModal(
      {super.key,
      required this.streak,
      required this.history,
      required this.streakData,
      required this.onClose,
      required this.onFreeze});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final size = MediaQuery.of(context).size;

    // Compute stats
    final allKeys = history.keys.toList()..sort();
    final totalDaysTracked = allKeys.length;
    final allEntries = history.values.expand((e) => e).toList();
    final totalTaken = allEntries.where((e) => e.taken).length;
    final totalDoses = allEntries.length;
    final overallAdh = totalDoses > 0 ? (totalTaken * 100 ~/ totalDoses) : 0;

    // Best streak
    int best = 0, cur = 0;
    String? prev;
    for (final k in allKeys) {
      final ds = history[k] ?? [];
      final rate = ds.isEmpty ? 0.0 : ds.where((x) => x.taken).length / ds.length;
      if (rate >= 0.8) {
        if (prev != null) {
          final diff = DateTime.parse(k).difference(DateTime.parse(prev)).inDays;
          cur = diff <= 1 ? cur + 1 : 1;
        } else {
          cur = 1;
        }
        if (cur > best) best = cur;
      } else {
        cur = 0;
      }
      prev = k;
    }

    final milestones = [
      {'d': 3, 'e': '🌱', 'l': '3 Days'},
      {'d': 7, 'e': '⚡', 'l': '1 Week'},
      {'d': 14, 'e': '🏅', 'l': '2 Weeks'},
      {'d': 30, 'e': '🏆', 'l': '1 Month'},
      {'d': 60, 'e': '💎', 'l': '2 Months'},
      {'d': 100, 'e': '👑', 'l': '100 Days'},
      {'d': 365, 'e': '🌟', 'l': '1 Year'},
    ];
    final nextM = milestones.firstWhere((m) => streak < (m['d'] as int), orElse: () => milestones.last);
    final prevM = milestones.reversed.firstWhere((m) => streak >= (m['d'] as int), orElse: () => {'d': 0});
    final nextDays = (nextM['d'] as int) - streak;
    final progressToNext = (nextM['d'] as int) > (prevM['d'] as int)
        ? (streak - (prevM['d'] as int)) / ((nextM['d'] as int) - (prevM['d'] as int))
        : 1.0;

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: size.width,
              constraints: BoxConstraints(maxHeight: size.height * 0.9, maxWidth: 430),
              decoration: BoxDecoration(
                  color: L.bg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border.all(color: L.border.withValues(alpha: 0.1), width: 1.0)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(height: 12),
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: L.border.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(99)))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('CONSISTENCY HUB',
                        style: AppTypography.headlineMedium.copyWith(
                            fontWeight: FontWeight.w900, fontSize: 22, color: L.text, letterSpacing: -0.5)),
                    IconButton(onPressed: onClose, icon: Icon(Icons.close_rounded, color: L.text, size: 24)),
                  ]),
                ),
                Flexible(
                  child: RawScrollbar(
                    thumbColor: L.text.withValues(alpha: 0.1),
                    radius: const Radius.circular(10),
                    thickness: 4,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Main Metric Card B&W Refined
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                              color: L.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: L.text.withValues(alpha: 0.1), width: 1.0),
                              boxShadow: L.shadowSoft),
                          child: Row(children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('$streak',
                                  style: AppTypography.displayLarge.copyWith(
                                      fontWeight: FontWeight.w900, color: L.text, letterSpacing: -3, height: 1.0)),
                              const SizedBox(height: 4),
                              Text('ADHERENCE CHAIN',
                                  style: AppTypography.labelSmall.copyWith(
                                      fontWeight: FontWeight.w900, color: L.sub, letterSpacing: 1.0, fontSize: 10)),
                            ]),
                            const Spacer(),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              _MiniStat(label: 'PEAK', val: '$best'),
                              const SizedBox(height: 12),
                              _MiniStat(label: 'ACCURACY', val: '$overallAdh%'),
                            ]),
                          ]),
                        ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 16),
                        
                        // B&W Stats Grid
                        Row(children: [
                          Expanded(child: _StatBox(label: 'Tracked', val: '$totalDaysTracked', icon: Icons.calendar_today_rounded, L: L)),
                          const SizedBox(width: 12),
                          Expanded(child: _StatBox(label: 'Taken', val: '$totalTaken', icon: Icons.done_all_rounded, L: L)),
                          const SizedBox(width: 12),
                          Expanded(child: _StatBox(label: 'Logged', val: '$totalDoses', icon: Icons.analytics_rounded, L: L)),
                        ]),
                        
                        const SizedBox(height: 24),
                        
                        // Progress
                        if (streak < (milestones.last['d'] as int))
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: L.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: L.border.withValues(alpha: 0.5))),
                            child: Column(children: [
                              Row(children: [
                                Text(nextM['e'] as String, style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 12),
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(nextM['l'] as String,
                                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900, color: L.text, fontSize: 14)),
                                  Text('$nextDays days remaining',
                                      style: AppTypography.labelSmall.copyWith(color: L.sub, fontWeight: FontWeight.w700, fontSize: 11)),
                                ]),
                                const Spacer(),
                                Text('$streak/${nextM['d']}',
                                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900, fontSize: 11, color: L.primary)),
                              ]),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                    value: progressToNext.clamp(0.0, 1.0), minHeight: 4, backgroundColor: L.fill, color: L.primary),
                              ),
                            ]),
                          ),
                        
                        const SizedBox(height: 24),
                        Text('30-DAY STABILITY MATRIX',
                            style: AppTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 10, color: L.sub)),
                        const SizedBox(height: 14),
                        _Heatmap(history: history, L: L),
                        const SizedBox(height: 32),
                        
                        // Ascension Steps
                        Text('MILESTONES / ASCENSION',
                            style: AppTypography.labelSmall.copyWith(
                                fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: L.sub)),
                        const SizedBox(height: 12),
                        ...milestones.map((m) {
                          final n = m['d'] as int;
                          final achieved = streak >= n;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                                color: achieved ? L.primary.withValues(alpha: 0.05) : L.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: achieved ? L.primary.withValues(alpha: 0.2) : L.border.withValues(alpha: 0.5))),
                            child: Row(children: [
                              Opacity(opacity: achieved ? 1.0 : 0.4, child: Text(m['e'] as String, style: const TextStyle(fontSize: 20))),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(m['l'] as String,
                                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900, fontSize: 14, color: L.text)),
                                Text(achieved ? 'STABILITY UNLOCKED' : '${n - streak} days remaining',
                                    style: AppTypography.bodySmall.copyWith(
                                        fontWeight: FontWeight.w700, fontSize: 11, color: achieved ? L.primary : L.sub)),
                              ])),
                              if (achieved) Icon(Icons.check_circle_rounded, color: L.primary, size: 20),
                            ]),
                          );
                        }),
                        
                        const SizedBox(height: 32),
                        
                        // High Contrast Share
                        GestureDetector(
                          onTap: () {
                            HapticEngine.selection();
                            ShareService.shareStreak(streak);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(color: L.text, borderRadius: BorderRadius.circular(12)),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.share_rounded, color: L.bg, size: 18),
                              const SizedBox(width: 10),
                              Text('EXPORT DATA',
                                  style: AppTypography.displaySmall.copyWith(
                                      color: L.bg, letterSpacing: 1.2, fontSize: 13, fontWeight: FontWeight.w900)),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, val;
  const _MiniStat({required this.label, required this.val});
  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(val,
          style: AppTypography.titleLarge
              .copyWith(fontWeight: FontWeight.w900, color: L.text, fontSize: 18, letterSpacing: -0.5)),
      Text(label,
          style: AppTypography.labelSmall
              .copyWith(fontWeight: FontWeight.w900, color: L.sub, fontSize: 9, letterSpacing: 1.0)),
    ]);
  }
}

class _StatBox extends StatelessWidget {
  final String label, val;
  final IconData icon;
  final AppThemeColors L;
  const _StatBox({required this.label, required this.val, required this.icon, required this.L});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: L.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: L.border.withValues(alpha: 0.5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: L.sub),
        const SizedBox(height: 12),
        Text(val,
            style: AppTypography.titleLarge
                .copyWith(fontWeight: FontWeight.w900, color: L.text, fontSize: 20, letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label.toUpperCase(),
            style: AppTypography.labelSmall
                .copyWith(color: L.sub, fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 1.0)),
      ]),
    );
  }
}

class _Heatmap extends StatelessWidget {
  final Map<String, List<DoseEntry>> history;
  final AppThemeColors L;
  const _Heatmap({required this.history, required this.L});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: 6, mainAxisSpacing: 6),
      itemCount: 28,
      itemBuilder: (c, i) {
        final d = today.subtract(Duration(days: 27 - i));
        final k = d.toIso8601String().substring(0, 10);
        final ds = history[k] ?? [];
        final rate = ds.isEmpty ? -1.0 : ds.where((e) => e.taken).length / ds.length;
        
        Color bg;
        if (rate < 0) bg = L.fill.withValues(alpha: 0.3);
        else if (rate >= 0.8) bg = L.primary;
        else if (rate > 0) bg = L.primary.withValues(alpha: 0.4);
        else bg = L.error.withValues(alpha: 0.2);

        return Container(
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Text('${d.day}',
                style: AppTypography.labelSmall.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: rate >= 0.8 ? Colors.white : L.text.withValues(alpha: 0.5))),
          ),
        );
      },
    );
  }
}
