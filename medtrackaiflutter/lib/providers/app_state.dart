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
import '../services/export_service.dart';
import '../services/auth_service.dart';
import '../services/link_service.dart';
import '../services/purchases_service.dart';
import '../services/performance_service.dart';
import '../services/dynamic_icon_service.dart';
import '../services/voice_service.dart';
import '../services/gemini_service.dart';
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

  ManagedProfile? _activeProfile;
  ManagedProfile? get activeProfile => _activeProfile;

  // UI Feedback State
  String? toast;
  String? toastType;
  bool lowStockBannerDismissed = false;
  bool isLocked = false;
  String? pendingCelebrationMedName;
  int? pendingMilestoneAnimation;

  // Voice Assistant State
  bool isVoiceActive = false;
  String voiceStatus = 'idle'; // idle, listening, thinking, success, error
  String voiceTranscript = '';
  String voiceFeedback = '';

  AppState({
    required this.medRepo,
    required this.userRepo,
    required this.symptomRepo,
    required SharedPreferences prefs,
    AudioPlayer? audioPlayer,
    LinkService? linkService,
  })  : _audioPlayer = audioPlayer ?? AudioPlayer(),
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
  Future<void> saveProfile(UserProfile p) => auth.saveProfile(p);

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

  bool get isBackgrounded =>
      _lifecycleState == AppLifecycleState.paused ||
      _lifecycleState == AppLifecycleState.inactive;

  // ── Lifecycle ──────────────────────────────────────────────────────
  Future<void> _rescheduleNotifications() async {
    if (profile == null || !profile!.notifPerm) return;

    // 1. Clear existing
    await NotificationService.cancelAll();

    // 2. Schedule Primary (Me)
    final myMeds = await medRepo.getMedicines(profileId: null);
    await NotificationService.scheduleAll(myMeds);

    // 3. Schedule Dependents
    for (var member in profile!.familyMembers) {
      final memberMeds = await medRepo.getMedicines(profileId: member.id);
      await NotificationService.scheduleAll(memberMeds, profileName: member.name);
    }
    
    // 4. Global Morning Summary (Primary only for now)
    await NotificationService.scheduleMorningSummary(
      totalDoses: myMeds.length,
      enableSound: profile!.notifSound,
    );
  }

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
        appLogger.e('[AppState] Critical load failure',
            error: e, stackTrace: stack);
        FirebaseCrashlytics.instance.recordError(e, stack);
        auth.phase = AppPhase.onboarding;
        safeNotifyListeners();
      }
    });
  }

  // ── Profile Switching ──────────────────────────────────────────────
  Future<void> switchProfile(ManagedProfile? profile) async {
    _activeProfile = profile;
    safeNotifyListeners();

    // Reload data for the switched profile
    await Future.wait([
      med.loadData(profileId: profile?.id),
      wellness.loadData(profileId: profile?.id),
    ]);
    
    await _rescheduleNotifications();
    safeNotifyListeners();
    showToast(profile == null ? 'Switched to Primary' : 'Switched to ${profile.name}');
  }

  // ── Medication Proxies ─────────────────────────────────────────────
  int getStreak() => med.getStreak();
  double getAdherenceScore() => med.getAdherenceScore();
  List<DoseItem> getDoses({DateTime? date}) => med.getDoses(date: date);
  List<Map<String, dynamic>> getTrendData() => med.getTrendData();

  Future<void> toggleDose(DoseItem dose) async {
    return PerformanceService.measure('toggle_dose_trace', () async {
      final key = dose.key;
      final wasTaken = takenToday[key] ?? false;
      final oldStreak = getStreak();

      await med.toggleDose(dose, todayStr());
      final newStreak = getStreak();

      if (!wasTaken) {
        // Success: Trigger delighter and increment growth counter
        await auth.incrementDosesMarked();

        // Evaluate Gamification Milestones
        final milestones = [3, 7, 14, 30, 60, 100, 365];
        if (newStreak > oldStreak && milestones.contains(newStreak)) {
          pendingMilestoneAnimation = newStreak;
        } else {
          pendingCelebrationMedName = dose.med.name;
        }

        toast = 'Dose logged';
        toastType = 'success';
      }

      safeNotifyListeners();
      await _rescheduleNotifications();
    });
  }

  Future<void> takeDose(int medId, int idx) async {
    final m = meds.firstWhere((m) => m.id == medId);
    final sched = m.schedule[idx];
    final dose = DoseItem(med: m, sched: sched, key: '${m.id}_${sched.id}');
    await toggleDose(dose);
  }

  void clearMilestone() {
    pendingMilestoneAnimation = null;
    safeNotifyListeners();
  }

  Future<void> skipDose(DoseItem dose) async {
    await med.skipDose(dose, todayStr());
    
    // Task Phase 2.4: Telemetry Alert for Critical Meds
    if (dose.med.isCritical) {
      await social.notifyCaregiversOfMissedDose(dose.med);
    }
    
    safeNotifyListeners();
    await _rescheduleNotifications();
  }

  Future<void> addMedicine(Medicine m) async {
    await med.addMedicine(m);
    await _rescheduleNotifications();
  }

  Future<void> updateMedicine(Medicine m) async {
    await med.updateMedDirect(m);
    await _rescheduleNotifications();
  }

  Future<void> deleteMedicine(int id) async {
    await med.deleteMedicine(id);
    await _rescheduleNotifications();
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

  Future<void> updateProfile(
          {String? name, String? accentColor, bool? amoledMode}) =>
      auth.updateProfile(
          name: name, accentColor: accentColor, amoledMode: amoledMode);

  Future<void> addFamilyMember(ManagedProfile member) async {
    if (profile == null) return;
    final updatedMembers = List<ManagedProfile>.from(profile!.familyMembers)
      ..add(member);
    await auth.saveProfile(profile!.copyWith(familyMembers: updatedMembers));
    await _rescheduleNotifications();
    showToast('Welcome, ${member.name}! ✨');
  }

  Future<void> removeFamilyMember(String memberId) async {
    if (profile == null) return;
    
    // Safety check: Don't remove if they have active meds?
    // For now, allow but warn in UI.
    final updatedMembers = profile!.familyMembers.where((m) => m.id != memberId).toList();
    await auth.saveProfile(profile!.copyWith(familyMembers: updatedMembers));
    
    // If we were viewing this profile, switch back to primary
    if (_activeProfile?.id == memberId) {
      await switchProfile(null);
    } else {
      await _rescheduleNotifications();
    }
    
    showToast('Profile removed');
  }

  Future<void> updateFamilyMember(ManagedProfile member) async {
    if (profile == null) return;
    final updatedMembers = profile!.familyMembers.map((m) => m.id == member.id ? member : m).toList();
    await auth.saveProfile(profile!.copyWith(familyMembers: updatedMembers));
    
    if (_activeProfile?.id == member.id) {
       _activeProfile = member;
    }
    
    await _rescheduleNotifications();
    safeNotifyListeners();
  }

  Future<void> completeOnboarding(UserProfile profile) =>
      auth.completeOnboarding(profile);
  void skipAuth() => auth.skipAuth();

  void toggleDarkMode() => auth.toggleDarkMode();
  void setLanguage(String lang) => auth.setLanguage(lang);
  Future<void> updateAccentColor(String color) => auth.updateAccentColor(color);
  Future<void> updateAppIcon(String icon) async {
    await DynamicIconService.setIcon(icon == 'default' ? null : icon);
    await auth.updateAppIcon(icon);
  }

  Future<void> updateReminderSound(String sound) =>
      auth.updateReminderSound(sound);
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
        'body':
            'User ID: ${AuthService.uid}\nApp Version: 1.0.0+1\n\nIssue Description:',
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
  Future<void> fetchHealthInsights() async {
    if (healthConnected) await health.syncData();
    return wellness.fetchHealthInsights(
      meds: meds,
      streak: getStreak(),
      adherence: getAdherenceScore(),
      latencyData: med.getLatencyHistory(),
      heartRate: healthHeartRate > 0 ? healthHeartRate : null,
      steps: healthSteps > 0 ? healthSteps : null,
      history: history,
    );
  }

  Future<void> logSymptom(Symptom s) async {
    await wellness.logSymptom(s, meds);
    safeNotifyListeners();
    fetchHealthInsights(); // Refresh correlations
  }

  Future<void> deleteSymptom(String id) async {
    await wellness.deleteSymptom(id);
    safeNotifyListeners();
  }

  // ── Voice Assistant (Phase 2.3) ────────────────────────────────────
  
  Future<void> processVoiceCommand(String transcript) async {
    final res = await GeminiService.parseVoiceCommand(
        transcript: transcript, meds: meds);

    if (res is Success<Map<String, dynamic>>) {
      final data = res.value;
      if (data['identified'] == true) {
        final medId = data['medId'] as int;
        final action = data['action'] as String;
        final confText = data['confirmationText'] as String;

        // Find the next upcoming dose for this med
        final doses = med.getDoses().where((d) => d.med.id == medId).toList();
        if (doses.isNotEmpty) {
          if (action == 'take') {
            await takeDose(medId, 0); // Simplified: take the first scheduled dose
          } else {
            await skipDose(doses.first);
          }
          
          await VoiceService.speak(confText);
          toast = confText;
          toastType = 'success';
          safeNotifyListeners();
        }
      } else {
        await VoiceService.speak("I couldn't identify that medication. Try saying the full name.");
      }
    }
  }

  // ── Social & Monitoring Proxies ────────────────────────────────────
  int get unseenAlertsCount => social.missedAlerts.length;
  Future<void> addCaregiver(Caregiver cg) => social.addCaregiver(cg);
  Future<String> createInvite(Caregiver cg) =>
      social.createInvite(cg, profile?.name, profile?.avatar);
  Future<void> activateCaregiver(int id) => social.activateCaregiver(id);
  void markAlertsAsSeen() => social.markAlertsAsSeen();
  Future<void> joinCareTeam(String code) => social.joinCareTeam(code);
  Future<List<Medicine>> getPatientMeds(String uid) =>
      social.getPatientMeds(uid);
  Future<Map<String, List<DoseEntry>>> getPatientHistory(String uid) =>
      social.getPatientHistory(uid);
  Future<void> nudgePatient(String uid) => social.nudgePatient(uid);
  Future<void> fetchProtectorInsight(
          Caregiver cg, List<Medicine> m, Map<String, List<DoseEntry>> h) =>
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

  Future<void> logPaywallEvent(String e) => med.logPaywallEvent(e);
  Future<void> useStreakFreeze() async {
    // Placeholder implementation
  }

  // ── Health & Vitals Proxies ─────────────────────────────────────────
  bool get healthConnected => health.isConnected;
  bool get healthSyncing => health.isSyncing;
  bool get healthAutoSync => health.autoSync;
  double get healthSteps => health.steps;
  double get healthHeartRate => health.heartRate;
  double get healthBloodGlucose => health.bloodGlucose;
  double get healthSystolic => health.systolic;
  double get healthDiastolic => health.diastolic;

  Future<bool> connectHealth() async {
    final success = await health.connect();
    if (success) safeNotifyListeners();
    return success;
  }

  Future<void> setHealthAutoSync(bool value) async {
    await health.setAutoSync(value);
    safeNotifyListeners();
  }

  Future<void> syncHealthData() async {
    await health.syncData();
    safeNotifyListeners();
  }

  void recordDose(DoseItem dose) => med.toggleDose(dose, todayStr());
  Future<void> logPrnDose(int medId, String label, String time) =>
      med.logPrnDose(medId, label, time);
  String getDoseGuidance(Medicine m) => med.getDoseGuidance(m);

  Future<String?> uploadImage(File file) => med.uploadMedicineImage(file);
  Future<void> incrementScanCount() => med.incrementScanCount(1);

  List<ScheduledMed> getAllSchedules() => med.getAllSchedules();
  Future<void> toggleSchedule(int medId, int idx) =>
      med.toggleSchedule(medId, idx);
  Future<void> removeSchedule(int medId, int idx) =>
      med.removeSchedule(medId, idx);
  Future<void> addSchedule(int medId, ScheduleEntry s) =>
      med.addSchedule(medId, s);
  Future<void> updateSchedule(int medId, int idx, ScheduleEntry s) =>
      med.updateSchedule(medId, idx, s);

  List<Map<String, dynamic>> getLatencyData() => med.getLatencyHistory();
  
  DateTime? get lastSyncedAt => null; 
  int getAdherenceForMed(int medId) => med.getAdherenceForMed(medId);
  ({int taken, int total}) getHistoryCountForMed(int medId) =>
      med.getHistoryCountForMed(medId);

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

    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      subject: 'MedAI Data Export (CSV)',
    ));
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

  void executeStepAction(String step, BuildContext context) =>
      wellness.executeStepAction(step);

  // ── WELLNESS & SYMPTOMS ──────────────────────────────────────────
  bool get loadingInsights => wellness.loadingInsights;
  bool get analyzingSymptom => wellness.analyzingSymptom;
  bool get hasNewDataForAI => med.history.isNotEmpty;

  Map<String, String> getMoodSummary({
    required String good,
    required String stable,
    required String severe,
    required String empty,
  }) =>
      wellness.getMoodSummary(
          good: good, stable: stable, severe: severe, empty: empty);

  List<double> getRecentSymptomStats() => wellness.getRecentSymptomStats();
  Future<void> updateProfileFromMap(Map<String, dynamic> data) =>
      auth.updateProfileFromMap(data);

  HealthInsight? get symptomAnalysis => (wellness.healthInsights.isNotEmpty)
      ? wellness.healthInsights.first
      : null;

  Future<void> saveSymptom(Symptom s) => wellness.logSymptom(s, med.meds);
  Future<void> getSymptoms() => wellness.loadData(profileId: _activeProfile?.id);

  // ── AI SAFETY ──────────────────────────────────────────────────────
  Future<Result<AISafetyProfile>> analyzeMedicineSafety(Medicine m) =>
      med.analyzeMedicineSafety(m);

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
  String todayStr() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }
  String timeContext() {
    final now = DateTime.now();
    return 'Current Time: ${now.hour}:${now.minute.toString().padLeft(2, "0")} on day ${now.weekday % 7} (0=Sun, 6=Sat)';
  }
  String fmtTime(int h, int m) =>
      '${h % 12 == 0 ? 12 : h % 12}:${m.toString().padLeft(2, '0')} ${h >= 12 ? 'PM' : 'AM'}';
  int dayIdx() => DateTime.now().weekday % 7;

  // ── Internal Helpers ───────────────────────────────────────────────

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
    appLogger.i('[AppState] Handling notification action: $payloadStr');
  }

  Future<void> _syncPendingActions() async {
    // Placeholder for offline-first sync
  }

  // ── VOICE ASSISTANT ───────────────────────────────────────────────
  
  Future<void> activateVoiceAssistant() async {
    if (isVoiceActive) return;
    
    isVoiceActive = true;
    voiceStatus = 'listening';
    voiceTranscript = 'Listening...';
    voiceFeedback = '';
    safeNotifyListeners();

    try {
      final available = await VoiceService.listen(
        onResult: (transcript) async {
          voiceTranscript = transcript;
          voiceStatus = 'thinking';
          safeNotifyListeners();

          final result = await GeminiService.parseVoiceCommand(
            transcript: transcript,
            meds: meds,
          );

          if (result is Success<Map<String, dynamic>>) {
            final data = result.value;
            if (data['identified'] == true) {
              final medId = data['medId'];
              final action = data['action'];
              final confirmation = data['confirmationText'] ?? 'Done!';

              if (action == 'take') {
                final medicine = meds.firstWhere((m) => m.id == medId);
                final schedIdx = medicine.schedule.indexWhere((s) => s.enabled);
                if (schedIdx != -1) {
                  await takeDose(medId, schedIdx);
                }
              }

              voiceStatus = 'success';
              voiceFeedback = confirmation;
              await VoiceService.speak(confirmation);
            } else {
              voiceStatus = 'error';
              voiceFeedback =
                  "I couldn't identify that medication. Try saying the name clearly.";
              await VoiceService.speak(voiceFeedback);
            }
          } else {
            voiceStatus = 'error';
            voiceFeedback = "Something went wrong. Please try again.";
          }

          safeNotifyListeners();
          await Future.delayed(const Duration(seconds: 3));
          closeVoiceAssistant();
        },
        onListeningChanged: (listening) {
          if (!listening && voiceStatus == 'listening') {
            // Signal stopped
            safeNotifyListeners();
          }
        },
      );

      if (!available) {
        voiceStatus = 'error';
        voiceFeedback = 'Speech recognition unavailable. Check permissions.';
        safeNotifyListeners();
        await Future.delayed(const Duration(seconds: 3));
        closeVoiceAssistant();
      }
    } catch (e) {
      voiceStatus = 'error';
      voiceFeedback = 'Voice Assistant connection lost.';
      safeNotifyListeners();
      await Future.delayed(const Duration(seconds: 3));
      closeVoiceAssistant();
    }
  }

  void closeVoiceAssistant() {
    isVoiceActive = false;
    voiceStatus = 'idle';
    VoiceService.stop();
    safeNotifyListeners();
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
