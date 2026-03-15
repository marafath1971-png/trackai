 import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';

// ══════════════════════════════════════════════
// STREAK MODAL (bottom sheet)
// ══════════════════════════════════════════════

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
    const ff = 'Inter';

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
      final rate =
          ds.isEmpty ? 0.0 : ds.where((x) => x.taken).length / ds.length;
      if (rate >= 0.8) {
        if (prev != null) {
          final diff =
              DateTime.parse(k).difference(DateTime.parse(prev)).inDays;
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
    final nextM = milestones.firstWhere((m) => streak < (m['d'] as int),
        orElse: () => milestones.last);
    final prevM = milestones.reversed
        .firstWhere((m) => streak >= (m['d'] as int), orElse: () => {'d': 0});
    final nextDays = (nextM['d'] as int) - streak;
    final progressToNext = (nextM['d'] as int) > (prevM['d'] as int)
        ? (streak - (prevM['d'] as int)) /
            ((nextM['d'] as int) - (prevM['d'] as int))
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
              constraints:
                  BoxConstraints(maxHeight: size.height * 0.9, maxWidth: 430),
              decoration: BoxDecoration(
                  color: L.bg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border.all(color: L.border, width: 1.5)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(height: 12),
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: L.border,
                            borderRadius: BorderRadius.circular(99)))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Streak 🔥',
                            style: TextStyle(
                                fontFamily: ff,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: L.text,
                                letterSpacing: -0.8)),
                        GestureDetector(
                          onTap: onClose,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: L.fill, shape: BoxShape.circle),
                            child: Center(
                                child: Icon(Icons.close_rounded,
                                    color: L.sub, size: 22)),
                          ),
                        ),
                      ]),
                ),
                Flexible(
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Big streak number card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                              color: const Color(0xFF111111),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: L.green.withValues(alpha: 0.2),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                  spreadRadius: -10,
                                ),
                              ]),
                          child: Row(children: [
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$streak',
                                      style: const TextStyle(
                                          fontFamily: ff,
                                          fontSize: 64,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -3,
                                          height: 1.0)),
                                  const SizedBox(height: 4),
                                  Text('day${streak != 1 ? "s" : ""} in a row',
                                      style: TextStyle(
                                          fontFamily: ff,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white
                                              .withValues(alpha: 0.55))),
                                ]),
                            const Spacer(),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _MiniStat(label: 'BEST', val: '$best'),
                                  const SizedBox(height: 12),
                                  _MiniStat(
                                      label: 'ADHERENCE', val: '$overallAdh%'),
                                ]),
                          ]),
                        ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0).scale(begin: const Offset(0.95, 0.95)),
                        const SizedBox(height: 16),
                        // Stats grid
                        Row(children: [
                          Expanded(
                              child: _StatBox(
                                  label: 'Days Tracked',
                                  val: '$totalDaysTracked',
                                  emoji: '📅',
                                  L: L).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _StatBox(
                                  label: 'Doses Taken',
                                  val: '$totalTaken',
                                  emoji: '✅',
                                  L: L).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _StatBox(
                                  label: 'Total Logged',
                                  val: '$totalDoses',
                                  emoji: '💊',
                                  L: L).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0)),
                        ]),
                        const SizedBox(height: 16),
                        // Milestone progress
                        if (streak < (milestones.last['d'] as int))
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: L.fill,
                                borderRadius: BorderRadius.circular(24)),
                            child: Column(children: [
                              Row(children: [
                                Text(nextM['e'] as String,
                                    style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 12),
                                Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(nextM['l'] as String,
                                          style: TextStyle(
                                              fontFamily: ff,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: L.text)),
                                      Text(
                                          '$nextDays day${nextDays != 1 ? "s" : ""} to go',
                                          style: TextStyle(
                                              fontFamily: ff,
                                              fontSize: 11,
                                              color: L.sub)),
                                    ]),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: L.greenLight,
                                      borderRadius: BorderRadius.circular(99)),
                                  child: Text('$streak/${nextM['d']}',
                                      style: TextStyle(
                                          fontFamily: ff,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: L.green)),
                                ),
                              ]),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                    value: progressToNext.clamp(0.0, 1.0),
                                    minHeight: 6,
                                    backgroundColor: L.border,
                                    color: L.green),
                              ),
                            ]),
                          ),
                        const SizedBox(height: 24),
                        Text('LAST 30 DAYS',
                            style: TextStyle(
                                fontFamily: ff,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: L.sub)),
                        const SizedBox(height: 10),
                        _Heatmap(history: history, L: L),
                        const SizedBox(height: 24),
                        // Streak Freeze section
                        if (!streakData.freezeUsedWeek && streak > 0)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: L.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                                border:
                                    Border.all(color: L.green.withValues(alpha: 0.3))),
                            child: Row(children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    color: L.green,
                                    borderRadius: BorderRadius.circular(16)),
                                child: const Center(
                                    child: Text('🧊',
                                        style: TextStyle(fontSize: 20))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    const Text('Streak Freeze Available',
                                        style: TextStyle(
                                            fontFamily: ff,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: Color(0xFF111111))),
                                    Text('Protect your streak for 1 missed day',
                                        style: TextStyle(
                                            fontFamily: ff,
                                            fontSize: 12,
                                            color: const Color(0xFF111111)
                                                .withValues(alpha: 0.8))),
                                  ])),
                              GestureDetector(
                                onTap: onFreeze,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF111111),
                                       borderRadius: BorderRadius.circular(24)),
                                  child: const Text('Use Freeze',
                                      style: TextStyle(
                                          fontFamily: ff,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          color: Colors.white)),
                                ),
                              ),
                            ]),
                          )
                        else if (streakData.freezeUsedWeek)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                                color: L.fill,
                                borderRadius: BorderRadius.circular(24)),
                            child: Row(children: [
                              const Text('🧊', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Text('Freeze used this week · Resets next Monday',
                                  style: TextStyle(
                                      fontFamily: ff,
                                      fontSize: 13,
                                      color: L.sub,
                                      fontWeight: FontWeight.w500)),
                            ]),
                          ),
                        const SizedBox(height: 24),
                        // Milestones List
                        Text('MILESTONES',
                            style: TextStyle(
                                fontFamily: ff,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: L.sub)),
                        const SizedBox(height: 10),
                        ...milestones.map((m) {
                          final n = m['d'] as int;
                          final achieved = streak >= n;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                                color:
                                    achieved ? L.green.withValues(alpha: 0.15) : L.fill,
                                borderRadius: BorderRadius.circular(24),
                                border: achieved 
                                  ? null 
                                  : Border.all(color: L.border.withValues(alpha: 0.5))),
                            child: Row(children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: achieved ? Colors.white.withValues(alpha: 0.1) : L.bg,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(m['e'] as String,
                                      style: TextStyle(
                                          fontSize: 22,
                                          color: achieved
                                              ? null
                                              : L.sub.withValues(alpha: 0.3))),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(m['l'] as String,
                                        style: TextStyle(
                                            fontFamily: ff,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: achieved
                                                ? L.text
                                                : L.text)),
                                    const SizedBox(height: 2),
                                    Text(
                                        achieved
                                            ? 'Unleashed ✓'
                                            : '${n - streak} days remaining',
                                        style: TextStyle(
                                            fontFamily: ff,
                                            fontSize: 12,
                                            color: achieved
                                                ? Colors.white
                                                    .withValues(alpha: 0.6)
                                                : L.sub)),
                                  ])),
                              if (achieved)
                                Icon(Icons.check_circle_rounded,
                                    color: L.green, size: 20),
                            ]),
                          ).animate().fade(delay: (400 + milestones.indexOf(m) * 50).ms).slideX(begin: 0.1, end: 0);
                        }),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(val,
          style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5)),
      Text(label,
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.45),
              letterSpacing: 0.6)),
    ]);
  }
}

