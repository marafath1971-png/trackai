enum PredictiveType { eveningRisk, weekendSlump, travelRisk, heatWarning }

class PredictiveInsight {
  final PredictiveType type;
  final String title;
  final String description;
  final double impactScore;

  PredictiveInsight({
    required this.type,
    required this.title,
    required this.description,
    this.impactScore = 0.5,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'title': title,
        'description': description,
        'impactScore': impactScore,
      };

  factory PredictiveInsight.fromJson(Map<String, dynamic> j) =>
      PredictiveInsight(
        type: PredictiveType.values.firstWhere(
          (e) => e.name == j['type'],
          orElse: () => PredictiveType.eveningRisk,
        ),
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        impactScore: (j['impactScore'] ?? 0.5).toDouble(),
      );
}
