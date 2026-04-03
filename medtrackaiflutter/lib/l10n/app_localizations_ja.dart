// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Med AI';

  @override
  String get greetingHero => 'ヒーロー';

  @override
  String get homeTab => 'ホーム';

  @override
  String get alarmsTab => 'アラーム';

  @override
  String get dashboardTab => 'トレンド';

  @override
  String get familyTab => 'サークル';

  @override
  String get scanTab => 'スキャン';

  @override
  String get countrySelectionTitle => 'お住まいの地域はどこですか？';

  @override
  String get countrySelectionSubtitle => '地域の医薬品ブランドを特定するのに役立ちます';

  @override
  String get prnLabel => '頓服';

  @override
  String get prnUndoToast => '頓服の記録を削除しました';

  @override
  String get dailyLogTitle => '今日の記録';

  @override
  String get noMedicinesScheduled => '今日の予定はありません。';

  @override
  String get remaining => '残り';

  @override
  String get refillRequired => '補充が必要';

  @override
  String get settings => '設定';

  @override
  String get profile => 'プロフィール';

  @override
  String get language => '言語';

  @override
  String get country => '国';

  @override
  String get saveChanges => '変更を保存';

  @override
  String get inventory => '在庫';

  @override
  String get noMedicines => '薬なし';

  @override
  String get takeNow => '服用する';

  @override
  String get snooze => 'スヌーズ';

  @override
  String get skip => 'スキップ';

  @override
  String get pharmacyLabel => '薬局';

  @override
  String get pharmacyPhoneLabel => '薬局の電話番号';

  @override
  String get rxNumberLabel => '処方箋番号';

  @override
  String get globalSettings => 'グローバル設定';

  @override
  String get religiousObservance => '宗教的配慮';

  @override
  String get shabbatMode => 'シャバットモード';

  @override
  String get prayerAwareReminders => '礼拝配慮アラーム';

  @override
  String get halalDetection => 'ハラール & ゼラチン検出';

  @override
  String get amoledMode => 'AMOLEDモード (節電)';

  @override
  String get diabetesMode => '糖尿病モード';

  @override
  String get hypertensionMode => '高血圧モード';

  @override
  String get supportedMarkets => '対応地域';

  @override
  String get halalSafe => 'ハラール対応';

  @override
  String get gelatinWarning => 'ゼラチン含有';

  @override
  String get halalUncertain => '確認が必要';

  @override
  String get edit => 'Edit';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get cancel => 'Cancel';

  @override
  String get globalSettingsSubtitle => '国際市場の設定を管理します';

  @override
  String get medicationDisplay => '医薬品の表示';

  @override
  String get showGenericNames => '一般名（INN）を表示';

  @override
  String get showGenericNamesSubtitle => 'ブランド名の代わりに国際一般名を表示します';

  @override
  String get pbsSafetyNet => 'PBSセーフティーネットトラッカー';

  @override
  String get pbsSafetyNetSubtitle => 'オーストラリア — 年間の自己負担額を追跡';

  @override
  String get pbsThreshold => '年間しきい値: \$1,622.90';

  @override
  String pbsSpent(Object amount) {
    return '支出額: \$$amount';
  }

  @override
  String pbsRemaining(Object amount) {
    return '残り \$$amount';
  }

  @override
  String get reached => '達成！';

  @override
  String get medsSubsidised => '薬が助成対象になりました！';

  @override
  String get spentAmountSubtitle => 'スライダーを動かして、今年のPBS処方箋の自己負担累計額を更新してください';

  @override
  String get clinicalModes => '臨床モード';

  @override
  String get clinicalModesSubtitle => '米国 · 英国 · UAE · マレーシア';

  @override
  String get diabetesModeSubtitle => 'インスリンや糖尿病薬と一緒に血糖値を記録します';

  @override
  String get hypertensionModeSubtitle => '降圧薬と一緒に血圧を記録します';

  @override
  String get displaySettings => '表示';

  @override
  String get amoledModeSubtitle =>
      '有機ELディスプレイ（AMOLED）に最適化し、背景を完全な黒（#000000）にして節電します';

  @override
  String get shabbatModeSubtitle => '金曜の日没から土曜の夜まで、通知をバイブレーションのみにします';

  @override
  String get selectCountry => '国を選択';

  @override
  String get selectLanguage => '言語を選択';

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
  String get appVersionValue => '1.0.0';

  @override
  String get analysisFailed => '解析に失敗しました';

  @override
  String get somethingWentWrong => '問題が発生しました。もう一度やり直してください。';

  @override
  String get retry => '再試行';
}
