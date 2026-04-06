import '../../domain/entities/entities.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/local_prefs_datasource.dart';
import '../datasources/firestore_datasource.dart';
import '../../services/auth_service.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/repository_ext.dart';

// ══════════════════════════════════════════════
// USER REPOSITORY — Offline-First
// ══════════════════════════════════════════════

class UserRepositoryImpl implements IUserRepository {
  final LocalDataSource localDataSource;
  final FirestoreDataSource firestoreDataSource;

  UserRepositoryImpl(this.localDataSource, this.firestoreDataSource);

  String? get _uid => AuthService.uid;
  bool get _hasAuth => _uid != null;

  // ── Profile ────────────────────────────────────────────────────────
  @override
  Future<UserProfile?> getProfile() async {
    if (_hasAuth) {
      final cloud = await firestoreDataSource.getProfile(_uid!).withHardenedTimeout(taskName: 'getProfile');
      if (cloud != null) {
        await localDataSource.setJson('profile', cloud.toJson(), encrypt: true);
        return cloud;
      }
    }
    final j = localDataSource.getJson('profile', decrypt: true);
    if (j == null) return null;
    return UserProfile.fromJson(j);
  }

  @override
  Future<UserProfile?> getOtherProfile(String uid) async {
    return await firestoreDataSource.getProfile(uid).withHardenedTimeout(taskName: 'getOtherProfile');
  }

  @override
  Stream<UserProfile?> getProfileStream() {
    if (!_hasAuth) return Stream.value(null);
    return firestoreDataSource.getProfileStream(_uid!);
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await localDataSource.setJson('profile', profile.toJson(), encrypt: true);
    if (_hasAuth) {
      firestoreDataSource.saveProfile(_uid!, profile).withHardenedTimeout(taskName: 'saveProfile').catchError((_) {});
    }
  }

  // ── Caregivers ─────────────────────────────────────────────────────
  @override
  Future<List<Caregiver>> getCaregivers() async {
    if (_hasAuth) {
      final cloud = await firestoreDataSource.getCaregivers(_uid!).withHardenedTimeout(taskName: 'getCaregivers');
      if (cloud.isNotEmpty) {
        await localDataSource.setJson(
            'caregivers', cloud.map((c) => c.toJson()).toList(),
            encrypt: true);
        return cloud;
      }
    }
    final j = localDataSource.getJson('caregivers', decrypt: true);
    if (j == null) return [];
    return (j as List).map((c) => Caregiver.fromJson(c)).toList();
  }

  @override
  Stream<List<Caregiver>> getCaregiversStream() {
    if (!_hasAuth) return Stream.value([]);
    return firestoreDataSource.getCaregiversStream(_uid!);
  }

  @override
  Future<void> saveCaregivers(List<Caregiver> caregivers) async {
    await localDataSource.setJson(
        'caregivers', caregivers.map((c) => c.toJson()).toList(),
        encrypt: true);
    if (_hasAuth) {
      firestoreDataSource.saveCaregivers(_uid!, caregivers).withHardenedTimeout(taskName: 'saveCaregivers').catchError((_) {});
    }
  }

  // ── Streak ─────────────────────────────────────────────────────────
  @override
  Future<StreakData> getStreakData() async {
    if (_hasAuth) {
      final cloud = await firestoreDataSource.getStreakData(_uid!).withHardenedTimeout(taskName: 'getStreakData');
      await localDataSource.setJson('streakData', cloud.toJson(),
          encrypt: true);
      return cloud;
    }
    final j = localDataSource.getJson('streakData', decrypt: true);
    if (j == null) return const StreakData();
    return StreakData.fromJson(j);
  }

  @override
  Future<void> saveStreakData(StreakData data) async {
    await localDataSource.setJson('streakData', data.toJson(), encrypt: true);
    if (_hasAuth) {
      firestoreDataSource.saveStreakData(_uid!, data).withHardenedTimeout(taskName: 'saveStreakData').catchError((_) {});
    }
  }

  // ── Dark Mode ──────────────────────────────────────────────────────
  @override
  Future<bool> getDarkMode() async {
    if (_hasAuth) {
      return firestoreDataSource.getDarkMode(_uid!).withHardenedTimeout(taskName: 'getDarkMode');
    }
    return localDataSource.getBool('darkMode') ?? false;
  }

  @override
  Future<void> saveDarkMode(bool darkMode) async {
    await localDataSource.setBool('darkMode', darkMode);
    if (_hasAuth) {
      firestoreDataSource.saveDarkMode(_uid!, darkMode).withHardenedTimeout(taskName: 'saveDarkMode').catchError((_) {});
    }
  }

