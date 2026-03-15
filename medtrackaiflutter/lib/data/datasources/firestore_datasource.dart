import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/entities.dart';

// ══════════════════════════════════════════════
// FIRESTORE DATA SOURCE
// ══════════════════════════════════════════════

class FirestoreDataSource {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference _userDoc(String uid) => _db.collection('users').doc(uid);
  CollectionReference _meds(String uid) =>
      _userDoc(uid).collection('medicines');
  CollectionReference _history(String uid) =>
      _userDoc(uid).collection('history');
  CollectionReference _caregivers(String uid) =>
      _userDoc(uid).collection('caregivers');
  CollectionReference _monitoring(String uid) =>
      _userDoc(uid).collection('monitoring');

  // ── Profile ────────────────────────────────────────────────────────
  Future<UserProfile?> getProfile(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
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

  // ── Medicines ──────────────────────────────────────────────────────
  Future<List<Medicine>> getMedicines(String uid) async {
    try {
      final snap = await _meds(uid).get();
      return snap.docs
          .map((d) => Medicine.fromJson(d.data() as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMedicine(String uid, Medicine med) async {
    await _meds(uid).doc('${med.id}').set(med.toJson());
  }

  Future<void> deleteMedicine(String uid, int medId) async {
    await _meds(uid).doc('$medId').delete();
  }

  // ── History ────────────────────────────────────────────────────────
  Future<Map<String, List<DoseEntry>>> getHistory(String uid) async {
    try {
      final snap = await _history(uid).get();
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
      {int days = 30}) async {
    try {
      final snap = await _history(uid)
          .orderBy(FieldPath.documentId, descending: true)
          .limit(days)
          .get();
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

  Future<void> saveDayHistory(
      String uid, String dateKey, List<DoseEntry> entries) async {
    await _history(uid)
        .doc(dateKey)
        .set({'entries': entries.map((e) => e.toJson()).toList()});
  }

  // ── Taken Today ────────────────────────────────────────────────────
  Future<Map<String, bool>> getTakenToday(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('takenToday')) return {};
      return Map<String, bool>.from(data['takenToday'] as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> saveTakenToday(String uid, Map<String, bool> taken) async {
    await _userDoc(uid).set({'takenToday': taken}, SetOptions(merge: true));
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
    return _caregivers(uid).snapshots().map((snap) => snap.docs
        .map((d) => Caregiver.fromJson(d.data() as Map<String, dynamic>))
        .toList());
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

  Future<void> joinCaregiver(String patientUid, int cgId) async {
    // 1. Update status on patient side
    await _caregivers(patientUid).doc('$cgId').update({'status': 'active'});
    
    // 2. Create reciprocal link on caregiver side
    // In a real app, cgId would correspond to the caregiver's actual UID.
    // For this simulation/prototype, we'll use the 'caregiverUID' if available or assume it exists.
    // For now, we'll just update the status.
  }

  // ── Monitoring (For Caregivers) ────────────────────────────────────
  
  Stream<List<Map<String, dynamic>>> getMonitoringPatientsStream(String uid) {
    return _monitoring(uid).snapshots().map((snap) => snap.docs
        .map((d) => {'uid': d.id, ...d.data() as Map<String, dynamic>})
        .toList());
  }

  Stream<List<Medicine>> getPatientMedsStream(String patientUid) {
    return _meds(patientUid).snapshots().map((snap) => snap.docs
        .map((d) => Medicine.fromJson(d.data() as Map<String, dynamic>))
        .toList());
  }

  Stream<Map<String, List<DoseEntry>>> getPatientHistoryStream(String patientUid) {
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
}
