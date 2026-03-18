class HealthInsight {
  final String category;
  final String title;
  final String body;
  final List<String> steps;

  HealthInsight({
    required this.category,
    required this.title,
    required this.body,
    this.steps = const [],
  });

  factory HealthInsight.fromJson(Map<String, dynamic> json) {
    return HealthInsight(
      category: json['category'] ?? 'General',
      title: json['title'] ?? 'Insight',
      body: json['body'] ?? '',
      steps: (json['steps'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'title': title,
        'body': body,
        'steps': steps,
      };
}
