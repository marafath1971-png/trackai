import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/user_repository.dart';
import '../../services/auth_service.dart';
import '../../services/circle_service.dart';
import '../../services/gemini_service.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_engine.dart';

class SocialController extends ChangeNotifier {
  final IUserRepository userRepo;
  
  List<Caregiver> _caregivers = [];
  List<Map<String, dynamic>> _monitoredPatients = [];
  List<MissedAlert> _missedAlerts = [];
  final Map<String, String> _protectorInsights = {};
  StreamSubscription? _cgSub;
  StreamSubscription? _monitoringSub;
  String? _pendingJoinCode;

  SocialController({required this.userRepo});

  List<Caregiver> get caregivers => _caregivers;
  List<Map<String, dynamic>> get monitoredPatients => _monitoredPatients;
  List<MissedAlert> get missedAlerts => _missedAlerts;
  Map<String, String> get protectorInsights => _protectorInsights;
  String? get pendingJoinCode => _pendingJoinCode;

  void addMissedAlert(MissedAlert alert) {
    _missedAlerts = [alert, ..._missedAlerts].take(20).toList();
    notifyListeners();
  }

  void setPendingJoinCode(String? code) {
    _pendingJoinCode = code;
    notifyListeners();
  }

  Future<void> loadData() async {
    try {
      _caregivers = await userRepo.getCaregivers();
      _listenToCaregivers();
      _listenToMonitoring();
      notifyListeners();
    } catch (e) {
      appLogger.e('[SocialController] Data load failed', error: e);
    }
  }

  void _listenToCaregivers() {
    _cgSub?.cancel();
    _cgSub = userRepo.getCaregiversStream().listen((list) {
      _caregivers = list;
      notifyListeners();
    });
  }

  void _listenToMonitoring() {
    _monitoringSub?.cancel();
    final uid = AuthService.uid;
    if (uid == null) return;

    _monitoringSub = userRepo.getMonitoringPatientsStream().listen((patients) {
      _monitoredPatients = patients;
      notifyListeners();
    }, onError: (e) {
      appLogger.e('[SocialController] Monitoring stream error', error: e);
    });
  }

  Future<String> createInvite(Caregiver cg, String? patientName, String? patientAvatar) async {
    final uid = AuthService.uid;
    if (uid == null) return '';
    try {
      final code = await CircleService.generateInviteCode(
        patientName: patientName ?? 'Member',
        patientAvatar: patientAvatar ?? '👤',
        relation: cg.relation,
        alertDelay: cg.alertDelay,
      );

      if (code.isNotEmpty) {
        _caregivers = _caregivers.map((c) => c.id == cg.id ? c.copyWith(inviteCode: code) : c).toList();
        await userRepo.saveCaregivers(_caregivers);
        notifyListeners();
      }
      return code;
    } catch (e) {
      appLogger.e('[SocialController] createInvite failed', error: e);
      return '';
    }
  }

  Future<void> joinCaregiver(String code) async {
    try {
      final result = await CircleService.verifyAndJoin(code.toUpperCase());
      if (result['success'] == true) {
        _listenToCaregivers();
        _listenToMonitoring();
      }
    } catch (e) {
      appLogger.e('[SocialController] joinCaregiver failed', error: e);
      rethrow;
    }
  }

  Future<void> addCaregiver(Caregiver cg) async {
    _caregivers.add(cg);
    await userRepo.saveCaregivers(_caregivers);
    notifyListeners();
  }

  Future<void> activateCaregiver(int id) async {
    final idx = _caregivers.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _caregivers[idx] = _caregivers[idx].copyWith(status: 'active');
      await userRepo.saveCaregivers(_caregivers);
      notifyListeners();
    }
  }

  void markAlertsAsSeen() {
    _missedAlerts = [];
    notifyListeners();
  }

  Future<List<Medicine>> getPatientMeds(String uid) async {
    // Bridge to user repository to fetch public meds of a monitored patient
    return await userRepo.getPatientMeds(uid);
  }

  Future<Map<String, List<DoseEntry>>> getPatientHistory(String uid) async {
    // Bridge to user repository to fetch public history of a monitored patient
    return await userRepo.getPatientHistory(uid);
  }

  Future<void> nudgePatient(String uid) async {
    appLogger.i('[Social] Nudging patient: $uid');
    await userRepo.nudgePatient(uid);
    HapticEngine.selection();
  }

  Future<void> fetchProtectorInsight(
      Caregiver cg, List<Medicine> meds, Map<String, List<DoseEntry>> history) async {
    final insight = await GeminiService.getProtectorInsight(
      patientName: 'Member',
      meds: meds,
      history: history,
    );
    _protectorInsights[cg.id.toString()] = insight;
    notifyListeners();
  }

  Future<void> joinCareTeam(String code) => joinCaregiver(code);

  @override
  void dispose() {
    _cgSub?.cancel();
    _monitoringSub?.cancel();
    super.dispose();
  }
}
