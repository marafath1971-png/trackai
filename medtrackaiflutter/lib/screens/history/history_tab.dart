import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../core/utils/date_formatter.dart';

// ══════════════════════════════════════════════
// HISTORY TAB
// ══════════════════════════════════════════════

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final L = context.L;

    final allDoses = state.history.values.expand((v) => v).toList();
    final taken = allDoses.where((d) => d.taken).length;
    final adh = allDoses.isEmpty ? 0 : (taken / allDoses.length * 100).round();
    final meds = state.meds;

    // Sort keys descending
    final sortedKeys = state.history.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(children: [
        // Background scrollable content
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                    top: 100 + MediaQuery.of(context).padding.top,
                    left: 20,
                    right: 20,
                    bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (allDoses.isNotEmpty) ...[
                      // Stats grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.4,
                        children: [
                          _HistStat(
                              emoji: '📊',
                              label: 'Adherence',
                              value: '$adh%',
                              color: adh >= 80 ? L.green : L.amber),
                          _HistStat(
                              emoji: '✅',
                              label: 'Doses taken',
                              value: '$taken',
                              color: L.blue),
                          _HistStat(
                              emoji: '💊',
                              label: 'Medicines',
                              value: '${meds.length}',
                              color: L.purple),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Weekly adherence card
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                            color: L.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.black.withValues(alpha: 0.05))),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Weekly Adherence',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: L.text)),
                              const SizedBox(height: 16),
                              _WeeklyBars(history: state.history, L: L),
                            ]),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
              if (sortedKeys.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildEmptyState(L),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, index) {
                      final dateKey = sortedKeys[index];
                      final entries = state.history[dateKey] ?? [];
                      return _DayLog(
                          dateKey: dateKey,
                          entries: entries,
                          state: state,
                          L: L);
                    },
                  ),
                ),
              const SizedBox(height: 120),
            ],
          ),
        ),

        // Fixed Glassmorphic Header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 54, 20, 16),
            decoration: BoxDecoration(
              color: L.bg.withValues(alpha: 0.95),
              border: Border(bottom: BorderSide(color: L.border, width: 0.5)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('History',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: L.text,
                      letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text('Your 14-day medicine log',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: L.sub,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      ]),
    );
  }


  Widget _buildEmptyState(AppThemeColors L) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration:
          BoxDecoration(color: L.card, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        const Text('📋', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 14),
        Text('No history yet',
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 17, color: L.text)),
        const SizedBox(height: 6),
        Text('Your dose history will appear here as you log medicines.',
            style: TextStyle(color: L.sub, fontSize: 14, height: 1.5)),
      ]),
    );
  }
}

class _HistStat extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _HistStat(
      {required this.emoji,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 3,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: L.sub,
                fontWeight: FontWeight.w600,
                height: 1.0)),
      ]),
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  final Map<String, List<DoseEntry>> history;
  final AppThemeColors L;
  const _WeeklyBars({required this.history, required this.L});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);
    // Show last 7 days from history or empty
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          final k = d.toIso8601String().substring(0, 10);
          final ds = history[k] ?? [];
          final rate =
              ds.isEmpty ? 0.0 : ds.where((e) => e.taken).length / ds.length;
          final isT = k == todayStr;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                        color: L.border,
                        borderRadius: BorderRadius.circular(8)),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: (isT ? 50 : (rate * 100))
                              .clamp(0, 100)
                              .toDouble(),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isT
                                ? const Color(0xFF93C5FD)
                                : rate >= 0.8
                                    ? L.green
                                    : rate > 0
                                        ? L.amber
                                        : L.border,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(['S', 'M', 'T', 'W', 'T', 'F', 'S'][d.weekday % 7],
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: isT ? FontWeight.w900 : FontWeight.w600,
                        color: isT ? L.blue : L.sub.withValues(alpha: 0.6))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DayLog extends StatelessWidget {
  final String dateKey;
  final List<DoseEntry> entries;
  final AppState state;
  final AppThemeColors L;
  const _DayLog(
      {required this.dateKey,
      required this.entries,
      required this.state,
      required this.L});

  String _fmtDate(String k) {
    try {
      final d = DateTime.parse(k);
      final now = DateTime.now();
      final today = now.toIso8601String().substring(0, 10);
      if (k == today) return 'Today';

      final weekday =
          ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][d.weekday % 7];
      final month = [
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
      ][d.month - 1];
      return '$weekday, $month ${d.day}';
    } catch (_) {
      return k;
    }
  }

  @override
  Widget build(BuildContext context) {
    final takenCount = entries.where((e) => e.taken).length;
    final isT = dateKey == todayStr();
    final rate = entries.isEmpty ? null : takenCount / entries.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_fmtDate(dateKey),
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isT ? L.blue : L.text)),
          if (rate != null)
            AppBadge(
                bg: rate >= 0.8
                    ? L.greenLight
                    : rate > 0
                        ? const Color(0xFFFEF3C7)
                        : L.redLight,
                textColor: rate >= 0.8 ? L.green : L.amber,
                text: '${(rate * 100).round()}%'),
        ]),
        const SizedBox(height: 8),
        if (isT && entries.isEmpty)
          Text('Log appears as you take doses today.',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: L.sub))
        else if (entries.isEmpty)
          Text('No doses logged',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: L.sub))
        else
          ...entries.asMap().entries.map((item) {
            final e = item.value;
            final med = state.meds.firstWhere((m) => m.id == e.medId,
                orElse: () => Medicine(
                    id: 0,
                    name: 'Unknown',
                    count: 0,
                    totalCount: 0,
                    color: '#666666',
                    courseStartDate: ''));

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: L.card,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1)),
                  // Inner shadow simulation via inset border or specialized decoration
                ],
                border: Border.all(color: L.border.withValues(alpha: 0.5)),
              ),
              child: Row(children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: e.taken ? L.green : L.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('${med.name} ${med.dose}',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: L.text)),
                      const SizedBox(height: 1),
                      Text(
                          '${e.label} · ${e.time} · ${e.taken ? "✓ Taken" : "✗ Missed"}',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: L.sub,
                              fontWeight: FontWeight.w500)),
                    ])),
                if (!e.taken)
                  const SizedBox()
                else
                  Text(e.time,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: L.sub.withValues(alpha: 0.5))),
              ]),
            );
          }),
      ]),
    );
  }
}
