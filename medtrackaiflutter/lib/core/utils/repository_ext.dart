import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import '../errors/exceptions.dart' as e;
import 'logger.dart';

/// Extension on Future to provide a hardened 15s timeout and
/// automatic mapping of lower-level errors to domain-specific AppExceptions.
///
/// Usage:
/// final result = await firestore.getDocs().withHardenedTimeout();

extension FutureHardening<T> on Future<T> {
  Future<T> withHardenedTimeout({
    Duration duration = const Duration(seconds: 15),
    String? taskName,
  }) async {
    try {
      return await timeout(duration);
    } on TimeoutException {
      appLogger.e(
          '[Hardening] Timeout reached for ${taskName ?? "unspecified task"}');
      throw const e.TimeoutException();
    } on SocketException catch (err) {
      appLogger.e('[Hardening] Network issue: ${err.message}');
      throw const e.NetworkException();
    } on FirebaseException catch (err) {
      appLogger.e('[Hardening] Firebase error: [${err.code}] ${err.message}');
      throw _mapFirebaseError(err);
    } catch (err) {
      appLogger.e('[Hardening] Unexpected error: $err');
      if (err is e.AppException) rethrow;
      throw e.ServerException(err.toString());
    }
  }

  e.AppException _mapFirebaseError(FirebaseException err) {
    switch (err.code) {
      case 'permission-denied':
        return const e.PermissionException();
      case 'unauthenticated':
        return const e.AuthException();
      case 'unavailable':
        return const e.NetworkException(
            'Firebase services are currently unavailable. 🌐');
      case 'deadline-exceeded':
        return const e.TimeoutException();
      default:
        return e.ServerException(err.message ?? 'Server error', err.code);
    }
  }
}
