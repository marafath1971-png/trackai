import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/entities/entities.dart';
import '../domain/repositories/medication_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../data/repositories/medication_repository_impl.dart';
import '../data/repositories/user_repository_impl.dart';
import '../core/utils/date_formatter.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../domain/repositories/symptom_repository.dart';
import '../services/purchases_service.dart';
import '../services/review_service.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/gemini_service.dart';
import '../services/biometric_service.dart';
import '../core/utils/haptic_engine.dart';
import '../core/utils/logger.dart';

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
  final SymptomRepository symptomRepo;

  AppPhase phase = AppPhase.loading;
  UserProfile? profile;
  List<Medicine> meds = [];
  Map<String, List<DoseEntry>> history = {};
  Map<String, bool> takenToday = {};
  StreakData streakData = const StreakData();
  List<Caregiver> caregivers = [];
  List<Map<String, dynamic>> monitoredPatients = [];
  List<MissedAlert> missedAlerts = [];
  bool darkMode = false;
  String? toast;
  String? toastType;
  List<HealthInsight> healthInsights = [];
  List<Symptom> symptoms = [];
  bool loadingInsight = false;
  bool isLocked = false;
  StreamSubscription? _cgSub;
  StreamSubscription? _notifSub;
  final AudioPlayer _audioPlayer;

  bool get isPremium => profile?.isPremium ?? false;
  bool _isPurchasing = false;
  bool get isPurchasing => _isPurchasing;

  void setPurchasing(bool value) {
    _isPurchasing = value;
    notifyListeners();
  }
 
  // ── Calculation Cache ──────────────────────────────────────────────
  int? _cachedStreak;
  double? _cachedAdherence;
  List<DoseItem>? _cachedDoses;
  List<({Medicine med, ScheduleEntry sched, int idx})>? _cachedAllSchedules;
  bool _isStreakDirty = true;
  bool _isAdherenceDirty = true;
  bool _isDosesDirty = true;
  bool _isAllSchedulesDirty = true;
  bool _isLatencyDirty = true;
  List<Map<String, dynamic>>? _cachedLatency;

  AppState({
    required this.medRepo,
    required this.userRepo,
    required this.symptomRepo,
    AudioPlayer? audioPlayer,
  }) : _audioPlayer = audioPlayer ?? AudioPlayer() {
    _notifSub = NotificationService.actionStream.stream
        .listen(_handleNotificationAction);
  }

  // ── Load from storage ──────────────────────────────────────────────
  Future<void> loadFromStorage() async {
    await NotificationService.refreshTimeZone();
    try {
      // Use localized error logging for each repository call to pinpoint failures
      final profileResult = await userRepo.getProfile().catchError((e) {
        appLogger.e('[AppState] Failed to fetch profile', error: e);
        return null;
      });
      final medsResult = await medRepo.getMedicines().catchError((e) {
        appLogger.e('[AppState] Failed to fetch medicines', error: e);
        return <Medicine>[];
      });
      final historyResult = await medRepo.getHistory().catchError((e) {
        appLogger.e('[AppState] Failed to fetch history', error: e);
        return <String, List<DoseEntry>>{};
      });
      final caregiversResult = await userRepo.getCaregivers().catchError((e) {
        appLogger.e('[AppState] Failed to fetch caregivers', error: e);
        return <Caregiver>[];
      });
      final symptomsResult = await symptomRepo.getSymptoms().catchError((e) {
        appLogger.e('[AppState] Failed to fetch symptoms', error: e);
        return <Symptom>[];
      });

      profile = profileResult;
      meds = medsResult;
      history = historyResult;
      caregivers = caregiversResult;
      symptoms = symptomsResult;

      // Other less critical loads
      try {
        streakData = await userRepo.getStreakData();
        takenToday = await medRepo.getTakenToday();
        darkMode = await userRepo.getDarkMode();
      } catch (e) {
        appLogger.w('[AppState] Secondary data load failed', error: e);
      }

      // If user is signed in but Firestore had no data, push our local data up.
      if (AuthService.uid != null &&
          profile == null &&
          meds.isEmpty) {
        _syncLocalToCloud();
      }

      phase = profile != null && profile!.name.isNotEmpty
          ? AppPhase.app
          : AppPhase.onboarding;
      
      _updateNotifications();
      _listenToCaregivers();
      _listenToMonitoring();

      if (AuthService.uid != null) {
        _syncUserProfileFromAuth();
        _initPushNotifications();
      }

      // Check for biometric lock
      if (profile?.biometricEnabled ?? false) {
        isLocked = true;
      }

      _invalidateCache();
      notifyListeners();
    } catch (e, stack) {
      appLogger.e('[AppState] Critical load failure', error: e, stackTrace: stack);
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
    _invalidateCache();
    notifyListeners();
    });
  }

  @override
  void dispose() {
    _cgSub?.cancel();
    // _monitoringSub?.cancel(); // This line was commented out in the original, but if it exists, it should be cancelled.
    _notifSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _listenToMonitoring() {
    // _monitoringSub?.cancel(); // This line was commented out in the original, but if it exists, it should be cancelled.
    final uid = AuthService.uid;
    if (uid == null) return;

    // _monitoringSub = userRepo.getMonitoringPatientsStream().listen((patients) { // This line was commented out in the original
    // monitoredPatients = patients;
    // _invalidateCache();
    // notifyListeners();
    // });
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

  Future<void> incrementScanCount() async {
    if (profile == null) return;
    final newCount = profile!.scansUsed + 1;
    await saveProfile(profile!.copyWith(scansUsed: newCount));
  }

  Future<String?> uploadImage(File file) async {
    try {
      return await medRepo.uploadMedicineImage(file);
    } catch (e) {
      appLogger.e('[AppState] Image upload failed', error: e);
      return null;
    }
  }

  Future<void> unlockPremium() async {
    if (profile == null) return;
    await saveProfile(profile!.copyWith(isPremium: true));
    showToast('Premium Unlocked! Full access granted 💎✨', type: 'success');
  }

  Future<void> logPaywallEvent(String name, {Map<String, Object>? params}) async {
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: params);
      debugPrint('📊 Analytics: $name $params');
    } catch (e) {
      debugPrint('📊 Analytics Error: $e');
    }
  }

  Future<bool> purchasePremium(String packageId) async {
    await logPaywallEvent('paywall_purchase_attempt', params: {'package_id': packageId});
    setPurchasing(true);
    final success = await PurchasesService.purchasePackage(packageId);
    setPurchasing(false);
    if (success) {
      await logPaywallEvent('paywall_purchase_success', params: {'package_id': packageId});
      await unlockPremium();
      return true;
    } else {
      await logPaywallEvent('paywall_purchase_failed', params: {'package_id': packageId});
      showToast('Purchase failed or cancelled', type: 'error');
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    await logPaywallEvent('paywall_restore_attempt');
    setPurchasing(true);
    final success = await PurchasesService.restorePurchases();
    setPurchasing(false);
    if (success && profile != null) {
      await logPaywallEvent('paywall_restore_success');
      await unlockPremium();
      return true;
    } else {
      showToast('No active subscriptions found');
      return false;
    }
  }

  Future<void> manageSubscription() async {
    await PurchasesService.manageSubscriptions();
  }

  // ── Authentication ──────────────────────────────────────────────────
  Future<void> signInWithGoogle() async {
    try {
      final cred = await AuthService.signInWithGoogle();
      if (cred != null) {
        await loadFromStorage(); // Reload everything from Firestore/Local
        _syncLocalToCloud();
        showToast('Signed in with Google');
      }
    } on PlatformException catch (e) {
      showToast('Sign in failed: ${e.message ?? e.code}', type: 'error');
    } catch (e) {
      showToast('Sign in failed. Please try again.', type: 'error');
    }
  }

  Future<void> signInWithApple() async {
    try {
      final cred = await AuthService.signInWithApple();
      if (cred != null) {
        await loadFromStorage();
        _syncLocalToCloud();
        showToast('Signed in with Apple');
      }
    } on PlatformException catch (e) {
      showToast('Sign in failed: ${e.message ?? e.code}', type: 'error');
    } catch (e) {
      showToast('Sign in failed. Please try again.', type: 'error');
    }
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    // Reset local state if needed, or just reload which will detect no UID
    await loadFromStorage();
    showToast('Signed out', type: 'info');
  }

  void _syncUserProfileFromAuth() {
    if (AuthService.currentUser == null) return;
    
    final user = AuthService.currentUser!;
    final currentProfile = profile ?? UserProfile();
    
    // Only update if current profile is empty or placeholder
    String? newName = currentProfile.name.isEmpty ? user.displayName : null;
    String? newPhoto = currentProfile.photoUrl == null ? user.photoURL : null;

    if (newName != null || newPhoto != null) {
      saveProfile(currentProfile.copyWith(
        name: newName ?? currentProfile.name,
        photoUrl: newPhoto ?? currentProfile.photoUrl,
      ));
    }
  }

  Future<void> toggleBiometricLock(bool enabled) async {
    if (profile == null) return;
    
    if (enabled) {
      // Verify they CAN use biometrics before enabling
      final canUse = await BiometricService.canCheckBiometrics();
      if (!canUse) {
        showToast('Biometrics are not available on this device', type: 'error');
        return;
      }
      
      // Force an authentication check before enabling
      final authenticated = await BiometricService.authenticate();
      if (!authenticated) {
        showToast('Authentication failed. Biometric lock not enabled.', type: 'error');
        return;
      }
    }
    
    await saveProfile(profile!.copyWith(biometricEnabled: enabled));
    showToast(enabled ? 'Biometric lock enabled 🛡️' : 'Biometric lock disabled', type: 'info');
  }

  Future<void> unlockApp() async {
    if (!(profile?.biometricEnabled ?? false)) {
      isLocked = false;
      notifyListeners();
      return;
    }

    final authenticated = await BiometricService.authenticate();
    if (authenticated) {
      isLocked = false;
      notifyListeners();
    } else {
      showToast('Authentication failed', type: 'error');
    }
  }

  void lockApp() {
    if (profile?.biometricEnabled ?? false) {
      isLocked = true;
      notifyListeners();
    }
  }

  Future<void> updateAccentColor(String colorHex) async {
    if (profile == null) return;
    await saveProfile(profile!.copyWith(accentColor: colorHex));
    showToast('Theme accent updated! ✨');
  }

  Future<void> updateAppIcon(String iconKey) async {
    if (profile == null) return;
    await saveProfile(profile!.copyWith(appIcon: iconKey));
    
    try {
      if (await FlutterDynamicIconPlus.supportsAlternateIcons) {
        // iconKey would be 'gold', 'blue', 'dark' or null (for default)
        final iconName = iconKey == 'default' ? null : iconKey;
        await FlutterDynamicIconPlus.setAlternateIconName(iconName: iconName);
        showToast('App icon updated! 📲');
      } else {
        showToast('Dynamic icons not supported on this device', type: 'info');
      }
    } catch (e) {
      debugPrint('Failed to update app icon: $e');
      showToast('App icon selection saved ✨');
    }
  }

  Future<void> updateReminderSound(String soundKey) async {
    if (profile == null) return;
    await saveProfile(profile!.copyWith(reminderSound: soundKey));
    _updateNotifications(); // Refresh notifications with new sound
    showToast('Reminder sound updated! 🎵');
    
    // Play the preview automatically when selected
    playReminderSoundPreview(soundKey);
  }

  Future<void> playReminderSoundPreview(String soundKey) async {
    try {
      await _audioPlayer.stop();
      if (soundKey == 'Default') return; // Don't play default for now or use a specific asset
      
      final fileName = soundKey.toLowerCase();
      await _audioPlayer.play(AssetSource('audio/$fileName.mp3'));
    } catch (e) {
      debugPrint('Failed to play sound preview: $e');
    }
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

  // ── Symptoms ───────────────────────────────────────────────────────
  Future<void> logSymptom(Symptom symptom) async {
    try {
      await symptomRepo.saveSymptom(symptom);
      final idx = symptoms.indexWhere((s) => s.id == symptom.id);
      if (idx != -1) {
        symptoms[idx] = symptom;
      } else {
        symptoms.add(symptom);
      }
      notifyListeners();
    } catch (e) {
      appLogger.e('[AppState] logSymptom failed', error: e);
    }
  }

  Future<void> deleteSymptom(String id) async {
    try {
      await symptomRepo.deleteSymptom(id);
      symptoms.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      appLogger.e('[AppState] deleteSymptom failed', error: e);
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
    if (!_isDosesDirty && _cachedDoses != null) return _cachedDoses!;

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
    
    _cachedDoses = items;
    _isDosesDirty = false;
    return items;
  }

  int getStreak() {
    if (!_isStreakDirty && _cachedStreak != null) return _cachedStreak!;

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
    _cachedStreak = s;
    _isStreakDirty = false;
    return s;
  }

  double getAdherenceScore() {
    if (!_isAdherenceDirty && _cachedAdherence != null) return _cachedAdherence!;
    if (history.isEmpty) return 1.0;
    
    int totalScheduled = 0;
    int totalTaken = 0;

    // Look back 30 days
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final dayOfWeek = date.weekday % 7;

      // Count what WAS scheduled on that day
      final scheduledOnDay = meds.where((m) => 
        m.schedule.any((s) => s.enabled && s.days.contains(dayOfWeek))
      ).length;

      if (scheduledOnDay > 0) {
        totalScheduled += scheduledOnDay;
        final entries = history[dateKey] ?? [];
        totalTaken += entries.where((e) => e.taken).length;
      }
    }

    if (totalScheduled == 0) {
      _cachedAdherence = 1.0;
      _isAdherenceDirty = false;
      return 1.0;
    }
    final score = (totalTaken / totalScheduled).clamp(0.0, 1.0);
    _cachedAdherence = score;
    _isAdherenceDirty = false;
    return score;
  }

  List<({Medicine med, ScheduleEntry sched, int idx})> getAllSchedules() {
    if (!_isAllSchedulesDirty && _cachedAllSchedules != null) {
      return _cachedAllSchedules!;
    }

    final items = meds
        .expand((m) => m.schedule
            .asMap()
            .entries
            .map((e) => (med: m, sched: e.value, idx: e.key)))
        .toList();
    items.sort(
        (a, b) => (a.sched.h * 60 + a.sched.m) - (b.sched.h * 60 + b.sched.m));

    _cachedAllSchedules = items;
    _isAllSchedulesDirty = false;
    return items;
  }

  List<Map<String, dynamic>> getTrendData() {
    final List<Map<String, dynamic>> data = [];
    final now = DateTime.now();
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final dayOfWeek = date.weekday % 7;

      final scheduledOnDay = meds.where((m) => 
        m.schedule.any((s) => s.enabled && s.days.contains(dayOfWeek))
      ).length;

      double adherence = 1.0;
      if (scheduledOnDay > 0) {
        final entries = history[dateKey] ?? [];
        adherence = entries.where((e) => e.taken).length / scheduledOnDay;
      }

      data.add({
        'date': dateKey,
        'label': ['S', 'M', 'T', 'W', 'T', 'F', 'S'][date.weekday % 7],
        'value': adherence,
        'scheduled': scheduledOnDay,
      });
    }
    return data;
  }

  int getAdherenceForMed(int medId) {
    final medHistory = history.values
        .expand((e) => e)
        .where((e) => e.medId == medId)
        .toList();
    final takenCount = medHistory.where((e) => e.taken).length;
    final totalDoses = medHistory.length;
    return totalDoses == 0 ? 0 : (takenCount * 100 / totalDoses).round();
  }

  ({int taken, int total}) getHistoryCountForMed(int medId) {
    final medHistory = history.values
        .expand((e) => e)
        .where((e) => e.medId == medId)
        .toList();
    return (taken: medHistory.where((e) => e.taken).length, total: medHistory.length);
  }

  int get unseenAlertsCount => missedAlerts.where((a) => !a.seen).length;

  List<Medicine> getLowMeds() =>
      meds.where((m) => m.count <= m.refillAt && m.count > 0).toList();

  // ── Phase control ──────────────────────────────────────────────────
  void completeOnboarding(UserProfile p) {
    profile = p;
    phase = AppPhase.app; // Go directly to App so user can scan immediately
    saveProfile(p);
    notifyListeners();
  }

  void updateProfile(UserProfile p) {
    profile = p;
    saveProfile(p);
    notifyListeners();
  }

  void updateProfileFromMap(Map<String, dynamic> updates) {
    if (profile == null) return;
    final json = profile!.toJson();
    json.addAll(updates);
    profile = UserProfile.fromJson(json);
    saveProfile(profile!);
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
    _invalidateCache();
    notifyListeners();
  }

  // ── Toggle dose taken ──────────────────────────────────────────────
  final Map<String, bool> _processingDoses = {};

  Future<void> toggleDose(DoseItem dose) async {
    final key = dose.key;
    if (_processingDoses[key] == true) return; // Prevent double-tap
    _processingDoses[key] = true;

    try {
      final key = dose.key;
      final wasTaken = takenToday[key] ?? false;
      takenToday = {...takenToday, key: !wasTaken};

      // Optimistic UI update instantly for perceived speed.
      _invalidateCache();
      notifyListeners();

      final todayKey = todayStr();
      if (!wasTaken) {
        showToast('✓ ${dose.med.name} taken');
        HapticEngine.heavyImpact(); // Premium success haptic
        
        // --- V2: Increment dosesMarked & check for review prompt ---
        final currentDoses = profile?.dosesMarked ?? 0;
        final nextDoses = currentDoses + 1;
        
        saveProfile(profile?.copyWith(
          dosesMarked: nextDoses,
        ) ?? UserProfile(dosesMarked: nextDoses));

        if (nextDoses == 20 && profile?.lastReviewPromptedAt == null) {
          ReviewService.requestReview();
          saveProfile(profile?.copyWith(
            lastReviewPromptedAt: DateTime.now(),
          ) ?? UserProfile(lastReviewPromptedAt: DateTime.now()));
        }
        
        // Update stock
        final medIdx = meds.indexWhere((m) => m.id == dose.med.id);
        if (medIdx != -1) {
          final m = meds[medIdx];
          if (m.count > 0) {
            final updatedMed = m.copyWith(count: m.count - 1);
            meds[medIdx] = updatedMed;
            medRepo.updateMedicine(updatedMed);
          }
        }

        // --- V2: Record history entry with timestamp ---
        final now = DateTime.now();
        final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        
        final entry = DoseEntry(
          medId: dose.med.id,
          label: dose.sched.label,
          time: timeStr,
          taken: true,
          takenAt: now.toIso8601String(),
        );

        history = {
          ...history,
          todayKey: [
            ...(history[todayKey] ?? []).where((e) => e.label != dose.sched.label || e.medId != dose.med.id),
            entry,
          ],
        };
      } else {
        showToast('Dose unmarked', type: 'info');
        
        // Revert stock
        final medIdx = meds.indexWhere((m) => m.id == dose.med.id);
        if (medIdx != -1) {
          final m = meds[medIdx];
          final updatedMed = m.copyWith(count: m.count + 1);
          meds[medIdx] = updatedMed;
          medRepo.updateMedicine(updatedMed);
        }

        // Remove from history if unmarked
        history = {
          ...history,
          todayKey: (history[todayKey] ?? [])
              .where((e) => e.label != dose.sched.label || e.medId != dose.med.id)
              .toList(),
        };
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

  Future<void> nudgePatient(String patientUid) async {
    try {
      await userRepo.nudgePatient(patientUid);
      showToast('Nudge sent! 🔔', type: 'success');
      HapticEngine.selection();
    } catch (e) {
      showToast('Failed to send nudge', type: 'error');
    }
  }

  // ── Medicine CRUD ──────────────────────────────────────────────────
  void addMedicine(Medicine med) {
    final isPremium = profile?.isPremium ?? false;
    if (!isPremium && meds.length >= 3) {
      showToast('Free plan limited to 3 medicines. Upgrade to Pro for unlimited! 💎', type: 'error');
      return;
    }
    meds = [...meds, med];
    medRepo.addMedicine(med);
    _updateNotifications();
    _invalidateCache();
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
    String? intakeInstructions,
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
        intakeInstructions: intakeInstructions,
        schedule: schedule,
      );
      medRepo.updateMedicine(updated);
      return updated;
    }).toList();
    if (updateNotifs) {
      _updateNotifications();
    }
    _invalidateCache();
    notifyListeners();
  }

  void deleteMed(int id) {
    meds = meds.where((m) => m.id != id).toList();
    medRepo.deleteMedicine(id);
    _updateNotifications();
    _invalidateCache();
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


  // ── Dashboard Data & Insights ──────────────────────────────────────

  Future<void> fetchHealthInsights() async {
    if (meds.isEmpty) return;
    loadingInsight = true;
    notifyListeners();

    try {
      final adherence = getAdherenceScore();
      final streak = getStreak();
      final latency = getLatencyData();
      
      final result = await GeminiService.getHealthInsight(
        meds: meds,
        streak: streak,
        adherence: adherence,
        latencyData: latency,
        symptoms: symptoms,
      );

      result.fold(
        (val) {
          healthInsights = val;
        },
        (failure) {
          // Failure handled by service's fallback to static tips,
          // but we could set an error state here if needed.
        },
      );
    } catch (e) {
      debugPrint('Error fetching health insights: $e');
    } finally {
      loadingInsight = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> getLatencyData() {
    if (!_isLatencyDirty && _cachedLatency != null) return _cachedLatency!;

    final List<Map<String, dynamic>> latency = [];
    final now = DateTime.now();

    // Last 7 days
    for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        final entries = history[dateKey] ?? [];

        for (final e in entries) {
            if (e.taken && e.takenAt != null) {
                try {
                    final actual = DateTime.parse(e.takenAt!);
                    // Parse scheduled time from 'HH:mm'
                    final timeParts = e.time.split(':');
                    final scheduled = DateTime(
                        actual.year, actual.month, actual.day, 
                        int.parse(timeParts[0]), int.parse(timeParts[1])
                    );
                    
                    final diffMins = actual.difference(scheduled).inMinutes;
                    latency.add({
                        'date': dateKey,
                        'time': e.time,
                        'latency': diffMins,
                        'medName': meds.firstWhere((m) => m.id == e.medId, orElse: () => Medicine(id: 0, name: 'Unknown', count: 0, totalCount: 0, courseStartDate: '')).name,
                    });
                } catch (_) {}
            }
        }
    }
    _cachedLatency = latency;
    _isLatencyDirty = false;
    return latency;
  }
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
      await userRepo.joinCaregiver(
        patientUid: patientUid,
        cgId: cgId,
        patientName: profile?.name ?? 'Unknown Patient',
        patientAvatar: profile?.avatar ?? '😊',
        relation: 'Connected Patient',
      );
      activateCaregiver(cgId);
      showToast('Successfully joined! Monitoring active ✓');
    } catch (e) {
      showToast('Failed to join: $e', type: 'error');
    }
  }

  Future<void> joinForce(String patientUid, int cgId) async {
    try {
      await userRepo.joinCaregiver(
        patientUid: patientUid,
        cgId: cgId,
        patientName: profile?.name ?? 'Unknown Patient',
        patientAvatar: profile?.avatar ?? '😊',
        relation: 'Connected Patient',
      );
      
      // Ensure it's in our local list or refreshed
      final match = caregivers.where((c) => c.id == cgId).firstOrNull;
      if (match != null) {
        activateCaregiver(cgId);
      } else {
        await userRepo.getCaregivers();
      }

      // Add to monitoring list if we are the one joining (caregiver role)
      await initMonitoring();
      
      showToast('Joined successfully! ✓');
    } catch (_) {
      activateCaregiver(cgId);
    }
  }

  // ── Monitoring Logic ──

  StreamSubscription? _monitoringSub;

  Future<void> initMonitoring() async {
    _monitoringSub?.cancel();
    final uid = AuthService.uid;
    if (uid == null) return;

    _monitoringSub = userRepo.getMonitoringPatientsStream().listen((patients) {
      monitoredPatients = patients;
      notifyListeners();
    });
  }

  // Helper to get real-time patient data (to be used in UI)
  Stream<List<Medicine>> getPatientMeds(String patientUid) {
    return userRepo.getPatientMedsStream(patientUid);
  }

  Stream<Map<String, List<DoseEntry>>> getPatientHistory(String patientUid) {
    return userRepo.getPatientHistoryStream(patientUid);
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
    final isPremium = profile?.isPremium ?? false;
    if (!isPremium) {
      showToast('Streak Freeze is a MedAI Pro feature! Upgrade to protect your progress. 🧊💎', type: 'error');
      return;
    }
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
    healthInsights = [];
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

  void _invalidateCache() {
    _isStreakDirty = true;
    _isAdherenceDirty = true;
    _isDosesDirty = true;
    _isAllSchedulesDirty = true;
    _isLatencyDirty = true;
  }
}
