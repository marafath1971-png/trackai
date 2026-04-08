import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:audioplayers/audioplayers.dart';

import '../domain/entities/entities.dart';
export '../domain/entities/entities.dart';
import '../domain/repositories/medication_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/repositories/symptom_repository.dart';

import '../services/notification_service.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/link_service.dart';
import '../services/purchases_service.dart';
import '../services/performance_service.dart';
import '../services/dynamic_icon_service.dart';
import '../services/export_service.dart';

import '../core/utils/logger.dart';
import '../core/utils/haptic_engine.dart';
import '../core/utils/result.dart';

import 'controllers/auth_controller.dart';
import 'controllers/medication_controller.dart';
import 'controllers/wellness_controller.dart';
import 'controllers/social_controller.dart';
import 'controllers/health_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ══════════════════════════════════════════════
// APP STATE — CENTRAL STATE BRIDGE
// ══════════════════════════════════════════════

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  // Domain Repositories
  final IMedicationRepository medRepo;
  final IUserRepository userRepo;
  final SymptomRepository symptomRepo;

  // Domain Controllers (Modular Architecture)
  late final AuthController auth;
  late final MedicationController med;
  late final WellnessController wellness;
  late final SocialController social;
  late final HealthController health;

  bool _isDisposed = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  final LinkService _linkService;
  final AudioPlayer _audioPlayer;
  StreamSubscription? _notifSub;

  // UI Feedback State
  String? toast;
  String? toastType;
  bool lowStockBannerDismissed = false;
  bool isLocked = false;
  String? pendingCelebrationMedName;

  AppState({
    required this.medRepo,
    required this.userRepo,
    required this.symptomRepo,
    required SharedPreferences prefs,
    AudioPlayer? audioPlayer,
    LinkService? linkService,
  }) : _audioPlayer = audioPlayer ?? AudioPlayer(),
       _linkService = linkService ?? LinkService() {
    // Controller Initialization
    auth = AuthController(userRepo: userRepo);
    med = MedicationController(medRepo: medRepo);
    wellness = WellnessController(symptomRepo: symptomRepo);
    social = SocialController(userRepo: userRepo);
    health = HealthController(prefs);

    // Sync state changes between tokens/profile and app state
    auth.addListener(safeNotifyListeners);
    med.addListener(safeNotifyListeners);
    wellness.addListener(safeNotifyListeners);
    social.addListener(safeNotifyListeners);
    health.addListener(safeNotifyListeners);

    WidgetsBinding.instance.addObserver(this);
    _notifSub = NotificationService.actionStream.stream
        .listen(_handleNotificationAction);

    // Deep Link Integration
    _linkService.onJoinCodeDetected = (code) {
      social.setPendingJoinCode(code);
      if (phase == AppPhase.app && profile != null) {
        social.joinCareTeam(code).then((_) {
           social.setPendingJoinCode(null);
        });
      }
      safeNotifyListeners();
    };
    _linkService.init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (_lifecycleState == AppLifecycleState.resumed) {
      _syncPendingActions();
    }
  }

  // ── Modular Accessors ──────────────────────────────────────────────
  AppPhase get phase => auth.phase;
  UserProfile? get profile => auth.profile;
  
  List<Medicine> get meds => med.meds;
  List<Medicine> get activeMeds => med.meds;
  Map<String, List<DoseEntry>> get history => med.history;
  Map<String, bool> get takenToday => med.takenToday;
  StreakData get streakData => med.streakData;
  List<double> get inventoryHistory => med.inventoryHistory;
  
  List<Caregiver> get caregivers => social.caregivers;
  List<Map<String, dynamic>> get monitoredPatients => social.monitoredPatients;
  List<MissedAlert> get missedAlerts => social.missedAlerts;
  Map<String, String> get protectorInsights => social.protectorInsights;
  
  List<Symptom> get symptoms => wellness.symptoms;
  List<HealthInsight> get healthInsights => wellness.healthInsights;
  
  bool get darkMode => auth.darkMode;
  String get language => auth.language;
  bool get isLockedApp => isLocked;

  bool get isBackgrounded => _lifecycleState == AppLifecycleState.paused || 
                            _lifecycleState == AppLifecycleState.inactive;

  // ── Lifecycle ──────────────────────────────────────────────────────
  Future<void> loadFromStorage() async {
    return PerformanceService.measure('app_load_trace', () async {
      await NotificationService.refreshTimeZone();
      try {
        await auth.loadProfile();
        AnalyticsService.setUserId(AuthService.uid);

        await Future.wait([
          med.loadData(),
          wellness.loadData(),
          social.loadData(),
        ]);

        if (AuthService.uid != null) {
          _syncUserProfileFromAuth();
          _initPushNotifications();
          
          // Apply saved app icon on start
          if (profile?.appIcon != null && profile?.appIcon != 'default') {
            await DynamicIconService.setIcon(profile!.appIcon);
          }
        }

        _syncPendingActions();
        safeNotifyListeners();
      } catch (e, stack) {
        appLogger.e('[AppState] Critical load failure', error: e, stackTrace: stack);
        FirebaseCrashlytics.instance.recordError(e, stack);
        auth.phase = AppPhase.onboarding;
        safeNotifyListeners();
      }
    });
  }

  // ── Medication Proxies ─────────────────────────────────────────────
  int getStreak() => med.getStreak();
  double getAdherenceScore() => med.getAdherenceScore();
  List<DoseItem> getDoses() => med.getDoses();
  List<Map<String, dynamic>> getTrendData() => med.getTrendData();

  Future<void> toggleDose(DoseItem dose) async {
    return PerformanceService.measure('toggle_dose_trace', () async {
      final key = dose.key;
      final wasTaken = takenToday[key] ?? false;
      
      await med.toggleDose(dose, todayStr());
      
      if (!wasTaken) {
        // Success: Trigger delighter and increment growth counter
        await auth.incrementDosesMarked();
        pendingCelebrationMedName = dose.med.name;
        toast = 'Dose logged';
        toastType = 'success';
      }
      
      safeNotifyListeners();
      _updateNotifications();
    });
  }
  
  Future<void> takeDose(int medId, int idx) async {
     final m = meds.firstWhere((m) => m.id == medId);
     final sched = m.schedule[idx];
    final dose = DoseItem(med: m, sched: sched, key: '${m.id}_${sched.id}');
     await toggleDose(dose);
  }

  Future<void> skipDose(DoseItem dose) async {
    await med.skipDose(dose, todayStr());
    safeNotifyListeners();
    _updateNotifications();
  }

  Future<void> addMedicine(Medicine m) async {
    await med.addMedicine(m);
    _updateNotifications();
  }

  Future<void> updateMedicine(Medicine m) async {
    await med.updateMedDirect(m);
    _updateNotifications();
  }

  Future<void> deleteMedicine(int id) async {
    await med.deleteMedicine(id);
    _updateNotifications();
  }

  Future<void> saveMedicine(Medicine m) => updateMedicine(m);
  Future<void> updateMed(int id, {int? count}) async {
    final m = meds.firstWhere((m) => m.id == id);
    if (count != null) {
      await updateMedicine(m.copyWith(count: count));
    }
  }
  Future<void> deleteMed(int id) => deleteMedicine(id);
  Future<void> updateMedDirect(Medicine updated) => updateMedicine(updated);

  Future<void> undoPrnDose(int medId, String label) async {
    await med.undoPrnDose(medId, label, todayStr());
    safeNotifyListeners();
  }

  Future<void> snoozeDose(DoseItem dose, int minutes) async {
    await med.snoozeDose(dose, minutes);
    safeNotifyListeners();
  }

  String? get interactionWarning => med.interactionWarning;
  String? get interactionWarningMedName => med.interactionWarningMedName;
  void clearInteractionWarning() => med.clearInteractionWarning();

  // ── Auth & Profile Proxies ─────────────────────────────────────────
  bool get isPremium => profile?.isPremium ?? false;
  bool get biometricEnabled => profile?.biometricEnabled ?? false;
  bool get isPurchasing => auth.isPurchasing;

  Future<void> logout() => auth.logout();
  Future<void> signOut() => auth.logout();
  Future<void> signInWithGoogle() => auth.signInWithGoogle();
  Future<void> signInWithApple() => auth.signInWithApple();

  Future<void> saveProfile(UserProfile profile) => auth.saveProfile(profile);
  Future<void> updateProfile({String? name, String? accentColor, bool? amoledMode}) => 
      auth.updateProfile(name: name, accentColor: accentColor, amoledMode: amoledMode);

  Future<void> completeOnboarding(UserProfile profile) => auth.completeOnboarding(profile);
  void skipAuth() => auth.skipAuth();
  
  void toggleDarkMode() => auth.toggleDarkMode();
  void setLanguage(String lang) => auth.setLanguage(lang);
  Future<void> updateAccentColor(String color) => auth.updateAccentColor(color);
  Future<void> updateAppIcon(String icon) async {
    await DynamicIconService.setIcon(icon == 'default' ? null : icon);
    await auth.updateAppIcon(icon);
  }
  Future<void> updateReminderSound(String sound) => auth.updateReminderSound(sound);
  void toggleBiometricLock(bool v) => auth.toggleBiometricLock(v);

  void unlockApp() {
    isLocked = false;
    notifyListeners();
  }
  void lockApp() {
    isLocked = true;
    notifyListeners();
  }

  void clearCelebration() {
    pendingCelebrationMedName = null;
    notifyListeners();
  }

  // ── LAUNCH READINESS: SUPPORT & LEGAL ───────────────────────
  
  Future<void> openPrivacyPolicy() async {
    final url = Uri.parse('https://medtrack.ai/privacy');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> openTermsOfService() async {
    final url = Uri.parse('https://medtrack.ai/terms');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> contactSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@medtrack.ai',
      query: encodeQueryParameters(<String, String>{
        'subject': 'MedAI Support Inquiry',
        'body': 'User ID: ${AuthService.uid}\nApp Version: 1.0.0+1\n\nIssue Description:',
      }),
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  Future<void> requestReview() => ReviewService.requestReview();
  Future<void> openStoreReview() => ReviewService.openStoreReview();

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  // ── Wellness & AI Proxies ──────────────────────────────────────────
  bool get loadingInsight => wellness.loadingInsights;
  Future<void> fetchHealthInsights() => wellness.fetchHealthInsights(
    meds: meds,
    streak: getStreak(),
    adherence: getAdherenceScore(),
    latencyData: [], 
  );

  Future<void> logSymptom(Symptom s) async {
    await wellness.logSymptom(s, meds);
    safeNotifyListeners();
  }

  Future<void> deleteSymptom(String id) async {
    await wellness.deleteSymptom(id);
    safeNotifyListeners();
  }

  // ── Social & Monitoring Proxies ────────────────────────────────────
  int get unseenAlertsCount => social.missedAlerts.length;
  Future<void> addCaregiver(Caregiver cg) => social.addCaregiver(cg);
  Future<String> createInvite(Caregiver cg) => social.createInvite(cg, profile?.name, profile?.avatar);
  Future<void> activateCaregiver(int id) => social.activateCaregiver(id);
  void markAlertsAsSeen() => social.markAlertsAsSeen();
  Future<void> joinCareTeam(String code) => social.joinCareTeam(code);
  Future<List<Medicine>> getPatientMeds(String uid) => social.getPatientMeds(uid);
  Future<Map<String, List<DoseEntry>>> getPatientHistory(String uid) => social.getPatientHistory(uid);
  Future<void> nudgePatient(String uid) => social.nudgePatient(uid);
  Future<void> fetchProtectorInsight(Caregiver cg, List<Medicine> m, Map<String, List<DoseEntry>> h) => 
      social.fetchProtectorInsight(cg, m, h);

  // ── Purchases ──────────────────────────────────────────────────────
  Future<void> manageSubscription() => auth.manageSubscription();
  Future<void> unlockPremium() => purchasePremium('annual');
  
  Future<bool> purchasePremium(String packageId) async {
    auth.isPurchasing = true;
    notifyListeners();
    try {
      final success = await PurchasesService.purchasePackage(packageId);
      if (success) {
        await auth.loadProfile();
        showToast('Premium unlocked! ✨');
      }
      return success;
    } finally {
      auth.isPurchasing = false;
      safeNotifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    auth.isPurchasing = true;
    notifyListeners();
    try {
      final success = await PurchasesService.restorePurchases();
      if (success) {
        await auth.loadProfile();
        showToast('Purchases restored 🔄');
      }
    } finally {
      auth.isPurchasing = false;
      safeNotifyListeners();
    }
  }

  // ── UI Persistence Proxies ─────────────────────────────────────────
  List<Medicine> getLowMeds() => med.getLowMeds();
  int getLowStockCount() => med.getLowStockCount();
  void dismissLowStockBanner() {
    lowStockBannerDismissed = true;
    notifyListeners();
  }
  
  bool get isMutating => med.isMutating;
  DateTime? get lastSyncedAt => null; // To be implemented in MedicationController if needed

  Future<void> logPaywallEvent(String e) => med.logPaywallEvent(e);
  Future<void> useStreakFreeze() async {
    // Placeholder implementation
  }
  
  void recordDose(DoseItem dose) => med.toggleDose(dose, todayStr());
  Future<void> logPrnDose(int medId, String label, String time) => med.logPrnDose(medId, label, time);
  String getDoseGuidance(Medicine m) => med.getDoseGuidance(m);
  
  Future<String?> uploadImage(File file) => med.uploadMedicineImage(file);
  Future<void> incrementScanCount() => med.incrementScanCount(1);
  
  List<ScheduledMed> getAllSchedules() => med.getAllSchedules();
  Future<void> toggleSchedule(int medId, int idx) => med.toggleSchedule(medId, idx);
  Future<void> removeSchedule(int medId, int idx) => med.removeSchedule(medId, idx);
  Future<void> addSchedule(int medId, ScheduleEntry s) => med.addSchedule(medId, s);
  Future<void> updateSchedule(int medId, int idx, ScheduleEntry s) => med.updateSchedule(medId, idx, s);
  
  List<Map<String, dynamic>> getLatencyData() => [];
  int getAdherenceForMed(int medId) => med.getAdherenceForMed(medId);
  ({int taken, int total}) getHistoryCountForMed(int medId) => med.getHistoryCountForMed(medId);
  
  List<Medicine> getRefillForecast() => [];
  Future<void> refillMedication(int id) async {}
  // ── CLINICAL DATA EXPORT ───────────────────────────────────────────

  /// Generates and shares a professional PDF Adherence Report
  Future<void> exportDataPDF() async {
    await ExportService.exportAdherenceReport(this);
  }

  /// Generates and shares a CSV file representing medication history
  Future<void> exportDataCSV() async {
    final buffer = StringBuffer();
    buffer.writeln('Date,MedicineID,MedicineName,Time,Status');

    history.forEach((date, doses) {
      for (var dose in doses) {
        final med = meds.where((m) => m.id == dose.medId).firstOrNull;
        final status =
            dose.taken ? 'Taken' : (dose.skipped ? 'Skipped' : 'Missed');
        buffer.writeln(
            '$date,${dose.medId},${med?.name ?? "Unknown"},${dose.time},$status');
      }
    });

    final csv = buffer.toString();
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/med_history.csv');
    await file.writeAsString(csv);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'MedAI Data Export (CSV)',
      ),
    );
  }
  Future<void> deleteAllData() async {
    HapticEngine.selection();
    await auth.logout();
    showToast('All local data cleared');
  }

  Future<void> deleteAccount() async {
    HapticEngine.selection();
    await auth.deleteAccount();
    showToast('Account deleted permanently', type: 'error');
  }
  void executeStepAction(String step, BuildContext context) => wellness.executeStepAction(step);

  // ── WELLNESS & SYMPTOMS ──────────────────────────────────────────
  bool get loadingInsights => wellness.loadingInsights;
  bool get analyzingSymptom => wellness.analyzingSymptom;
  bool get hasNewDataForAI => med.history.isNotEmpty;

  Map<String, String> getMoodSummary({
    required String good,
    required String stable,
    required String severe,
    required String empty,
  }) => wellness.getMoodSummary(good: good, stable: stable, severe: severe, empty: empty);

  List<double> getRecentSymptomStats() => wellness.getRecentSymptomStats();
  Future<void> updateProfileFromMap(Map<String, dynamic> data) => auth.updateProfileFromMap(data);

  HealthInsight? get symptomAnalysis => (wellness.healthInsights.isNotEmpty) ? wellness.healthInsights.first : null;

  
  Future<void> saveSymptom(Symptom s) => wellness.logSymptom(s, med.meds);
  Future<void> getSymptoms() => wellness.loadData();

  // ── AI SAFETY ──────────────────────────────────────────────────────
  Future<Result<AISafetyProfile>> analyzeMedicineSafety(Medicine m) => med.analyzeMedicineSafety(m);

  // ── UI Feedback ────────────────────────────────────────────────────
  void showToast(String message, {String type = 'success'}) {
    toast = message;
    toastType = type;
    if (type == 'success') {
      HapticEngine.light();
    } else {
      HapticEngine.selection();
    }
    
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      toast = null;
      notifyListeners();
    });
  }

  // ── Utility ────────────────────────────────────────────────────────
  String todayStr() => dateToKey(DateTime.now());
  String dateToKey(DateTime d) => "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
  String fmtTime(int h, int m) => '${h % 12 == 0 ? 12 : h % 12}:${m.toString().padLeft(2, '0')} ${h >= 12 ? 'PM' : 'AM'}';
  int dayIdx() => DateTime.now().weekday % 7;

  // ── Internal Helpers ───────────────────────────────────────────────
  void _updateNotifications() {
    NotificationService.scheduleAll(meds);
  }

  void safeNotifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  void _syncUserProfileFromAuth() {
    if (auth.profile != null) {
      auth.phase = AppPhase.app;
    } else {
      auth.phase = AppPhase.onboarding;
    }
  }

  Future<void> _initPushNotifications() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await messaging.getToken();
        if (token != null) await userRepo.saveFcmToken(token);
      }
    } catch (e) {
      appLogger.w('FCM Init failed', error: e);
    }
  }

  void _handleNotificationAction(String payloadStr) {
    // Action handling for background notifications
    appLogger.i('[AppState] Handling notification action: $payloadStr');
  }

  Future<void> _syncPendingActions() async {
    // Placeholder for offline-first sync
  }

  @override
  void dispose() {
    _isDisposed = true;
    auth.removeListener(safeNotifyListeners);
    med.removeListener(safeNotifyListeners);
    wellness.removeListener(safeNotifyListeners);
    social.removeListener(safeNotifyListeners);
    _notifSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
