class AISafetyProfile {
  final List<String> warnings;
  final List<String> interactions;
  final List<String> foodRules;
  final List<String> ahaMoments;
  
  // Phase 3 Pharmacokinetic / Body Impact extensions
  final String mechanismOfAction;
  final int onsetMinutes;
  final double peakHours;
  final double durationHours;
  final List<String> bodySystems;
  final List<Map<String, dynamic>> timelineEffects;
  final List<String> ahaFacts;

  const AISafetyProfile({
    required this.warnings,
    required this.interactions,
    required this.foodRules,
    required this.ahaMoments,
    this.mechanismOfAction = 'Details about how this medication works in your body will appear here.',
    this.onsetMinutes = 0,
    this.peakHours = 0.0,
    this.durationHours = 0.0,
    this.bodySystems = const [],
    this.timelineEffects = const [],
    this.ahaFacts = const [],
  });

  Map<String, dynamic> toJson() => {
        'warnings': warnings,
        'interactions': interactions,
        'foodRules': foodRules,
        'ahaMoments': ahaMoments,
        'mechanismOfAction': mechanismOfAction,
        'onsetMinutes': onsetMinutes,
        'peakHours': peakHours,
        'durationHours': durationHours,
        'bodySystems': bodySystems,
        'timelineEffects': timelineEffects,
        'ahaFacts': ahaFacts,
      };

  factory AISafetyProfile.fromJson(Map<String, dynamic> json) =>
      AISafetyProfile(
        warnings: List<String>.from(json['warnings'] ?? []),
        interactions: List<String>.from(json['interactions'] ?? []),
        foodRules: List<String>.from(json['foodRules'] ?? []),
        ahaMoments: List<String>.from(json['ahaMoments'] ?? []),
        mechanismOfAction: json['mechanismOfAction'] ?? 'Details about how this medication works in your body will appear here.',
        onsetMinutes: (json['onsetMinutes'] as num?)?.toInt() ?? 0,
        peakHours: (json['peakHours'] as num?)?.toDouble() ?? 0.0,
        durationHours: (json['durationHours'] as num?)?.toDouble() ?? 0.0,
        bodySystems: List<String>.from(json['bodySystems'] ?? []),
        timelineEffects: List<Map<String, dynamic>>.from(
          (json['timelineEffects'] as List?)?.map(
                  (e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}) ??
              [],
        ),
        ahaFacts: List<String>.from(json['ahaFacts'] ?? []),
      );
}
