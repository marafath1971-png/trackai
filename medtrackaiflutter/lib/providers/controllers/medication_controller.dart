import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/medication_repository.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_engine.dart';
import '../../services/analytics_service.dart';
import '../../core/utils/result.dart';

class ScheduledMed {
  final Medicine med;
  final ScheduleEntry sched;
  final int idx;
  ScheduledMed({required this.med, required this.sched, required this.idx});
}

class MedicationController extends ChangeNotifier {
  final IMedicationRepository medRepo;
  
  List<Medicine> _meds = [];
  Map<String, List<DoseEntry>> _history = {};
  Map<String, bool> _takenToday = {};
  final StreakData _streakData = const StreakData();
  int _scanCount = 0;
  DateTime? _lastReviewRequest;

  bool _isMutating = false;
  String? _interactionWarning;
  String? _interactionWarningMedName;
  
  // Cache dirty flags
  bool isDosesDirty = true;
  bool isStreakDirty = true;
  bool isAdherenceDirty = true;

  // Cached values
  int? _cachedStreak;
  double? _cachedAdherence;
  List<DoseItem>? _cachedDoses;

  MedicationController({required this.medRepo});

  List<Medicine> get meds => _meds;
  Map<String, List<DoseEntry>> get history => _history;
  Map<String, bool> get takenToday => _takenToday;
  StreakData get streakData => _streakData;
  int get scanCount => _scanCount;
  DateTime? get lastReviewRequest => _lastReviewRequest;
  bool get isMutating => _isMutating;
  String? get interactionWarning => _interactionWarning;
  String? get interactionWarningMedName => _interactionWarningMedName;

  Future<void> loadData() async {
    try {
      _meds = await medRepo.getMedicines();
      _history = await medRepo.getHistory();
      _takenToday = await medRepo.getTakenToday();
      
      final prefs = await medRepo.getPrefs();
      _scanCount = prefs.getInt('scan_count') ?? 0;
      final lastRev = prefs.getString('last_review_request');
      if (lastRev != null) _lastReviewRequest = DateTime.tryParse(lastRev);

      invalidateCache();
      notifyListeners();
    } catch (e) {
      appLogger.e('[MedicationController] Data load failed', error: e);
    }
  }

  void clearInteractionWarning() {
    _interactionWarning = null;
    _interactionWarningMedName = null;
    notifyListeners();
  }

  void invalidateCache() {
    isDosesDirty = true;
    isStreakDirty = true;
    isAdherenceDirty = true;
  }

  // ── Adherence & Streak Logic ──────────────────────────────────────
  
  int getStreak() {
    if (!isStreakDirty && _cachedStreak != null) return _cachedStreak!;
    int s = 0;
    DateTime d = DateTime.now().subtract(const Duration(days: 1));
    for (int i = 0; i < 365; i++) {
      final k = d.toIso8601String().substring(0, 10);
      final ds = _history[k] ?? [];
      final dayOfWeek = d.weekday % 7;
      final scheduledForDay = _meds.where((m) => m.schedule.any((s) => s.enabled && s.days.contains(dayOfWeek))).length;
      if (scheduledForDay == 0) { d = d.subtract(const Duration(days: 1)); continue; }
      if (ds.isEmpty) break;
      final rate = ds.where((d) => d.taken).length / ds.length;
      if (rate >= 0.8) { s++; d = d.subtract(const Duration(days: 1)); } else {
        break;
      }
    }
    _cachedStreak = s;
    isStreakDirty = false;
    return s;
  }

