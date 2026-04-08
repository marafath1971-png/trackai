// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'ميد أي';

  @override
  String get greetingHero => 'بطل';

  @override
  String get homeTab => 'الرئيسية';

  @override
  String get alarmsTab => 'التنبيهات';

  @override
  String get dashboardTab => 'الاتجاهات';

  @override
  String get familyTab => 'الدائرة';

  @override
  String get scanTab => 'مسح';

  @override
  String get countrySelectionTitle => 'أين تقع؟';

  @override
  String get countrySelectionSubtitle =>
      'يساعدنا في التعرف على العلامات التجارية للأدوية المحلية';

  @override
  String get prnLabel => 'عند الحاجة';

  @override
  String get prnUndoToast => 'تمت إزالة جرعة عند الحاجة';

  @override
  String get dailyLogTitle => 'السجل اليومي';

  @override
  String get noMedicinesScheduled => 'لا توجد أدوية مجدولة لهذا اليوم.';

  @override
  String get remaining => 'متبقي';

  @override
  String get refillRequired => 'مطلوب إعادة التعبئة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get language => 'اللغة';

  @override
  String get country => 'البلد';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get inventory => 'المخزون';

  @override
  String get noMedicines => 'لا توجد أدوية';

  @override
  String get takeNow => 'خذ الآن';

  @override
  String get snooze => 'غفوة';

  @override
  String get skip => 'تخطي';

  @override
  String get pharmacyLabel => 'الصيدلية';

  @override
  String get pharmacyPhoneLabel => 'هاتف الصيدلية';

  @override
  String get rxNumberLabel => 'رقم الوصفة';

  @override
  String get globalSettings => 'الإعدادات العالمية';

  @override
  String get religiousObservance => 'الالتزام الديني';

  @override
  String get shabbatMode => 'وضع السبت';

  @override
  String get prayerAwareReminders => 'تذكيرات مراعية للصلاة';

  @override
  String get halalDetection => 'كشف الحلال والجيلاتين';

  @override
  String get amoledMode => 'وضع AMOLED (توفير البطارية)';

  @override
  String get diabetesMode => 'وضع السكري';

  @override
  String get hypertensionMode => 'وضع ارتفاع ضغط الدم';

  @override
  String get supportedMarkets => 'الأسواق المدعومة';

  @override
  String get halalSafe => 'حلال آمن';

  @override
  String get gelatinWarning => 'يحتوي على جيلاتين';

  @override
  String get halalUncertain => 'حلال غير مؤكد';

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
  String get analysisFailed => 'فشل التحليل';

  @override
  String get somethingWentWrong => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get retry => 'إعادة المحاولة';
}
