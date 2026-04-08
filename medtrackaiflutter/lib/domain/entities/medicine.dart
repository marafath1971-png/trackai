import 'package:medai/domain/entities/ai_safety_profile.dart';

enum Ritual {
  none,
  beforeBreakfast,
  withBreakfast,
  afterBreakfast,
  beforeLunch,
  withLunch,
  afterLunch,
  beforeDinner,
  withDinner,
  afterDinner,
  beforeSleep,
  onWaking,
  asNeeded,
}

extension RitualExtension on Ritual {
  String get displayName {
    switch (this) {
      case Ritual.none:
        return 'Standard';
      case Ritual.beforeBreakfast:
        return 'Before Breakfast';
      case Ritual.withBreakfast:
        return 'With Breakfast';
      case Ritual.afterBreakfast:
        return 'After Breakfast';
      case Ritual.beforeLunch:
        return 'Before Lunch';
      case Ritual.withLunch:
        return 'With Lunch';
      case Ritual.afterLunch:
        return 'After Lunch';
      case Ritual.beforeDinner:
        return 'Before Dinner';
      case Ritual.withDinner:
        return 'With Dinner';
      case Ritual.afterDinner:
        return 'After Dinner';
      case Ritual.beforeSleep:
        return 'Before Sleep';
      case Ritual.onWaking:
        return 'On Waking';
      case Ritual.asNeeded:
        return 'As Needed';
    }
  }

  String get emoji {
    switch (this) {
      case Ritual.none:
        return '';
      case Ritual.beforeBreakfast:
      case Ritual.withBreakfast:
      case Ritual.afterBreakfast:
        return '🍳'; // More descriptive than bread
      case Ritual.beforeLunch:
      case Ritual.withLunch:
      case Ritual.afterLunch:
        return '🍱'; // Modern bento box for lunch
      case Ritual.beforeDinner:
      case Ritual.withDinner:
      case Ritual.afterDinner:
        return '🍽️'; // Premium dinner setting
      case Ritual.beforeSleep:
        return '🌃'; // Modern night vista
      case Ritual.onWaking:
        return '☀️'; // Crisp sunrise
      case Ritual.asNeeded:
        return '🆘';
    }
  }
}

class ScheduleEntry {
  final String id;
  int h;
  int m;
  String label;
  List<int> days;
  bool enabled;
  Ritual ritual;

  ScheduleEntry({
    required this.id,
    required this.h,
    required this.m,
    required this.label,
    required this.days,
    this.enabled = true,
    this.ritual = Ritual.none,
  });

  String get key => '${label}_${h}_$m';

  Map<String, dynamic> toJson() => {
        'id': id,
        'h': h,
        'm': m,
        'label': label,
        'days': days,
        'enabled': enabled,
        'ritual': ritual.name,
      };

  factory ScheduleEntry.fromJson(Map<String, dynamic> j) => ScheduleEntry(
        id: j['id'] ??
            (j['label'] ?? 'Morning') +
                (j['h'] ?? 8).toString() +
                (j['m'] ?? 0).toString(),
        h: j['h'] ?? 8,
        m: j['m'] ?? 0,
        label: j['label'] ?? 'Morning',
        days: List<int>.from(j['days'] ?? [1, 2, 3, 4, 5, 6, 0]),
        enabled: j['enabled'] ?? true,
        ritual: Ritual.values.firstWhere(
          (e) => e.name == j['ritual'],
          orElse: () => Ritual.none,
        ),
      );

  ScheduleEntry copyWith({
    String? id,
    int? h,
    int? m,
    String? label,
    List<int>? days,
    bool? enabled,
    Ritual? ritual,
  }) {
    return ScheduleEntry(
      id: id ?? this.id,
      h: h ?? this.h,
      m: m ?? this.m,
      label: label ?? this.label,
      days: days ?? this.days,
      enabled: enabled ?? this.enabled,
      ritual: ritual ?? this.ritual,
    );
  }
}

typedef DoseHistoryEntry = DoseEntry;

class DoseEntry {
  final int medId;
  final String? scheduleId;
  final String label;
  final String time;
  final bool taken;
  final bool skipped;
  final String? takenAt;

  DoseEntry({
    required this.medId,
    this.scheduleId,
    required this.label,
    required this.time,
    required this.taken,
    this.skipped = false,
    this.takenAt,
  });

  Map<String, dynamic> toJson() => {
        'medId': medId,
        'scheduleId': scheduleId,
        'label': label,
        'time': time,
        'taken': taken,
        'skipped': skipped,
        'takenAt': takenAt,
      };

  factory DoseEntry.fromJson(Map<String, dynamic> j) => DoseEntry(
        medId: j['medId'] ?? 0,
        scheduleId: j['scheduleId'],
        label: j['label'] ?? '',
        time: j['time'] ?? '',
        taken: j['taken'] ?? false,
        skipped: j['skipped'] ?? false,
        takenAt: j['takenAt'],
      );

