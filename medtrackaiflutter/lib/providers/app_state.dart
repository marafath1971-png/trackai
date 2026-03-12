import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/entities/entities.dart';
import '../domain/repositories/medication_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../data/repositories/medication_repository_impl.dart';
import '../data/repositories/user_repository_impl.dart';
import '../core/utils/date_formatter.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

enum AppPhase { loading, onboarding, auth, app }

// ── Dose with its key ──────────────────────────────────────────────────
class DoseItem {
  final Medicine med;
  final ScheduleEntry sched;
  final String key; // medId-schedLabel

  DoseItem({required this.med, required this.sched, required this.key});
}

enum DoseStatus { upcoming, taken, overdue, missed, skipped }

// ══════════════════════════════════════════════
// APP STATE PROVIDER
// ══════════════════════════════════════════════

class AppState extends ChangeNotifier {
  final IMedicationRepository medRepo;
  final IUserRepository userRepo;

  AppPhase phase = AppPhase.loading;
  UserProfile? profile;
  List<Medicine> meds = [];
  Map<String, List<DoseEntry>> history = {};
  Map<String, bool> takenToday = {};
  StreakData streakData = const StreakData();
  List<Caregiver> caregivers = [];
  List<MissedAlert> missedAlerts = [];
  bool darkMode = false;
  String? toast;
  String? toastType;
  String? healthInsights;
  bool loadingInsight = false;
  StreamSubscription? _cgSub;
  StreamSubscription? _notifSub;

  AppState({required this.medRepo, required this.userRepo}) {
    _notifSub = NotificationService.actionStream.stream
        .listen(_handleNotificationAction);
  }

  // ── Load from storage ──────────────────────────────────────────────
  Future<void> loadFromStorage() async {
    try {
      final results = await Future.wait([
        userRepo.getProfile(),
        medRepo.getMedicines(),
        medRepo.getHistory(),
        userRepo.getCaregivers(),
        userRepo.getStreakData(),
        medRepo.getTakenToday(),
        userRepo.getDarkMode(),
      ]);

      final cloudProfile = results[0] as UserProfile?;
      final cloudMeds = results[1] as List<Medicine>;
      // history merge already done inside MedicationRepositoryImpl.getHistory()
      history = results[2] as Map<String, List<DoseEntry>>;
      caregivers = results[3] as List<Caregiver>;
      streakData = results[4] as StreakData;
      takenToday = results[5] as Map<String, bool>;
      darkMode = results[6] as bool;

      profile = cloudProfile;
      meds = cloudMeds;

      // If user is signed in but Firestore had no data, push our local data up.
      // This handles the first-login after using the app offline.
      if (AuthService.uid != null &&
          cloudProfile == null &&
          cloudMeds.isEmpty) {
        _syncLocalToCloud();
      }

      phase = profile != null && profile!.name.isNotEmpty
          ? AppPhase.app
          : AppPhase.onboarding;
      _updateNotifications();
      _listenToCaregivers();

      if (AuthService.uid != null) {
        _initPushNotifications();
      }

      notifyListeners();
    } catch (_) {
      phase = AppPhase.onboarding;
      notifyListeners();
    }
  }

  /// Push all local data to Firestore (fire-and-forget, called on first sign-in).
  void _syncLocalToCloud() {
    (medRepo as MedicationRepositoryImpl).syncToCloud().catchError((_) {});
    (userRepo as UserRepositoryImpl).syncToCloud().catchError((_) {});
  }

