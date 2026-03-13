class ScanResult {
  bool identified;
  String name;
  String brand;
  String dose;
  String form;
  bool isLiquid;
  bool isAntibiotic;
  String category;
  String description;
  String howToTake;
  String sideEffects;
  String interactions;
  String storage;
  String whenToTake;
  String frequency;
  int pillCount;
  int packSize;
  int refillAlert;
  int volumeAmount;
  String volumeUnit;
  String dosePerTake;
  String confidence;
  String? imageUrl;

  // Phase 3 additions:
  int? courseDurationDays;
  String courseType; // fixed, ongoing, as-needed
  List<Map<String, dynamic>>
      scheduleSlots; // e.g., [{"label":"Morning", "h":8, "m":0}]
  bool withFood;
  String warnings;
  bool isOngoing;

  ScanResult({
    this.identified = false,
    this.name = '',
    this.brand = '',
    this.dose = '',
    this.form = 'tablet',
    this.isLiquid = false,
    this.isAntibiotic = false,
    this.category = '',
    this.description = '',
    this.howToTake = '',
    this.sideEffects = '',
    this.interactions = '',
    this.storage = '',
    this.whenToTake = '',
    this.frequency = '',
    this.pillCount = 30,
    this.packSize = 30,
    this.refillAlert = 7,
    this.volumeAmount = 0,
    this.volumeUnit = 'ml',
    this.dosePerTake = '',
    this.confidence = 'low',
    this.imageUrl,
    this.courseDurationDays,
    this.courseType = 'ongoing',
    this.scheduleSlots = const [],
    this.withFood = false,
    this.warnings = '',
    this.isOngoing = true,
  });

  int _parseInt(dynamic v, int fallback) {
    if (v == null) return fallback;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? fallback;
  }

  factory ScanResult.fromJson(Map<String, dynamic> j) {
    final self = ScanResult();
    return ScanResult(
      identified: j['identified'] ?? false,
      name: j['name'] ?? '',
      brand: j['brand'] ?? '',
      dose: j['dose'] ?? '',
      form: j['form'] ?? 'tablet',
      isLiquid: j['isLiquid'] ?? false,
      isAntibiotic: j['isAntibiotic'] ?? false,
      category: j['category'] ?? '',
      description: j['description'] ?? '',
      howToTake: j['howToTake'] ?? '',
      sideEffects: j['sideEffects'] ?? '',
      interactions: j['interactions'] ?? '',
      storage: j['storage'] ?? '',
      whenToTake: j['whenToTake'] ?? '',
      frequency: j['frequency'] ?? '',
      pillCount: self._parseInt(j['pillCount'], 30),
      packSize: self._parseInt(j['packSize'], 30),
      refillAlert: self._parseInt(j['refillAlert'], 7),
      volumeAmount: self._parseInt(j['volumeAmount'], 0),
      volumeUnit: j['volumeUnit'] ?? 'ml',
      dosePerTake: j['dosePerTake'] ?? '',
      confidence: j['confidence'] ?? 'low',
      imageUrl: j['imageUrl'],
      courseDurationDays: j['courseDurationDays'] != null
          ? self._parseInt(j['courseDurationDays'], 0)
          : null,
      courseType: j['courseType'] ?? 'ongoing',
      scheduleSlots: (j['scheduleSlots'] as List?)?.map((e) {
            if (e is Map) return Map<String, dynamic>.from(e);
            return <String, dynamic>{};
          }).toList() ??
          [],
      withFood: j['withFood'] ?? false,
      warnings: j['warnings'] ?? '',
      isOngoing: j['isOngoing'] ?? (j['courseType'] == 'ongoing'),
    );
  }

  ScanResult copyWith({
    bool? identified,
    String? name,
    String? brand,
    String? dose,
    String? form,
    bool? isLiquid,
    bool? isAntibiotic,
    String? category,
    String? description,
    String? howToTake,
    String? sideEffects,
    String? interactions,
    String? storage,
    String? whenToTake,
    String? frequency,
    int? pillCount,
    int? packSize,
    int? refillAlert,
    int? volumeAmount,
    String? volumeUnit,
    String? dosePerTake,
    String? confidence,
    String? imageUrl,
    int? courseDurationDays,
    String? courseType,
    List<Map<String, dynamic>>? scheduleSlots,
    bool? withFood,
    String? warnings,
    bool? isOngoing,
  }) =>
      ScanResult(
        identified: identified ?? this.identified,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        dose: dose ?? this.dose,
        form: form ?? this.form,
        isLiquid: isLiquid ?? this.isLiquid,
        isAntibiotic: isAntibiotic ?? this.isAntibiotic,
        category: category ?? this.category,
        description: description ?? this.description,
        howToTake: howToTake ?? this.howToTake,
        sideEffects: sideEffects ?? this.sideEffects,
        interactions: interactions ?? this.interactions,
        storage: storage ?? this.storage,
        whenToTake: whenToTake ?? this.whenToTake,
        frequency: frequency ?? this.frequency,
        pillCount: pillCount ?? this.pillCount,
        packSize: packSize ?? this.packSize,
        refillAlert: refillAlert ?? this.refillAlert,
        volumeAmount: volumeAmount ?? this.volumeAmount,
        volumeUnit: volumeUnit ?? this.volumeUnit,
        dosePerTake: dosePerTake ?? this.dosePerTake,
        confidence: confidence ?? this.confidence,
        imageUrl: imageUrl ?? this.imageUrl,
        courseDurationDays: courseDurationDays ?? this.courseDurationDays,
        courseType: courseType ?? this.courseType,
        scheduleSlots: scheduleSlots ?? this.scheduleSlots,
        withFood: withFood ?? this.withFood,
        warnings: warnings ?? this.warnings,
        isOngoing: isOngoing ?? this.isOngoing,
      );
}
