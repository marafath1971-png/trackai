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

  factory BodyImpactSummary.fromJson(Map<String, dynamic> json) {
    num parseNum(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v;
      return num.tryParse(v.toString()) ?? 0;
    }

    return BodyImpactSummary(
      mechanismOfAction: json['mechanismOfAction'] ?? 'Unknown mechanism.',
      onsetMinutes: parseNum(json['onsetMinutes']).toInt(),
      peakHours: parseNum(json['peakHours']).toDouble(),
      durationHours: parseNum(json['durationHours']).toDouble(),
      bodySystems: List<String>.from(json['bodySystems'] ?? []),
      timelineEffects: List<Map<String, dynamic>>.from(
        (json['timelineEffects'] as List?)?.map((e) => e is Map
                ? Map<String, dynamic>.from(e)
                : <String, dynamic>{}) ??
            [],
      ),
      ahaFacts: List<String>.from(json['ahaFacts'] ?? []),
    );
  }

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
