import '../entities/entities.dart';

abstract class IUserRepository {
  Future<UserProfile?> getProfile();
  Future<void> saveProfile(UserProfile profile);

  Future<List<Caregiver>> getCaregivers();
  Stream<List<Caregiver>> getCaregiversStream();
  Future<void> saveCaregivers(List<Caregiver> caregivers);
  Future<void> joinCaregiver(String patientUid, int cgId);

  Future<StreakData> getStreakData();
  Future<void> saveStreakData(StreakData data);

  Future<bool> getDarkMode();
  Future<void> saveDarkMode(bool darkMode);

  Future<void> createInvite(String patientUid, Caregiver cg);
  Future<Caregiver?> getInvite(String code);
  Future<Map<String, dynamic>?> getRawInvite(String code);
  Future<void> deleteInvite(String code);
  Future<void> saveFcmToken(String token);
}