  @override
  Future<String> getLanguage() async {
    if (_hasAuth) {
      final cloud = await firestoreDataSource.getLanguage(_uid!).withHardenedTimeout(taskName: 'getLanguage');
      if (cloud != null) {
        await localDataSource.setString('language', cloud);
        return cloud;
      }
    }
    return localDataSource.getString('language') ?? 'en';
  }

  @override
  Future<void> saveLanguage(String language) async {
    await localDataSource.setString('language', language);
    if (_hasAuth) {
      firestoreDataSource.saveLanguage(_uid!, language).withHardenedTimeout(taskName: 'saveLanguage').catchError((_) {});
    }
  }

  // ── FCM Token ──────────────────────────────────────────────────────
  @override
  Future<void> saveFcmToken(String token) async {
    if (_hasAuth) {
      await firestoreDataSource.saveFcmToken(_uid!, token).catchError((_) {});
    }
  }

  // ── Invites ────────────────────────────────────────────────────────
  @override
  Future<void> createInvite(String patientUid, Caregiver cg) async {
    await firestoreDataSource.createInvite(patientUid, cg);
  }

  @override
  Future<Caregiver?> getInvite(String code) async {
    final data = await firestoreDataSource.getInvite(code);
    if (data == null) return null;
    return Caregiver(
      id: data['cgId'] as int,
      name: data['cgName'] as String,
      relation: data['relation'] as String,
      patientUid: data['patientUid'] as String,
      status: 'pending',
    );
  }

  @override
  Future<Map<String, dynamic>?> getRawInvite(String code) async {
    // Directly fetch the raw document data from Firestore.
    return await firestoreDataSource.getInvite(code);
  }

  @override
  Future<void> deleteInvite(String code) async {
    await firestoreDataSource.deleteInvite(code);
  }

  @override
  Stream<List<Map<String, dynamic>>> getMonitoringPatientsStream() {
    if (!_hasAuth) {
      appLogger.i('[UserRepositoryImpl] No auth, skipping monitoring stream');
      return Stream.value([]);
    }
    appLogger
        .i('[UserRepositoryImpl] Starting monitoring stream for UID: $_uid');
    return firestoreDataSource.getMonitoringPatientsStream(_uid!);
  }

  @override
  Stream<List<Medicine>> getPatientMedsStream(String patientUid) {
    return firestoreDataSource.getPatientMedsStream(patientUid);
  }

  @override
  Stream<Map<String, List<DoseEntry>>> getPatientHistoryStream(
      String patientUid) {
    return firestoreDataSource.getPatientHistoryStream(patientUid);
  }

  @override
  Future<void> nudgePatient(String patientUid) async {
    if (_hasAuth) {
      await firestoreDataSource.nudgePatient(patientUid).withHardenedTimeout(taskName: 'nudgePatient').catchError((_) {});
    }
  }

  // ── Offline-to-Cloud Sync ──────────────────────────────────────────
  /// Upload all local user data to Firestore. Called once after first sign-in
  /// when Firestore has no user document yet.
  Future<void> syncToCloud() async {
    if (!_hasAuth) return;
    try {
      // Profile
      final localProfile = localDataSource.getJson('profile');
      if (localProfile != null) {
        await firestoreDataSource.saveProfile(
            _uid!, UserProfile.fromJson(localProfile));
      }
      // Caregivers — upsert each independently (no read needed)
      final localCgs = localDataSource.getJson('caregivers');
      if (localCgs != null) {
        for (final j in (localCgs as List)) {
          final cg = Caregiver.fromJson(j);
          firestoreDataSource.upsertCaregiver(_uid!, cg).catchError((_) {});
        }
      }
      // Streak
      final localStreak = localDataSource.getJson('streakData');
      if (localStreak != null) {
        firestoreDataSource
            .saveStreakData(_uid!, StreakData.fromJson(localStreak))
            .catchError((_) {});
      }
      // Dark mode
      final dm = localDataSource.getBool('darkMode');
      if (dm != null) {
        firestoreDataSource.saveDarkMode(_uid!, dm).catchError((_) {});
      }
      // Language
      final lang = localDataSource.getString('language');
      if (lang != null) {
        firestoreDataSource.saveLanguage(_uid!, lang).catchError((_) {});
      }
    } catch (e) {
      appLogger.e('[UserRepositoryImpl] Cloud sync failed: $e');
    }
  }

  @override
  Future<List<Medicine>> getPatientMeds(String patientUid) async {
    return firestoreDataSource.getMedicines(patientUid).withHardenedTimeout();
  }

  @override
  Future<Map<String, List<DoseEntry>>> getPatientHistory(
      String patientUid) async {
    return firestoreDataSource.getRecentHistory(patientUid).withHardenedTimeout();
  }
}
