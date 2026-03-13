class ScheduleEntry {
  int h;
  int m;
  String label;
  List<int> days;
  bool enabled;

  ScheduleEntry({
    required this.h,
    required this.m,
    required this.label,
    required this.days,
    this.enabled = true,
  });

  String get key => '${label}_${h}_$m';

  Map<String, dynamic> toJson() => {
        'h': h,
        'm': m,
        'label': label,
        'days': days,
        'enabled': enabled,
      };

  factory ScheduleEntry.fromJson(Map<String, dynamic> j) => ScheduleEntry(
        h: j['h'] ?? 8,
        m: j['m'] ?? 0,
        label: j['label'] ?? 'Morning',
        days: List<int>.from(j['days'] ?? [1, 2, 3, 4, 5, 6, 0]),
        enabled: j['enabled'] ?? true,
      );

  ScheduleEntry copyWith({bool? enabled}) => ScheduleEntry(
        h: h,
        m: m,
        label: label,
        days: days,
        enabled: enabled ?? this.enabled,
      );
}

class DoseEntry {
  final int medId;
  final String label;
  final String time;
  final bool taken;
  final bool skipped;
  final String? takenAt; // NEW - Actual time taken (ISO)

  DoseEntry({
    required this.medId,
    required this.label,
    required this.time,
    required this.taken,
    this.skipped = false,
    this.takenAt,
  });

  Map<String, dynamic> toJson() => {
        'medId': medId,
        'label': label,
        'time': time,
        'taken': taken,
        'skipped': skipped,
        'takenAt': takenAt,
      };

  factory DoseEntry.fromJson(Map<String, dynamic> j) => DoseEntry(
        medId: j['medId'] ?? 0,
        label: j['label'] ?? '',
        time: j['time'] ?? '',
        taken: j['taken'] ?? false,
        skipped: j['skipped'] ?? false,
        takenAt: j['takenAt'],
      );

  DoseEntry copyWith({bool? taken, bool? skipped, String? takenAt}) =>
      DoseEntry(
        medId: medId,
        label: label,
        time: time,
        taken: taken ?? this.taken,
        skipped: skipped ?? this.skipped,
        takenAt: takenAt ?? this.takenAt,
      );
}

class Medicine {
  final int id;
  String name;
  String brand;
  String dose;
  String form;
  String category;
  int count;
  int totalCount;
  String color; // hex string
  int refillAt;
  String? imageUrl;
  String notes;
  List<ScheduleEntry> schedule;
  String courseStartDate;

  Medicine({
    required this.id,
    required this.name,
    this.brand = '',
    this.dose = '',
    this.form = 'tablet',
    this.category = '',
    required this.count,
    required this.totalCount,
    this.color = '#10B981',
    this.refillAt = 7,
    this.imageUrl,
    this.notes = '',
    this.schedule = const [],
    required this.courseStartDate,
  });

  /// 0.0 – 1.0 course progress fraction.
  double get coursePct => 1.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'dose': dose,
        'form': form,
        'category': category,
        'count': count,
        'totalCount': totalCount,
        'color': color,
        'refillAt': refillAt,
        'imageUrl': imageUrl,
        'notes': notes,
        'schedule': schedule.map((s) => s.toJson()).toList(),
        'courseStartDate': courseStartDate,
      };

  factory Medicine.fromJson(Map<String, dynamic> j) => Medicine(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        brand: j['brand'] ?? '',
        dose: j['dose'] ?? '',
        form: j['form'] ?? 'tablet',
        category: j['category'] ?? '',
        count: j['count'] ?? 0,
        totalCount: j['totalCount'] ?? 30,
        color: j['color'] ?? '#10B981',
        refillAt: j['refillAt'] ?? 7,
        imageUrl: j['imageUrl'],
        notes: j['notes'] ?? '',
        schedule: (j['schedule'] as List<dynamic>? ?? [])
            .map((s) => ScheduleEntry.fromJson(s))
            .toList(),
        courseStartDate: j['courseStartDate'] ?? '',
      );

  Medicine copyWith({
    String? name,
    String? brand,
    String? dose,
    String? form,
    String? category,
    int? count,
    int? totalCount,
    String? color,
    int? refillAt,
    String? notes,
    List<ScheduleEntry>? schedule,
  }) =>
      Medicine(
        id: id,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        dose: dose ?? this.dose,
        form: form ?? this.form,
        category: category ?? this.category,
        count: count ?? this.count,
        totalCount: totalCount ?? this.totalCount,
        color: color ?? this.color,
        refillAt: refillAt ?? this.refillAt,
        imageUrl: imageUrl,
        notes: notes ?? this.notes,
        schedule: schedule ?? this.schedule,
        courseStartDate: courseStartDate,
      );
}
