import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../../core/utils/haptic_engine.dart';
import '../../core/utils/date_formatter.dart';
import '../common/refined_sheet_wrapper.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../common/premium_empty_state.dart';

class DailyLogSheet extends StatefulWidget {
  final DateTime date;
  const DailyLogSheet({super.key, required this.date});

  static void show(BuildContext context, {DateTime? date}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DailyLogSheet(date: date ?? DateTime.now()),
    );
  }

  @override
  State<DailyLogSheet> createState() => _DailyLogSheetState();
}

class _DailyLogSheetState extends State<DailyLogSheet> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date;
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final S = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();

    final isToday = _isSameDay(_selectedDate, DateTime.now());

    // Adjust doses based on selected date's day of week
    final weekday = (_selectedDate.weekday % 7);
    final dayKey =
        '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';
    final historicalDoseEntries = state.history[dayKey] ?? [];

    // Get scheduled doses for the current view
    final doses = state.meds
        .expand((m) => m.schedule
            .where((s) => s.enabled && s.days.contains(weekday))
            .map((s) => DoseItem(med: m, sched: s, key: '${m.id}-${s.label}')))
        .toList();

    // Combine scheduled doses with PRN doses from history
    final prnDoses = historicalDoseEntries
        .where((e) => e.label.startsWith('PRN-'))
        .map((e) {
          final med = state.meds.firstWhere((m) => m.id == e.medId,
              orElse: () => Medicine(
                  id: -1,
                  name: 'Unknown',
                  count: 0,
                  totalCount: 0,
                  courseStartDate: ''));
          return DoseItem(
            med: med,
            sched: ScheduleEntry(
                id: 'prn_${e.medId}_${e.time}',
                h: int.parse(e.time.split(':')[0]),
                m: int.parse(e.time.split(':')[1]),
                label: 'PRN',
                days: const []),
            key: 'PRN-${e.medId}-${e.time}',
          );
        })
        .where((d) => d.med.id != -1) // Filter out placeholders
        .toList();

    final allDosesToShow = [...doses, ...prnDoses];

    final todaySymptoms = state.symptoms.where((s) {
      return s.timestamp.year == _selectedDate.year &&
          s.timestamp.month == _selectedDate.month &&
          s.timestamp.day == _selectedDate.day;
    }).toList();

    final takenCount = isToday
        ? allDosesToShow
            .where((d) =>
                d.key.startsWith('PRN-') || (state.takenToday[d.key] == true))
            .length
        : historicalDoseEntries.where((e) => e.taken).length;

    final completion =
        allDosesToShow.isNotEmpty ? takenCount / allDosesToShow.length : 0.0;

    return RefinedSheetWrapper(
      title: S.dailyLogTitle,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: L.secondary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.history_rounded, color: L.secondary, size: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Navigator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  HapticEngine.light();
                  setState(() => _selectedDate =
                      _selectedDate.subtract(const Duration(days: 1)));
                },
                icon: Icon(Icons.chevron_left_rounded, color: L.sub),
              ),
              Column(
                children: [
                  Text(
                    isToday
                        ? 'TODAY'
                        : '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                    style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: L.text,
                        letterSpacing: 0.5),
                  ),
                  Text(_getWeekdayName(_selectedDate.weekday),
                      style: AppTypography.bodySmall
                          .copyWith(color: L.sub, fontSize: 11)),
                ],
              ),
              IconButton(
                onPressed: _selectedDate.isAfter(
                        DateTime.now().subtract(const Duration(hours: 1)))
                    ? null
                    : () {
                        HapticEngine.light();
                        setState(() => _selectedDate =
                            _selectedDate.add(const Duration(days: 1)));
                      },
                icon: Icon(Icons.chevron_right_rounded,
                    color: _selectedDate.isAfter(
                            DateTime.now().subtract(const Duration(hours: 1)))
                        ? L.border
                        : L.sub),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Completion Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: L.border),
              boxShadow: L.shadowSoft,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: completion,
                        strokeWidth: 7,
                        backgroundColor: L.border.withValues(alpha: 0.2),
                        color: completion == 1.0 ? L.success : L.text,
                        strokeCap: StrokeCap.round,
                      ),
                      Text(
                        '${(completion * 100).round()}%',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: L.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        completion == 1.0 ? 'Perfect Day! 🌟' : 'Daily Completion',
                        style: AppTypography.labelSmall.copyWith(
                          color: completion == 1.0 ? L.success : L.sub,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$takenCount of ${doses.length} doses recorded',
                        style: AppTypography.titleLarge.copyWith(
                          color: L.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // --- MEDICATIONS SECTION ---
          _SectionHeader(
              title: 'MEDICATIONS', count: allDosesToShow.length, L: L),
          if (allDosesToShow.isEmpty)
            const PremiumEmptyState(
              title: 'No doses scheduled',
              subtitle: 'Check back later or add a PRN dose to see logs here.',
              emoji: '📅',
            )
          else
            ...allDosesToShow.asMap().entries.map((entry) {
              final idx = entry.key;
              final d = entry.value;
              final isPrn = d.key.startsWith('PRN-');
              final taken = isToday
                  ? (isPrn || (state.takenToday[d.key] ?? false))
                  : historicalDoseEntries.any((e) =>
                      e.medId == d.med.id &&
                      e.taken &&
                      e.label == d.sched.label);
              return _DoseLogRow(
                dose: d,
                taken: taken,
                isPrn: isPrn,
                L: L,
                onUndo: isPrn
                    ? () {
                        HapticEngine.light();
                        state.undoPrnDose(d.med.id, d.key.split('-').last);
                      }
                    : null,
              )
                  .animate(delay: (idx * 50).ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0);
            }),

          const SizedBox(height: 32),

          // --- SYMPTOMS SECTION ---
          _SectionHeader(
              title: 'SYMPTOMS & LOGS', count: todaySymptoms.length, L: L),
          if (todaySymptoms.isEmpty)
            _EmptyState(message: 'No symptoms logged for this day.', L: L)
          else
            ...todaySymptoms.asMap().entries.map((entry) {
              final idx = entry.key;
              final s = entry.value;
              return _SymptomLogRow(
                symptom: s,
                L: L,
                onDelete: () => state.deleteSymptom(s.id),
              )
                  .animate(delay: (idx * 50).ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0);
            }),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getMonthName(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return months[month - 1];
  }

  String _getWeekdayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[weekday - 1];
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final AppThemeColors L;
  const _SectionHeader(
      {required this.title, required this.count, required this.L});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: L.sub,
                letterSpacing: 1.2,
              )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: L.fill,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('$count',
                style: AppTypography.labelSmall.copyWith(
                    fontSize: 10, fontWeight: FontWeight.w900, color: L.sub)),
          ),
        ],
      ),
    );
  }
}

