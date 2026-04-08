import '../../domain/entities/entities.dart';

abstract class SymptomRepository {
  Future<List<Symptom>> getSymptoms({String? profileId});
  Future<void> saveSymptom(Symptom symptom, {String? profileId});
  Future<void> deleteSymptom(String id, {String? profileId});
  Future<void> clearSymptoms({String? profileId});
}
