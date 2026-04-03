import '../../domain/entities/medicine.dart';

class JahisParser {
  /// Parses a JAHIS-compliant QR string into a list of Medicine objects.
  /// JAHIS format is typically comma-separated lines starting with a record type ID.
  ///
  /// Record type 11 (Medication) format:
  /// 11, medName, dose, form, frequencyCode, days, quantity, unit, ...
  static List<Medicine> parse(String data) {
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

        // Frequency to Ritual Mapping (Basic)
        Ritual ritual = Ritual.none;
        final frequency = parts[4].toLowerCase();
        if (frequency.contains('朝')) ritual = Ritual.withBreakfast;
        if (frequency.contains('昼')) ritual = Ritual.withLunch;
        if (frequency.contains('夕')) ritual = Ritual.withDinner;
        if (frequency.contains('就寝')) ritual = Ritual.beforeSleep;

        parsedMeds.add(Medicine(
          id: idCounter++,
          name: name,
          brand: '',
          dose: dose,
          form: 'tablet', // Default, can refine with further parsing
          category: 'Prescription (JAHIS)',
          count: totalCount,
          totalCount: totalCount,
          courseStartDate: DateTime.now().toIso8601String(),
          unit: unit,
          schedule: [
            ScheduleEntry(
              h: _getHourForRitual(ritual),
              m: 0,
              label: _getLabelForRitual(ritual),
              days: [1, 2, 3, 4, 5, 6, 0],
              ritual: ritual,
            )
          ],
        ));
      }
    }

    return parsedMeds;
  }

  static int _getHourForRitual(Ritual ritual) {
    switch (ritual) {
      case Ritual.withBreakfast:
        return 8;
      case Ritual.withLunch:
        return 12;
      case Ritual.withDinner:
        return 19;
      case Ritual.beforeSleep:
        return 22;
      default:
        return 9;
    }
  }

  static String _getLabelForRitual(Ritual ritual) {
    switch (ritual) {
      case Ritual.withBreakfast:
        return 'Breakfast';
      case Ritual.withLunch:
        return 'Lunch';
      case Ritual.withDinner:
        return 'Dinner';
      case Ritual.beforeSleep:
        return 'Before Sleep';
      default:
        return 'Daily';
    }
  }

  /// Detects if a string is likely a JAHIS QR code.
  static bool isJahis(String data) {
    // Basic detection: starts with "1," (Header) or contains "11," (Medication)
    return data.startsWith('1,') || data.contains('\n11,');
  }
}
