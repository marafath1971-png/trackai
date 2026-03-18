// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Med Trackr';

  @override
  String get greetingHero => 'Hero';

  @override
  String get homeTab => 'Home';

  @override
  String get alarmsTab => 'Alarms';

  @override
  String get dashboardTab => 'Trends';

  @override
  String get familyTab => 'Circle';

  @override
  String get scanTab => 'Scan';
}
