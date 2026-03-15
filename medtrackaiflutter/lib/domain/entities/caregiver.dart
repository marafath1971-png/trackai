class Caregiver {
  final int id;
  final String name;
  final String relation;
  final String contact;
  final String avatar;
  String status; // pending / active
  final String color;
  final int alertDelay;
  final List<String> methods;
  final String addedAt;
  final String patientUid;

  Caregiver({
    required this.id,
    required this.name,
    required this.relation,
    this.contact = '',
    this.avatar = '👩',
    this.status = 'pending',
    this.color = '#10B981',
    this.alertDelay = 30,
    this.methods = const ['push', 'sms'],
    this.addedAt = '',
    this.patientUid = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relation': relation,
        'contact': contact,
        'avatar': avatar,
        'status': status,
        'color': color,
        'alertDelay': alertDelay,
        'methods': methods,
        'addedAt': addedAt,
        'patientUid': patientUid,
      };

  factory Caregiver.fromJson(Map<String, dynamic> j) => Caregiver(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        relation: j['relation'] ?? '',
        contact: j['contact'] ?? '',
        avatar: j['avatar'] ?? '👩',
        status: j['status'] ?? 'pending',
        color: j['color'] ?? '#10B981',
        alertDelay: j['alertDelay'] ?? 30,
        methods: List<String>.from(j['methods'] ?? ['push', 'sms']),
        addedAt: j['addedAt'] ?? '',
        patientUid: j['patientUid'] ?? '',
      );

  Caregiver copyWith({String? status}) => Caregiver(
        id: id,
        name: name,
        relation: relation,
        contact: contact,
        avatar: avatar,
        status: status ?? this.status,
        color: color,
        alertDelay: alertDelay,
        methods: methods,
        addedAt: addedAt,
        patientUid: patientUid,
      );

  String get inviteCode =>
      'MT-${id.abs().toRadixString(16).toUpperCase().padLeft(6, '0').substring(0, 6)}';
  String get inviteUrl => 'https://medai.app/join/$patientUid/$inviteCode';
}
