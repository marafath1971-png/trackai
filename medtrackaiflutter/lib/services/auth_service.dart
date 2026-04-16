import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/logger.dart';

// ══════════════════════════════════════════════
// AUTH SERVICE
// ══════════════════════════════════════════════

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _google = GoogleSignIn();

  // Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  static bool get isLoggedIn => currentUser != null;
  static User? get currentUser => _auth.currentUser;
  static String? get uid => currentUser?.uid;
  static String? get email => currentUser?.email;
  static String? get displayName => currentUser?.displayName;
  static String? get photoUrl => currentUser?.photoURL;

  // ── Email/Password ─────────────────────────────────────────────────
  static Future<UserCredential?> signUpWithEmail(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  static Future<UserCredential?> signInWithEmail(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _google.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException {
      rethrow;
    } on PlatformException catch (e) {
      appLogger.e("Google Sign-In Platform Error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      appLogger.e("Google Sign-In General Error: $e");
      rethrow;
    }
  }

  // ── Apple Sign-In ──────────────────────────────────────────────────
  static Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthProvider oAuthProvider = OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException {
      rethrow;
    } on PlatformException catch (e) {
      appLogger.e("Apple Sign-In Platform Error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      appLogger.e("Apple Sign-In General Error: $e");
      rethrow;
    }
  }

  // ── Password Reset ─────────────────────────────────────────────────
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  static Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _google.signOut(),
    ]);
  }

  // ── DELETE ACCOUNT ──────────────────────────────────────────────────
  static Future<void> deleteAccount() async {
    final user = currentUser;
    if (user != null) {
      try {
        final uid = user.uid;
        final firestore = FirebaseFirestore.instance;
        final userRef = firestore.collection('users').doc(uid);
        
        // Comply with 2026 Data Protection: explicit erasure of granular subcollections
        final subcollections = ['medicines', 'history', 'symptoms', 'caregivers', 'monitoring'];
        for (final sub in subcollections) {
          final snap = await userRef.collection(sub).get();
          // WriteBatch can handle up to 500 ops. We'll iterate simply to ensure erasure here.
          // For massive data sets Cloud Functions are preferred, but this handles >95% cases.
          for (var doc in snap.docs) {
            await doc.reference.delete();
          }
        }
        
        // Terminate parent user document
        await userRef.delete();

        // Terminate Auth Identity
        await user.delete();
        await _google.disconnect(); // Disconnect Google Sign-In
        appLogger.i("User $uid successfully deleted with all local/remote data.");
      } catch (e) {
        appLogger.e("FATAL: Failed to erase account data - $e");
        rethrow;
      }
    }
  }
}
