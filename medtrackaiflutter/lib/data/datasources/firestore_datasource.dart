import '../../core/utils/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/entities.dart';

// ══════════════════════════════════════════════
// FIRESTORE DATA SOURCE
// ══════════════════════════════════════════════

class FirestoreDataSource {
  FirestoreDataSource() {
    // 🛡️ HARDENING: Explicit offline persistence + performance settings
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference _userDoc(String uid) => _db.collection('users').doc(uid);

  CollectionReference _meds(String uid, {String? profileId}) {
    if (profileId != null) {
      return _userDoc(uid)
          .collection('dependents')
          .doc(profileId)
          .collection('medicines');
    }
    return _userDoc(uid).collection('medicines');
  }

  CollectionReference _history(String uid, {String? profileId}) {
    if (profileId != null) {
      return _userDoc(uid)
          .collection('dependents')
          .doc(profileId)
          .collection('history');
    }
    return _userDoc(uid).collection('history');
  }

  CollectionReference _caregivers(String uid) =>
      _userDoc(uid).collection('caregivers');

  // ── Profile ────────────────────────────────────────────────────────
  Future<UserProfile?> getProfile(String uid) async {
    try {
      // 🛡️ HARDENING: Timeout fallback to prevent hangs on DNS/Host errors
      final doc = await _userDoc(uid).get().timeout(const Duration(seconds: 5));
      final data = doc.data() as Map<String, dynamic>?;

      if (data == null || !data.containsKey('profile')) return null;
      return UserProfile.fromJson(data['profile'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(String uid, UserProfile profile) async {
    await _userDoc(uid)
        .set({'profile': profile.toJson()}, SetOptions(merge: true));
  }

  Stream<UserProfile?> getProfileStream(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('profile')) return null;
      return UserProfile.fromJson(data['profile'] as Map<String, dynamic>);
    });
  }

  // ── Medicines ──────────────────────────────────────────────────────
  Future<List<Medicine>> getMedicines(String uid, {String? profileId}) async {
    try {
      // 🛡️ HARDENING: Timeout fallback
      final snap =
          await _meds(uid, profileId: profileId).get().timeout(const Duration(seconds: 5));
      return snap.docs
          .map((d) => Medicine.fromJson(d.data() as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMedicine(String uid, Medicine med, {String? profileId}) async {
    await _meds(uid, profileId: profileId).doc('${med.id}').set(med.toJson());
  }

  Future<void> deleteMedicine(String uid, int medId, {String? profileId}) async {
    await _meds(uid, profileId: profileId).doc('$medId').delete();
  }

  // ── History ────────────────────────────────────────────────────────
  Future<Map<String, List<DoseEntry>>> getHistory(String uid,
      {String? profileId}) async {
    try {
      // 🛡️ HARDENING: Timeout fallback
      final snap = await _history(uid, profileId: profileId)
          .get()
          .timeout(const Duration(seconds: 8));
      final result = <String, List<DoseEntry>>{};

      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final entries = (data['entries'] as List? ?? [])
            .map((e) => DoseEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        result[doc.id] = entries;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Fetch only the most recent [days] days of history (ordered by dateKey desc).
  /// This is the preferred method for startup — avoids pulling years of data.
  Future<Map<String, List<DoseEntry>>> getRecentHistory(String uid,
      {int days = 30, String? profileId}) async {
    try {
      // 🛡️ HARDENING: Timeout fallback
      final snap = await _history(uid, profileId: profileId)
          .limit(days)
          .get()
          .timeout(const Duration(seconds: 5));
      final result = <String, List<DoseEntry>>{};

      final sortedDocs = snap.docs.toList()
        ..sort((a, b) => b.id.compareTo(a.id));

      for (final doc in sortedDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final entries = (data['entries'] as List? ?? [])
            .map((e) => DoseEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        result[doc.id] = entries;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveDayHistory(String uid, String dateKey, List<DoseEntry> entries,
      {String? profileId}) async {
    await _history(uid, profileId: profileId)
        .doc(dateKey)
        .set({'entries': entries.map((e) => e.toJson()).toList()});
  }

  // ── Taken Today ────────────────────────────────────────────────────
  Future<Map<String, bool>> getTakenToday(String uid, {String? profileId}) async {
    try {
      if (profileId != null) {
        final doc = await _userDoc(uid).collection('dependents').doc(profileId).get();
        final data = doc.data();
        return Map<String, bool>.from(data?['takenToday'] as Map? ?? {});
      }
      final doc = await _userDoc(uid).get();
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('takenToday')) return {};
      return Map<String, bool>.from(data['takenToday'] as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> saveTakenToday(String uid, Map<String, bool> taken,
      {String? profileId}) async {
    if (profileId != null) {
      await _userDoc(uid)
          .collection('dependents')
          .doc(profileId)
          .set({'takenToday': taken}, SetOptions(merge: true));
    } else {
      await _userDoc(uid).set({'takenToday': taken}, SetOptions(merge: true));
    }
  }

  // ── Caregivers ─────────────────────────────────────────────────────
  Future<List<Caregiver>> getCaregivers(String uid) async {
    try {
      final snap = await _caregivers(uid).get();
      return snap.docs
          .map((d) => Caregiver.fromJson(d.data() as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Stream<List<Caregiver>> getCaregiversStream(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('caregivers')) return [];
      final list = data['caregivers'] as List<dynamic>;
      return list
          .map((item) => Caregiver.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> saveCaregivers(String uid, List<Caregiver> caregivers) async {
    final batch = _db.batch();
    // Clear + rewrite
    final existing = await _caregivers(uid).get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    for (final cg in caregivers) {
      batch.set(_caregivers(uid).doc('${cg.id}'), cg.toJson());
    }
    await batch.commit();
  }

  /// Upsert a single caregiver doc without a read (used by auto-sync).
  Future<void> upsertCaregiver(String uid, Caregiver cg) async {
    await _caregivers(uid)
        .doc('${cg.id}')
        .set(cg.toJson(), SetOptions(merge: true));
  }

  // joinCaregiver legacy logic removed in favor of CircleService.verifyAndJoin logic.

  // ── Monitoring (For Caregivers) ────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getMonitoringPatientsStream(String uid) {
    appLogger.i(
        '[FirestoreDataSource] Starting monitoring stream on root user document: $uid');
    return _userDoc(uid).snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('monitoring')) {
        return <Map<String, dynamic>>[];
      }
      final list = data['monitoring'] as List<dynamic>;
      return list.map((item) => item as Map<String, dynamic>).toList();
    }).handleError((e) {
      appLogger.e('[FirestoreDataSource] Monitoring stream error: $e');
      return <Map<String, dynamic>>[];
    });
  }

  Stream<List<Medicine>> getPatientMedsStream(String patientUid) {
    return _meds(patientUid)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Medicine.fromJson(d.data() as Map<String, dynamic>))
            .toList())
        .handleError((e) {
      appLogger.e('[FirestoreDataSource] Patient meds stream error: $e');
      return <Medicine>[];
    });
  }

  Stream<Map<String, List<DoseEntry>>> getPatientHistoryStream(
      String patientUid) {
    return _history(patientUid).snapshots().map((snap) {
      final result = <String, List<DoseEntry>>{};
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final entries = (data['entries'] as List? ?? [])
            .map((e) => DoseEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        result[doc.id] = entries;
      }
      return result;
    }).handleError((e) {
      appLogger.e('[FirestoreDataSource] Patient history stream error: $e');
      return <String, List<DoseEntry>>{};
    });
  }

  // ── Streak ─────────────────────────────────────────────────────────
  Future<StreakData> getStreakData(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('streakData')) {
        return const StreakData();
      }
      return StreakData.fromJson(data['streakData'] as Map<String, dynamic>);
    } catch (_) {
      return const StreakData();
    }
  }

  Future<void> saveStreakData(String uid, StreakData streak) async {
    await _userDoc(uid)
        .set({'streakData': streak.toJson()}, SetOptions(merge: true));
  }

  // ── Dark Mode ──────────────────────────────────────────────────────
  Future<bool> getDarkMode(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      final data = doc.data() as Map<String, dynamic>?;
      return (data?['darkMode'] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveDarkMode(String uid, bool darkMode) async {
    await _userDoc(uid).set({'darkMode': darkMode}, SetOptions(merge: true));
  }

  Future<String?> getLanguage(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      final data = doc.data() as Map<String, dynamic>?;
      return data?['language'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLanguage(String uid, String language) async {
    await _userDoc(uid).set({'language': language}, SetOptions(merge: true));
  }

  // ── FCM Token ──────────────────────────────────────────────────────
  Future<void> saveFcmToken(String uid, String token) async {
    await _userDoc(uid).set({'fcmToken': token}, SetOptions(merge: true));
  }

  // ── Invites ────────────────────────────────────────────────────────
  Future<void> createInvite(String patientUid, Caregiver cg) async {
    final inviteCode = cg.inviteCode;
    await _db.collection('caregiverInvites').doc(inviteCode).set({
      'patientUid': patientUid,
      'cgId': cg.id,
      'cgName': cg.name,
      'relation': cg.relation,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getInvite(String inviteCode) async {
    final doc = await _db.collection('caregiverInvites').doc(inviteCode).get();
    return doc.data();
  }

  Future<void> deleteInvite(String inviteCode) async {
    await _db.collection('caregiverInvites').doc(inviteCode).delete();
  }

  Future<void> nudgePatient(String patientUid) async {
    await _userDoc(patientUid).set({
      'lastNudgeAt': FieldValue.serverTimestamp(),
      'nudgeCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }
}