  DoseEntry copyWith(
          {String? scheduleId, bool? taken, bool? skipped, String? takenAt}) =>
      DoseEntry(
        medId: medId,
        scheduleId: scheduleId ?? this.scheduleId,
        label: label,
        time: time,
        taken: taken ?? this.taken,
        skipped: skipped ?? this.skipped,
        takenAt: takenAt ?? this.takenAt,
      );
}

class RefillInfo {
  final String? pharmacyName;
  final String? pharmacyPhone;
  final String? rxNumber;
  final String? lastRefilledAt;
  final double totalQuantity;
  final double currentInventory;
  final double refillThreshold;

  RefillInfo({
    this.pharmacyName = '',
    this.pharmacyPhone = '',
    this.rxNumber = '',
    this.lastRefilledAt,
    this.totalQuantity = 30.0,
    this.currentInventory = 30.0,
    this.refillThreshold = 7.0,
  });

  Map<String, dynamic> toJson() => {
        'pharmacyName': pharmacyName,
        'pharmacyPhone': pharmacyPhone,
        'rxNumber': rxNumber,
        'lastRefilledAt': lastRefilledAt,
        'totalQuantity': totalQuantity,
        'currentInventory': currentInventory,
        'refillThreshold': refillThreshold,
      };

  factory RefillInfo.fromJson(Map<String, dynamic> j) => RefillInfo(
        pharmacyName: j['pharmacyName'] ?? '',
        pharmacyPhone: j['pharmacyPhone'] ?? '',
        rxNumber: j['rxNumber'] ?? '',
        lastRefilledAt: j['lastRefilledAt'],
        totalQuantity: (j['totalQuantity'] ?? 30.0).toDouble(),
        currentInventory: (j['currentInventory'] ?? 30.0).toDouble(),
        refillThreshold: (j['refillThreshold'] ?? 7.0).toDouble(),
      );

  RefillInfo copyWith({
    String? pharmacyName,
    String? pharmacyPhone,
    String? rxNumber,
    String? lastRefilledAt,
    double? totalQuantity,
    double? currentInventory,
    double? refillThreshold,
  }) =>
      RefillInfo(
        pharmacyName: pharmacyName ?? this.pharmacyName,
        pharmacyPhone: pharmacyPhone ?? this.pharmacyPhone,
        rxNumber: rxNumber ?? this.rxNumber,
        lastRefilledAt: lastRefilledAt ?? this.lastRefilledAt,
        totalQuantity: totalQuantity ?? this.totalQuantity,
        currentInventory: currentInventory ?? this.currentInventory,
        refillThreshold: refillThreshold ?? this.refillThreshold,
      );
}

class Medicine {
  final int id;
  final String name;
  final String brand;
  final String genericName;
  final String din;
  final String dose;
  final String form;
  final String category;
  final int count;
  final int totalCount;
  final String color;
  final int refillAt;
  final String? imageUrl;
  final String notes;
  final String intakeInstructions;
  final List<ScheduleEntry> schedule;
  final String courseStartDate;
  final String unit;
  final bool isPrescription;
  final RefillInfo? refillInfo;
  final double? price;
  final String? currency;
  final bool isHalalSafe;
  final bool? isHalalCertified;
  final bool isSachet;
  final String? repeatPrescriptionDueDate;
  final AISafetyProfile? aiSafetyProfile;
  final bool isCritical;

  Medicine({
    required this.id,
    required this.name,
    this.brand = '',
    this.genericName = '',
    this.din = '',
    this.dose = '',
    this.form = 'tablet',
    this.category = 'Tablet',
    this.count = 30,
    this.totalCount = 30,
    this.color = '#10B981',
    this.refillAt = 7,
    this.imageUrl,
    this.notes = '',
    this.intakeInstructions = '',
    this.schedule = const [],
    required this.courseStartDate,
    this.unit = 'units',
    this.isPrescription = false,
    this.refillInfo,
    this.price,
    this.currency,
    this.isHalalSafe = true,
    this.isHalalCertified,
    this.isSachet = false,
    this.repeatPrescriptionDueDate,
    this.aiSafetyProfile,
    this.isCritical = false,
  });

  factory Medicine.empty() => Medicine(
        id: -1,
        name: 'Empty Medicine',
        courseStartDate: '',
        schedule: [],
      );

  double get coursePct => 1.0;

  String? get halalStatus {
    if (isHalalSafe) return 'safe';
    if (isHalalCertified == false) return 'non-halal';
    return 'none';
  }

  String? get halalNote {
    if (isHalalCertified == true) return 'Certified Halal';
    if (!isHalalSafe) return 'Contains animal-derived ingredients';
    return null;
  }

