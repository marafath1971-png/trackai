class UserProfile {
  final String name;
  final String age;
  final String gender;
  final String goal;
  final List<String> conditions;
  final String medCount;
  final String forgetting;
  final Map<String, int> wakeTime;
  final Map<String, int> breakfastTime;
  final Map<String, int> lunchTime;
  final Map<String, int> dinnerTime;
  final Map<String, int> sleepTime;
  final String doctorVisits;
  final String support;
  final String challenge;
  final String prevApp;
  final List<String> motivation;
  final String reminderStyle;
  final bool notifPerm;
  final bool notifSound;
  final bool notifRefill;
  final String? promoCode;
  final Map<String, dynamic>? appliedPromo;
  final String avatar;
  final bool biometricEnabled;
  final String accentColor;
  final String appIcon;
  final String reminderSound;
  final int scansUsed;
  final bool isPremium;
  final String? photoUrl;
  final DateTime createdAt;
  final int dosesMarked;
  final DateTime? lastReviewPromptedAt;

  UserProfile({
    this.name = '',
    this.age = '',
    this.gender = '',
    this.goal = '',
    this.conditions = const [],
    this.medCount = '',
    this.forgetting = '',
    this.wakeTime = const {'h': 7, 'm': 0},
    this.breakfastTime = const {'h': 8, 'm': 0},
    this.lunchTime = const {'h': 12, 'm': 0},
    this.dinnerTime = const {'h': 19, 'm': 0},
    this.sleepTime = const {'h': 22, 'm': 0},
    this.doctorVisits = '',
    this.support = '',
    this.challenge = '',
    this.prevApp = '',
    this.motivation = const [],
    this.reminderStyle = '',
    this.notifPerm = true,
    this.notifSound = true,
    this.notifRefill = true,
    this.promoCode,
    this.appliedPromo,
    this.avatar = '😊',
    this.biometricEnabled = false,
    this.accentColor = '111111',
    this.appIcon = 'classic',
    this.reminderSound = 'default',
    this.scansUsed = 0,
    this.isPremium = false,
    this.photoUrl,
    DateTime? createdAt,
    this.dosesMarked = 0,
    this.lastReviewPromptedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'gender': gender,
        'goal': goal,
        'conditions': conditions,
        'medCount': medCount,
        'forgetting': forgetting,
        'wakeTime': wakeTime,
        'breakfastTime': breakfastTime,
        'lunchTime': lunchTime,
        'dinnerTime': dinnerTime,
        'sleepTime': sleepTime,
        'doctorVisits': doctorVisits,
        'support': support,
        'challenge': challenge,
        'prevApp': prevApp,
        'motivation': motivation,
        'reminderStyle': reminderStyle,
        'notifPerm': notifPerm,
        'notifSound': notifSound,
        'notifRefill': notifRefill,
        'promoCode': promoCode,
        'appliedPromo': appliedPromo,
        'avatar': avatar,
        'biometricEnabled': biometricEnabled,
        'accentColor': accentColor,
        'appIcon': appIcon,
        'reminderSound': reminderSound,
        'scansUsed': scansUsed,
        'isPremium': isPremium,
        'photoUrl': photoUrl,
        'createdAt': createdAt.toIso8601String(),
        'dosesMarked': dosesMarked,
        'lastReviewPromptedAt': lastReviewPromptedAt?.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: j['name'] ?? '',
        age: j['age'] ?? '',
        gender: j['gender'] ?? '',
        goal: j['goal'] ?? '',
        conditions: List<String>.from(j['conditions'] ?? []),
        medCount: j['medCount'] ?? '',
        forgetting: j['forgetting'] ?? '',
        wakeTime: Map<String, int>.from(j['wakeTime'] ?? {'h': 7, 'm': 0}),
        breakfastTime:
            Map<String, int>.from(j['breakfastTime'] ?? {'h': 8, 'm': 0}),
        lunchTime: Map<String, int>.from(j['lunchTime'] ?? {'h': 12, 'm': 0}),
        dinnerTime: Map<String, int>.from(j['dinnerTime'] ?? {'h': 19, 'm': 0}),
        sleepTime: Map<String, int>.from(j['sleepTime'] ?? {'h': 22, 'm': 0}),
        doctorVisits: j['doctorVisits'] ?? '',
        support: j['support'] ?? '',
        challenge: j['challenge'] ?? '',
        prevApp: j['prevApp'] ?? '',
        motivation: List<String>.from(j['motivation'] ?? []),
        reminderStyle: j['reminderStyle'] ?? '',
        notifPerm: j['notifPerm'] ?? true,
        notifSound: j['notifSound'] ?? true,
        notifRefill: j['notifRefill'] ?? true,
        promoCode: j['promoCode'],
        appliedPromo: j['appliedPromo'],
        avatar: j['avatar'] ?? '😊',
        biometricEnabled: j['biometricEnabled'] ?? false,
        accentColor: j['accentColor'] ?? '111111',
        appIcon: j['appIcon'] ?? 'classic',
        reminderSound: j['reminderSound'] ?? 'default',
        scansUsed: j['scansUsed'] ?? 0,
        isPremium: j['isPremium'] ?? false,
        photoUrl: j['photoUrl'],
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt'])
            : DateTime.now(),
        dosesMarked: j['dosesMarked'] ?? 0,
        lastReviewPromptedAt: j['lastReviewPromptedAt'] != null
            ? DateTime.parse(j['lastReviewPromptedAt'])
            : null,
      );

  UserProfile copyWith({
    String? name,
    String? age,
    String? gender,
    String? goal,
    List<String>? conditions,
    String? medCount,
    String? forgetting,
    Map<String, int>? wakeTime,
    Map<String, int>? breakfastTime,
    Map<String, int>? lunchTime,
    Map<String, int>? dinnerTime,
    Map<String, int>? sleepTime,
    String? doctorVisits,
    String? support,
    String? challenge,
    String? prevApp,
    List<String>? motivation,
    String? reminderStyle,
    bool? notifPerm,
    bool? notifSound,
    bool? notifRefill,
    String? avatar,
    bool? biometricEnabled,
    String? accentColor,
    String? appIcon,
    String? reminderSound,
    int? scansUsed,
    bool? isPremium,
    String? photoUrl,
    DateTime? createdAt,
    int? dosesMarked,
    DateTime? lastReviewPromptedAt,
  }) =>
      UserProfile(
        name: name ?? this.name,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        goal: goal ?? this.goal,
        conditions: conditions ?? this.conditions,
        medCount: medCount ?? this.medCount,
        forgetting: forgetting ?? this.forgetting,
        wakeTime: wakeTime ?? this.wakeTime,
        breakfastTime: breakfastTime ?? this.breakfastTime,
        lunchTime: lunchTime ?? this.lunchTime,
        dinnerTime: dinnerTime ?? this.dinnerTime,
        sleepTime: sleepTime ?? this.sleepTime,
        doctorVisits: doctorVisits ?? this.doctorVisits,
        support: support ?? this.support,
        challenge: challenge ?? this.challenge,
        prevApp: prevApp ?? this.prevApp,
        motivation: motivation ?? this.motivation,
        reminderStyle: reminderStyle ?? this.reminderStyle,
        notifPerm: notifPerm ?? this.notifPerm,
        notifSound: notifSound ?? this.notifSound,
        notifRefill: notifRefill ?? this.notifRefill,
        promoCode: promoCode,
        appliedPromo: appliedPromo,
        avatar: avatar ?? this.avatar,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        accentColor: accentColor ?? this.accentColor,
        appIcon: appIcon ?? this.appIcon,
        reminderSound: reminderSound ?? this.reminderSound,
        scansUsed: scansUsed ?? this.scansUsed,
        isPremium: isPremium ?? this.isPremium,
        photoUrl: photoUrl ?? this.photoUrl,
        createdAt: createdAt ?? this.createdAt,
        dosesMarked: dosesMarked ?? this.dosesMarked,
        lastReviewPromptedAt: lastReviewPromptedAt ?? this.lastReviewPromptedAt,
      );
}
