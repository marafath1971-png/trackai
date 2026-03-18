import '../domain/repositories/user_repository.dart';
import '../domain/entities/entities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InviteService {
  final IUserRepository userRepository;
  // Default expiration period in days
  final int expirationDays;

  InviteService(this.userRepository, {this.expirationDays = 7});

  /// Creates an invitation for a caregiver.
  /// Returns the generated invite code.
  Future<String> createInvite(String patientUid, Caregiver caregiver) async {
    await userRepository.createInvite(patientUid, caregiver);
    return caregiver.inviteCode;
  }

  /// Retrieves a caregiver invitation by its code.
  /// Returns the raw map data if the invite exists, otherwise null.
  Future<Map<String, dynamic>?> fetchInvite(String code) async {
    final data = await userRepository.getRawInvite(code);
    if (data == null) return null;
    return data;
  }

  /// Checks if an invite created at [createdAt] is still valid.
  bool isInviteValid(Timestamp createdAt) {
    final now = Timestamp.now();
    final diff = now.seconds - createdAt.seconds;
    return diff <= expirationDays * 24 * 60 * 60;
  }

  /// Accepts an invitation by joining the caregiver to the patient.
  /// Validates expiration before proceeding.
  Future<bool> acceptInvite(String patientUid, String code) async {
    // Retrieve raw invite data to check timestamp.
    final raw = await (userRepository as dynamic).getRawInvite(code);
    if (raw == null) return false;
    final Timestamp? createdAt = raw['createdAt'] as Timestamp?;
    if (createdAt == null || !isInviteValid(createdAt)) {
      // Optionally delete expired invite.
      await (userRepository as dynamic).deleteInvite(code);
      return false;
    }
    final int caregiverId = raw['cgId'] as int;
    final String relation = raw['relation'] as String? ?? 'Family';
    
    // Fetch patient profile to get their name and avatar
    final patientProfile = await userRepository.getOtherProfile(patientUid);
    
    await userRepository.joinCaregiver(
      patientUid: patientUid,
      cgId: caregiverId,
      patientName: patientProfile?.name ?? 'Patient',
      patientAvatar: patientProfile?.avatar ?? '👤',
      relation: relation,
    );
    // Optionally delete after acceptance.
    await (userRepository as dynamic).deleteInvite(code);
    return true;
  }
}
