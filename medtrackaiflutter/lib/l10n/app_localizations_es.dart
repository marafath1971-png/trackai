// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MedAI';

  @override
  String get greetingHero => 'Héroe';

  @override
  String get homeTab => 'Inicio';

  @override
  String get alarmsTab => 'Alarmas';

  @override
  String get dashboardTab => 'Tendencias';

  @override
  String get familyTab => 'Círculo';

  @override
  String get scanTab => 'Escanear';

  @override
  String get countrySelectionTitle => '¿Dónde se encuentra?';

  @override
  String get countrySelectionSubtitle =>
      'Nos ayuda a identificar marcas de medicamentos locales';

  @override
  String get prnLabel => 'Según sea necesario';

  @override
  String get prnUndoToast => 'Dosis PRN eliminada';

  @override
  String get dailyLogTitle => 'Registro Diario';

  @override
  String get noMedicinesScheduled =>
      'No hay medicamentos programados para este día.';

  @override
  String get remaining => 'restante';

  @override
  String get refillRequired => 'Recarga Requerida';

  @override
  String get settings => 'Ajustes';

  @override
  String get profile => 'Perfil';

  @override
  String get language => 'Idioma';

  @override
  String get country => 'País';

  @override
  String get saveChanges => 'GUARDAR CAMBIOS';

  @override
  String get inventory => 'Inventario';

  @override
  String get noMedicines => 'Sin medicamentos';

  @override
  String get takeNow => 'Tomar ahora';

  @override
  String get snooze => 'Posponer';

  @override
  String get skip => 'Omitir';

  @override
  String get pharmacyLabel => 'Farmacia';

  @override
  String get pharmacyPhoneLabel => 'Teléfono de Farmacia';

  @override
  String get rxNumberLabel => 'Número de Receta';

  @override
  String get globalSettings => 'Ajustes Globales';

  @override
  String get religiousObservance => 'Observancia Religiosa';

  @override
  String get shabbatMode => 'Modo Shabat';

  @override
  String get prayerAwareReminders => 'Recordatorios de Oración';

  @override
  String get halalDetection => 'Detección Halal y Gelatina';

  @override
  String get amoledMode => 'Modo AMOLED (Ahorro)';

  @override
  String get diabetesMode => 'Modo Diabetes';

  @override
  String get hypertensionMode => 'Modo Hipertensión';

  @override
  String get supportedMarkets => 'Mercados Compatibles';

  @override
  String get halalSafe => 'Halal Seguro';

  @override
  String get gelatinWarning => 'Contiene Gelatina';

  @override
  String get halalUncertain => 'Halal Incierto';

  @override
  String get edit => 'Edit';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get cancel => 'Cancel';

  @override
  String get globalSettingsSubtitle => 'Manage international market settings';

  @override
  String get medicationDisplay => 'Medication Display';

  @override
  String get showGenericNames => 'Show Generic (INN) Names';

  @override
  String get showGenericNamesSubtitle =>
      'Display international non-proprietary names instead of brand names';

  @override
  String get pbsSafetyNet => 'PBS Safety Net Tracker';

  @override
  String get pbsSafetyNetSubtitle =>
      'Australia — track annual co-payment spend';

  @override
  String get pbsThreshold => 'Annual threshold: \$1,622.90';

  @override
  String pbsSpent(Object amount) {
    return 'Spent: \$$amount';
  }

  @override
  String pbsRemaining(Object amount) {
    return '\$$amount to go';
  }

  @override
  String get reached => 'Reached!';

  @override
  String get medsSubsidised => 'Meds now subsidised!';

  @override
  String get spentAmountSubtitle =>
      'Drag to update your annual spent amount (co-payments for all PBS prescriptions this calendar year)';

  @override
  String get clinicalModes => 'Clinical Modes';

  @override
  String get clinicalModesSubtitle => 'USA · UK · UAE · Malaysia';

  @override
  String get diabetesModeSubtitle =>
      'Log blood glucose alongside insulin / diabetes medications';

  @override
  String get hypertensionModeSubtitle =>
      'Log blood pressure alongside antihypertensive medications';

  @override
  String get displaySettings => 'Display';

  @override
  String get amoledModeSubtitle =>
      'Use true #000000 background to optimise AMOLED displays and save battery';

  @override
  String get shabbatModeSubtitle =>
      'Gentle vibrate-only reminders from Friday sunset to Saturday night';

  @override
  String get selectCountry => 'Select Country';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get aiSafetyProfile => 'AI Safety Profile';

  @override
  String get verified => 'Verified';

  @override
  String get criticalWarnings => 'Critical Warnings';

  @override
  String get drugInteractions => 'Drug Interactions';

  @override
  String get dietaryLifestyleRules => 'Dietary & Lifestyle Rules';

  @override
  String get ahaInsight => 'Aha! Insight';

  @override
  String get generateSafetyProfile => 'Generate Safety Profile';

  @override
  String get analyzingClinicalLimits => 'Analyzing Clinical Limits...';

  @override
  String get safetyLoadingSubtitle =>
      'Please wait while AI verifies interactions, dangers, and food rules.';

  @override
  String get safetyPromptSubtitle =>
      'Tap to instantly analyze this medication for dangers, drug interactions, and lifestyle rules.';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String hiUser(String name) {
    return 'Hi, $name 👋';
  }

  @override
  String get startJourney => 'Let\'s start your health journey ✨';

  @override
  String get allDosesTaken => 'All doses taken today! 🌟';

  @override
  String dosesOverdue(int count) {
    return '$count doses overdue — take them now ⚠️';
  }

  @override
  String dosesLeft(int count) {
    return '$count doses left today';
  }

  @override
  String get healthReportTitle => 'MedAI Health Report';

  @override
  String get medicalSummarySubtitle =>
      'Personal Medical Summary & Adherence Trends';

  @override
  String patientLabel(String name) {
    return 'Patient: $name';
  }

  @override
  String reportDate(String date) {
    return 'Date: $date';
  }

  @override
  String get overallAdherence => 'Overall Adherence';

  @override
  String get activeMedications => 'Active Medications';

  @override
  String get reportPeriod => 'Report Period';

  @override
  String get last30Days => 'Last 30 Days';

  @override
  String get currentMedications => 'Current Medications';

  @override
  String get medicineCol => 'Medicine';

  @override
  String get doseCol => 'Dose';

  @override
  String get frequencyCol => 'Frequency';

  @override
  String get stockRemainingCol => 'Stock Remaining';

  @override
  String get recentSymptoms => 'Recent Symptoms & Well-being';

  @override
  String get symptomDateCol => 'Date';

  @override
  String get symptomNameCol => 'Symptom';

  @override
  String get severityCol => 'Severity';

  @override
  String get notesCol => 'Notes';

  @override
  String get noSymptomsLogged => 'No symptoms logged in this period.';

  @override
  String get reportFooter =>
      'Generated by MedAI Pro. This report is for informational purposes only and should be reviewed by a qualified healthcare professional.';

  @override
  String get settingsStats => 'Stats';

  @override
  String get settingsApp => 'App Settings';

  @override
  String get settingsData => 'Data & Privacy';

  @override
  String get settingsGlobal => 'Global Settings';

  @override
  String get settingsProfile => 'My Profile';

  @override
  String get adherenceLabel => 'ADHERENCE';

  @override
  String get streakLabel => 'STREAK';

  @override
  String streakDays(int count) {
    return '$count Days';
  }

  @override
  String get generateClinicalReport => 'GENERATE CLINICAL REPORT';

  @override
  String get fetchingAiInsights => 'FETCHING AI INSIGHTS...';

  @override
  String get aiCoachDisclaimer =>
      'This dashboard uses AI to analyze patterns. Always consult your doctor for medical advice.';

  @override
  String get insightsTitle => 'Insights';

  @override
  String get insightsSubtitle => 'Analytics & health patterns';

  @override
  String get dataSummaryTitle => 'YOUR DATA SUMMARY';

  @override
  String get dataMedicinesLabel => 'Medicines';

  @override
  String get dataAlarmsLabel => 'Alarms set';

  @override
  String get dataDaysTrackedLabel => 'Days tracked';

  @override
  String get dataDosesLoggedLabel => 'Doses logged';

  @override
  String get exportAndBackup => 'Export & Backup';

  @override
  String get exportPdfReport => 'Export PDF Report';

  @override
  String get exportPdfSubtitle => 'For doctors and caregivers';

  @override
  String get exportCsv => 'Export History as CSV';

  @override
  String exportCsvSubtitle(int count) {
    return '$count dose records';
  }

  @override
  String get resetSection => 'Reset';

  @override
  String get deleteAllData => 'Delete All Data';

  @override
  String get deleteAllDataSubtitle =>
      'Removes all medicines, history & settings';

  @override
  String get deleteConfirmTitle => 'Delete All Data?';

  @override
  String get deleteConfirmBody =>
      'This will permanently delete all your data. This cannot be undone.';

  @override
  String get deleteButton => 'Delete Everything';

  @override
  String get legalSection => 'Legal';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicySubtitle => 'How we protect your health data';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get termsOfServiceSubtitle => 'Rules for using MedAI';

  @override
  String get appVersionLabel => 'App Version';

  @override
  String get appVersionValue => '1.0.0+1';

  @override
  String get analysisFailed => 'Análisis fallido';

  @override
  String get somethingWentWrong =>
      'Algo salió mal. Por favor intente nuevamente.';

  @override
  String get retry => 'Reintentar';
}
