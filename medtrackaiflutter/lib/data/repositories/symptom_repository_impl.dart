import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/logger.dart';
import '../../services/auth_service.dart';
import '../../data/datasources/local_prefs_datasource.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/symptom_repository.dart';
import '../../core/utils/repository_ext.dart';

class SymptomRepositoryImpl implements SymptomRepository {
  final LocalDataSource _storage;
  final _db = FirebaseFirestore.instance;
  static const String _key = 'symptoms';
  SymptomRepositoryImpl(this._storage);

  String _keyHelper(String? profileId) =>
      profileId == null ? _key : 'p_${profileId}_$_key';

  CollectionReference _symptomsCollection(String uid, {String? profileId}) {
    if (profileId != null) {
      return _db
          .collection('users')
          .doc(uid)
          .collection('dependents')
          .doc(profileId)
          .collection('symptoms');
    }
    return _db.collection('users').doc(uid).collection('symptoms');
  }

  @override
  Future<List<Symptom>> getSymptoms({String? profileId}) async {
    final uid = AuthService.uid;
    final key = _keyHelper(profileId);

    if (uid != null) {
      try {
        final snap = await _symptomsCollection(uid, profileId: profileId)
            .get()
            .withHardenedTimeout(taskName: 'getSymptoms');
        final cloudSymptoms =
            snap.docs.map((doc) => Symptom.fromJson(doc.data() as Map<String, dynamic>)).toList();

        // Update local cache
        _storage.setString(
            key, jsonEncode(cloudSymptoms.map((s) => s.toJson()).toList()));
        return cloudSymptoms;
      } catch (e) {
        appLogger.e('[SymptomRepo] Failed to fetch from Firestore', error: e);
      }
    }

    final local = _storage.getString(key);
    if (local != null) {
      try {
        final List decoded = jsonDecode(local);
        return decoded.map((s) => Symptom.fromJson(s)).toList();
      } catch (_) {}
    }
    return [];
  }

  @override
  Future<void> saveSymptom(Symptom symptom, {String? profileId}) async {
    final uid = AuthService.uid;
    final key = _keyHelper(profileId);

    // Save locally
    final symptoms = await getSymptoms(profileId: profileId);
    final idx = symptoms.indexWhere((s) => s.id == symptom.id);
    if (idx != -1) {
      symptoms[idx] = symptom;
    } else {
      symptoms.add(symptom);
    }
    await _storage.setString(
        key, jsonEncode(symptoms.map((s) => s.toJson()).toList()));

    // Save to Firestore
    if (uid != null) {
      try {
        await _symptomsCollection(uid, profileId: profileId)
            .doc(symptom.id)
            .set(symptom.toJson())
            .withHardenedTimeout(taskName: 'saveSymptom');
      } catch (e) {
        appLogger.e('[SymptomRepo] Failed to save to Firestore', error: e);
      }
    }
  }

  @override
  Future<void> deleteSymptom(String id, {String? profileId}) async {
    final uid = AuthService.uid;
    final key = _keyHelper(profileId);

    // Delete locally
    final symptoms = await getSymptoms(profileId: profileId);
    symptoms.removeWhere((s) => s.id == id);
    await _storage.setString(
        key, jsonEncode(symptoms.map((s) => s.toJson()).toList()));

    // Delete from Firestore
    if (uid != null) {
      try {
        await _symptomsCollection(uid, profileId: profileId)
            .doc(id)
            .delete()
            .withHardenedTimeout(taskName: 'deleteSymptom');
      } catch (e) {
        appLogger.e('[SymptomRepo] Failed to delete from Firestore', error: e);
      }
    }
  }

  @override
  Future<void> clearSymptoms({String? profileId}) async {
    await _storage.remove(_keyHelper(profileId));
  }
}