  double getAdherenceScore() {
    if (!isAdherenceDirty && _cachedAdherence != null) return _cachedAdherence!;
    if (_history.isEmpty) return 1.0;
    int totalScheduled = 0, totalTaken = 0;
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final dayOfWeek = date.weekday % 7;
      final scheduledOnDay = _meds.where((m) => m.schedule.any((s) => s.enabled && s.days.contains(dayOfWeek))).length;
      if (scheduledOnDay > 0) {
        totalScheduled += scheduledOnDay;
        final dailyEntries = _history[dateKey] ?? [];
        totalTaken += dailyEntries.where((e) => e.taken && !e.label.startsWith('PRN-')).length;
      }
    }
    _cachedAdherence = totalScheduled == 0 ? 1.0 : (totalTaken / totalScheduled).clamp(0.0, 1.0);
    isAdherenceDirty = false;
    return _cachedAdherence!;
  }

  List<Map<String, dynamic>> getTrendData() {
    final List<Map<String, dynamic>> trend = [];
    final now = DateTime.now();
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final dayOfWeek = date.weekday % 7;
      final dayScheduled = _meds.where((m) => m.schedule.any((s) => s.enabled && s.days.contains(dayOfWeek))).length;
      if (dayScheduled == 0) {
        trend.add({'date': dateKey, 'value': 1.0}); // Treat no-med days as perfect adherence
      } else {
        final dailyEntries = _history[dateKey] ?? [];
        final takenCount = dailyEntries.where((e) => e.taken && !e.label.startsWith('PRN-')).length;
        trend.add({'date': dateKey, 'value': (takenCount / dayScheduled).clamp(0.0, 1.0)});
      }
    }
    return trend;
  }

  int getLowStockCount() {
    return _meds.where((m) => m.count <= m.refillAt && m.totalCount > 0).length;
  }

  String getDoseGuidance(Medicine m) {
    if (m.intakeInstructions.isNotEmpty) return m.intakeInstructions;
    return '-';
  }

  Future<void> logPrnDose(int medId, String label, String time) async {
    final todayKey = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
    final entry = DoseEntry(
      medId: medId,
      label: 'PRN-$label',
      time: time,
      taken: true,
      takenAt: DateTime.now().toIso8601String(),
    );
    _history = {
      ..._history,
      todayKey: [...(_history[todayKey] ?? []), entry],
    };
    
    final idx = _meds.indexWhere((m) => m.id == medId);
    if (idx != -1 && _meds[idx].count > 0) {
      final updatedMed = _meds[idx].copyWith(count: _meds[idx].count - 1);
      _meds[idx] = updatedMed;
      await medRepo.updateMedicine(updatedMed);
    }

    await medRepo.saveHistory(_history, onlyDateKey: todayKey);
    invalidateCache();
    notifyListeners();
  }

  // ── Dose Operations ────────────────────────────────────────────────

  
  List<DoseItem> getDoses() {
    if (!isDosesDirty && _cachedDoses != null) return _cachedDoses!;
    final today = DateTime.now().weekday % 7;
    final items = <DoseItem>[];
    for (final med in _meds) {
      for (final s in med.schedule) {
        if (s.enabled && s.days.contains(today)) {
          items.add(DoseItem(med: med, sched: s, key: '${med.id}-${s.label}'));
        }
      }
    }
    items.sort((a, b) => (a.sched.h * 60 + a.sched.m) - (b.sched.h * 60 + b.sched.m));
    _cachedDoses = items;
    isDosesDirty = false;
    return items;
  }

  Future<void> toggleDose(DoseItem dose, String todayKey) async {
    final key = dose.key;
    final wasTaken = _takenToday[key] ?? false;
    _takenToday = {..._takenToday, key: !wasTaken};

    if (!wasTaken) {
      // 1. Update Inventory
      final idx = _meds.indexWhere((m) => m.id == dose.med.id);
      if (idx != -1) {
        final m = _meds[idx];
        if (m.count > 0) {
          final updatedMed = m.copyWith(count: m.count - 1);
          _meds[idx] = updatedMed;
          await medRepo.updateMedicine(updatedMed);
        }
      }
      // 2. Update History
      final entry = DoseEntry(
        medId: dose.med.id,
        label: dose.sched.label,
        time: '${dose.sched.h.toString().padLeft(2, '0')}:${dose.sched.m.toString().padLeft(2, '0')}',
        taken: true,
        takenAt: DateTime.now().toIso8601String(),
      );
      _history = {
        ..._history,
        todayKey: [...(_history[todayKey] ?? []).where((e) => e.label != dose.sched.label || e.medId != dose.med.id), entry],
      };
      AnalyticsService.logDoseAction(medName: dose.med.name, action: 'take');
    }
    
    await medRepo.saveTakenToday(_takenToday);
    await medRepo.saveHistory(_history, onlyDateKey: todayKey);
    invalidateCache();
    notifyListeners();
  }

  Future<void> skipDose(DoseItem dose, String todayKey) async {
    final entry = DoseEntry(
      medId: dose.med.id,
      label: dose.sched.label,
      time: '${dose.sched.h.toString().padLeft(2, '0')}:${dose.sched.m.toString().padLeft(2, '0')}',
      taken: false,
      takenAt: DateTime.now().toIso8601String(),
    );
    _history = {
      ..._history,
      todayKey: [...(_history[todayKey] ?? []).where((e) => e.label != dose.sched.label || e.medId != dose.med.id), entry],
    };
    await medRepo.saveHistory(_history, onlyDateKey: todayKey);
    invalidateCache();
    notifyListeners();
  }

  Future<void> undoPrnDose(int medId, String label, String todayKey) async {
    final dayHistory = List<DoseEntry>.from(_history[todayKey] ?? []);
    final idx = dayHistory.indexWhere((e) => e.medId == medId && e.label == label);
    if (idx != -1) {
      dayHistory.removeAt(idx);
      _history = {..._history, todayKey: dayHistory};
      
      final mIdx = _meds.indexWhere((m) => m.id == medId);
      if (mIdx != -1) {
        final updated = _meds[mIdx].copyWith(count: _meds[mIdx].count + 1);
        _meds[mIdx] = updated;
        await medRepo.updateMedicine(updated);
      }
      
      await medRepo.saveHistory(_history, onlyDateKey: todayKey);
      invalidateCache();
      notifyListeners();
    }
  }

  Future<void> addMedicine(Medicine medicine) async {
    _isMutating = true;
    notifyListeners();
    try {
      await medRepo.addMedicine(medicine);
      _meds.add(medicine);
      invalidateCache();
      HapticEngine.success();
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> deleteMedicine(int id) async {
    _isMutating = true;
    notifyListeners();
    try {
      await medRepo.deleteMedicine(id);
      _meds.removeWhere((m) => m.id == id);
      invalidateCache();
      HapticEngine.selection();
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> updateMedDirect(Medicine updated) async {
    _meds = _meds.map((m) => m.id == updated.id ? updated : m).toList();
    medRepo.updateMedicine(updated);
    invalidateCache();
    notifyListeners();
  }

  Future<Result<AISafetyProfile>> analyzeMedicineSafety(Medicine m) async {
    _isMutating = true;
    notifyListeners();
    try {
      final res = await medRepo.analyzeMedicineSafety(m);
      if (res is Success<AISafetyProfile>) {
        final idx = _meds.indexWhere((x) => x.id == m.id);
        if (idx != -1) {
          _meds[idx] = _meds[idx].copyWith(aiSafetyProfile: res.value);
          await medRepo.updateMedicine(_meds[idx]);
        }
      }
      return res;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
  
  Future<void> incrementScanCount(int newMedsCount) async {
    _scanCount++;
    final prefs = await medRepo.getPrefs();
    await prefs.setInt('scan_count', _scanCount);
    notifyListeners();
  }

  // ── Bridge Proxies for 1.0 UI ───────────────────────────────────────
  List<Medicine> getLowMeds() {
    return _meds.where((m) => m.count <= 3).toList();
  }

  int getAdherenceForMed(int medId) {
    int total = 0, taken = 0;
    _history.forEach((_, list) {
      for (var entry in list) {
        if (entry.medId == medId) {
          total++;
          if (entry.taken) taken++;
        }
      }
    });
    return total == 0 ? 100 : (taken / total * 100).round();
  }

  ({int taken, int total}) getHistoryCountForMed(int medId) {
    int total = 0, taken = 0;
    _history.forEach((_, list) {
      for (var entry in list) {
        if (entry.medId == medId) {
          total++;
          if (entry.taken) taken++;
        }
      }
    });
    return (taken: taken, total: total);
  }

  Future<String?> uploadMedicineImage(File file) => medRepo.uploadMedicineImage(file);

  Future<void> snoozeDose(DoseItem dose, int minutes) async {
    appLogger.i('[Med] Snoozing dose ${dose.med.name}');
    HapticEngine.selection();
  }

  Future<void> logPaywallEvent(String eventName) async {
    appLogger.i('[Analytics] $eventName');
    await AnalyticsService.logEvent(eventName);
  }

  // ── Scheduling Bridge ───────────────────────────────────────────────
  Future<void> toggleSchedule(int medId, int idx) async {
    final mIdx = _meds.indexWhere((m) => m.id == medId);
    if (mIdx == -1) return;
    final m = _meds[mIdx];
    final s = m.schedule[idx];
    m.schedule[idx] = s.copyWith(enabled: !s.enabled);
    updateMedDirect(m);
  }

  Future<void> removeSchedule(int medId, int idx) async {
    final mIdx = _meds.indexWhere((m) => m.id == medId);
    if (mIdx == -1) return;
    final m = _meds[mIdx];
    m.schedule.removeAt(idx);
    updateMedDirect(m);
  }

  Future<void> addSchedule(int medId, ScheduleEntry s) async {
    final mIdx = _meds.indexWhere((m) => m.id == medId);
    if (mIdx == -1) return;
    final m = _meds[mIdx];
    m.schedule.add(s);
    updateMedDirect(m);
  }

  Future<void> updateSchedule(int medId, int idx, ScheduleEntry s) async {
    final mIdx = _meds.indexWhere((m) => m.id == medId);
    if (mIdx == -1) return;
    final m = _meds[mIdx];
    m.schedule[idx] = s;
    updateMedDirect(m);
  }

  List<ScheduledMed> getAllSchedules() {
    final List<ScheduledMed> list = [];
    for (var m in _meds) {
      for (int i = 0; i < m.schedule.length; i++) {
        list.add(ScheduledMed(med: m, sched: m.schedule[i], idx: i));
      }
    }
    return list;
  }
}

