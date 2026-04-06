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
  static const _key = 'user_symptoms';

  SymptomRepositoryImpl(this._storage);

  @override
  Future<List<Symptom>> getSymptoms() async {
    final uid = AuthService.uid;
    if (uid != null) {
      try {
        final snap =
            await _db.collection('users').doc(uid).collection('symptoms').get().withHardenedTimeout(taskName: 'getSymptoms');
        final cloudSymptoms =
            snap.docs.map((doc) => Symptom.fromJson(doc.data())).toList();

        // Update local cache
        _storage.setString(
            _key, jsonEncode(cloudSymptoms.map((s) => s.toJson()).toList()));
        return cloudSymptoms;
      } catch (e) {
        appLogger.e('[SymptomRepo] Failed to fetch from Firestore', error: e);
      }
    }

    final local = _storage.getString(_key);
    if (local != null) {
      final List decoded = jsonDecode(local);
      return decoded.map((s) => Symptom.fromJson(s)).toList();
    }
    return [];
  }

  @override
  Future<void> saveSymptom(Symptom symptom) async {
    final uid = AuthService.uid;

    // Save locally
    final symptoms = await getSymptoms();
    final idx = symptoms.indexWhere((s) => s.id == symptom.id);
    if (idx != -1) {
      symptoms[idx] = symptom;
    } else {
      symptoms.add(symptom);
    }
    await _storage.setString(
        _key, jsonEncode(symptoms.map((s) => s.toJson()).toList()));

    // Save to Firestore
    if (uid != null) {
      try {
        await _db
            .collection('users')
            .doc(uid)
            .collection('symptoms')
            .doc(symptom.id)
            .set(symptom.toJson())
            .withHardenedTimeout(taskName: 'saveSymptom');
      } catch (e) {
        appLogger.e('[SymptomRepo] Failed to save to Firestore', error: e);
      }
    }
  }

  @override
  Future<void> deleteSymptom(String id) async {
    final uid = AuthService.uid;

    // Delete locally
    final symptoms = await getSymptoms();
    symptoms.removeWhere((s) => s.id == id);
    await _storage.setString(
        _key, jsonEncode(symptoms.map((s) => s.toJson()).toList()));

    // Delete from Firestore
    if (uid != null) {
      try {
        await _db
            .collection('users')
            .doc(uid)
            .collection('symptoms')
            .doc(id)
            .delete()
            .withHardenedTimeout(taskName: 'deleteSymptom');
      } catch (e) {
        appLogger.e('[SymptomRepo] Failed to delete from Firestore', error: e);
      }
    }
  }

  @override
  Future<void> clearSymptoms() async {
    await _storage.remove(_key);
    // Clearing Firestore requires more logic (batch delete or cloud function),
    // but for now we focus on the local/session experience.
  }
}
