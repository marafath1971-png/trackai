import 'package:flutter_test/flutter_test.dart';
import 'package:medai/core/utils/refill_helper.dart';
import 'package:medai/domain/entities/medicine.dart';

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

    test('calculateExhaustionDate returns null if all schedules are disabled (PRN)', () {
      final prnMed = testMed.copyWith(schedule: [
        ScheduleEntry(h: 8, m: 0, label: 'Morning', days: [1, 2, 3, 4, 5, 6, 0], enabled: false),
      ]);
      expect(RefillHelper.calculateExhaustionDate(prnMed), isNull);
    });

    test('calculateExhaustionDate returns null if count is 0', () {
      final zeroCountMed = testMed.copyWith(count: 0);
      expect(RefillHelper.calculateExhaustionDate(zeroCountMed), isNull);
    });

    test('calculateExhaustionDate correctly handles multiple doses per day', () {
      final multiDoseMed = testMed.copyWith(
        count: 10,
        schedule: [
          ScheduleEntry(h: 8, m: 0, label: 'Morning', days: [1, 2, 3, 4, 5, 6, 0], enabled: true),
          ScheduleEntry(h: 20, m: 0, label: 'Evening', days: [1, 2, 3, 4, 5, 6, 0], enabled: true),
        ],
      );
      final date = RefillHelper.calculateExhaustionDate(multiDoseMed);
      expect(date, isNotNull);
      final diff = date!.difference(DateTime.now()).inDays;
      // 10 pills, 2 per day = exactly 5 days
      expect(diff, closeTo(5, 1)); // Allowing small variance for time-of-day
    });

    test('getExhaustionStatus returns "Runs out today" when exhausted today', () {
      final exhaustedMed = testMed.copyWith(
        count: 1, // 1 pill left, 1 dose per day
      );
      final status = RefillHelper.getExhaustionStatus(exhaustedMed);
      expect(status, anyOf('Runs out today', 'Runs out tomorrow')); // Depends on exact time of test execution
    });
  });
}
