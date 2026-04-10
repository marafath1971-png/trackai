import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/medication_repository.dart';
import '../datasources/local_prefs_datasource.dart';
import '../datasources/firestore_datasource.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../core/utils/repository_ext.dart';
import '../../core/utils/result.dart';
import '../../core/error/failures.dart';
import '../../core/utils/logger.dart';

// ══════════════════════════════════════════════
// MEDICATION REPOSITORY — Offline-First
// Writes locally first (instant), then syncs to
// Firestore in the background when user is logged in.
// ══════════════════════════════════════════════

class MedicationRepositoryImpl implements IMedicationRepository {
  final LocalDataSource localDataSource;
  final FirestoreDataSource firestoreDataSource;
  final StorageService storageService;

  MedicationRepositoryImpl(
      this.localDataSource, this.firestoreDataSource, this.storageService);

  String? get _uid => AuthService.uid;
  bool get _hasAuth => _uid != null;

  String _key(String base, String? profileId) {
    if (profileId == null) return base;
    return 'p_${profileId}_$base';
  }

  // ── Medicines ──────────────────────────────────────────────────────
  @override
  Future<List<Medicine>> getMedicines({String? profileId}) async {
    final key = _key('meds', profileId);
    // 1. Load local meds
    final j = localDataSource.getJson(key, decrypt: true);
    final List<Medicine> localMeds =
        j == null ? [] : (j as List).map((m) => Medicine.fromJson(m)).toList();

    // 2. If authenticated, fetch cloud and merge
    if (_hasAuth) {
      try {
        final cloudMeds = await firestoreDataSource
            .getMedicines(_uid!, profileId: profileId)
            .withHardenedTimeout(taskName: 'getMedicines');

        // Merge strategy
        final cloudIds = cloudMeds.map((m) => m.id).toSet();
        final List<Medicine> toPush =
            localMeds.where((m) => !cloudIds.contains(m.id)).toList();

        for (var m in toPush) {
          firestoreDataSource
              .saveMedicine(_uid!, m, profileId: profileId)
              .withHardenedTimeout(taskName: 'saveMedicine')
              .catchError((_) {});
          cloudMeds.add(m);
        }

        if (cloudMeds.isNotEmpty) {
          await localDataSource.setJson(
              key, cloudMeds.map((m) => m.toJson()).toList(),
              encrypt: true);
        }
        return cloudMeds;
      } catch (e) {
        // Fallback to local if offline
      }
    }

    return localMeds;
  }

  @override
  Future<void> addMedicine(Medicine med, {String? profileId}) async {
    final meds = await getMedicines(profileId: profileId);
    final key = _key('meds', profileId);
    meds.add(med);
    await localDataSource.setJson(key, meds.map((m) => m.toJson()).toList(),
        encrypt: true);
    if (_hasAuth) {
      firestoreDataSource
          .saveMedicine(_uid!, med, profileId: profileId)
          .withHardenedTimeout(taskName: 'saveMedicine')
          .catchError((_) {});
    }
  }

  @override
  Future<void> updateMedicine(Medicine med, {String? profileId}) async {
    final meds = await getMedicines(profileId: profileId);
    final key = _key('meds', profileId);
    final idx = meds.indexWhere((m) => m.id == med.id);
    if (idx != -1) {
      meds[idx] = med;
      await localDataSource
          .setJson(key, meds.map((m) => m.toJson()).toList(), encrypt: true);
      if (_hasAuth) {
        firestoreDataSource
            .saveMedicine(_uid!, med, profileId: profileId)
            .withHardenedTimeout(taskName: 'updateMedicine')
            .catchError((_) {});
      }
    }
  }

  @override
  Future<void> deleteMedicine(int id, {String? profileId}) async {
    final meds = await getMedicines(profileId: profileId);
    final key = _key('meds', profileId);
    meds.removeWhere((m) => m.id == id);
    await localDataSource.setJson(key, meds.map((m) => m.toJson()).toList(),
        encrypt: true);
    if (_hasAuth) {
      firestoreDataSource.deleteMedicine(_uid!, id, profileId: profileId).catchError((_) {});
    }
  }

  // ── History ────────────────────────────────────────────────────────
  @override
  Future<Map<String, List<DoseEntry>>> getHistory({String? profileId}) async {
    final Map<String, List<DoseEntry>> local = _loadLocalHistory(profileId);

    if (_hasAuth) {
      try {
        final cloudHistory = await firestoreDataSource
            .getRecentHistory(_uid!, days: 30, profileId: profileId)
            .withHardenedTimeout(taskName: 'getHistory');
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final merged = <String, List<DoseEntry>>{...cloudHistory};

        for (final entry in local.entries) {
          if (!merged.containsKey(entry.key) || entry.key == today) {
            merged[entry.key] = entry.value;
            firestoreDataSource
                .saveDayHistory(_uid!, entry.key, entry.value, profileId: profileId)
                .catchError((_) {});
          }
        }

        await localDataSource.setJson(
          _key('history', profileId),
          merged.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
          encrypt: true,
        );
        return merged;
      } catch (e) {
        // Offline
      }
    }
    return local;
  }

