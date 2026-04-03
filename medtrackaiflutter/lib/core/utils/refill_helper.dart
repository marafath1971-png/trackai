import '../../domain/entities/medicine.dart';

class RefillHelper {
  /// Calculates the estimated date when the medicine will run out.
  /// Returns null if there's no schedule or count is already 0.
  static DateTime? calculateExhaustionDate(Medicine med) {
    if (med.count <= 0 || med.schedule.isEmpty) return null;

    // Calculate total doses per week
    int weeklyDoses = 0;
    for (var entry in med.schedule) {
      if (entry.enabled) {
        weeklyDoses += entry.days.length;
      }
    }

    if (weeklyDoses == 0) return null;

    // Average daily doses
    double dailyRate = weeklyDoses / 7.0;

    // Remaining days
    int daysLeft = (med.count / dailyRate).floor();

    return DateTime.now().add(Duration(days: daysLeft));
  }

  /// Returns a human-friendly string for the exhaustion date.
  static String getExhaustionStatus(Medicine med) {
    final date = calculateExhaustionDate(med);
    if (date == null) return 'No schedule set';

    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference <= 0) return 'Runs out today';
    if (difference == 1) return 'Runs out tomorrow';
    if (difference < 7) return 'Runs out in $difference days';

    final monthNames = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return 'Runs out on ${monthNames[date.month]} ${date.day}';
  }

  /// Returns true if the medicine is critically low (below refill threshold).
  static bool isCriticallyLow(Medicine med) {
    return med.count <= med.refillAt;
  }
}
