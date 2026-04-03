import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/medication_repository.dart';
import '../datasources/local_prefs_datasource.dart';
import '../datasources/firestore_datasource.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';

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

  @override
  Future<String?> uploadMedicineImage(File imageFile) async {
    if (!_hasAuth) return null;
    return await storageService.uploadMedicineImage(_uid!, imageFile);
  }

  // ── Medicines ──────────────────────────────────────────────────────
  @override
  Future<List<Medicine>> getMedicines() async {
    // 1. Load local meds
    final j = localDataSource.getJson('meds', decrypt: true);
    final List<Medicine> localMeds =
        j == null ? [] : (j as List).map((m) => Medicine.fromJson(m)).toList();

    // 2. If authenticated, fetch cloud and merge
    if (_hasAuth) {
      try {
        final cloudMeds = await firestoreDataSource.getMedicines(_uid!);

        // Merge strategy: If local has meds that cloud doesn't, we assume they were created offline and push them.
        final cloudIds = cloudMeds.map((m) => m.id).toSet();
        final List<Medicine> toPush =
            localMeds.where((m) => !cloudIds.contains(m.id)).toList();

        for (var m in toPush) {
          firestoreDataSource.saveMedicine(_uid!, m).catchError((_) {});
          cloudMeds.add(m);
        }

        if (cloudMeds.isNotEmpty) {
          // Cache the merged list
          await localDataSource.setJson(
              'meds', cloudMeds.map((m) => m.toJson()).toList(),
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
  Future<void> addMedicine(Medicine med) async {
    final meds = await getMedicines();
    meds.add(med);
    await localDataSource.setJson('meds', meds.map((m) => m.toJson()).toList(),
        encrypt: true);
    if (_hasAuth) {
      firestoreDataSource.saveMedicine(_uid!, med).catchError((_) {});
    }
  }

  @override
  Future<void> updateMedicine(Medicine med) async {
    final meds = await getMedicines();
    final idx = meds.indexWhere((m) => m.id == med.id);
    if (idx != -1) {
      meds[idx] = med;
      await localDataSource
          .setJson('meds', meds.map((m) => m.toJson()).toList(), encrypt: true);
      if (_hasAuth) {
        firestoreDataSource.saveMedicine(_uid!, med).catchError((_) {});
      }
    }
  }

  @override
  Future<void> deleteMedicine(int id) async {
    final meds = await getMedicines();
    meds.removeWhere((m) => m.id == id);
    await localDataSource.setJson('meds', meds.map((m) => m.toJson()).toList(),
        encrypt: true);
    if (_hasAuth) {
      firestoreDataSource.deleteMedicine(_uid!, id).catchError((_) {});
    }
  }

  // ── History ────────────────────────────────────────────────────────
  @override
  Future<Map<String, List<DoseEntry>>> getHistory() async {
    // 1. Load local history (always load first for speed).
    final Map<String, List<DoseEntry>> local = _loadLocalHistory();

    // 2. If authenticated, fetch cloud and MERGE.
    if (_hasAuth) {
      try {
        final cloudHistory =
            await firestoreDataSource.getRecentHistory(_uid!, days: 30);
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final merged = <String, List<DoseEntry>>{...cloudHistory};

        // Push local missing dates (or today's local updates) to Cloud
        for (final entry in local.entries) {
          if (!merged.containsKey(entry.key) || entry.key == today) {
            merged[entry.key] = entry.value;
            // Push missing/today to cloud asynchronously
            firestoreDataSource
                .saveDayHistory(_uid!, entry.key, entry.value)
                .catchError((_) {});
          }
        }

        // Persist merged result locally.
        await localDataSource.setJson(
          'history',
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

  Map<String, List<DoseEntry>> _loadLocalHistory() {
    final j = localDataSource.getJson('history', decrypt: true);
    if (j == null) return {};
    return (j as Map<String, dynamic>).map(
      (k, v) =>
          MapEntry(k, (v as List).map((e) => DoseEntry.fromJson(e)).toList()),
    );
  }

  @override
  Future<void> saveHistory(Map<String, List<DoseEntry>> history,
      {String? onlyDateKey}) async {
    await localDataSource.setJson(
      'history',
      history.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
      encrypt: true,
    );
    if (_hasAuth) {
      if (onlyDateKey != null) {
        final dayEntries = history[onlyDateKey] ?? [];
        firestoreDataSource
            .saveDayHistory(_uid!, onlyDateKey, dayEntries)
            .catchError((_) {});
      } else {
        // Full sync (rarely used except on initial post-login upload).
        for (final entry in history.entries) {
          firestoreDataSource
              .saveDayHistory(_uid!, entry.key, entry.value)
              .catchError((_) {});
        }
      }
    }
  }

  // ── Taken Today ────────────────────────────────────────────────────
  @override
  Future<Map<String, bool>> getTakenToday() async {
    if (_hasAuth) {
      final cloud = await firestoreDataSource.getTakenToday(_uid!);
      if (cloud.isNotEmpty) {
        await localDataSource.setJson('takenToday', cloud, encrypt: true);
        return cloud;
      }
    }
    final j = localDataSource.getJson('takenToday', decrypt: true);
    if (j == null) return {};
    return Map<String, bool>.from(j);
  }

  @override
  Future<void> saveTakenToday(Map<String, bool> takenToday) async {
    await localDataSource.setJson('takenToday', takenToday, encrypt: true);
    if (_hasAuth) {
      firestoreDataSource.saveTakenToday(_uid!, takenToday).catchError((_) {});
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
      final localHistory = _loadLocalHistory();
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
  Future<SharedPreferences> getPrefs() async {
    return localDataSource.prefs;
  }
}
