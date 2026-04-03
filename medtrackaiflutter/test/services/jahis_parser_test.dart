import 'package:flutter_test/flutter_test.dart';
import 'package:medtrackaiflutter/services/parsers/jahis_parser.dart';
import 'package:medtrackaiflutter/domain/entities/medicine.dart';

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
      expect(meds[0].schedule[0].ritual, equals(Ritual.withBreakfast));

      // '朝夕' contains '夕' (Evening/Dinner) -> withDinner (Parser implementation uses last match for simplicity currently)
      expect(meds[1].schedule[0].ritual, equals(Ritual.withDinner));
    });

    test('parse handles invalid or empty data gracefully', () {
      expect(JahisParser.parse(''), isEmpty);
      expect(JahisParser.parse('invalid,data,here'), isEmpty);
    });
  });
}
