import 'package:flutter/material.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/symptom_repository.dart';
import '../../core/utils/logger.dart';

class WellnessController extends ChangeNotifier {
  final SymptomRepository symptomRepo;

  List<Symptom> _symptoms = [];
  final List<HealthInsight> _healthInsights = [];
  bool _loadingInsights = false;

  WellnessController({required this.symptomRepo});

  List<Symptom> get symptoms => _symptoms;
  List<HealthInsight> get healthInsights => _healthInsights;
  bool get loadingInsights => _loadingInsights;
  bool get analyzingSymptom => false;

  Map<String, String> getMoodSummary({
    required String good,
    required String stable,
    required String severe,
    required String empty,
  }) {
    if (_symptoms.isEmpty) return {'value': '-', 'unit': empty, 'sublabel': 'No logs'};
    // calculate mood summary logic
    return {'value': good, 'unit': 'mood', 'sublabel': 'Trend'};
  }

  List<double> getRecentSymptomStats() {
    return _symptoms.isEmpty ? [0.5, 0.5, 0.5, 0.5] : [0.8, 0.6, 0.9, 0.4];
  }

  Future<void> loadData() async {
    _symptoms = await symptomRepo.getSymptoms();
    notifyListeners();
  }

  Future<void> logSymptom(Symptom s, List<Medicine> meds) async {
    _symptoms.insert(0, s);
    await symptomRepo.saveSymptom(s);
    notifyListeners();
  }

  Future<void> deleteSymptom(String id) async {
    _symptoms.removeWhere((s) => s.id == id);
    await symptomRepo.deleteSymptom(id);
    notifyListeners();
  }

  Future<void> fetchHealthInsights({
    required List<Medicine> meds,
    required int streak,
    required double adherence,
    required List<Map<String, dynamic>> latencyData,
  }) async {
    _loadingInsights = true;
    notifyListeners();

    try {
      // Logic for fetching insights from GeminiService
    } finally {
      _loadingInsights = false;
      notifyListeners();
    }
  }

  void executeStepAction(String step) {
    appLogger.i('[Wellness] Executing step action: $step');
    notifyListeners();
  }
}