  Map<String, List<DoseEntry>> _loadLocalHistory(String? profileId) {
    final j = localDataSource.getJson(_key('history', profileId), decrypt: true);
    if (j == null) return {};
    return (j as Map<String, dynamic>).map(
      (k, v) =>
          MapEntry(k, (v as List).map((e) => DoseEntry.fromJson(e)).toList()),
    );
  }

  @override
  Future<void> saveHistory(Map<String, List<DoseEntry>> history,
      {String? onlyDateKey, String? profileId}) async {
    await localDataSource.setJson(
      _key('history', profileId),
      history.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
      encrypt: true,
    );
    if (_hasAuth) {
      if (onlyDateKey != null) {
        final dayEntries = history[onlyDateKey] ?? [];
        firestoreDataSource
            .saveDayHistory(_uid!, onlyDateKey, dayEntries, profileId: profileId)
            .catchError((_) {});
      } else {
        for (final entry in history.entries) {
          firestoreDataSource
              .saveDayHistory(_uid!, entry.key, entry.value, profileId: profileId)
              .catchError((_) {});
        }
      }
    }
  }

  // ── Taken Today ────────────────────────────────────────────────────
  @override
  Future<Map<String, bool>> getTakenToday({String? profileId}) async {
    final key = _key('takenToday', profileId);
    if (_hasAuth) {
      try {
        final cloud = await firestoreDataSource
            .getTakenToday(_uid!, profileId: profileId)
            .withHardenedTimeout(taskName: 'getTakenToday');
        if (cloud.isNotEmpty) {
          await localDataSource.setJson(key, cloud, encrypt: true);
          return cloud;
        }
      } catch (e) {
        // Fallback to local on terminal timeout/error
        appLogger.w('[MedRepo] takenToday fetch failed: $e');
      }
    }
    final j = localDataSource.getJson(key, decrypt: true);
    if (j == null) return {};
    return Map<String, bool>.from(j);
  }

  @override
  Future<void> saveTakenToday(Map<String, bool> takenToday,
      {String? profileId}) async {
    final key = _key('takenToday', profileId);
    await localDataSource.setJson(key, takenToday, encrypt: true);
    if (_hasAuth) {
      firestoreDataSource
          .saveTakenToday(_uid!, takenToday, profileId: profileId)
          .catchError((_) {});
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingActions() async {
    final j = localDataSource.getJson('pendingActions', decrypt: true);
    if (j == null) return [];
    return List<Map<String, dynamic>>.from(j);
  }

  @override
  Future<void> savePendingActions(List<Map<String, dynamic>> actions) async {
    await localDataSource.setJson('pendingActions', actions, encrypt: true);
  }

  // ── Offline-to-Cloud Sync ──────────────────────────────────────────
  /// Upload all local data to Firestore. Called once after first sign-in
  /// when Firestore has no data yet.
  Future<void> syncToCloud() async {
    if (!_hasAuth) return;
    try {
      // Medicines
      final localMeds = _loadLocalMeds();
      for (final med in localMeds) {
        firestoreDataSource.saveMedicine(_uid!, med).catchError((_) {});
      }
      // History
      final localHistory = _loadLocalHistory(null);
      for (final entry in localHistory.entries) {
        firestoreDataSource
            .saveDayHistory(_uid!, entry.key, entry.value)
            .catchError((_) {});
      }
      // TakenToday
      final tt = localDataSource.getJson('takenToday');
      if (tt != null) {
        firestoreDataSource
            .saveTakenToday(_uid!, Map<String, bool>.from(tt))
            .catchError((_) {});
      }
    } catch (_) {}
  }

  List<Medicine> _loadLocalMeds() {
    final j = localDataSource.getJson('meds');
    if (j == null) return [];
    return (j as List).map((m) => Medicine.fromJson(m)).toList();
  }

  @override
  Future<String?> uploadMedicineImage(File imageFile) async {
    if (!_hasAuth) return null;
    return await storageService.uploadMedicineImage(_uid!, imageFile);
  }

  @override
  Future<Result<AISafetyProfile>> analyzeMedicineSafety(Medicine m) async {
    // Structural Placeholder for 1.0 Release
    // Logic: In a real scenario, this would call GeminiService or a Cloud Function.
    // For the initial hardening, we return a successful structural response to ensure the UI works.
    try {
      const profile = AISafetyProfile(
        warnings: [
          "Take exactly as prescribed.",
          "Consult your doctor for side effects."
        ],
        interactions: ["Keep track of all other medications."],
        foodRules: ["Take with a full glass of water."],
        ahaMoments: ["MedAI helps you stay on track!"],
      );
      return const Success(profile);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  @override
  Future<SharedPreferences> getPrefs() async {
    return localDataSource.prefs;
  }
}
