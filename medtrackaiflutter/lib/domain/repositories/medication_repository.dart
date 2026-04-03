import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../entities/entities.dart';

abstract class IMedicationRepository {
  Future<List<Medicine>> getMedicines();
  Future<void> addMedicine(Medicine med);
  Future<void> updateMedicine(Medicine med);
  Future<void> deleteMedicine(int id);

  Future<String?> uploadMedicineImage(File imageFile);

  Future<Map<String, List<DoseEntry>>> getHistory();
  Future<void> saveHistory(Map<String, List<DoseEntry>> history,
      {String? onlyDateKey});

  Future<Map<String, bool>> getTakenToday();
  Future<void> saveTakenToday(Map<String, bool> takenToday);

  Future<List<Map<String, dynamic>>> getPendingActions();
  Future<void> savePendingActions(List<Map<String, dynamic>> actions);

  Future<SharedPreferences> getPrefs();
}