  void _listenToCaregivers() {
    _cgSub?.cancel();
    _cgSub = userRepo.getCaregiversStream().listen((list) {
      caregivers = list;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _cgSub?.cancel();
    _notifSub?.cancel();
    super.dispose();
  }

  void _handleNotificationAction(String payloadStr) {
    if (meds.isEmpty) return; // Not loaded yet

    final parts = payloadStr.split('|');
    if (parts.length < 5) return;

    final action = parts[0];
    final medId = int.tryParse(parts[1]);
    final h = int.tryParse(parts[2]);
    final m = int.tryParse(parts[3]);
    final label = parts[4];

    if (medId == null || h == null || m == null) return;

    final doseList = getDoses();
    final doseItem = doseList
        .where((d) =>
            d.med.id == medId &&
            d.sched.h == h &&
            d.sched.m == m &&
            d.sched.label == label)
        .firstOrNull;

    if (doseItem == null) return;

    if (action == 'take') {
      if (!(takenToday[doseItem.key] ?? false)) {
        toggleDose(doseItem);
      }
    } else if (action == 'skip') {
      if (!(takenToday[doseItem.key] ?? false)) {
        skipDose(doseItem);
      }
    } else if (action == 'snooze_10') {
      final payloadForSnooze = 'take|$medId|$h|$m|$label';
      NotificationService.scheduleOneOffReminder(
        id: medId + 500000, // Snooze offset
        title: '⏰ Snooze: ${doseItem.med.name}',
        body: 'Time to take your ${doseItem.sched.label} dose',
        scheduledDate: DateTime.now().add(const Duration(minutes: 10)),
        payload: payloadForSnooze,
      );
      showToast('Snoozed for 10 minutes', type: 'info');
    } else {
      // Normal tap — just opens the app, maybe route to details later
    }
  }

  Future<void> _initPushNotifications() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await messaging.getToken();
        if (token != null) {
          await userRepo.saveFcmToken(token);
        }
        messaging.onTokenRefresh.listen((newToken) {
          userRepo.saveFcmToken(newToken);
        });
      }
    } catch (e) {
      debugPrint('Failed to initialize push notifications: $e');
    }
  }

  // Persist methods will now wrap repo calls
  Future<void> _persistAll({bool updateNotifs = false, String? dateKey}) async {
    await Future.wait([
      medRepo.saveTakenToday(takenToday),
      medRepo.saveHistory(history, onlyDateKey: dateKey),
      userRepo.saveCaregivers(caregivers),
      userRepo.saveStreakData(streakData),
      userRepo.saveDarkMode(darkMode),
    ]);
    if (updateNotifs) {
      _updateNotifications();
    }
  }

  Future<void> saveProfile(UserProfile p) async {
    profile = p;
    await userRepo.saveProfile(p);
    notifyListeners();
  }

  Future<void> _updateNotifications() async {
    await NotificationService.cancelAll();
    for (final med in meds) {
      for (int entryIdx = 0; entryIdx < med.schedule.length; entryIdx++) {
        final s = med.schedule[entryIdx];
        if (s.enabled) {
          for (final dayIdx in s.days) {
            // Deterministic ID: (medHash % 10000) * 100 + (entryIdx * 10) + dayIdx
            // This allows up to 10k meds, 10 entries per med, and 7 days.
            final notifId =
                (med.id.hashCode % 10000) * 100 + (entryIdx * 10) + dayIdx;

            // Check if THIS specific scheduled dose (on today's dayIdx) was already taken today.
            final now = DateTime.now();
            final todayDayIdx = now.weekday % 7;
            bool isTakenTodayFlag = false;

            if (dayIdx == todayDayIdx) {
              final doseKey = '${med.id}-${s.label}';
              isTakenTodayFlag = takenToday[doseKey] ?? false;
            }

            await NotificationService.scheduleWeeklyReminder(
              med: med,
              sched: s,
              notifId: notifId,
              enableSound: profile?.notifSound ?? true,
              enableVibration: profile?.notifSound ??
                  true, // Using notifSound for both as per UI
              isTakenToday: isTakenTodayFlag,
              dayIdx: dayIdx,
            );
          }
        }
      }
    }

    // Schedule morning summary
    final todayDoses = getDoses().length;
    if (todayDoses > 0) {
      await NotificationService.scheduleMorningSummary(
        totalDoses: todayDoses,
        enableSound: profile?.notifSound ?? true,
      );
    }
  }

  // ── Toast ─────────────────────────────────────────────────────────
  void showToast(String message, {String type = 'success'}) {
    toast = message;
    toastType = type;
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      toast = null;
      notifyListeners();
    });
  }

  // ── Computed values ────────────────────────────────────────────────
  List<Medicine> get activeMeds => meds;

  List<DoseItem> getDoses() {
    final today = dayIdx();
    final items = <DoseItem>[];
    for (final med in activeMeds) {
      for (final s in med.schedule) {
        if (s.enabled && s.days.contains(today)) {
          items.add(DoseItem(med: med, sched: s, key: '${med.id}-${s.label}'));
        }
      }
    }
    items.sort(
        (a, b) => (a.sched.h * 60 + a.sched.m) - (b.sched.h * 60 + b.sched.m));
    return items;
  }

  int getStreak() {
    int s = 0;

    // We check up to 365 days back
    DateTime d = DateTime.now().subtract(const Duration(days: 1));
    for (int i = 0; i < 365; i++) {
      final k = d.toIso8601String().substring(0, 10);
      final ds = history[k] ?? [];

      // Calculate what *should* have been taken on this day
      final dayOfWeek = d.weekday % 7;
      final scheduledForDay = meds
          .where((m) =>
              m.schedule.any((s) => s.enabled && s.days.contains(dayOfWeek)))
          .length;

      if (scheduledForDay == 0) {
        // No meds scheduled for this day, skip it (streak continues)
        d = d.subtract(const Duration(days: 1));
        continue;
      }

      if (ds.isEmpty) {
        if (streakData.frozen) {
          // If frozen, we skip one day of failure
          // (This is a simplified freeze logic: first failure day is ignored if frozen)
          d = d.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }

      final rate = ds.where((d) => d.taken).length / ds.length;
      if (rate >= 0.8) {
        s++;
        d = d.subtract(const Duration(days: 1));
      } else {
        if (streakData.frozen && s == 0) {
          // Only freeze if it would break a 0 streak? No, freeze usually preserves.
          d = d.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
    }
    return s;
  }

  List<Medicine> getLowMeds() =>
      meds.where((m) => m.count <= m.refillAt && m.count > 0).toList();

  // ── Phase control ──────────────────────────────────────────────────
  void completeOnboarding(UserProfile p) {
    profile = p;
    phase = AppPhase.auth; // Go to Login next
    saveProfile(p);
    notifyListeners();
  }

  void skipAuth() {
    phase = AppPhase.app;
    notifyListeners();
  }

  // ── Dark mode ──────────────────────────────────────────────────────
  void toggleDarkMode() {
    darkMode = !darkMode;
    userRepo.saveDarkMode(darkMode);
    notifyListeners();
  }

  // ── Toggle dose taken ──────────────────────────────────────────────
  final Map<String, bool> _processingDoses = {};

  Future<void> toggleDose(DoseItem dose) async {
    final key = dose.key;
    if (_processingDoses[key] == true) return; // Prevent double-tap
    _processingDoses[key] = true;

    try {
      final todayKey = todayStr();
      final wasTaken = takenToday[key] ?? false;
      takenToday = {...takenToday, key: !wasTaken};

      // Optimistic UI update instantly for perceived speed.
      notifyListeners();

      if (!wasTaken) {
        showToast('✓ ${dose.med.name} taken');
      } else {
        showToast('Dose unmarked', type: 'info');
      }

      // updateNotifs: true forces the cancellation of any immediate pending alarms for THIS dose today.
      await _persistAll(dateKey: todayKey, updateNotifs: true);
    } finally {
      _processingDoses.remove(key);
    }
  }

  DoseStatus getDoseStatus(DoseItem dose) {
    if (takenToday[dose.key] == true) return DoseStatus.taken;

    // Check history for skip
    final todayKey = todayStr();
    final entries = history[todayKey] ?? [];
    if (entries.any((e) =>
        e.medId == dose.med.id && e.label == dose.sched.label && e.skipped)) {
      return DoseStatus.skipped;
    }

    final nowM = nowMins();
    final schedM = dose.sched.h * 60 + dose.sched.m;

    if (nowM < schedM) return DoseStatus.upcoming;
    if (nowM <= schedM + 120) return DoseStatus.overdue; // < 2h
    return DoseStatus.missed; // > 2h
  }

  String getDoseGuidance(DoseItem dose) {
    final status = getDoseStatus(dose);
    if (status != DoseStatus.overdue && status != DoseStatus.missed) return '';

    final nowM = nowMins();
    final schedM = dose.sched.h * 60 + dose.sched.m;
    final diff = nowM - schedM;

    if (diff <= 120) return 'Take it now'; // < 2h
    if (diff <= 360) return 'Take it now unless next dose soon'; // 2-6h
    return 'Skip this dose, take next at scheduled time'; // > 6h
  }

  // ── Medicine CRUD ──────────────────────────────────────────────────
  void addMedicine(Medicine med) {
    meds = [...meds, med];
    medRepo.addMedicine(med);
    _updateNotifications();
    notifyListeners();
  }

  void updateMed(
    int id, {
    String? name,
    String? brand,
    String? dose,
    String? form,
    String? category,
    int? count,
    int? totalCount,
    String? color,
    int? refillAt,
    String? notes,
    List<ScheduleEntry>? schedule,
    String? courseStartDate,
    bool updateNotifs = true,
  }) {
    meds = meds.map((m) {
      if (m.id != id) return m;
      final updated = m.copyWith(
        name: name,
        brand: brand,
        dose: dose,
        form: form,
        category: category,
        count: count,
        totalCount: totalCount,
        color: color,
        refillAt: refillAt,
        notes: notes,
        schedule: schedule,
      );
      medRepo.updateMedicine(updated);
      return updated;
    }).toList();
    if (updateNotifs) {
      _updateNotifications();
    }
    notifyListeners();
  }

  void deleteMed(int id) {
    meds = meds.where((m) => m.id != id).toList();
    medRepo.deleteMedicine(id);
    _updateNotifications();
    notifyListeners();
    showToast('Medicine removed');
  }

  /// Archive a completed medicine course (hides it from active list).

  /// Skip a specific dose without marking it taken.
  void skipDose(DoseItem dose) {
    final key = dose.key;
    final todayKey = todayStr();
    // Mark as explicitly skipped in takenToday (false = not taken, but don't add auto-mark).
    // We record a DoseEntry with skipped=true so history reflects it.
    history = {
      ...history,
      todayKey: [
        ...(history[todayKey] ?? []),
        DoseEntry(
          medId: dose.med.id,
          label: dose.sched.label,
          time:
              '${dose.sched.h.toString().padLeft(2, '0')}:${dose.sched.m.toString().padLeft(2, '0')}',
          taken: false,
          skipped: true,
        ),
      ],
    };
    takenToday = {...takenToday, key: false};
    _persistAll(dateKey: todayKey);
    notifyListeners();
    showToast('Dose skipped', type: 'info');
  }


  // ── Alarms ────────────────────────────────────────────────────────
  void addSchedule(int medId, ScheduleEntry s) {
    final med = meds.firstWhere((m) => m.id == medId);
    updateMed(medId, schedule: [...med.schedule, s]);
    showToast('⏰ Reminder set for ${fmtTime(s.h, s.m)}');
  }

  void toggleSchedule(int medId, int idx) {
    final med = meds.firstWhere((m) => m.id == medId);
    final s = med.schedule[idx];
    final newSched = [...med.schedule];
    newSched[idx] = s.copyWith(enabled: !s.enabled);
    updateMed(medId, schedule: newSched);
    showToast(s.enabled ? 'Reminder paused' : 'Reminder resumed');
  }

  void removeSchedule(int medId, int idx) {
    final med = meds.firstWhere((m) => m.id == medId);
    final newSched = [...med.schedule]..removeAt(idx);
    updateMed(medId, schedule: newSched);
    showToast('Reminder removed');
  }

  // ── Caregivers ─────────────────────────────────────────────────────
  void addCaregiver(Caregiver cg) {
    caregivers = [...caregivers, cg];
    userRepo.saveCaregivers(caregivers);
    notifyListeners();
    showToast('${cg.name} added as caregiver');
  }

  /// Write invite to Firestore so any device can look it up via the 6-char code.
  Future<void> createInvite(Caregiver cg) async {
    final uid = AuthService.uid;
    if (uid == null) return; // no-op when offline / not signed in
    try {
      await userRepo.createInvite(uid, cg);
    } catch (_) {}
  }

  /// Look up an invite code globally in Firestore. Returns null if not found.
  Future<Caregiver?> lookupInvite(String code) async {
    try {
      return await userRepo.getInvite(code);
    } catch (_) {
      return null;
    }
  }

  void activateCaregiver(int id) {
    caregivers = caregivers
        .map((c) => c.id == id ? c.copyWith(status: 'active') : c)
        .toList();
    userRepo.saveCaregivers(caregivers);
    notifyListeners();
    showToast('Caregiver activated ✓');
  }

  void removeCaregiver(int id) {
    caregivers = caregivers.where((c) => c.id != id).toList();
    userRepo.saveCaregivers(caregivers);
    notifyListeners();
    showToast('Caregiver removed', type: 'warning');
  }

  Future<void> joinCaregiver(String patientUid, int cgId) async {
    try {
      await userRepo.joinCaregiver(patientUid, cgId);
      activateCaregiver(cgId);
      showToast('Successfully joined! Monitoring active ✓');
    } catch (e) {
      showToast('Failed to join: $e', type: 'error');
    }
  }

  Future<void> joinForce(String patientUid, int cgId) async {
    try {
      await userRepo.joinCaregiver(patientUid, cgId);
      // Ensure it's in our local list or refreshed
      final match = caregivers.where((c) => c.id == cgId).firstOrNull;
      if (match != null) {
        activateCaregiver(cgId);
      } else {
        // If not found (rare), reload
        await userRepo.getCaregivers();
      }
      showToast('Joined successfully! ✓');
    } catch (_) {
      // Direct join fallback
      activateCaregiver(cgId);
    }
  }

  void addMissedAlert(MissedAlert alert) {
    missedAlerts = [alert, ...missedAlerts].take(20).toList();
    notifyListeners();
  }

  void markAlertsAsSeen() {
    missedAlerts = missedAlerts
        .map((a) => MissedAlert(
              id: a.id,
              medName: a.medName,
              doseLabel: a.doseLabel,
              time: a.time,
              timestamp: a.timestamp,
              caregivers: a.caregivers,
              seen: true,
            ))
        .toList();
    notifyListeners();
  }

  void simulateMissedDose() {
    showToast('Missed dose simulation not available in this version', type: 'info');
  }

  // ── Streak Freeze ──────────────────────────────────────────────────
  void useStreakFreeze() {
    streakData = streakData.copyWith(frozen: true, freezeUsedWeek: true);
    userRepo.saveStreakData(streakData);
    notifyListeners();
  }

  // ── Delete all data ────────────────────────────────────────────────
  Future<void> deleteAllData() async {
    meds = [];
    history = {};
    caregivers = [];
    takenToday = {};
    streakData = const StreakData();
    healthInsights = null;
    missedAlerts = [];
    await Future.wait([
      medRepo.saveHistory({}),
      medRepo.saveTakenToday({}),
      userRepo.saveCaregivers([]),
      userRepo.saveStreakData(const StreakData()),
    ]);
    notifyListeners();
  }

  // ── Reset taken today at midnight ──────────────────────────────────
  void resetTakenToday() {
    takenToday = {};
    medRepo.saveTakenToday({});
    notifyListeners();
  }

  // ── Data Export ─────────────────────────────────────────────────────
  String exportDataCSV() {
    final sb = StringBuffer();
    sb.writeln('Type,ID,Name,Label,Details,Taken,Timestamp');

    // Meds
    for (final m in meds) {
      sb.writeln(
          'Medicine,${m.id},"${m.name}","${m.dose}","${m.count} units",,');
    }

    // History
    history.forEach((date, entries) {
      for (final e in entries) {
        final med =
            meds.firstWhere((m) => m.id == e.medId, orElse: () => meds.first);
        sb.writeln(
            'History,${e.medId},"${med.name}","${e.label}",,"${e.taken}","$date ${e.time}"');
      }
    });

    return sb.toString();
  }
}
