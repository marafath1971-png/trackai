import 'caregiver.dart';
import 'managed_profile.dart';

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
  final String country;
  final DateTime createdAt;
  final int dosesMarked;
  final DateTime? lastReviewPromptedAt;
  // ── Global Market Settings ──────────────────────────
  final bool shabbatMode; // IL: gentle mode Friday sunset–Saturday night
  final String preferredLanguage; // en, fr, ja, ko, he, ms, zh
  final bool showGenericNames; // UK, IL, CA: show INN names instead of brand
  final double pbsSpendThisYear; // AU: PBS Safety Net spend tracker
  final bool diabetesMode; // MY, US: glucose tracking alongside meds
  final bool hypertensionMode; // MY, US: BP tracking alongside meds
  final bool amoledMode; // KR: pure black AMOLED display
  final DateTime? lastNudgeAt;
  final int nudgeCount;
  final List<Caregiver> caregiverContacts;
  final List<ManagedProfile> familyMembers;

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
    this.country = '',
    DateTime? createdAt,
    this.dosesMarked = 0,
    this.lastReviewPromptedAt,
    this.shabbatMode = false,
    this.preferredLanguage = 'en',
    this.showGenericNames = false,
    this.pbsSpendThisYear = 0.0,
    this.diabetesMode = false,
    this.hypertensionMode = false,
    this.amoledMode = false,
    this.lastNudgeAt,
    this.nudgeCount = 0,
    this.caregiverContacts = const [],
    this.familyMembers = const [],
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
        'country': country,
        'createdAt': createdAt.toIso8601String(),
        'dosesMarked': dosesMarked,
        'lastReviewPromptedAt': lastReviewPromptedAt?.toIso8601String(),
        'shabbatMode': shabbatMode,
        'preferredLanguage': preferredLanguage,
        'showGenericNames': showGenericNames,
        'pbsSpendThisYear': pbsSpendThisYear,
        'diabetesMode': diabetesMode,
        'hypertensionMode': hypertensionMode,
        'amoledMode': amoledMode,
        'lastNudgeAt': lastNudgeAt?.toIso8601String(),
        'nudgeCount': nudgeCount,
        'caregiverContacts': caregiverContacts.map((c) => c.toJson()).toList(),
        'familyMembers': familyMembers.map((m) => m.toJson()).toList(),
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
        country: j['country'] ?? '',
        createdAt: j['createdAt'] != null
            ? DateTime.parse(j['createdAt'])
            : DateTime.now(),
        dosesMarked: j['dosesMarked'] ?? 0,
        lastReviewPromptedAt: j['lastReviewPromptedAt'] != null
            ? DateTime.parse(j['lastReviewPromptedAt'])
            : null,
        shabbatMode: j['shabbatMode'] ?? false,
        preferredLanguage: j['preferredLanguage'] ?? 'en',
        showGenericNames: j['showGenericNames'] ?? false,
        pbsSpendThisYear: (j['pbsSpendThisYear'] ?? 0.0).toDouble(),
        diabetesMode: j['diabetesMode'] ?? false,
        hypertensionMode: j['hypertensionMode'] ?? false,
        amoledMode: j['amoledMode'] ?? false,
        lastNudgeAt:
            j['lastNudgeAt'] != null ? DateTime.parse(j['lastNudgeAt']) : null,
        nudgeCount: j['nudgeCount'] ?? 0,
        caregiverContacts: (j['caregiverContacts'] as List? ?? [])
            .map((c) => Caregiver.fromJson(c))
            .toList(),
        familyMembers: (j['familyMembers'] as List? ?? [])
            .map((m) => ManagedProfile.fromJson(m))
            .toList(),
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
    String? country,
    DateTime? createdAt,
    int? dosesMarked,
    DateTime? lastReviewPromptedAt,
    bool? shabbatMode,
    String? preferredLanguage,
    bool? showGenericNames,
    double? pbsSpendThisYear,
    bool? diabetesMode,
    bool? hypertensionMode,
    bool? amoledMode,
    DateTime? lastNudgeAt,
    int? nudgeCount,
    List<Caregiver>? caregiverContacts,
    List<ManagedProfile>? familyMembers,
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
        country: country ?? this.country,
        createdAt: createdAt ?? this.createdAt,
        dosesMarked: dosesMarked ?? this.dosesMarked,
        lastReviewPromptedAt: lastReviewPromptedAt ?? this.lastReviewPromptedAt,
        shabbatMode: shabbatMode ?? this.shabbatMode,
        preferredLanguage: preferredLanguage ?? this.preferredLanguage,
        showGenericNames: showGenericNames ?? this.showGenericNames,
        pbsSpendThisYear: pbsSpendThisYear ?? this.pbsSpendThisYear,
        diabetesMode: diabetesMode ?? this.diabetesMode,
        hypertensionMode: hypertensionMode ?? this.hypertensionMode,
        amoledMode: amoledMode ?? this.amoledMode,
        lastNudgeAt: lastNudgeAt ?? this.lastNudgeAt,
        nudgeCount: nudgeCount ?? this.nudgeCount,
        caregiverContacts: caregiverContacts ?? this.caregiverContacts,
        familyMembers: familyMembers ?? this.familyMembers,
      );
}
