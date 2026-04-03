class AISafetyProfile {
  final List<String> warnings;
  final List<String> interactions;
  final List<String> foodRules;
  final List<String> ahaMoments;

  const AISafetyProfile({
    required this.warnings,
    required this.interactions,
    required this.foodRules,
    required this.ahaMoments,
  });

  Map<String, dynamic> toJson() => {
        'warnings': warnings,
        'interactions': interactions,
        'foodRules': foodRules,
        'ahaMoments': ahaMoments,
      };

  factory AISafetyProfile.fromJson(Map<String, dynamic> json) =>
      AISafetyProfile(
        warnings: List<String>.from(json['warnings'] ?? []),
        interactions: List<String>.from(json['interactions'] ?? []),
        foodRules: List<String>.from(json['foodRules'] ?? []),
        ahaMoments: List<String>.from(json['ahaMoments'] ?? []),
      );
}
