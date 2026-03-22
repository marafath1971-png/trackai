import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../../core/utils/haptic_engine.dart';
import '../../core/utils/date_formatter.dart';
import '../common/refined_sheet_wrapper.dart';

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
    final state = context.watch<AppState>();
    
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    
    // Adjust doses based on selected date's day of week
    final weekday = (_selectedDate.weekday % 7);
    final doses = state.meds.expand((m) => m.schedule
        .where((s) => s.enabled && s.days.contains(weekday))
        .map((s) => DoseItem(med: m, sched: s, key: '${m.id}-${s.label}'))
    ).toList();
    
    final dayKey = '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';
    final historicalDoseEntries = state.history[dayKey] ?? [];
    
    final todaySymptoms = state.symptoms.where((s) {
      return s.timestamp.year == _selectedDate.year &&
             s.timestamp.month == _selectedDate.month &&
             s.timestamp.day == _selectedDate.day;
    }).toList();

    final takenCount = isToday 
        ? doses.where((d) => state.takenToday[d.key] == true).length
        : historicalDoseEntries.where((e) => e.taken).length;
        
    final completion = doses.isNotEmpty ? takenCount / doses.length : 0.0;

    return RefinedSheetWrapper(
      title: 'Daily Log',
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
                  setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
                },
                icon: Icon(Icons.chevron_left_rounded, color: L.sub),
              ),
              Column(
                children: [
                  Text(
                    isToday ? 'TODAY' : '${_selectedDate.day} ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: L.text, letterSpacing: 0.5),
                  ),
                  Text(_getWeekdayName(_selectedDate.weekday), style: TextStyle(color: L.sub, fontSize: 11)),
                ],
              ),
              IconButton(
                onPressed: _selectedDate.isAfter(DateTime.now().subtract(const Duration(hours: 1))) 
                  ? null 
                  : () {
                      HapticEngine.light();
                      setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                    },
                icon: Icon(Icons.chevron_right_rounded, color: _selectedDate.isAfter(DateTime.now().subtract(const Duration(hours: 1))) ? L.border : L.sub),
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          // Completion Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: L.fill,
              borderRadius: AppRadius.roundL,
              border: Border.all(color: L.border),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: completion,
                        strokeWidth: 6,
                        backgroundColor: L.border.withValues(alpha: 0.2),
                        color: L.secondary,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text('${(completion * 100).round()}%',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: L.text)),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily Completion', 
                        style: TextStyle(color: L.sub, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text('$takenCount of ${doses.length} doses recorded',
                        style: TextStyle(color: L.text, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          // --- MEDICATIONS SECTION ---
          _SectionHeader(title: 'MEDICATIONS', count: doses.length, L: L),
          if (doses.isEmpty)
            _EmptyState(message: 'No medicines scheduled for this day.', L: L)
          else
            ...doses.map((d) {
              final taken = isToday 
                  ? (state.takenToday[d.key] ?? false)
                  : historicalDoseEntries.any((e) => e.medId == d.med.id && e.taken && e.label == d.sched.label);
              return _DoseLogRow(dose: d, taken: taken, L: L);
            }),

          const SizedBox(height: 32),

          // --- SYMPTOMS SECTION ---
          _SectionHeader(title: 'SYMPTOMS & LOGS', count: todaySymptoms.length, L: L),
          if (todaySymptoms.isEmpty)
            _EmptyState(message: 'No symptoms logged for this day.', L: L)
          else
            ...todaySymptoms.map((s) => _SymptomLogRow(
              symptom: s, 
              L: L, 
              onDelete: () => state.deleteSymptom(s.id),
            )),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getMonthName(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }

  String _getWeekdayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final AppThemeColors L;
  const _SectionHeader({required this.title, required this.count, required this.L});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(
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
            child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: L.sub)),
          ),
        ],
      ),
    );
  }
}

class _DoseLogRow extends StatelessWidget {
  final DoseItem dose;
  final bool taken;
  final AppThemeColors L;

  const _DoseLogRow({required this.dose, required this.taken, required this.L});

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
              color: taken ? L.secondary.withValues(alpha: 0.1) : L.fill,
              shape: BoxShape.circle,
            ),
            child: Icon(
              taken ? Icons.check_rounded : Icons.schedule_rounded,
              size: 16,
              color: taken ? L.secondary : L.sub,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dose.med.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: L.text)),
                Text('${dose.med.dose} · ${dose.sched.label}', style: TextStyle(fontSize: 12, color: L.sub)),
              ],
            ),
          ),
          Text(
            fmtTime(dose.sched.h, dose.sched.m, context),
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: L.text),
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

  const _SymptomLogRow({required this.symptom, required this.L, required this.onDelete});

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
                Text(symptom.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: L.text)),
                Row(
                  children: [
                    Text('Severity: ${symptom.severity}/10', style: TextStyle(fontSize: 12, color: L.sub)),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Text(message, style: TextStyle(color: L.sub, fontSize: 13, fontStyle: FontStyle.italic)),
    );
  }
}
