import 'caregiver.dart';

class MissedAlert {
  final int id;
  final String medName;
  final String doseLabel;
  final String time;
  final String timestamp;
  final List<Caregiver> caregivers;
  bool seen;

  MissedAlert({
    required this.id,
    required this.medName,
    required this.doseLabel,
    required this.time,
    required this.timestamp,
    required this.caregivers,
    this.seen = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'medName': medName,
        'doseLabel': doseLabel,
        'time': time,
        'timestamp': timestamp,
        'caregivers': caregivers.map((c) => c.toJson()).toList(),
        'seen': seen,
      };

  factory MissedAlert.fromJson(Map<String, dynamic> j) => MissedAlert(
        id: j['id'] ?? 0,
        medName: j['medName'] ?? '',
        doseLabel: j['doseLabel'] ?? '',
        time: j['time'] ?? '',
        timestamp: j['timestamp'] ?? '',
        caregivers: (j['caregivers'] as List<dynamic>? ?? [])
            .map((c) => Caregiver.fromJson(c))
            .toList(),
        seen: j['seen'] ?? false,
      );
}
