class BodyImpactSummary {
  final String mechanismOfAction;
  final int onsetMinutes;
  final double peakHours;
  final double durationHours;
  final List<String> bodySystems;
  final List<Map<String, dynamic>> timelineEffects;
  final List<String> ahaFacts;

  const BodyImpactSummary({
    required this.mechanismOfAction,
    required this.onsetMinutes,
    required this.peakHours,
    required this.durationHours,
    required this.bodySystems,
    required this.timelineEffects,
    required this.ahaFacts,
  });

  Map<String, dynamic> toJson() => {
        'mechanismOfAction': mechanismOfAction,
        'onsetMinutes': onsetMinutes,
        'peakHours': peakHours,
        'durationHours': durationHours,
        'bodySystems': bodySystems,
        'timelineEffects': timelineEffects,
        'ahaFacts': ahaFacts,
      };

  factory BodyImpactSummary.fromJson(Map<String, dynamic> json) =>
      BodyImpactSummary(
        mechanismOfAction: json['mechanismOfAction'] ?? 'Unknown mechanism.',
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

  factory BodyImpactSummary.empty() => const BodyImpactSummary(
        mechanismOfAction: '',
        onsetMinutes: 0,
        peakHours: 0,
        durationHours: 0,
        bodySystems: [],
        timelineEffects: [],
        ahaFacts: [],
      );
}
