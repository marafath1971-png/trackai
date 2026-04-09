import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/logger.dart';

class HealthController extends ChangeNotifier {
  final SharedPreferences _prefs;
  final Health _health = Health();

  bool _isConnected = false;
  bool _isSyncing = false;
  bool _autoSync = false;

  double _steps = 0;
  double _heartRate = 0;
  double _bloodGlucose = 0;
  double _systolic = 0;
  double _diastolic = 0;
  String _sleepStatus = 'No data';

  HealthController(this._prefs) {
    _isConnected = _prefs.getBool('health_connected') ?? false;
    _autoSync = _prefs.getBool('health_auto_sync') ?? true;
    if (_isConnected && _autoSync) {
      syncData();
    }
  }

  bool get isConnected => _isConnected;
  bool get isSyncing => _isSyncing;
  bool get autoSync => _autoSync;
  double get steps => _steps;
  double get heartRate => _heartRate;
  double get bloodGlucose => _bloodGlucose;
  double get systolic => _systolic;
  double get diastolic => _diastolic;
  String get sleepStatus => _sleepStatus;

  Future<void> setAutoSync(bool value) async {
    _autoSync = value;
    await _prefs.setBool('health_auto_sync', value);
    notifyListeners();
    if (_autoSync) await syncData();
  }

  static const List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  ];

  static const List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  Future<bool> connect() async {
    try {
      // 1. Request Activity Recognition permission (Android only, handled by health package internally mostly but good to check)
      if (defaultTargetPlatform == TargetPlatform.android) {
        await Permission.activityRecognition.request();
      }

      // 2. Request Health permissions
      bool requested = await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );

      if (requested) {
        _isConnected = true;
        await _prefs.setBool('health_connected', true);
        notifyListeners();
        await syncData();
        return true;
      }
      return false;
    } catch (e) {
      appLogger.e('Health Connect Error: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    _isConnected = false;
    await _prefs.setBool('health_connected', false);
    _steps = 0;
    _heartRate = 0;
    _sleepStatus = 'No data';
    notifyListeners();
  }

  Future<void> syncData() async {
    if (!_isConnected || _isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      // Fetch Steps
      List<HealthDataPoint> stepData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: yesterday,
        endTime: now,
      );
      _steps = stepData.fold(0.0, (sum, p) {
        final val = p.value;
        if (val is NumericHealthValue) return sum + val.numericValue;
        return sum;
      });

      // Fetch Heart Rate (latest)
      List<HealthDataPoint> hrData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: yesterday,
        endTime: now,
      );
      if (hrData.isNotEmpty) {
        final val = hrData.last.value;
        if (val is NumericHealthValue) {
          _heartRate = val.numericValue.toDouble();
        }
      }

      // Fetch Sleep
      List<HealthDataPoint> sleepData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_SESSION],
        startTime: yesterday,
        endTime: now,
      );
      if (sleepData.isNotEmpty) _sleepStatus = 'Logged';

      // Fetch Blood Glucose (latest)
      List<HealthDataPoint> bgData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.BLOOD_GLUCOSE],
        startTime: yesterday,
        endTime: now,
      );
      if (bgData.isNotEmpty) {
        final val = bgData.last.value;
        if (val is NumericHealthValue) _bloodGlucose = val.numericValue.toDouble();
      }

      // Fetch Blood Pressure (latest)
      List<HealthDataPoint> sysData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.BLOOD_PRESSURE_SYSTOLIC],
        startTime: yesterday,
        endTime: now,
      );
      if (sysData.isNotEmpty) {
        final val = sysData.last.value;
        if (val is NumericHealthValue) _systolic = val.numericValue.toDouble();
      }

      List<HealthDataPoint> diaData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.BLOOD_PRESSURE_DIASTOLIC],
        startTime: yesterday,
        endTime: now,
      );
      if (diaData.isNotEmpty) {
        final val = diaData.last.value;
        if (val is NumericHealthValue) _diastolic = val.numericValue.toDouble();
      }

      appLogger.i(
          'Health Sync Complete: Steps: $_steps, HR: $_heartRate, BG: $_bloodGlucose, BP: $_systolic/$_diastolic');
    } catch (e) {
      appLogger.e('Health Sync Error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
