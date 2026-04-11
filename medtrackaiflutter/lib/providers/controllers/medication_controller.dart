import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/medication_repository.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_engine.dart';
import '../../services/analytics_service.dart';
import '../../core/utils/result.dart';
import 'package:live_activities/live_activities.dart';
import '../../services/notification_service.dart';

class ScheduledMed {
  final Medicine med;
  final ScheduleEntry sched;
  final int idx;
  ScheduledMed({required this.med, required this.sched, required this.idx});
}

class MedicationController extends ChangeNotifier {
  final IMedicationRepository medRepo;

  String? _currentProfileId;
  List<Medicine> _meds = [];
  Map<String, List<DoseEntry>> _history = {};
  Map<String, bool> _takenToday = {};
  final StreakData _streakData = const StreakData();
  int _scanCount = 0;
  DateTime? _lastReviewRequest;
  List<double> _inventoryHistory = [];
  final _liveActivitiesPlugin = LiveActivities();

  bool _isMutating = false;
  String? _interactionWarning;
  String? _interactionWarningMedName;

  List<double> get inventoryHistory => _inventoryHistory;

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
  String? get currentProfileId => _currentProfileId;

  Future<void> loadData({String? profileId}) async {
    _currentProfileId = profileId;
    try {
      _meds = await medRepo.getMedicines(profileId: profileId);
      _history = await medRepo.getHistory(profileId: profileId);
      _takenToday = await medRepo.getTakenToday(profileId: profileId);

      final prefs = await medRepo.getPrefs();
      _scanCount = prefs.getInt('scan_count') ?? 0;
      final lastRev = prefs.getString('last_review_request');
      if (lastRev != null) _lastReviewRequest = DateTime.tryParse(lastRev);

      final invHistRaw = prefs.getStringList('inventory_history');
      if (invHistRaw != null) {
        _inventoryHistory =
            invHistRaw.map((e) => double.tryParse(e) ?? 0.0).toList();
      } else {
        // Seed with current health if empty
        _inventoryHistory =
            List.generate(7, (_) => _calculateCurrentInventoryHealth());
      }

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
    DateTime d = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final k = d.toIso8601String().substring(0, 10);
      final ds = _history[k] ?? [];
      final dayOfWeek = d.weekday % 7;
      final scheduledForDay = _meds
          .where((m) =>
              m.schedule.any((s) => s.enabled && s.days.contains(dayOfWeek)))
          .length;
      if (scheduledForDay == 0) {
        d = d.subtract(const Duration(days: 1));
        continue;
      }

      final takenDoses = ds.where((e) => e.taken).length;
      final rate = scheduledForDay > 0 ? (takenDoses / scheduledForDay) : 0.0;

      if (rate >= 0.8) {
        s++;
      } else if (i == 0) {
        // Today isn't complete, do not break the streak.
      } else {
        break;
      }
      d = d.subtract(const Duration(days: 1));
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
      final dateKey =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final dayOfWeek = date.weekday % 7;
      final scheduledOnDay = _meds
          .where((m) =>
              m.schedule.any((s) => s.enabled && s.days.contains(dayOfWeek)))
          .length;
      if (scheduledOnDay > 0) {
        totalScheduled += scheduledOnDay;
        final dailyEntries = _history[dateKey] ?? [];
        totalTaken += dailyEntries
            .where((e) => e.taken && !e.label.startsWith('PRN-'))
            .length;
      }
    }
    _cachedAdherence = totalScheduled == 0
        ? 1.0
        : (totalTaken / totalScheduled).clamp(0.0, 1.0);
    isAdherenceDirty = false;
    return _cachedAdherence!;
  }

