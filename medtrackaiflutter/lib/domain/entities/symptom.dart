class Symptom {
  final String id;
  final String name;
  final int severity; // 1-10
  final String? notes;
  final DateTime timestamp;

  Symptom({
    required this.id,
    required this.name,
    required this.severity,
    this.notes,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'severity': severity,
        'notes': notes,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Symptom.fromJson(Map<String, dynamic> j) => Symptom(
        id: j['id'],
        name: j['name'],
        severity: j['severity'] ?? 1,
        notes: j['notes'],
        timestamp: DateTime.parse(j['timestamp']),
      );

  Symptom copyWith({
    String? id,
    String? name,
    int? severity,
    String? notes,
    DateTime? timestamp,
  }) =>
      Symptom(
        id: id ?? this.id,
        name: name ?? this.name,
        severity: severity ?? this.severity,
        notes: notes ?? this.notes,
        timestamp: timestamp ?? this.timestamp,
      );
}
