import 'medicine.dart';

class DoseItem {
  final Medicine med;
  final ScheduleEntry sched;
  final String key;

  DoseItem({
    required this.med,
    required this.sched,
    required this.key,
  });
}
