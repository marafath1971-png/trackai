import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../entities/entities.dart';
import '../../core/utils/result.dart';

abstract class IMedicationRepository {
  Future<List<Medicine>> getMedicines({String? profileId});
  Future<void> addMedicine(Medicine med, {String? profileId});
  Future<void> updateMedicine(Medicine med, {String? profileId});
  Future<void> deleteMedicine(int id, {String? profileId});

  Future<String?> uploadMedicineImage(File imageFile);

  Future<Map<String, List<DoseEntry>>> getHistory({String? profileId});
  Future<void> saveHistory(Map<String, List<DoseEntry>> history,
      {String? onlyDateKey, String? profileId});

  Future<Map<String, bool>> getTakenToday({String? profileId});
  Future<void> saveTakenToday(Map<String, bool> takenToday, {String? profileId});

  Future<List<Map<String, dynamic>>> getPendingActions();
  Future<void> savePendingActions(List<Map<String, dynamic>> actions);

  Future<Result<AISafetyProfile>> analyzeMedicineSafety(Medicine m);
  Future<SharedPreferences> getPrefs();
}
