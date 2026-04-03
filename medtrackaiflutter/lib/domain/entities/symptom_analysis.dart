class SymptomAnalysis {
  final String description;
  final List<String> steps;
  final String warning;

  SymptomAnalysis({
    required this.description,
    this.steps = const [],
    this.warning =
        'This is not medical advice. Consult your doctor if symptoms persist.',
  });

  factory SymptomAnalysis.fromJson(Map<String, dynamic> json) {
    return SymptomAnalysis(
      description: json['description'] ?? '',
      steps: (json['steps'] as List?)?.map((e) => e.toString()).toList() ?? [],
      warning: json['warning'] ??
          'This is not medical advice. Consult your doctor if symptoms persist.',
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'steps': steps,
        'warning': warning,
      };
}
