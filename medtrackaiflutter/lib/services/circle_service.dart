import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/utils/logger.dart';

class CircleService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Generate a unique 6-digit invite code and store it in Firestore.
  static Future<String> generateInviteCode({
    required String patientName,
    required String patientAvatar,
    required String relation,
    required int alertDelay,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    final code = _generateRandomCode(6);

    // Store in 'invites' collection with 24h expiration
    await _db.collection('invites').doc(code).set({
      'patientUid': uid,
      'patientName': patientName,
      'patientAvatar': patientAvatar,
      'relation': relation,
      'alertDelay': alertDelay,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt':
          DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch,
    });

    appLogger.i('[CircleService] Created invite code: $code for patient: $uid');
    return code;
  }

  /// Verify and consume an invite code.
  /// Updates both the patient's caregiver list and the caregiver's monitoring list.
  static Future<Map<String, dynamic>> verifyAndJoin(String code) async {
    final cgUid = _auth.currentUser?.uid;
    if (cgUid == null) throw Exception('User not authenticated');

    return await _db.runTransaction((tx) async {
      final inviteRef = _db.collection('invites').doc(code.toUpperCase());
      final inviteDoc = await tx.get(inviteRef);

      if (!inviteDoc.exists) {
        throw Exception('Invalid or expired invite code');
      }

      final data = inviteDoc.data()!;
      final expiresAt = data['expiresAt'] as int;
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        tx.delete(inviteRef);
        throw Exception('Invite code has expired');
      }

      final patientUid = data['patientUid'] as String;
      if (patientUid == cgUid) {
        throw Exception('You cannot join your own care circle');
      }

      // 1. Add caregiver to patient's document (or subcollection)
      // For simplicity in this architecture, we use a 'caregivers' field in the user document
      final patientRef = _db.collection('users').doc(patientUid);
      tx.update(patientRef, {
        'caregivers': FieldValue.arrayUnion([
          {
            'uid': cgUid,
            'name': _auth.currentUser?.displayName ?? 'Family Member',
            'status': 'active',
            'relation': data['relation'],
            'addedAt': DateTime.now().toIso8601String(),
          }
        ])
      });

      // 2. Add patient to caregiver's 'monitoring' list
      final cgRef = _db.collection('users').doc(cgUid);
      tx.update(cgRef, {
        'monitoring': FieldValue.arrayUnion([
          {
            'uid': patientUid,
            'name': data['patientName'],
            'avatar': data['patientAvatar'],
            'relation': data['relation'],
            'status': 'active',
            'addedAt': DateTime.now().toIso8601String(),
          }
        ])
      });

      // 3. Consume the invite
      tx.delete(inviteRef);

      appLogger.i(
          '[CircleService] Transaction complete: $cgUid joined $patientUid circle');

      return {
        'success': true,
        'patientName': data['patientName'],
        'patientUid': patientUid,
      };
    });
  }

  static String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No O, 0, I, 1
    final rnd = Random();
    return List.generate(length, (index) => chars[rnd.nextInt(chars.length)])
        .join();
  }
}
