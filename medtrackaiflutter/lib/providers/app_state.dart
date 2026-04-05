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
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/gemini_service.dart';
import '../services/biometric_service.dart';
import '../core/utils/haptic_engine.dart';
import '../services/analytics_service.dart';
import '../core/utils/logger.dart';
import '../core/utils/result.dart';
import '../widgets/modals/daily_log_sheet.dart';
import '../services/link_service.dart';
import '../services/circle_service.dart';
import 'package:in_app_review/in_app_review.dart';
import '../core/utils/refill_helper.dart';

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

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  final IMedicationRepository medRepo;
  final IUserRepository userRepo;
  final SymptomRepository symptomRepo;

  bool _isDisposed = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (_lifecycleState == AppLifecycleState.resumed) {
      _syncPendingActions();
    }
  }

  bool get isBackgrounded => _lifecycleState == AppLifecycleState.paused || 
                            _lifecycleState == AppLifecycleState.inactive;

  void safeNotifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  AppPhase phase = AppPhase.loading;
  UserProfile? profile;
  List<Medicine> meds = [];
  Map<String, List<DoseEntry>> history = {};
  Map<int, String> medInteractions = {};
  Map<String, String> protectorInsights =
      {}; // NEW (Phase 10): patientUid -> Insight String
  Map<String, bool> takenToday = {};
  StreakData streakData = const StreakData();
  List<Caregiver> caregivers = [];
  List<Map<String, dynamic>> monitoredPatients = [];
  List<MissedAlert> missedAlerts = [];
  bool darkMode = false;
  bool lowStockBannerDismissed = false;
  String? toast;
  String? toastType;
  List<HealthInsight> healthInsights = [];
  List<Symptom> symptoms = [];
  bool hasNewDataForAI = false;
  bool loadingInsight = false;
  bool isLocked = false;
  String language = 'en';
  SymptomAnalysis? symptomAnalysis;
  bool analyzingSymptom = false;
  DateTime? lastInsightFetch;
  // Drug interaction warning (shown after adding a new medicine)
  String? interactionWarning;
  String? interactionWarningMedName;
  StreamSubscription? _cgSub;
  StreamSubscription? _notifSub;
  StreamSubscription? _monitoringSub;
  String? pendingJoinCode;
  final LinkService _linkService = LinkService();
  final AudioPlayer _audioPlayer;

  // ── Growth & Metrics (Phase 12) ────────────────────────────────────
  int _scanCount = 0;
  DateTime? _lastReviewRequest;
  int get scanCount => _scanCount;
  bool _isMutating = false;
  bool get isMutating => _isMutating;
  DateTime? lastSyncedAt;

  // ── PENDING ACTIONS (WAL) ──────────────────────────────────────────
  List<Map<String, dynamic>> _pendingActions = [];
  bool _isSyncing = false;

  Future<void> _loadPendingActions() async {
    _pendingActions = await medRepo.getPendingActions();
  }

  Future<void> _savePendingActions() async {
    await medRepo.savePendingActions(_pendingActions);
  }

  Future<void> _syncPendingActions() async {
    if (_isSyncing || _pendingActions.isEmpty || isBackgrounded) return;
    _isSyncing = true;

    FirebaseCrashlytics.instance
        .log('Syncing ${_pendingActions.length} pending actions');
    final trace = FirebasePerformance.instance.newTrace('wal_sync');
    await trace.start();
    trace.setMetric('queue_size', _pendingActions.length);

    try {
      final toProcess = List<Map<String, dynamic>>.from(_pendingActions);
      for (final action in toProcess) {
        try {
          if (action['type'] == 'takeDose') {
            await FirebaseFunctions.instance
                .httpsCallable('takeDose')
                .call(action['data']);
          }
          _pendingActions.remove(action);
          await _savePendingActions();
          lastSyncedAt = DateTime.now(); // Update sync timestamp
        } catch (e) {
          final errStr = e.toString().toLowerCase();
          appLogger.e('[AppState] Sync failed for $action: $e');

          if (errStr.contains('not-found') || errStr.contains('404')) {
            appLogger.w(
                '[AppState] Cloud Function not found. Suspending sync for this session.');
            break; 
          }

          if (errStr.contains('network') || errStr.contains('unavailable')) {
            trace.putAttribute('exit_reason', 'network_failure');
            break;
          }
          _pendingActions.remove(action);
          await _savePendingActions();
        }
      }
    } finally {
      _isSyncing = false;
      await trace.stop();
      safeNotifyListeners();
    }
  }

  bool get isPremium {
    // Return the profile premium status directly
    return profile?.isPremium ?? false;
  }

  bool _isPurchasing = false;
  bool get isPurchasing => _isPurchasing;

  void setPurchasing(bool value) {
    _isPurchasing = value;
    safeNotifyListeners();
  }

  int getBonusDaysRemaining() {
    if (profile == null) return 0;
    return 0; // Hardened release: Trial system disabled or simplified
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
    WidgetsBinding.instance.addObserver(this);
    _notifSub = NotificationService.actionStream.stream
        .listen(_handleNotificationAction);

    // Deep Link Integration (Phase 7)
    _linkService.onJoinCodeDetected = (code) {
      pendingJoinCode = code;
      appLogger.i('[AppState] Pending join code set: $code');
      if (phase == AppPhase.app && profile != null) {
        joinCaregiver(code);
        pendingJoinCode = null;
      }
      safeNotifyListeners();
    };

    _linkService.init();
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
      // HIPAA-conscious user identification (Anonymous ID)
      AnalyticsService.setUserId(AuthService.uid);
      meds = medsResult;
      history = historyResult;
      caregivers = caregiversResult;
      symptoms = symptomsResult;

      // Other less critical loads
      try {
        final prefs = await medRepo.getPrefs();
        _scanCount = prefs.getInt('scan_count') ?? 0;
        final lastRev = prefs.getString('last_review_request');
        if (lastRev != null) _lastReviewRequest = DateTime.tryParse(lastRev);

        takenToday = await medRepo.getTakenToday();
        darkMode = await userRepo.getDarkMode();
        language = await userRepo.getLanguage();
      } catch (e) {
        appLogger.w('[AppState] Secondary data load failed', error: e);
      }

      // If user is signed in but Firestore had no data, push our local data up.
      if (AuthService.uid != null && profile == null && meds.isEmpty) {
        _syncLocalToCloud();
      }

      if (profile != null) {
        phase = AppPhase.app;

        // Handle deferred deep link join codes
        if (pendingJoinCode != null && AuthService.uid != null) {
          appLogger.i(
              '[AppState] Processing deferred join code on load: $pendingJoinCode');
          joinCaregiver(pendingJoinCode!);
          pendingJoinCode = null;
        }
      } else {
        phase = AppPhase.onboarding;
      }

      _updateNotifications();
      _listenToCaregivers();
      _listenToProfileChanges();
      _listenToMonitoring();

      // Initialize WAL (Restore)
      await _loadPendingActions();
      Timer.periodic(const Duration(minutes: 1), (_) => _syncPendingActions());
      _syncPendingActions();

      if (AuthService.uid != null) {
        _syncUserProfileFromAuth();
        _initPushNotifications();
      }

      // WAL initialization and sync handled below
      _invalidateCache();
      if (profile?.biometricEnabled ?? false) {
        isLocked = true;
      }

      _invalidateCache();
      safeNotifyListeners();
    } catch (e, stack) {
      appLogger.e('[AppState] Critical load failure',
          error: e, stackTrace: stack);
      phase = AppPhase.onboarding;
      safeNotifyListeners();
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
      safeNotifyListeners();
    });
  }

  StreamSubscription? _profileSub;
  void _listenToProfileChanges() {
    _profileSub?.cancel();
    _profileSub = userRepo.getProfileStream().listen((updatedProfile) {
      if (updatedProfile == null) return;

      // Check for Nudges
      if (profile != null && updatedProfile.lastNudgeAt != null) {
        final lastOld = profile?.lastNudgeAt;
        final lastNew = updatedProfile.lastNudgeAt;

        if (lastNew != lastOld && lastNew != null) {
          // WE GOT NUDGED!
          HapticEngine.heavyImpact();
          _audioPlayer.play(AssetSource('sounds/nudge.mp3')).catchError((_) {});
          showToast('Family is checking on you! Please take your meds. 💙',
              type: 'info');
        }
      }

      profile = updatedProfile;
      safeNotifyListeners();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _cgSub?.cancel();
    _notifSub?.cancel();
    _monitoringSub?.cancel();
    _profileSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void setLanguage(String lang) {
    language = lang;
    userRepo.saveLanguage(lang);
    safeNotifyListeners();
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
    phase = AppPhase.app;

    // Ensure AppState language is synced with profile preferredLanguage
    if (p.preferredLanguage != language) {
      language = p.preferredLanguage;
      userRepo.saveLanguage(language);
    }

    await userRepo.saveProfile(p);

    _updateNotifications();
    if (pendingJoinCode != null) {
      appLogger.i(
          '[AppState] Processing deferred join code on login: $pendingJoinCode');
      joinCaregiver(pendingJoinCode!);
      pendingJoinCode = null;
    }

    _updateNotifications();
    safeNotifyListeners();
  }

  /// Increments the scan counter and evaluates if the user should be
  /// prompted for a review. Call this after successful AI operations.
  Future<void> incrementScanCount() async {
    if (profile == null) return;

    // 1. Profile Persistence (Existing logic)
    final newCount = profile!.scansUsed + 1;
    await saveProfile(profile!.copyWith(scansUsed: newCount));

    // 2. Growth Milestone Tracking (Phase 12)
    _scanCount++;
    final prefs = await medRepo.getPrefs();
    await prefs.setInt('scan_count', _scanCount);

    // Logic: Request review on specific milestones (e.g., 3rd and 10th successful scan)
    if ([3, 10, 50].contains(_scanCount)) {
      triggerReviewIfEligible();
    }
  }

  Future<String?> uploadImage(File file) async {
    try {
      return await medRepo.uploadMedicineImage(file);
    } catch (e) {
      appLogger.e('[AppState] Image upload failed', error: e);
      return null;
    }
  }

  Future<void> unlockPremium({String? packageId}) async {
    if (profile != null) {
      if (packageId != null) {
        AnalyticsService.logSubscriptionStart(packageId);
      }
      await saveProfile(profile!.copyWith(isPremium: true));
      showToast('Premium Unlocked! Full access granted 💎✨', type: 'success');
    }
  }

  Future<void> logPaywallEvent(String name,
      {Map<String, Object>? params}) async {
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: params);
      debugPrint('📊 Analytics: $name $params');
    } catch (e) {
      debugPrint('📊 Analytics Error: $e');
    }
  }

  Future<bool> purchasePremium(String packageId) async {
    await logPaywallEvent('paywall_purchase_attempt',
        params: {'package_id': packageId});
    setPurchasing(true);
    final success = await PurchasesService.purchasePackage(packageId);
    setPurchasing(false);
    if (success) {
      await logPaywallEvent('paywall_purchase_success',
          params: {'package_id': packageId});
      await unlockPremium(packageId: packageId);
      return true;
    } else {
      await logPaywallEvent('paywall_purchase_failed',
          params: {'package_id': packageId});
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
        showToast('Authentication failed. Biometric lock not enabled.',
            type: 'error');
        return;
      }
    }

    await saveProfile(profile!.copyWith(biometricEnabled: enabled));
    showToast(
        enabled ? 'Biometric lock enabled 🛡️' : 'Biometric lock disabled',
        type: 'info');
  }

  Future<void> unlockApp() async {
    if (!(profile?.biometricEnabled ?? false)) {
      isLocked = false;
      safeNotifyListeners();
      return;
    }

    final authenticated = await BiometricService.authenticate();
    if (authenticated) {
      isLocked = false;
      safeNotifyListeners();
    } else {
      showToast('Authentication failed', type: 'error');
    }
  }

  void lockApp() {
    if (profile?.biometricEnabled ?? false) {
      isLocked = true;
      safeNotifyListeners();
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
    showToast('App icon choice saved! ✨');

    // Note: Native dynamic icon switching requires specific platform setup (Info.plist/AndroidManifest)
    // and is currently scoped for a future update.
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
      if (soundKey == 'Default') {
        return; // Don't play default for now or use a specific asset
      }

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
              isShabbatMode: profile?.shabbatMode ?? false,
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
    if (_isMutating) return;
    _isMutating = true;
    try {
      await symptomRepo.saveSymptom(symptom);
      final idx = symptoms.indexWhere((s) => s.id == symptom.id);
      if (idx != -1) {
        symptoms[idx] = symptom;
      } else {
        symptoms.add(symptom);
      }
      _invalidateCache();
      safeNotifyListeners();

      analyzingSymptom = true;
      symptomAnalysis = null;
      safeNotifyListeners();

      final result = await GeminiService.analyzeSymptom(symptom, meds);
      if (result is Success<SymptomAnalysis>) {
        symptomAnalysis = result.value;
      }
      analyzingSymptom = false;
      HapticEngine.light();
      showToast('Symptom logged');
    } catch (e) {
      appLogger.e('[AppState] logSymptom failed', error: e);
      analyzingSymptom = false;
    } finally {
      _isMutating = false;
      safeNotifyListeners();
    }
  }

  Future<void> deleteSymptom(String id) async {
    if (_isMutating) return;
    _isMutating = true;
    try {
      await symptomRepo.deleteSymptom(id);
      symptoms.removeWhere((s) => s.id == id);
      _invalidateCache();
      HapticEngine.selection();
      showToast('Symptom removed', type: 'info');
    } catch (e) {
      appLogger.e('[AppState] deleteSymptom failed', error: e);
    } finally {
      _isMutating = false;
      safeNotifyListeners();
    }
  }

  void executeStepAction(String step, BuildContext context) {
    HapticEngine.selection();
    final action = step.toLowerCase();

    if (action.contains('log')) {
      DailyLogSheet.show(context);
    } else if (action.contains('insight') || action.contains('refresh')) {
      fetchHealthInsights();
      showToast('Refreshing health insights... ✨', type: 'info');
    } else if (action.contains('med') || action.contains('detail')) {
      // Potentially navigate to meds tab or show details
      showToast('Check your Medications tab for details! 💊');
    } else if (action.contains('streak')) {
      showToast('Current Streak: ${getStreak()} days! 🔥');
    } else if (action.contains('doctor')) {
      showToast('Always consult your physician for medical concerns. 👨‍🏼‍⚕️');
    } else {
      showToast('Action noted: $step');
    }
  }

  void handleInsightAction(String actionId, BuildContext context) {
    HapticEngine.selection();
    switch (actionId) {
      case 'ACTION_VIEW_LOG':
        DailyLogSheet.show(context);
        break;
      case 'ACTION_OPEN_STREAK':
        // This usually happens in HomeTab via state. Trigger a toast for now
        // if we can't easily reach the state toggle here.
        showToast('Check your streak in the Home tab! 🔥');
        break;
      case 'ACTION_REFRESH_INSIGHTS':
        fetchHealthInsights();
        break;
      default:
        debugPrint('Unknown AI Action: $actionId');
    }
  }

  void clearInteractionWarning() {
    interactionWarning = null;
    interactionWarningMedName = null;
    safeNotifyListeners();
  }

  // ── Toast ─────────────────────────────────────────────────────────
  void showToast(String message, {String type = 'success'}) {
    toast = message;
    toastType = type;
    
    // Industrial logic: Trigger haptics based on type
    if (type == 'error' || type == 'warning') {
      HapticEngine.selection(); // Or a custom 'warning' haptic if available
    } else if (type == 'success') {
      HapticEngine.light();
    }

    safeNotifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      toast = null;
      safeNotifyListeners();
    });
  }

  // ── Low Stock Banner Dismissal ────────────────────────────────────
  void dismissLowStockBanner() {
    lowStockBannerDismissed = true;
    safeNotifyListeners();
  }

  // ── Snooze Dose (30 min, schedules real notification) ─────────────
  void snoozeDose(DoseItem dose, int minutes) {
    final snoozeTime = DateTime.now().add(Duration(minutes: minutes));
    final payload = 'take|${dose.med.id}|${dose.sched.h}|${dose.sched.m}|${dose.sched.label}';
    NotificationService.scheduleOneOffReminder(
      id: dose.med.id + 600000 + minutes,
      title: '⏰ Snoozed: ${dose.med.name}',
      body: 'Time to take your ${dose.sched.label} dose (snoozed)',
      scheduledDate: snoozeTime,
      payload: payload,
    );
    showToast('⏱ Snoozed ${dose.med.name} for $minutes min', type: 'info');
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
    if (!_isAdherenceDirty && _cachedAdherence != null) {
      return _cachedAdherence!;
    }
    if (history.isEmpty) return 1.0;

    int totalScheduled = 0;
    int totalTaken = 0;

    // Look back 30 days
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final dayOfWeek = date.weekday % 7;

      // Count what WAS scheduled on that day
      final scheduledOnDay = meds
          .where((m) =>
              m.schedule.any((s) => s.enabled && s.days.contains(dayOfWeek)))
          .length;

      if (scheduledOnDay > 0) {
        totalScheduled += scheduledOnDay;
        final dailyEntries = history[dateKey] ?? [];
        // Only count taken doses that are NOT PRN
        totalTaken += dailyEntries
            .where((e) => e.taken && !e.label.startsWith('PRN-'))
            .length;
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
      final dateKey =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final dayOfWeek = date.weekday % 7;

      final scheduledOnDay = meds
          .where((m) =>
              m.schedule.any((s) => s.enabled && s.days.contains(dayOfWeek)))
          .length;

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
    final medHistory =
        history.values.expand((e) => e).where((e) => e.medId == medId).toList();
    final takenCount = medHistory.where((e) => e.taken).length;
    final totalDoses = medHistory.length;
    return totalDoses == 0 ? -1 : (takenCount * 100 / totalDoses).round();
  }

  ({int taken, int total}) getHistoryCountForMed(int medId) {
    final medHistory =
        history.values.expand((e) => e).where((e) => e.medId == medId).toList();
    return (
      taken: medHistory.where((e) => e.taken).length,
      total: medHistory.length
    );
  }

  int get unseenAlertsCount => missedAlerts.where((a) => !a.seen).length;

  List<Medicine> getLowMeds() =>
      meds.where((m) => m.count <= m.refillAt && m.count > 0).toList();

  // ── Phase control ──────────────────────────────────────────────────
  void completeOnboarding(UserProfile p) {
    profile = p;
    phase = AppPhase.app; // Go directly to App so user can scan immediately
    saveProfile(p);
    safeNotifyListeners();
  }

  void updateProfile(UserProfile p) {
    profile = p;
    saveProfile(p);
    safeNotifyListeners();
  }

  void updateProfileFromMap(Map<String, dynamic> updates) {
    if (profile == null) return;
    final json = profile!.toJson();
    json.addAll(updates);
    profile = UserProfile.fromJson(json);
    saveProfile(profile!);
    safeNotifyListeners();
  }

  void skipAuth() {
    phase = AppPhase.app;
    safeNotifyListeners();
  }

  // ── Dark mode ──────────────────────────────────────────────────────
  void toggleDarkMode() {
    darkMode = !darkMode;
    userRepo.saveDarkMode(darkMode);
    _invalidateCache();
    safeNotifyListeners();
  }

  // ── Toggle dose taken ──────────────────────────────────────────────
  final Map<String, bool> _processingDoses = {};

  
  /// Specifically record a scheduled dose as taken.
  Future<void> takeDose(int medId, int index) async {
    final med = meds.firstWhere((m) => m.id == medId);
    final sched = med.schedule[index];
    final doseItem = DoseItem(
      med: med,
      sched: sched,
      key: '${med.id}-${sched.label}',
    );

    if (!(takenToday[doseItem.key] ?? false)) {
      await toggleDose(doseItem);
    }
  }

  Future<void> toggleDose(DoseItem dose) async {
    final key = dose.key;
    if (_isMutating || _processingDoses[key] == true) return; 
    _isMutating = true;
    _processingDoses[key] = true;

    try {
      final key = dose.key;
      final wasTaken = takenToday[key] ?? false;
      takenToday = {...takenToday, key: !wasTaken};

      _invalidateCache();
      safeNotifyListeners();

      final todayKey = todayStr();
      if (!wasTaken) {
        showToast('✓ ${dose.med.name} taken');
        HapticEngine.heavyImpact(); // Premium success haptic

        // 1. Local Optimistic Update (Inventory)
        final medIdx = meds.indexWhere((m) => m.id == dose.med.id);
        if (medIdx != -1) {
          final m = meds[medIdx];
          if (m.count > 0) {
            final updatedRefill = m.refillInfo?.copyWith(
              currentInventory: (m.refillInfo!.currentInventory - 1)
                  .clamp(0, m.refillInfo!.totalQuantity),
            );
            final updatedMed = m.copyWith(
              count: m.count - 1,
              refillInfo: updatedRefill ?? m.refillInfo,
            );
            meds[medIdx] = updatedMed;
            medRepo.updateMedicine(updatedMed); // Offline repo update
          }
        }

        // 2. Local Optimistic Update (History)
        final now = DateTime.now();
        final timeStr =
            '${dose.sched.h.toString().padLeft(2, '0')}:${dose.sched.m.toString().padLeft(2, '0')}';
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
            ...(history[todayKey] ?? []).where(
                (e) => e.label != dose.sched.label || e.medId != dose.med.id),
            entry,
          ],
        };

        hasNewDataForAI = true;
        triggerReviewIfEligible();

        // 3. Queue for Cloud Sync (WAL)
        final action = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'type': 'takeDose',
          'data': {
            'medId': dose.med.id,
            'dayKey': todayKey,
            'doseEntry': entry.toJson(),
          }
        };
        _pendingActions.add(action);
        _savePendingActions();
        _syncPendingActions(); // Try sync immediately
      } else {
        // Unmarking logic (Legacy path for now)
        showToast('Dose unmarked', type: 'info');

        // Revert stock — restore both count AND refillInfo.currentInventory
        final medIdx = meds.indexWhere((m) => m.id == dose.med.id);
        if (medIdx != -1) {
          final m = meds[medIdx];
          final updatedRefill = m.refillInfo?.copyWith(
            currentInventory: (m.refillInfo!.currentInventory + 1)
                .clamp(0, m.refillInfo!.totalQuantity),
          );
          final updatedMed = m.copyWith(
            count: m.count + 1,
            refillInfo: updatedRefill ?? m.refillInfo,
          );
          meds[medIdx] = updatedMed;
          medRepo.updateMedicine(updatedMed);
        }

        // Remove from history if unmarked
        history = {
          ...history,
          todayKey: (history[todayKey] ?? [])
              .where(
                  (e) => e.label != dose.sched.label || e.medId != dose.med.id)
              .toList(),
        };
      }

      await _persistAll(dateKey: todayKey, updateNotifs: true);
    } finally {
      _processingDoses.remove(key);
      _isMutating = false;
      safeNotifyListeners();
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
      showToast('Nudge sent! 💨');
      HapticEngine.selection();
    } catch (e) {
      appLogger.e('[AppState] nudgePatient failed', error: e);
    }
  }

  // ── Medicine CRUD ──────────────────────────────────────────────────
  void addMedicine(Medicine med, {BuildContext? context}) {
    if (_isMutating) return;
    _isMutating = true;
    
    final isPremium = profile?.isPremium ?? false;
    if (!isPremium && meds.length >= 3) {
      showToast(
          'Free plan limited to 3 medicines. Upgrade to Pro for unlimited! 💎',
          type: 'error');
      _isMutating = false;
      safeNotifyListeners();
      return;
    }
    
    meds = [...meds, med];
    medRepo.addMedicine(med);
    _updateNotifications();
    _invalidateCache();
    
    HapticEngine.heavyImpact(); 
    showToast('Medicine added');
    
    _isMutating = false;
    safeNotifyListeners();

    // Async drug interaction check
    _checkDrugInteractionsAsync(med);
  }

  Future<void> _checkDrugInteractionsAsync(Medicine newMed) async {
    if (meds.length < 2) return; // Only 1 med, no interactions possible
    try {
      final otherMeds = meds.where((m) => m.id != newMed.id).toList();
      final result = await GeminiService.checkInteractions(
        newMed: newMed,
        existingMeds: otherMeds,
      );
      if (result != null && result.isNotEmpty) {
        // Trigger an in-app alert with the interaction warning
        interactionWarning = result;
        interactionWarningMedName = newMed.name;
        safeNotifyListeners();
      }
    } catch (e) {
      appLogger.w('[AppState] Drug interaction check failed: $e');
    }
  }

  /// Manually triggers an AI Safety Scan for a specific medicine.
  Future<Result<AISafetyProfile>> analyzeMedicineSafety(Medicine med) async {
    final result = await GeminiService.generateSafetyProfile(
        med: med, country: profile?.country ?? '');

    if (result is Success<AISafetyProfile>) {
      // Create a copy of the medicine with the new AI safety profile
      final updatedMed = med.copyWith(aiSafetyProfile: result.data);

      // Update local state
      final idx = meds.indexWhere((m) => m.id == med.id);
      if (idx != -1) {
        final newMeds = [...meds];
        newMeds[idx] = updatedMed;
        meds = newMeds;

        // Save to DB
        await medRepo.updateMedicine(updatedMed);
        safeNotifyListeners();
      }
    }
    return result;
  }

  Future<void> logPrnDose(Medicine med) async {
    final medIdx = meds.indexWhere((m) => m.id == med.id);
    if (medIdx == -1) return;

    if (_isMutating) return;
    _isMutating = true;

    try {
      final now = DateTime.now();
      final todayKey = todayStr();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final prnLabel = 'PRN-$timeStr';

      // Record in history
      history = {
        ...history,
        todayKey: [
          ...(history[todayKey] ?? []),
          DoseEntry(
            medId: med.id,
            label: prnLabel,
            time: timeStr,
            taken: true,
            takenAt: now.toIso8601String(),
          ),
        ],
      };

      // Decrement stock
      final m = meds[medIdx];
      if (m.count > 0) {
        final updatedRefill = m.refillInfo?.copyWith(
          currentInventory: (m.refillInfo!.currentInventory - 1)
              .clamp(0, m.refillInfo!.totalQuantity),
        );
        final updatedMed = m.copyWith(
          count: m.count - 1,
          refillInfo: updatedRefill ?? m.refillInfo,
        );
        meds[medIdx] = updatedMed;
        medRepo.updateMedicine(updatedMed);
      }

      await _persistAll(dateKey: todayKey);
      hasNewDataForAI = true;
      _invalidateCache();
      safeNotifyListeners();
      HapticEngine.heavyImpact();
      showToast('✓ ${med.name} PRN dose logged');
    } finally {
      _isMutating = false;
      safeNotifyListeners();
    }
  }

  /// Undo a PRN dose by removing it from history and restoring inventory.
  Future<void> undoPrnDose(int medId, String timeStr) async {
    final todayKey = todayStr();
    final List<DoseEntry> entries = List.from(history[todayKey] ?? []);
    final idx = entries.indexWhere((e) =>
        e.medId == medId && e.time == timeStr && e.label.startsWith('PRN-'));

    if (idx == -1) return;

    if (_isMutating) return;
    _isMutating = true;
    try {
      entries.removeAt(idx);
      history = {
        ...history,
        todayKey: entries,
      };

      // Increment stock back
      final medIdx = meds.indexWhere((m) => m.id == medId);
      if (medIdx != -1) {
        final m = meds[medIdx];
        final updatedRefill = m.refillInfo?.copyWith(
          currentInventory: (m.refillInfo!.currentInventory + 1)
              .clamp(0, m.refillInfo!.totalQuantity),
        );
        final updatedMed = m.copyWith(
          count: m.count + 1,
          refillInfo: updatedRefill ?? m.refillInfo,
        );
        meds[medIdx] = updatedMed;
        medRepo.updateMedicine(updatedMed);
      }

      await _persistAll(dateKey: todayKey);
      _invalidateCache();
      safeNotifyListeners();
      HapticEngine.selection();
      showToast('PRN dose removed', type: 'info');
    } finally {
      _isMutating = false;
      safeNotifyListeners();
    }
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
    if (_isMutating) return;
    _isMutating = true;
    
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
    HapticEngine.selection();
    _isMutating = false;
    safeNotifyListeners();
  }

  void updateMedDirect(Medicine updated) {
    if (_isMutating) return;
    _isMutating = true;
    
    meds = meds.map((m) => m.id == updated.id ? updated : m).toList();
    medRepo.updateMedicine(updated);
    _updateNotifications();
    _invalidateCache();
    HapticEngine.selection();
    
    _isMutating = false;
    safeNotifyListeners();
  }

  void deleteMed(int id) async {
    if (_isMutating) return;
    _isMutating = true;
    
    meds = meds.where((m) => m.id != id).toList();
    await medRepo.deleteMedicine(id);
    _updateNotifications();
    _invalidateCache();
    HapticEngine.selection(); 
    showToast('Medicine removed', type: 'warning');
    
    _isMutating = false;
    safeNotifyListeners();
  }

  /// Archive a completed medicine course (hides it from active list).

  /// Skip a specific dose without marking it taken.
  Future<void> skipDose(DoseItem dose) async {
    if (_isMutating) return;
    _isMutating = true;
    
    final key = dose.key;
    final todayKey = todayStr();
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
    await _persistAll(dateKey: todayKey);
    HapticEngine.selection();
    showToast('Dose skipped', type: 'info');
    
    _isMutating = false;
    safeNotifyListeners();
  }

  // ── Dashboard Data & Insights ──────────────────────────────────────

  Future<void> fetchHealthInsights({bool force = false}) async {
    if (meds.isEmpty || isBackgrounded) return;

    // Cache check: Skip if fetched in the last 15 minutes unless forced
    if (!force &&
        lastInsightFetch != null &&
        DateTime.now().difference(lastInsightFetch!).inMinutes < 15) {
      return;
    }

    loadingInsight = true;
    safeNotifyListeners();

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
        country: profile?.country ?? '',
      );

      result.fold(
        (val) {
          healthInsights = val;
          hasNewDataForAI = false;
          lastInsightFetch = DateTime.now();
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
      safeNotifyListeners();
    }
  }

  List<Map<String, dynamic>> getLatencyData() {
    if (!_isLatencyDirty && _cachedLatency != null) return _cachedLatency!;

    final List<Map<String, dynamic>> latency = [];
    final now = DateTime.now();

    // Last 7 days
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final entries = history[dateKey] ?? [];

      for (final e in entries) {
        if (e.taken && e.takenAt != null) {
          try {
            final actual = DateTime.parse(e.takenAt!);
            // Parse scheduled time from 'HH:mm'
            final timeParts = e.time.split(':');
            final scheduled = DateTime(actual.year, actual.month, actual.day,
                int.parse(timeParts[0]), int.parse(timeParts[1]));

            final diffMins = actual.difference(scheduled).inMinutes;
            latency.add({
              'date': dateKey,
              'time': e.time,
              'latency': diffMins,
              'medName': meds
                  .firstWhere((m) => m.id == e.medId,
                      orElse: () => Medicine(
                          id: 0,
                          name: 'Unknown',
                          count: 0,
                          totalCount: 0,
                          courseStartDate: ''))
                  .name,
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

  void updateSchedule(int medId, int idx, ScheduleEntry s) {
    final med = meds.firstWhere((m) => m.id == medId);
    final newSched = [...med.schedule];
    newSched[idx] = s;
    updateMed(medId, schedule: newSched);
  }

  // ── Caregivers ─────────────────────────────────────────────────────
  void addCaregiver(Caregiver cg) {
    caregivers = [...caregivers, cg];
    userRepo.saveCaregivers(caregivers);
    safeNotifyListeners();
    showToast('${cg.name} added as caregiver');
  }

  /// Write invite to Firestore so any device can look it up via the 6-char code.
  Future<String> createInvite(Caregiver cg) async {
    final uid = AuthService.uid;
    if (uid == null) return '';
    try {
      final code = await CircleService.generateInviteCode(
        patientName: profile?.name ?? 'Member',
        patientAvatar: profile?.avatar ?? '👤',
        relation: cg.relation,
        alertDelay: cg.alertDelay,
      );

      if (code.isNotEmpty) {
        // Update the caregiver with the generated code
        caregivers = caregivers.map((c) {
          if (c.id == cg.id) {
            return c.copyWith(inviteCode: code);
          }
          return c;
        }).toList();
        userRepo.saveCaregivers(caregivers);
        safeNotifyListeners();
      }

      return code;
    } catch (e) {
      appLogger.e('[AppState] createInvite failed', error: e);
      return '';
    }
  }

  /// NEW (Phase 10): Fetch AI analysis for a family member.
  Future<void> fetchProtectorInsight(Caregiver cg, List<Medicine> meds,
      Map<String, List<DoseEntry>> history) async {
    // Only fetch if missing or user is Pro
    if (protectorInsights.containsKey(cg.patientUid)) return;

    appLogger.d('[AppState] Fetching AI Protector Insight for ${cg.name}');
    try {
      final insight = await GeminiService.getProtectorInsight(
        patientName: cg.name,
        meds: meds,
        history: history,
      );
      protectorInsights[cg.patientUid] = insight;
      safeNotifyListeners();
    } catch (e) {
      appLogger.w('[AppState] fetchProtectorInsight failed: $e');
    }
  }

  /// Look up and join a care team via invite code.
  Future<void> joinCareTeam(String code) async {
    if (AuthService.uid == null) {
      showToast('Authentication required', type: 'error');
      return;
    }

    final trace = FirebasePerformance.instance.newTrace('join_care_team');
    await trace.start();
    FirebaseCrashlytics.instance
        .log('User joining care team via CircleService: $code');

    try {
      final result = await CircleService.verifyAndJoin(code);

      if (result['success'] == true) {
        trace.putAttribute('status', 'success');
        showToast('Joined ${result['patientName']}\'s care team! ✓');

        // Refresh caregivers and monitoring
        _listenToCaregivers();
        _listenToMonitoring();
      }
    } catch (e) {
      trace.putAttribute('status', 'error');
      appLogger.e('[AppState] joinCareTeam failed', error: e);
      showToast(e.toString().replaceAll('Exception: ', ''), type: 'error');
    } finally {
      await trace.stop();
    }
  }

  void activateCaregiver(int id) {
    caregivers = caregivers
        .map((c) => c.id == id ? c.copyWith(status: 'active') : c)
        .toList();
    userRepo.saveCaregivers(caregivers);
    safeNotifyListeners();
    showToast('Caregiver activated ✓');
  }

  void removeCaregiver(int id) {
    caregivers = caregivers.where((c) => c.id != id).toList();
    userRepo.saveCaregivers(caregivers);
    safeNotifyListeners();
    showToast('Caregiver removed', type: 'warning');
  }

  Future<void> joinCaregiver(String code) async {
    try {
      final result = await CircleService.verifyAndJoin(code);
      if (result['success'] == true) {
        showToast('Successfully joined ${result['patientName']}\'s circle! ✓');
        _updateNotifications(); // Refresh
        _listenToCaregivers(); // Refresh
        _listenToMonitoring(); // Refresh
      }
    } catch (e) {
      showToast('Join failed: ${e.toString().replaceAll('Exception: ', '')}',
          type: 'error');
    }
  }

  // ── Monitoring Logic ──

  Future<void> _listenToMonitoring() async {
    _monitoringSub?.cancel();
    final uid = AuthService.uid;
    if (uid == null) return;

    appLogger.i('[AppState] Initializing monitoring stream for $uid');
    _monitoringSub = userRepo.getMonitoringPatientsStream().listen((patients) {
      appLogger.d('[AppState] Received ${patients.length} monitoring updates');
      monitoredPatients = patients;
      safeNotifyListeners();
    }, onError: (e) {
      appLogger.e('[AppState] Monitoring stream error', error: e);
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
    safeNotifyListeners();
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
    safeNotifyListeners();
  }

  void simulateMissedDose() {
    showToast('Missed dose simulation not available in this version',
        type: 'info');
  }

  // ── Streak Freeze ──────────────────────────────────────────────────
  void useStreakFreeze() {
    final isPremium = profile?.isPremium ?? false;
    if (!isPremium) {
      showToast(
          'Streak Freeze is a MedAI Pro feature! Upgrade to protect your progress. 🧊💎',
          type: 'error');
      return;
    }
    streakData = streakData.copyWith(frozen: true, freezeUsedWeek: true);
    userRepo.saveStreakData(streakData);
    safeNotifyListeners();
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
    safeNotifyListeners();
  }

  // ── Reset taken today at midnight ──────────────────────────────────
  void resetTakenToday() {
    takenToday = {};
    medRepo.saveTakenToday({});
    safeNotifyListeners();
  }

  // ── Data Export ─────────────────────────────────────────────────────
  String exportDataCSV() {
    final sb = StringBuffer();
    sb.writeln('Type,ID,Name,Label,Details,Taken/Severity,Timestamp/Notes');

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

    // Symptoms (Phase 13: Live Integration)
    for (final s in symptoms) {
      sb.writeln(
          'Symptom,${s.id},"${s.name}","Severity: ${s.severity}",,"${s.severity}","${s.timestamp} - ${s.notes ?? ''}"');
    }

    return sb.toString();
  }

  // ── Health Data Helpers (Phase 13: Live Integration) ──────────────
  
  /// Returns a normalized list of severity scores (0.0 to 1.0) for the last 7 logs.
  List<double> getRecentSymptomStats() {
    if (symptoms.isEmpty) return [0.5, 0.4, 0.6, 0.3, 0.5, 0.4, 0.5];
    
    // Get last 7 symptoms, sorted by date
    final sorted = List<Symptom>.from(symptoms)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final last7 = sorted.length > 7 ? sorted.sublist(sorted.length - 7) : sorted;
    
    // Map severity (1-10) to 0.0-1.0
    final data = last7.map((s) => s.severity / 10.0).toList();
    
    // Pad if less than 7
    while (data.length < 7) {
      data.insert(0, 0.0);
    }
    return data;
  }

  /// Returns a summary of the most recent health state.
  Map<String, String> getMoodSummary({
    required String good,
    required String stable,
    required String severe,
    required String empty,
  }) {
    if (symptoms.isEmpty) {
      return {
        'value': empty,
        'unit': '',
        'sublabel': 'No recent logs',
      };
    }

    final latest = List<Symptom>.from(symptoms)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final s = latest.last;

    String val = stable;
    if (s.severity <= 3) val = good;
    if (s.severity >= 8) val = severe;

    return {
      'value': val,
      'unit': '(${s.severity}/10)',
      'sublabel': 'Last: ${s.name}',
    };
  }

  // ── Inventory Helpers (Phase 14: Stock Integration) ──────────────

  /// Returns the number of medications that are critically low.
  int getLowStockCount() {
    return meds.where((m) => RefillHelper.isCriticallyLow(m)).length;
  }

  /// Returns a list of medications sorted by their estimated exhaustion date.
  /// Only includes medications with an active schedule.
  List<Medicine> getRefillForecast() {
    final list = meds.where((m) => m.schedule.isNotEmpty).toList();
    list.sort((a, b) {
      final dateA = RefillHelper.calculateExhaustionDate(a) ?? DateTime(2100);
      final dateB = RefillHelper.calculateExhaustionDate(b) ?? DateTime(2100);
      return dateA.compareTo(dateB);
    });
    return list;
  }

  void _invalidateCache() {
    _isStreakDirty = true;
    _isAdherenceDirty = true;
    _isDosesDirty = true;
    _isAllSchedulesDirty = true;
    _isLatencyDirty = true;
  }

  // ── Smart Review Engine (Phase 12) ──
  // logic merged into incrementScanCount above.

  Future<void> triggerReviewIfEligible() async {
    final InAppReview inAppReview = InAppReview.instance;

    // Reliability: Check if we've asked in the last 30 days to avoid fatigue
    if (_lastReviewRequest != null) {
      if (DateTime.now().difference(_lastReviewRequest!).inDays < 30) {
        return;
      }
    }

    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        _lastReviewRequest = DateTime.now();
        final prefs = await medRepo.getPrefs();
        await prefs.setString(
            'last_review_request', _lastReviewRequest!.toIso8601String());
        appLogger
            .i('[AppState] Smart Review requested at milestone $_scanCount');
      }
    } catch (e) {
      appLogger.e('[AppState] Failed to request review: $e');
    }
  }

  /// Reset medication stock to its original total quantity.
  Future<void> refillMedication(int medId) async {
    final idx = meds.indexWhere((m) => m.id == medId);
    if (idx == -1) return;

    final m = meds[idx];
    final updatedMed = m.copyWith(
      count: m.totalCount,
      refillInfo: m.refillInfo?.copyWith(
        currentInventory: m.refillInfo!.totalQuantity,
      ),
    );

    meds[idx] = updatedMed;
    await medRepo.updateMedicine(updatedMed);
    
    _invalidateCache();
    safeNotifyListeners();
    HapticEngine.success();
    showToast('✓ ${m.name} refilled');
  }
}
