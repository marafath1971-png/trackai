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

  const UserProfile({
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
  });

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
      );

  UserProfile copyWith({
    String? name,
    String? age,
    String? gender,
    String? goal,
    List<String>? conditions,
    String? avatar,
    bool? notifPerm,
    bool? notifSound,
    bool? notifRefill,
  }) =>
      UserProfile(
        name: name ?? this.name,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        goal: goal ?? this.goal,
        conditions: conditions ?? this.conditions,
        medCount: medCount,
        forgetting: forgetting,
        wakeTime: wakeTime,
        breakfastTime: breakfastTime,
        lunchTime: lunchTime,
        dinnerTime: dinnerTime,
        sleepTime: sleepTime,
        doctorVisits: doctorVisits,
        support: support,
        challenge: challenge,
        prevApp: prevApp,
        motivation: motivation,
        reminderStyle: reminderStyle,
        notifPerm: notifPerm ?? this.notifPerm,
        notifSound: notifSound ?? this.notifSound,
        notifRefill: notifRefill ?? this.notifRefill,
        promoCode: promoCode,
        appliedPromo: appliedPromo,
        avatar: avatar ?? this.avatar,
      );
}
