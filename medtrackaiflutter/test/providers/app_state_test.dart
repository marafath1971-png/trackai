import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:medtrackaiflutter/providers/app_state.dart';
import 'package:medtrackaiflutter/domain/repositories/medication_repository.dart';
import 'package:medtrackaiflutter/domain/repositories/user_repository.dart';
import 'package:medtrackaiflutter/domain/repositories/symptom_repository.dart';
import 'package:medtrackaiflutter/domain/entities/entities.dart';
import 'package:audioplayers/audioplayers.dart';

class MockMedicationRepository extends Mock implements IMedicationRepository {}
class MockUserRepository extends Mock implements IUserRepository {}
class MockSymptomRepository extends Mock implements SymptomRepository {}
class MockAudioPlayer extends Mock implements AudioPlayer {}

class FakeUserProfile extends Fake implements UserProfile {}
class FakeMedicine extends Fake implements Medicine {}
class FakeStreakData extends Fake implements StreakData {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUserProfile());
    registerFallbackValue(FakeMedicine());
    registerFallbackValue(FakeStreakData());
  });

  late AppState appState;
  late MockMedicationRepository mockMedRepo;
  late MockUserRepository mockUserRepo;
  late MockSymptomRepository mockSymptomRepo;
  late MockAudioPlayer mockAudioPlayer;

  setup() {
    mockMedRepo = MockMedicationRepository();
    mockUserRepo = MockUserRepository();
    mockSymptomRepo = MockSymptomRepository();
    mockAudioPlayer = MockAudioPlayer();
    
    // Default mock behavior
    when(() => mockUserRepo.getCaregiversStream()).thenAnswer((_) => Stream.value([]));
    when(() => mockUserRepo.getMonitoringPatientsStream()).thenAnswer((_) => Stream.value([]));
    when(() => mockUserRepo.saveDarkMode(any())).thenAnswer((_) => Future.value());
    when(() => mockUserRepo.saveProfile(any())).thenAnswer((_) => Future.value());
    when(() => mockUserRepo.saveCaregivers(any())).thenAnswer((_) => Future.value());
    when(() => mockUserRepo.saveStreakData(any())).thenAnswer((_) => Future.value());
    
    when(() => mockMedRepo.saveTakenToday(any())).thenAnswer((_) => Future.value());
    when(() => mockMedRepo.saveHistory(any(), onlyDateKey: any(named: 'onlyDateKey'))).thenAnswer((_) => Future.value());
    when(() => mockMedRepo.updateMedicine(any())).thenAnswer((_) => Future.value());
    when(() => mockSymptomRepo.getSymptoms()).thenAnswer((_) => Future.value([]));
    
    appState = AppState(
      medRepo: mockMedRepo,
      userRepo: mockUserRepo,
      symptomRepo: mockSymptomRepo,
      audioPlayer: mockAudioPlayer,
    );
  }

  group('AppState Analytics Logic', () {
    setUp(() => setup());

    test('getStreak returns 0 with no history', () {
      expect(appState.getStreak(), 0);
    });

    test('getAdherenceScore returns 1.0 with no history', () {
      expect(appState.getAdherenceScore(), 1.0);
    });

    test('getTrendData returns 30 entries', () {
      final trend = appState.getTrendData();
      expect(trend.length, 30);
      expect(trend.first.containsKey('date'), true);
      expect(trend.first.containsKey('value'), true);
    });

    test('getAdherenceScore calculates correctly with history', () {
      final now = DateTime.now();
      // Case 1: Fresh install behavior (No history)

      // Add a medicine scheduled for ALL days for simplicity in testing
      final med = Medicine(
        id: 1,
        name: 'Test Med',
        count: 10,
        totalCount: 30,
        courseStartDate: '2024-01-01',
        schedule: [
          ScheduleEntry(h: 8, m: 0, label: 'Morning', days: [0, 1, 2, 3, 4, 5, 6])
        ],
      );
      appState.meds = [med];

      // Case 1: Fresh install behavior (No history)
      appState.history = {};
      expect(appState.getAdherenceScore(), 1.0);

      // Case 2: Some history exists, but none in the last 30 days (Adherence should drop if meds scheduled)
      appState.history = {
        '2000-01-01': [DoseEntry(medId: 1, label: 'Morning', time: '08:00', taken: true)]
      };
      appState.toggleDarkMode(); 
      expect(appState.getAdherenceScore(), 0.0);

      // Case 2: Fully adherent
      // Populate last 30 days
      final Map<String, List<DoseEntry>> fullHistory = {};
      for (int i = 0; i < 30; i++) {
        final d = now.subtract(Duration(days: i));
        final k = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
        fullHistory[k] = [DoseEntry(medId: 1, label: 'Morning', time: '08:00', taken: true)];
      }
      appState.history = fullHistory;
      appState.toggleDarkMode(); 
      expect(appState.getAdherenceScore(), 1.0);
    });

    test('getStreak calculates correctly', () {
      final now = DateTime.now();
      
      final med = Medicine(
        id: 1,
        name: 'Test Med',
        count: 10,
        totalCount: 30,
        courseStartDate: '2024-01-01',
        schedule: [
          ScheduleEntry(h: 8, m: 0, label: 'Morning', days: [0, 1, 2, 3, 4, 5, 6])
        ],
      );
      appState.meds = [med];

      // Case 1: 3-day streak
      final Map<String, List<DoseEntry>> streakHistory = {};
      for (int i = 1; i <= 3; i++) {
        final d = now.subtract(Duration(days: i));
        final k = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
        streakHistory[k] = [DoseEntry(medId: 1, label: 'Morning', time: '08:00', taken: true)];
      }
      appState.history = streakHistory;
      appState.toggleDarkMode();
      expect(appState.getStreak(), 3);
    });
  });
}
