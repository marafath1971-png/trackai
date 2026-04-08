import '../../domain/entities/medicine.dart';
import '../performance_service.dart';

class JahisParser {
  /// Parses a JAHIS-compliant QR string into a list of Medicine objects.
  static List<Medicine> parse(String data) {
    return PerformanceService.measureSync('jahis_parse_trace', () {
      final List<Medicine> parsedMeds = [];
      final lines = data.split('\n');
      int idCounter = DateTime.now().millisecondsSinceEpoch;

      for (var line in lines) {
        final parts = line.split(',');
        if (parts.isEmpty) continue;

        final recordType = parts[0].trim();

        // Record type 11 = Medication
        if (recordType == '11' && parts.length >= 8) {
          final name = parts[1].trim();
          final dose = parts[2].trim();
          final unit = parts[7].trim();
          final totalCount = int.tryParse(parts[6].trim()) ?? 30;

          // ── Frequency to Multi-Ritual Mapping (Enhanced) ───────────
          final frequency = parts[4];
          final List<Ritual> rituals = _parseJapaneseRituals(frequency);

          // If no match, default to Breakfast or Daily
          if (rituals.isEmpty) rituals.add(Ritual.withBreakfast);

          parsedMeds.add(Medicine(
            id: idCounter,
            name: name,
            brand: '',
            dose: dose,
            form: _detectForm(parts[3], unit),
            category: 'Prescription (JAHIS)',
            count: totalCount,
            totalCount: totalCount,
            courseStartDate: DateTime.now().toIso8601String(),
            unit: unit,
            schedule: rituals
                .map((ritual) => ScheduleEntry(
                      id: 'jahis_${idCounter++}',
                      h: _getHourForRitual(ritual),
                      m: 0,
                      label: _getLabelForRitual(ritual),
                      days: [1, 2, 3, 4, 5, 6, 0],
                      ritual: ritual,
                    ))
                .toList(),
          ));
        }
      }
      return parsedMeds;
    });
  }

  static List<Ritual> _parseJapaneseRituals(String frequency) {
    final List<Ritual> results = [];
    final isBeforeMeal = frequency.contains('食前');

    // Group 1: Specific Times
    if (frequency.contains('朝')) {
      results.add(isBeforeMeal ? Ritual.beforeBreakfast : Ritual.withBreakfast);
    }
    if (frequency.contains('昼')) {
      results.add(isBeforeMeal ? Ritual.beforeLunch : Ritual.withLunch);
    }
    if (frequency.contains('夕')) {
      results.add(isBeforeMeal ? Ritual.beforeDinner : Ritual.withDinner);
    }

    // Group 2: All Meals
    if (frequency.contains('毎食') || frequency.contains('1日3回')) {
      if (results.isEmpty) {
        results
            .add(isBeforeMeal ? Ritual.beforeBreakfast : Ritual.withBreakfast);
        results.add(isBeforeMeal ? Ritual.beforeLunch : Ritual.withLunch);
        results.add(isBeforeMeal ? Ritual.beforeDinner : Ritual.withDinner);
      }
    }

    // Group 3: Sleep
    if (frequency.contains('就寝')) {
      results.add(Ritual.beforeSleep);
    }

    // Group 4: Waking
    if (frequency.contains('起床')) {
      results.add(Ritual.onWaking);
    }

    // De-duplicate in case of messy strings
    return results.toSet().toList();
  }

  static String _detectForm(String formHint, String unit) {
    final combined = '$formHint $unit'.toLowerCase();
    if (combined.contains('錠') || combined.contains('カプセル')) return 'tablet';
    if (combined.contains('噴霧') || combined.contains('スプレー')) return 'spray';
    if (combined.contains('注入') || combined.contains('注射')) return 'injection';
    if (combined.contains('点眼') || combined.contains('点鼻')) return 'drops';
    if (combined.contains('塗布') || combined.contains('クリーム')) return 'cream';
    if (combined.contains('液') || combined.contains('内用液')) return 'liquid';
    return 'tablet';
  }

  static int _getHourForRitual(Ritual ritual) {
    switch (ritual) {
      case Ritual.beforeBreakfast:
        return 7;
      case Ritual.withBreakfast:
        return 8;
      case Ritual.afterBreakfast:
        return 9;
      case Ritual.beforeLunch:
        return 11;
      case Ritual.withLunch:
        return 12;
      case Ritual.afterLunch:
        return 13;
      case Ritual.beforeDinner:
        return 18;
      case Ritual.withDinner:
        return 19;
      case Ritual.afterDinner:
        return 20;
      case Ritual.beforeSleep:
        return 22;
      case Ritual.onWaking:
        return 6;
      default:
        return 9;
    }
  }

  static String _getLabelForRitual(Ritual ritual) {
    return ritual.displayName;
  }

  /// Detects if a string is likely a JAHIS QR code.
  static bool isJahis(String data) {
    // Basic detection: starts with "1," (Header) or contains "11," (Medication)
    return data.startsWith('1,') || data.contains('\n11,');
  }
}
