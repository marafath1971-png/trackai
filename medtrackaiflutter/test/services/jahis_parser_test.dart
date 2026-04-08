import 'package:flutter_test/flutter_test.dart';
import 'package:medai/services/parsers/jahis_parser.dart';
import 'package:medai/domain/entities/medicine.dart';

void main() {
  group('JahisParser Tests', () {
    const jahisData =
        '1,Header Info\n11,Loxonin,60mg,form,朝,7,14,錠\n11,Magmit,330mg,form,朝夕,7,28,錠';

    test('isJahis correctly identifies JAHIS format', () {
      expect(JahisParser.isJahis(jahisData), isTrue);
      expect(JahisParser.isJahis('Generic Text'), isFalse);
    });

    test('parse correctly extracts medications', () {
      final meds = JahisParser.parse(jahisData);
      expect(meds.length, equals(2));

      expect(meds[0].name, equals('Loxonin'));
      expect(meds[0].dose, equals('60mg'));
      expect(meds[0].unit, equals('錠'));
      expect(meds[0].count, equals(14));

      expect(meds[1].name, equals('Magmit'));
      expect(meds[1].count, equals(28));
    });

    test('parse correctly maps rituals from common Japanese frequency terms',
        () {
      final meds = JahisParser.parse(jahisData);

      // '朝' (Morning) -> withBreakfast
      expect(meds[0].schedule.length, equals(1));
      expect(meds[0].schedule[0].ritual, equals(Ritual.withBreakfast));

      // '朝夕' contains '朝' and '夕' -> withBreakfast and withDinner
      expect(meds[1].schedule.length, equals(2));
      expect(meds[1].schedule.any((s) => s.ritual == Ritual.withBreakfast),
          isTrue);
      expect(
          meds[1].schedule.any((s) => s.ritual == Ritual.withDinner), isTrue);
    });

    test('parse handles complex meal-related timings (Before/After)', () {
      const complexData =
          '1,Header\n11,MedA,10mg,form,毎食後,7,21,錠\n11,MedB,5mg,form,夕食前,7,7,錠';
      final meds = JahisParser.parse(complexData);

      // MedA: '毎食後' -> Breakfast, Lunch, Dinner
      expect(meds[0].schedule.length, equals(3));
      expect(meds[0].schedule.any((s) => s.ritual == Ritual.withBreakfast),
          isTrue);
      expect(meds[0].schedule.any((s) => s.ritual == Ritual.withLunch), isTrue);
      expect(
          meds[0].schedule.any((s) => s.ritual == Ritual.withDinner), isTrue);

      // MedB: '夕食前' -> beforeDinner
      expect(meds[1].schedule.length, equals(1));
      expect(meds[1].schedule[0].ritual, equals(Ritual.beforeDinner));
    });

    test('parse handles waking and sleeping correctly', () {
      const timingData =
          '1,Header\n11,SleepMed,10mg,form,就寝前,7,7,錠\n11,WakeMed,5mg,form,起床時,7,7,錠';
      final meds = JahisParser.parse(timingData);

      expect(meds[0].schedule[0].ritual, equals(Ritual.beforeSleep));
      expect(meds[1].schedule[0].ritual, equals(Ritual.onWaking));
    });

    test('parse handles invalid or empty data gracefully', () {
      expect(JahisParser.parse(''), isEmpty);
      expect(JahisParser.parse('invalid,data,here'), isEmpty);
    });
  });
}