class _StatBox extends StatelessWidget {
  final String label, val, emoji;
  final AppThemeColors L;
  const _StatBox(
      {required this.label,
      required this.val,
      required this.emoji,
      required this.L});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration:
          BoxDecoration(color: L.fill, borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(val,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: L.text,
                letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: L.sub,
                fontWeight: FontWeight.w600)),
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
    final todayKey = today.toIso8601String().substring(0, 10);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10, crossAxisSpacing: 4, mainAxisSpacing: 4),
      itemCount: 30,
      itemBuilder: (c, i) {
        final d = today.subtract(Duration(days: 29 - i));
        final k = d.toIso8601String().substring(0, 10);
        final ds = history[k] ?? [];
        final rate =
            ds.isEmpty ? -1.0 : ds.where((e) => e.taken).length / ds.length;
        final isT = k == todayKey;

        Color bg;
        if (isT) {
          bg = const Color(0xFF111111);
        } else if (rate < 0) {
          bg = L.fill;
        } else if (rate >= 0.8) {
          bg = L.green;
        } else if (rate > 0) {
          bg = L.amber;
        } else {
          bg = const Color(0xFFFCA5A5); // Red for missed
        }

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: isT
                ? Border.all(color: const Color(0xFF111111), width: 2)
                : null,
          ),
          child: Center(
            child: Text('${d.day}',
                style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: (isT || rate > 0) ? Colors.white : L.sub)),
          ),
        );
      },
    );
  }
}
