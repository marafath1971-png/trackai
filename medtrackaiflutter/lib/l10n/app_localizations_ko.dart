// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'MedAI';

  @override
  String get greetingHero => '히어로';

  @override
  String get homeTab => '홈';

  @override
  String get alarmsTab => '알림';

  @override
  String get dashboardTab => '트렌드';

  @override
  String get familyTab => '서클';

  @override
  String get scanTab => '스캔';

  @override
  String get countrySelectionTitle => '어느 국가에 거주하시나요?';

  @override
  String get countrySelectionSubtitle => '지역 의약품 브랜드를 식별하는 데 도움이 됩니다';

  @override
  String get prnLabel => '필요시 복용';

  @override
  String get prnUndoToast => '복용 기록이 삭제되었습니다';

  @override
  String get dailyLogTitle => '오늘의 기록';

  @override
  String get noMedicinesScheduled => '오늘 예정된 약이 없습니다.';

  @override
  String get remaining => '남음';

  @override
  String get refillRequired => '남은 약 부족';

  @override
  String get settings => '설정';

  @override
  String get profile => '프로필';

  @override
  String get language => '언어';

  @override
  String get country => '국가';

  @override
  String get saveChanges => '변경사항 저장';

  @override
  String get inventory => '재고';

  @override
  String get noMedicines => '약 없음';

  @override
  String get takeNow => '복용하기';

  @override
  String get snooze => '미루기';

  @override
  String get skip => '건너뛰기';

  @override
  String get pharmacyLabel => '약국';

  @override
  String get pharmacyPhoneLabel => '약국 전화번호';

  @override
  String get rxNumberLabel => '처방 번호';

  @override
  String get globalSettings => '글로벌 설정';

  @override
  String get religiousObservance => '종교적 고려사항';

  @override
  String get shabbatMode => '샤밧 모드';

  @override
  String get prayerAwareReminders => '기도 시간 고려 알림';

  @override
  String get halalDetection => '할랄 및 젤라틴 감지';

  @override
  String get amoledMode => 'AMOLED 모드 (절전)';

  @override
  String get diabetesMode => '당뇨 모드';

  @override
  String get hypertensionMode => '고혈압 모드';

  @override
  String get supportedMarkets => '지원 국가';

  @override
  String get halalSafe => '할랄 안전';

  @override
  String get gelatinWarning => '젤라틴 포함';

  @override
  String get halalUncertain => '확인 필요';

  @override
  String get edit => 'Edit';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get cancel => 'Cancel';

  @override
  String get globalSettingsSubtitle => '국제 마켓 설정을 관리합니다';

  @override
  String get medicationDisplay => '의약품 표시';

  @override
  String get showGenericNames => '성분명(INN) 표시';

  @override
  String get showGenericNamesSubtitle => '상표명 대신 국제 성분명을 표시합니다';

  @override
  String get pbsSafetyNet => 'PBS 세이프티 넷 추적';

  @override
  String get pbsSafetyNetSubtitle => '호주 — 연간 본인부담금을 추적합니다';

  @override
  String get pbsThreshold => '연간 한도: \$1,622.90';

  @override
  String pbsSpent(Object amount) {
    return '지출액: \$$amount';
  }

  @override
  String pbsRemaining(Object amount) {
    return '남은 금액: \$$amount';
  }

  @override
  String get reached => '달성!';

  @override
  String get medsSubsidised => '이제 약값을 보조받을 수 있습니다!';

  @override
  String get spentAmountSubtitle =>
      '슬라이더를 움직여 이번 해의 PBS 조제 본인부담금 총 누적액을 업데이트하세요';

  @override
  String get clinicalModes => '임상 모드';

  @override
  String get clinicalModesSubtitle => '미국 · 영국 · UAE · 말레이시아';

  @override
  String get diabetesModeSubtitle => '인슐린/당뇨 약과 함께 혈당을 기록합니다';

  @override
  String get hypertensionModeSubtitle => '혈압약과 함께 혈압을 기록합니다';

  @override
  String get displaySettings => '디스플레이';

  @override
  String get amoledModeSubtitle =>
      '배경을 완전한 블랙(#000000)으로 설정하여 AMOLED 디스플레이를 최적화하고 배터리를 절약합니다';

  @override
  String get shabbatModeSubtitle => '금요일 일몰부터 토요일 밤까지 알림을 진동으로만 설정합니다';

  @override
  String get selectCountry => '국가 선택';

  @override
  String get selectLanguage => '언어 선택';

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
  String get analysisFailed => '분석 실패';

  @override
  String get somethingWentWrong => '문제가 발생했습니다. 다시 시도해 주세요.';

  @override
  String get retry => '재시도';
}
