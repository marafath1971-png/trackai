enum PredictiveType { eveningRisk, weekendSlump, travelRisk, heatWarning }

class PredictiveInsight {
  final PredictiveType type;
  final String title;
  final String description;
  final double impactScore; // 0.0 to 1.0

  PredictiveInsight({
    required this.type,
    required this.title,
    required this.description,
    this.impactScore = 0.5,
  });
}
