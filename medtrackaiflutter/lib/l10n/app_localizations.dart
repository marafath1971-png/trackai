import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_he.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ms.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('he'),
    Locale('ja'),
    Locale('ko'),
    Locale('ms')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Med Trackr'**
  String get appTitle;

  /// No description provided for @greetingHero.
  ///
  /// In en, this message translates to:
  /// **'Hero'**
  String get greetingHero;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @alarmsTab.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get alarmsTab;

  /// No description provided for @dashboardTab.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get dashboardTab;

  /// No description provided for @familyTab.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get familyTab;

  /// No description provided for @scanTab.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scanTab;

  /// No description provided for @countrySelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Where are you located?'**
  String get countrySelectionTitle;

  /// No description provided for @countrySelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Helps us identify local medicine brands'**
  String get countrySelectionSubtitle;

  /// No description provided for @prnLabel.
  ///
  /// In en, this message translates to:
  /// **'As Needed'**
  String get prnLabel;

  /// No description provided for @prnUndoToast.
  ///
  /// In en, this message translates to:
  /// **'PRN dose removed'**
  String get prnUndoToast;

  /// No description provided for @dailyLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Log'**
  String get dailyLogTitle;

  /// No description provided for @noMedicinesScheduled.
  ///
  /// In en, this message translates to:
  /// **'No medicines scheduled for this day.'**
  String get noMedicinesScheduled;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get remaining;

  /// No description provided for @refillRequired.
  ///
  /// In en, this message translates to:
  /// **'Refill Required'**
  String get refillRequired;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'SAVE CHANGES'**
  String get saveChanges;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @noMedicines.
  ///
  /// In en, this message translates to:
  /// **'No medicines'**
  String get noMedicines;

  /// No description provided for @takeNow.
  ///
  /// In en, this message translates to:
  /// **'Take Now'**
  String get takeNow;

  /// No description provided for @snooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get snooze;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @pharmacyLabel.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get pharmacyLabel;

  /// No description provided for @pharmacyPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Phone'**
  String get pharmacyPhoneLabel;

  /// No description provided for @rxNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Rx Number'**
  String get rxNumberLabel;

  /// No description provided for @globalSettings.
  ///
  /// In en, this message translates to:
  /// **'Global Settings'**
  String get globalSettings;

  /// No description provided for @religiousObservance.
  ///
  /// In en, this message translates to:
  /// **'Religious Observance'**
  String get religiousObservance;

  /// No description provided for @shabbatMode.
  ///
  /// In en, this message translates to:
  /// **'Shabbat Mode'**
  String get shabbatMode;

  /// No description provided for @prayerAwareReminders.
  ///
  /// In en, this message translates to:
  /// **'Prayer-Aware Reminders'**
  String get prayerAwareReminders;

  /// No description provided for @halalDetection.
  ///
  /// In en, this message translates to:
  /// **'Halal & Gelatin Detection'**
  String get halalDetection;

  /// No description provided for @amoledMode.
  ///
  /// In en, this message translates to:
  /// **'AMOLED Mode (Pixel Save)'**
  String get amoledMode;

  /// No description provided for @diabetesMode.
  ///
  /// In en, this message translates to:
  /// **'Diabetes Mode'**
  String get diabetesMode;

  /// No description provided for @hypertensionMode.
  ///
  /// In en, this message translates to:
  /// **'Hypertension Mode'**
  String get hypertensionMode;

  /// No description provided for @supportedMarkets.
  ///
  /// In en, this message translates to:
  /// **'Supported Markets'**
  String get supportedMarkets;

  /// No description provided for @halalSafe.
  ///
  /// In en, this message translates to:
  /// **'Halal Safe'**
  String get halalSafe;

  /// No description provided for @gelatinWarning.
  ///
  /// In en, this message translates to:
  /// **'Contains Gelatin'**
  String get gelatinWarning;

  /// No description provided for @halalUncertain.
  ///
  /// In en, this message translates to:
  /// **'Halal Uncertain'**
  String get halalUncertain;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @globalSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage international market settings'**
  String get globalSettingsSubtitle;

  /// No description provided for @medicationDisplay.
  ///
  /// In en, this message translates to:
  /// **'Medication Display'**
  String get medicationDisplay;

  /// No description provided for @showGenericNames.
  ///
  /// In en, this message translates to:
  /// **'Show Generic (INN) Names'**
  String get showGenericNames;

  /// No description provided for @showGenericNamesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display international non-proprietary names instead of brand names'**
  String get showGenericNamesSubtitle;

  /// No description provided for @pbsSafetyNet.
  ///
  /// In en, this message translates to:
  /// **'PBS Safety Net Tracker'**
  String get pbsSafetyNet;

  /// No description provided for @pbsSafetyNetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Australia — track annual co-payment spend'**
  String get pbsSafetyNetSubtitle;

  /// No description provided for @pbsThreshold.
  ///
  /// In en, this message translates to:
  /// **'Annual threshold: \$1,622.90'**
  String get pbsThreshold;

  /// No description provided for @pbsSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent: \${amount}'**
  String pbsSpent(Object amount);

  /// No description provided for @pbsRemaining.
  ///
  /// In en, this message translates to:
  /// **'\${amount} to go'**
  String pbsRemaining(Object amount);

  /// No description provided for @reached.
  ///
  /// In en, this message translates to:
  /// **'Reached!'**
  String get reached;

  /// No description provided for @medsSubsidised.
  ///
  /// In en, this message translates to:
  /// **'Meds now subsidised!'**
  String get medsSubsidised;

  /// No description provided for @spentAmountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Drag to update your annual spent amount (co-payments for all PBS prescriptions this calendar year)'**
  String get spentAmountSubtitle;

  /// No description provided for @clinicalModes.
  ///
  /// In en, this message translates to:
  /// **'Clinical Modes'**
  String get clinicalModes;

  /// No description provided for @clinicalModesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'USA · UK · UAE · Malaysia'**
  String get clinicalModesSubtitle;

  /// No description provided for @diabetesModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log blood glucose alongside insulin / diabetes medications'**
  String get diabetesModeSubtitle;

  /// No description provided for @hypertensionModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log blood pressure alongside antihypertensive medications'**
  String get hypertensionModeSubtitle;

  /// No description provided for @displaySettings.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get displaySettings;

  /// No description provided for @amoledModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use true #000000 background to optimise AMOLED displays and save battery'**
  String get amoledModeSubtitle;

  /// No description provided for @shabbatModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gentle vibrate-only reminders from Friday sunset to Saturday night'**
  String get shabbatModeSubtitle;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get selectCountry;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @aiSafetyProfile.
  ///
  /// In en, this message translates to:
  /// **'AI Safety Profile'**
  String get aiSafetyProfile;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @criticalWarnings.
  ///
  /// In en, this message translates to:
  /// **'Critical Warnings'**
  String get criticalWarnings;

  /// No description provided for @drugInteractions.
  ///
  /// In en, this message translates to:
  /// **'Drug Interactions'**
  String get drugInteractions;

  /// No description provided for @dietaryLifestyleRules.
  ///
  /// In en, this message translates to:
  /// **'Dietary & Lifestyle Rules'**
  String get dietaryLifestyleRules;

  /// No description provided for @ahaInsight.
  ///
  /// In en, this message translates to:
  /// **'Aha! Insight'**
  String get ahaInsight;

  /// No description provided for @generateSafetyProfile.
  ///
  /// In en, this message translates to:
  /// **'Generate Safety Profile'**
  String get generateSafetyProfile;

  /// No description provided for @analyzingClinicalLimits.
  ///
  /// In en, this message translates to:
  /// **'Analyzing Clinical Limits...'**
  String get analyzingClinicalLimits;

  /// No description provided for @safetyLoadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please wait while AI verifies interactions, dangers, and food rules.'**
  String get safetyLoadingSubtitle;

  /// No description provided for @safetyPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to instantly analyze this medication for dangers, drug interactions, and lifestyle rules.'**
  String get safetyPromptSubtitle;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @hiUser.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name} 👋'**
  String hiUser(String name);

  /// No description provided for @startJourney.
  ///
  /// In en, this message translates to:
  /// **'Let\'s start your health journey ✨'**
  String get startJourney;

  /// No description provided for @allDosesTaken.
  ///
  /// In en, this message translates to:
  /// **'All doses taken today! 🌟'**
  String get allDosesTaken;

  /// No description provided for @dosesOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count} doses overdue — take them now ⚠️'**
  String dosesOverdue(int count);

  /// No description provided for @dosesLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} doses left today'**
  String dosesLeft(int count);

  /// No description provided for @healthReportTitle.
  ///
  /// In en, this message translates to:
  /// **'MedAI Health Report'**
  String get healthReportTitle;

  /// No description provided for @medicalSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Medical Summary & Adherence Trends'**
  String get medicalSummarySubtitle;

  /// No description provided for @patientLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient: {name}'**
  String patientLabel(String name);

  /// No description provided for @reportDate.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String reportDate(String date);

  /// No description provided for @overallAdherence.
  ///
  /// In en, this message translates to:
  /// **'Overall Adherence'**
  String get overallAdherence;

  /// No description provided for @activeMedications.
  ///
  /// In en, this message translates to:
  /// **'Active Medications'**
  String get activeMedications;

  /// No description provided for @reportPeriod.
  ///
  /// In en, this message translates to:
  /// **'Report Period'**
  String get reportPeriod;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get last30Days;

  /// No description provided for @currentMedications.
  ///
  /// In en, this message translates to:
  /// **'Current Medications'**
  String get currentMedications;

  /// No description provided for @medicineCol.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get medicineCol;

  /// No description provided for @doseCol.
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get doseCol;

  /// No description provided for @frequencyCol.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequencyCol;

  /// No description provided for @stockRemainingCol.
  ///
  /// In en, this message translates to:
  /// **'Stock Remaining'**
  String get stockRemainingCol;

  /// No description provided for @recentSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Recent Symptoms & Well-being'**
  String get recentSymptoms;

  /// No description provided for @symptomDateCol.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get symptomDateCol;

  /// No description provided for @symptomNameCol.
  ///
  /// In en, this message translates to:
  /// **'Symptom'**
  String get symptomNameCol;

  /// No description provided for @severityCol.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severityCol;

  /// No description provided for @notesCol.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesCol;

  /// No description provided for @noSymptomsLogged.
  ///
  /// In en, this message translates to:
  /// **'No symptoms logged in this period.'**
  String get noSymptomsLogged;

  /// No description provided for @reportFooter.
  ///
  /// In en, this message translates to:
  /// **'Generated by MedAI Pro. This report is for informational purposes only and should be reviewed by a qualified healthcare professional.'**
  String get reportFooter;

  /// No description provided for @settingsStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get settingsStats;

  /// No description provided for @settingsApp.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get settingsApp;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data & Privacy'**
  String get settingsData;

  /// No description provided for @settingsGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global Settings'**
  String get settingsGlobal;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get settingsProfile;

  /// No description provided for @adherenceLabel.
  ///
  /// In en, this message translates to:
  /// **'ADHERENCE'**
  String get adherenceLabel;

  /// No description provided for @streakLabel.
  ///
  /// In en, this message translates to:
  /// **'STREAK'**
  String get streakLabel;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count} Days'**
  String streakDays(int count);

  /// No description provided for @generateClinicalReport.
  ///
  /// In en, this message translates to:
  /// **'GENERATE CLINICAL REPORT'**
  String get generateClinicalReport;

  /// No description provided for @fetchingAiInsights.
  ///
  /// In en, this message translates to:
  /// **'FETCHING AI INSIGHTS...'**
  String get fetchingAiInsights;

  /// No description provided for @aiCoachDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This dashboard uses AI to analyze patterns. Always consult your doctor for medical advice.'**
  String get aiCoachDisclaimer;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsTitle;

  /// No description provided for @insightsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics & health patterns'**
  String get insightsSubtitle;

  /// No description provided for @dataSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'YOUR DATA SUMMARY'**
  String get dataSummaryTitle;

  /// No description provided for @dataMedicinesLabel.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get dataMedicinesLabel;

  /// No description provided for @dataAlarmsLabel.
  ///
  /// In en, this message translates to:
  /// **'Alarms set'**
  String get dataAlarmsLabel;

  /// No description provided for @dataDaysTrackedLabel.
  ///
  /// In en, this message translates to:
  /// **'Days tracked'**
  String get dataDaysTrackedLabel;

  /// No description provided for @dataDosesLoggedLabel.
  ///
  /// In en, this message translates to:
  /// **'Doses logged'**
  String get dataDosesLoggedLabel;

  /// No description provided for @exportAndBackup.
  ///
  /// In en, this message translates to:
  /// **'Export & Backup'**
  String get exportAndBackup;

  /// No description provided for @exportPdfReport.
  ///
  /// In en, this message translates to:
  /// **'Export PDF Report'**
  String get exportPdfReport;

  /// No description provided for @exportPdfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For doctors and caregivers'**
  String get exportPdfSubtitle;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export History as CSV'**
  String get exportCsv;

  /// No description provided for @exportCsvSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} dose records'**
  String exportCsvSubtitle(int count);

  /// No description provided for @resetSection.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetSection;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllData;

  /// No description provided for @deleteAllDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Removes all medicines, history & settings'**
  String get deleteAllDataSubtitle;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your data. This cannot be undone.'**
  String get deleteConfirmBody;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Everything'**
  String get deleteButton;

  /// No description provided for @legalSection.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legalSection;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How we protect your health data'**
  String get privacyPolicySubtitle;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @termsOfServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rules for using MedAI'**
  String get termsOfServiceSubtitle;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersionLabel;

  /// No description provided for @appVersionValue.
  ///
  /// In en, this message translates to:
  /// **'1.0.0'**
  String get appVersionValue;

  /// No description provided for @analysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis Failed'**
  String get analysisFailed;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'en',
        'es',
        'he',
        'ja',
        'ko',
        'ms'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'he':
      return AppLocalizationsHe();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'ms':
      return AppLocalizationsMs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
