import 'package:flutter_test/flutter_test.dart';
import 'package:medtrackaiflutter/core/utils/refill_helper.dart';
import 'package:medtrackaiflutter/domain/entities/medicine.dart';

void main() {
  group('RefillHelper Tests', () {
    final testMed = Medicine(
      id: 1,
      name: 'Test Med',
      brand: 'Test Brand',
      dose: '500mg',
      form: 'tablet',
      category: 'Analgesic',
      count: 10,
      totalCount: 30,
      refillAt: 5,
      courseStartDate: DateTime.now().toIso8601String(),
      color: '#FF0000',
      schedule: [
        ScheduleEntry(
          h: 8,
          m: 0,
          label: 'Morning',
          days: [1, 2, 3, 4, 5, 6, 0], // Every day
          enabled: true,
        ),
      ],
    );

    test('calculateExhaustionDate returns correct date for daily dose', () {
      final date = RefillHelper.calculateExhaustionDate(testMed);
      expect(date, isNotNull);

      final diff = date!.difference(DateTime.now()).inDays;
      // 10 pills, 1 per day = roughly 9-10 days depending on the current time of day
      expect(diff, anyOf(9, 10));
    });

    test('getExhaustionStatus returns correct string', () {
      final status = RefillHelper.getExhaustionStatus(testMed);
      // 10 days is >= 7, so it should show the date
      expect(status, contains('Runs out on'));
    });

    test('isCriticallyLow returns true when below threshold', () {
      final lowMed = testMed.copyWith(count: 3);
      expect(RefillHelper.isCriticallyLow(lowMed), isTrue);
    });

    test('isCriticallyLow returns false when above threshold', () {
      final okayMed = testMed.copyWith(count: 10);
      expect(RefillHelper.isCriticallyLow(okayMed), isFalse);
    });

    test('calculateExhaustionDate returns null if no schedule', () {
      final noSchedMed = testMed.copyWith(schedule: []);
      expect(RefillHelper.calculateExhaustionDate(noSchedMed), isNull);
    });
  });
}