  List<Map<String, dynamic>> getTrendData() {
    final List<Map<String, dynamic>> trend = [];
    final now = DateTime.now();
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final dayOfWeek = date.weekday % 7;
      final dayScheduled = _meds
          .where((m) =>
              m.schedule.any((s) => s.enabled && s.days.contains(dayOfWeek)))
          .length;
      if (dayScheduled == 0) {
        trend.add({
          'date': dateKey,
          'value': 1.0
        }); // Treat no-med days as perfect adherence
      } else {
        final dailyEntries = _history[dateKey] ?? [];
        final takenCount = dailyEntries
            .where((e) => e.taken && !e.label.startsWith('PRN-'))
            .length;
        trend.add({
          'date': dateKey,
          'value': (takenCount / dayScheduled).clamp(0.0, 1.0)
        });
      }
    }
    return trend;
  }

  int getLowStockCount() {
    return _meds.where((m) => m.count <= m.refillAt && m.totalCount > 0).length;
  }

  double _calculateCurrentInventoryHealth() {
    if (_meds.isEmpty) return 1.0;
    double totalPct = 0;
    for (var m in _meds) {
      if (m.totalCount > 0) {
        totalPct += (m.count / m.totalCount).clamp(0.0, 1.0);
      } else {
        totalPct += 1.0; // Infinite/Untracked stock is "healthy"
      }
    }
    return totalPct / _meds.length;
  }

  Future<void> _recordInventorySnapshot() async {
    final currentHealth = _calculateCurrentInventoryHealth();
    _inventoryHistory.add(currentHealth);
    if (_inventoryHistory.length > 30) _inventoryHistory.removeAt(0);

    final prefs = await medRepo.getPrefs();
    await prefs.setStringList('inventory_history',
        _inventoryHistory.map((e) => e.toString()).toList());
    notifyListeners();
  }

  String getDoseGuidance(Medicine m) {
    if (m.intakeInstructions.isNotEmpty) return m.intakeInstructions;
    return '-';
  }

  Future<void> logPrnDose(int medId, String label, String time) async {
    final todayKey =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
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
      await medRepo.updateMedicine(updatedMed, profileId: _currentProfileId);

      if (updatedMed.count == updatedMed.refillAt) {
        NotificationService.showRefillAlert(med: updatedMed);
      }
    }

    await medRepo.saveHistory(_history,
        onlyDateKey: todayKey, profileId: _currentProfileId);
    await _recordInventorySnapshot();
    invalidateCache();
    notifyListeners();
    HapticEngine.success();
  }

  // ── Dose Operations ────────────────────────────────────────────────

  List<DoseItem> getDoses({DateTime? date}) {
    final targetDate = date ?? DateTime.now();
    if (!isDosesDirty && _cachedDoses != null && date == null) {
      return _cachedDoses!;
    }

    final dayOfWeek = targetDate.weekday % 7;
    final items = <DoseItem>[];
    for (final med in _meds) {
      for (final s in med.schedule) {
        if (s.enabled && s.days.contains(dayOfWeek)) {
          items.add(DoseItem(med: med, sched: s, key: '${med.id}-${s.label}'));
        }
      }
    }
    items.sort(
        (a, b) => (a.sched.h * 60 + a.sched.m) - (b.sched.h * 60 + b.sched.m));

    if (date == null) {
      _cachedDoses = items;
      isDosesDirty = false;
    }
    return items;
  }

  Map<String, bool> getTakenMapForDate(DateTime date) {
    final dateKey =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final dayHistory = _history[dateKey] ?? [];
    return {
      for (var entry in dayHistory) '${entry.medId}-${entry.label}': entry.taken
    };
  }

  Future<void> toggleDose(DoseItem dose, String dateKey) async {
    final key = dose.key;
    final now = DateTime.now();
    final realToday =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final isActualToday = dateKey == realToday;

    // Determine current taken status for THIS specific date
    final dailyHistory = _history[dateKey] ?? [];
    final wasTaken = dailyHistory.any((e) =>
        e.medId == dose.med.id && e.label == dose.sched.label && e.taken);

    if (isActualToday) {
      _takenToday = {..._takenToday, key: !wasTaken};
    }
    HapticEngine.success();

    if (!wasTaken) {
      // 1. Update Inventory
      final idx = _meds.indexWhere((m) => m.id == dose.med.id);
      if (idx != -1) {
        final m = _meds[idx];
        if (m.count > 0) {
          final updatedMed = m.copyWith(count: m.count - 1);
          _meds[idx] = updatedMed;
          await medRepo.updateMedicine(updatedMed,
              profileId: _currentProfileId);

          // Auto-Refill Alert Check
          if (updatedMed.count == updatedMed.refillAt) {
            NotificationService.showRefillAlert(med: updatedMed);
          }
        }
      }
      // 2. Update History
      final entry = DoseEntry(
        medId: dose.med.id,
        label: dose.sched.label,
        time:
            '${dose.sched.h.toString().padLeft(2, '0')}:${dose.sched.m.toString().padLeft(2, '0')}',
        taken: true,
        takenAt: DateTime.now().toIso8601String(),
      );
      _history = {
        ..._history,
        dateKey: [
          ...(_history[dateKey] ?? []).where(
              (e) => e.label != dose.sched.label || e.medId != dose.med.id),
          entry
        ],
      };
      AnalyticsService.logDoseAction(medName: dose.med.name, action: 'take');
    }

    await medRepo.saveTakenToday(_takenToday, profileId: _currentProfileId);
    await medRepo.saveHistory(_history,
        onlyDateKey: dateKey, profileId: _currentProfileId);
    await _recordInventorySnapshot();
    invalidateCache();

    // Update Live Activities if on iOS
    if (Platform.isIOS) {
      updateLiveActivityCards();
    }

    notifyListeners();
  }

  Future<void> skipDose(DoseItem dose, String dateKey) async {
    final entry = DoseEntry(
      medId: dose.med.id,
      label: dose.sched.label,
      time:
          '${dose.sched.h.toString().padLeft(2, '0')}:${dose.sched.m.toString().padLeft(2, '0')}',
      taken: false,
      takenAt: DateTime.now().toIso8601String(),
    );
    HapticEngine.selection();
    _history = {
      ..._history,
      dateKey: [
        ...(_history[dateKey] ?? []).where(
            (e) => e.label != dose.sched.label || e.medId != dose.med.id),
        entry
      ],
    };
    await medRepo.saveHistory(_history,
        onlyDateKey: dateKey, profileId: _currentProfileId);
    invalidateCache();

    // Update Live Activities if on iOS
    if (Platform.isIOS) {
      updateLiveActivityCards();
    }

    notifyListeners();
  }

  Future<void> undoPrnDose(int medId, String label, String dateKey) async {
    final dayHistory = List<DoseEntry>.from(_history[dateKey] ?? []);
    final idx =
        dayHistory.indexWhere((e) => e.medId == medId && e.label == label);
    if (idx != -1) {
      dayHistory.removeAt(idx);
      _history = {..._history, dateKey: dayHistory};

      final mIdx = _meds.indexWhere((m) => m.id == medId);
      if (mIdx != -1) {
        final updated = _meds[mIdx].copyWith(count: _meds[mIdx].count + 1);
        _meds[mIdx] = updated;
        await medRepo.updateMedicine(updated, profileId: _currentProfileId);
      }

      await medRepo.saveHistory(_history,
          onlyDateKey: dateKey, profileId: _currentProfileId);
      await _recordInventorySnapshot();
      invalidateCache();
      notifyListeners();
    }
  }

  Future<void> addMedicine(Medicine medicine) async {
    _isMutating = true;
    notifyListeners();
    try {
      await medRepo.addMedicine(medicine, profileId: _currentProfileId);
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
      await medRepo.deleteMedicine(id, profileId: _currentProfileId);
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
    medRepo.updateMedicine(updated, profileId: _currentProfileId);
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
          await medRepo.updateMedicine(_meds[idx],
              profileId: _currentProfileId);
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

  Future<String?> uploadMedicineImage(File file) =>
      medRepo.uploadMedicineImage(file);

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

  /// ── Live Activities & Dynamic Island (v1.5) ─────────────────────────

  Future<void> updateLiveActivityCards() async {
    if (!Platform.isIOS) return;

    try {
      final now = DateTime.now();
      final doses = getDoses();

      // Find the next upcoming dose that isn't taken
      final nextDose = doses.where((d) {
        final taken = takenToday[d.key] ?? false;
        if (taken) return false;

        // Is it today?
        final dTime =
            DateTime(now.year, now.month, now.day, d.sched.h, d.sched.m);
        // Only show if it's within 4 hours or passed
        return dTime.difference(now).inHours <= 4;
      }).toList();

      if (nextDose.isEmpty) {
        await _liveActivitiesPlugin.endAllActivities();
        return;
      }

      // We only show the primary "Next" dose on the Dynamic Island
      final d = nextDose.first;
      final dTime =
          DateTime(now.year, now.month, now.day, d.sched.h, d.sched.m);
      final diff = dTime.difference(now);

      String timeLeft;
      if (diff.isNegative) {
        timeLeft = "LATE";
      } else if (diff.inMinutes < 60) {
        timeLeft = "${diff.inMinutes}m";
      } else {
        timeLeft = "${diff.inHours}h";
      }

      // This Map must match the MedTrackActivityAttributes.ContentState in Swift
      await _liveActivitiesPlugin.createActivity('med_timer', {
        'medName': d.med.name,
        'dose': d.med.dose,
        'timeLeft': timeLeft,
      });
    } catch (e) {
      appLogger.w('[LiveActivities] Failed to update: $e');
      appLogger.w('[LiveActivities] Failed to update: $e');
    }
  }

  // Gets the average delay minutes in taking medications today
  double getLatencyData() {
    if (_history.isEmpty) return 0.0;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final historyToday = _history[today];
    if (historyToday == null || historyToday.isEmpty) return 0.0;

    int totalMinutesLate = 0;
    int count = 0;
    for (var entry in historyToday) {
      if (!entry.taken) continue;
      final takenAtStr = entry.takenAt;
      if (takenAtStr == null) continue;

      final dtTaken = DateTime.parse(takenAtStr);
      final timeParts = entry.time.split(':');
      if (timeParts.length < 2) continue;

      final sH = int.parse(timeParts[0]);
      final sM = int.parse(timeParts[1]);

      final scheduledTime =
          DateTime(dtTaken.year, dtTaken.month, dtTaken.day, sH, sM);

      final diff = dtTaken.difference(scheduledTime).inMinutes;
      if (diff > 0) totalMinutesLate += diff;
      count++;
    }

    return count == 0 ? 0.0 : totalMinutesLate / count;
  }

  List<Map<String, dynamic>> getLatencyHistory() {
    // Collect last 7 days for the heatmap
    final List<Map<String, dynamic>> result = [];
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final dateStr =
          now.subtract(Duration(days: i)).toIso8601String().substring(0, 10);
      final dayHistory = _history[dateStr];
      if (dayHistory != null) {
        for (var entry in dayHistory) {
          if (!entry.taken || entry.takenAt == null) continue;
          final dtTaken = DateTime.parse(entry.takenAt!);
          final parts = entry.time.split(':');
          if (parts.length < 2) continue;
          final sH = int.parse(parts[0]);
          final sM = int.parse(parts[1]);
          final scheduled =
              DateTime(dtTaken.year, dtTaken.month, dtTaken.day, sH, sM);
          final latency = dtTaken.difference(scheduled).inMinutes;

          result.add({
            'date': dateStr,
            'latency': latency,
          });
        }
      }
    }
    return result;
  }
}