class _DoseLogRow extends StatelessWidget {
  final DoseItem dose;
  final bool taken;
  final bool isPrn;
  final AppThemeColors L;
  final VoidCallback? onUndo;

  const _DoseLogRow({
    required this.dose,
    required this.taken,
    required this.L,
    this.isPrn = false,
    this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final isPrnBadge = isPrn;
    final accentColor = taken
        ? (isPrnBadge ? L.text : L.success)
        : L.sub.withValues(alpha: 0.4);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: taken
              ? (isPrnBadge
                  ? L.primary.withValues(alpha: 0.2)
                  : L.success.withValues(alpha: 0.2))
              : L.border.withValues(alpha: 0.5),
        ),
        boxShadow: L.shadowSoft,
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Icon(
                taken ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dose.med.name,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: L.text,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (isPrnBadge)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: L.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.max),
                          border: Border.all(color: L.primary.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          'PRN',
                          style: AppTypography.labelSmall.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${dose.med.dose} · ${isPrnBadge ? AppLocalizations.of(context)!.prnLabel : dose.sched.label}',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 12,
                    color: L.sub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isPrnBadge && onUndo != null)
            GestureDetector(
              onTap: onUndo,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: L.error.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline_rounded, size: 16, color: L.error),
              ),
            ),
          if (isPrnBadge && onUndo != null) const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: L.fill.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppRadius.max),
            ),
            child: Text(
              fmtTime(dose.sched.h, dose.sched.m, context),
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: L.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SymptomLogRow extends StatelessWidget {
  final Symptom symptom;
  final AppThemeColors L;
  final VoidCallback onDelete;

  const _SymptomLogRow(
      {required this.symptom, required this.L, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: L.bg,
        borderRadius: AppRadius.roundM,
        border: Border.all(color: L.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: L.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.sick_rounded, size: 16, color: L.error),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(symptom.name,
                    style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: L.text)),
                Row(
                  children: [
                    Text('Severity: ${symptom.severity}/10',
                        style: AppTypography.bodySmall
                            .copyWith(fontSize: 12, color: L.sub)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HapticEngine.selection();
              onDelete();
            },
            icon: Icon(Icons.delete_outline_rounded, size: 18, color: L.sub),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final AppThemeColors L;
  const _EmptyState({required this.message, required this.L});

  @override
  Widget build(BuildContext context) {
    return PremiumEmptyState(
      title: 'Empty',
      subtitle: message,
      emoji: '✨',
    );
  }
}
