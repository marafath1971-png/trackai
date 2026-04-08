import 'package:flutter/material.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/symptom_repository.dart';
import '../../services/gemini_service.dart';
import '../../core/utils/result.dart';
import '../../core/utils/logger.dart';

class WellnessController extends ChangeNotifier {
  final SymptomRepository symptomRepo;

  String? _currentProfileId;
  List<Symptom> _symptoms = [];
  final List<HealthInsight> _healthInsights = [];
  final List<PredictiveInsight> _predictions = [];
  bool _loadingInsights = false;

  WellnessController({required this.symptomRepo});

  String? get currentProfileId => _currentProfileId;
  List<Symptom> get symptoms => _symptoms;
  List<HealthInsight> get healthInsights => _healthInsights;
  List<PredictiveInsight> get predictions => _predictions;
  bool get loadingInsights => _loadingInsights;
  bool get analyzingSymptom => false;

  Map<String, String> getMoodSummary({
    required String good,
    required String stable,
    required String severe,
    required String empty,
  }) {
    if (_symptoms.isEmpty) {
      return {'value': '-', 'unit': empty, 'sublabel': 'No logs'};
    }
    // calculate mood summary logic
    return {'value': good, 'unit': 'mood', 'sublabel': 'Trend'};
  }

  List<double> getRecentSymptomStats() {
    return _symptoms.isEmpty ? [0.5, 0.5, 0.5, 0.5] : [0.8, 0.6, 0.9, 0.4];
  }

  Future<void> loadData({String? profileId}) async {
    _currentProfileId = profileId;
    _symptoms = await symptomRepo.getSymptoms(profileId: profileId);
    notifyListeners();
  }

  Future<void> logSymptom(Symptom s, List<Medicine> meds) async {
    _symptoms.insert(0, s);
    await symptomRepo.saveSymptom(s, profileId: _currentProfileId);
    notifyListeners();
  }

  Future<void> deleteSymptom(String id) async {
    _symptoms.removeWhere((s) => s.id == id);
    await symptomRepo.deleteSymptom(id, profileId: _currentProfileId);
    notifyListeners();
  }

  Future<void> clearSymptoms() async {
    _symptoms.clear();
    await symptomRepo.clearSymptoms(profileId: _currentProfileId);
    notifyListeners();
  }

  Future<void> fetchHealthInsights({
    required List<Medicine> meds,
    required int streak,
    required double adherence,
    required List<Map<String, dynamic>> latencyData,
    double? heartRate,
    double? steps,
    Map<String, List<DoseEntry>> history = const {},
  }) async {
    _loadingInsights = true;
    notifyListeners();

    try {
      final correlations = _analyzeSideEffectPatterns(meds, history);

      final res = await GeminiService.getHealthInsight(
        meds: meds,
        streak: streak,
        adherence: adherence,
        latencyData: latencyData,
        symptoms: _symptoms,
        heartRate: heartRate,
        steps: steps,
        correlations: correlations,
      );

      if (res is Success<List<HealthInsight>>) {
        _healthInsights.clear();
        _healthInsights.addAll(res.value);
      }
    } finally {
      _loadingInsights = false;
      notifyListeners();
    }
  }

  /// 🧠 Phase 5.0: Predictive Analytics Logic
  void analyzePredictivePatterns(Map<String, List<DoseEntry>> history) {
    _predictions.clear();
    
    // 1. Analyze Evening Risk
    int eveningMisses = 0;
    int totalEveningDoses = 0;
    
    // 2. Analyze Weekend Slump
    int weekendMisses = 0;
    
    history.forEach((date, doses) {
      final isWeekend = DateTime.parse(date).weekday >= 6;
      for (var d in doses) {
        final hour = int.tryParse(d.time.split(':')[0]) ?? 0;
        if (hour >= 18) {
          totalEveningDoses++;
          if (!d.taken) eveningMisses++;
        }
        if (isWeekend && !d.taken) weekendMisses++;
      }
    });

    if (totalEveningDoses > 3 && (eveningMisses / totalEveningDoses) > 0.4) {
      _predictions.add(PredictiveInsight(
        type: PredictiveType.eveningRisk,
        title: 'Evening Routine Risk',
        description: 'You tend to forget doses after 6 PM. Maybe move notifications earlier?',
        impactScore: 0.8,
      ));
    }

    if (weekendMisses > 2) {
      _predictions.add(PredictiveInsight(
        type: PredictiveType.weekendSlump,
        title: 'Weekend Pattern Change',
        description: 'Consistency drops on Saturdays. Stay regular this weekend!',
        impactScore: 0.6,
      ));
    }
    
    notifyListeners();
  }

  void executeStepAction(String step) {
    appLogger.i('[Wellness] Executing step action: $step');
    notifyListeners();
  }

  /// Task Phase 2.2: Side-Effect Pattern Discovery Logic
  List<Map<String, dynamic>> _analyzeSideEffectPatterns(
      List<Medicine> meds, Map<String, List<DoseEntry>> history) {
    final List<Map<String, dynamic>> correlations = [];

    for (var s in _symptoms) {
      final sTime = s.timestamp;
      final sDateKey = sTime.toIso8601String().substring(0, 10);

      // Check if any med was taken on that day within 4 hours prior
      final dayDoses = history[sDateKey] ?? [];
      for (var dose in dayDoses) {
        if (!dose.taken || dose.takenAt == null) continue;

        final tTime = DateTime.parse(dose.takenAt!);
        final diff = sTime.difference(tTime);

        // If symptom occurred between 15 mins and 4 hours after intake
        if (diff.inMinutes >= 15 && diff.inHours <= 4) {
          final med = meds.firstWhere((m) => m.id == dose.medId,
              orElse: () => Medicine.empty());

          correlations.add({
            'medName': med.name,
            'symptom': s.name,
            'severity': s.severity,
            'hoursAfter': diff.inHours,
            'date': sDateKey,
          });
        }
      }
    }
    return correlations;
  }
}