  String get frequency {
    if (schedule.isEmpty) return 'No schedule';
    final count = schedule.length;
    if (count == 1) return 'Once daily';
    if (count == 2) return 'Twice daily';
    if (count == 3) return 'Three times daily';
    return '$count times daily';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'genericName': genericName,
        'din': din,
        'dose': dose,
        'form': form,
        'category': category,
        'count': count,
        'totalCount': totalCount,
        'color': color,
        'refillAt': refillAt,
        'imageUrl': imageUrl,
        'notes': notes,
        'intakeInstructions': intakeInstructions,
        'schedule': schedule.map((s) => s.toJson()).toList(),
        'courseStartDate': courseStartDate,
        'unit': unit,
        'isPrescription': isPrescription,
        'refillInfo': refillInfo?.toJson(),
        'price': price,
        'currency': currency,
        'isHalalSafe': isHalalSafe,
        'isHalalCertified': isHalalCertified,
        'isSachet': isSachet,
        'repeatPrescriptionDueDate': repeatPrescriptionDueDate,
        'aiSafetyProfile': aiSafetyProfile?.toJson(),
        'isCritical': isCritical,
      };

  factory Medicine.fromJson(Map<String, dynamic> j) => Medicine(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        brand: j['brand'] ?? '',
        genericName: j['genericName'] ?? '',
        din: j['din'] ?? '',
        dose: j['dose'] ?? '',
        form: j['form'] ?? 'tablet',
        category: j['category'] ?? '',
        count: j['count'] ?? 0,
        totalCount: j['totalCount'] ?? 30,
        color: j['color'] ?? '#10B981',
        refillAt: j['refillAt'] ?? 7,
        imageUrl: j['imageUrl'],
        notes: j['notes'] ?? '',
        intakeInstructions: j['intakeInstructions'] ?? '',
        schedule: (j['schedule'] as List<dynamic>? ?? [])
            .map((s) => ScheduleEntry.fromJson(s))
            .toList(),
        courseStartDate: j['courseStartDate'] ?? '',
        unit: j['unit'] ?? 'units',
        isPrescription: j['isPrescription'] ?? false,
        refillInfo: j['refillInfo'] != null
            ? RefillInfo.fromJson(j['refillInfo'])
            : null,
        price: (j['price'] as num?)?.toDouble(),
        currency: j['currency'],
        isHalalSafe: j['isHalalSafe'] ?? true,
        isHalalCertified: j['isHalalCertified'],
        isSachet: j['isSachet'] ?? false,
        repeatPrescriptionDueDate: j['repeatPrescriptionDueDate'],
        aiSafetyProfile: j['aiSafetyProfile'] != null
            ? AISafetyProfile.fromJson(j['aiSafetyProfile'])
            : null,
        isCritical: j['isCritical'] ?? false,
      );

  Medicine copyWith({
    String? name,
    String? brand,
    String? genericName,
    String? din,
    String? dose,
    String? form,
    String? category,
    int? count,
    int? totalCount,
    String? color,
    int? refillAt,
    String? notes,
    String? intakeInstructions,
    List<ScheduleEntry>? schedule,
    String? unit,
    bool? isPrescription,
    RefillInfo? refillInfo,
    double? price,
    String? currency,
    bool? isHalalSafe,
    bool? isHalalCertified,
    bool? isSachet,
    String? repeatPrescriptionDueDate,
    AISafetyProfile? aiSafetyProfile,
    bool? isCritical,
  }) =>
      Medicine(
        id: id,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        genericName: genericName ?? this.genericName,
        din: din ?? this.din,
        dose: dose ?? this.dose,
        form: form ?? this.form,
        category: category ?? this.category,
        count: count ?? this.count,
        totalCount: totalCount ?? this.totalCount,
        color: color ?? this.color,
        refillAt: refillAt ?? this.refillAt,
        imageUrl: imageUrl,
        notes: notes ?? this.notes,
        intakeInstructions: intakeInstructions ?? this.intakeInstructions,
        schedule: schedule ?? this.schedule,
        courseStartDate: courseStartDate,
        unit: unit ?? this.unit,
        isPrescription: isPrescription ?? this.isPrescription,
        refillInfo: refillInfo ?? this.refillInfo,
        price: price ?? this.price,
        currency: currency ?? this.currency,
        isHalalSafe: isHalalSafe ?? this.isHalalSafe,
        isHalalCertified: isHalalCertified ?? this.isHalalCertified,
        isSachet: isSachet ?? this.isSachet,
        repeatPrescriptionDueDate:
            repeatPrescriptionDueDate ?? this.repeatPrescriptionDueDate,
        aiSafetyProfile: aiSafetyProfile ?? this.aiSafetyProfile,
        isCritical: isCritical ?? this.isCritical,
      );
}
