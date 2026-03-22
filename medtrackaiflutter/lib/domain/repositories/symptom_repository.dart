import '../../domain/entities/entities.dart';

abstract class SymptomRepository {
  Future<List<Symptom>> getSymptoms();
  Future<void> saveSymptom(Symptom symptom);
  Future<void> deleteSymptom(String id);
  Future<void> clearSymptoms();
}
