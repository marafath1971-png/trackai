/// Unified Domain Exception Model for MedAI 1.0
///
/// Following the 'Hardening Point 4' of the 15-point checklist.
/// Aim: Prevent runtime crashes by ensuring all repository failures are typed.
library;

sealed class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => '$runtimeType: $message${code != null ? " ($code)" : ""}';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Check your internet connection 🌐', String? code])
      : super(code: code);
}

class ServerException extends AppException {
  const ServerException([super.message = 'The server is taking a breather... 😴', String? code])
      : super(code: code);
}

class AuthException extends AppException {
  const AuthException([super.message = 'Authentication failed. Please sign in again. 🔐', String? code])
      : super(code: code);
}

class SecurityException extends AppException {
  const SecurityException([super.message = 'Security breach or unauthorized access. 🛡️', String? code])
      : super(code: code);
}

class CacheException extends AppException {
  const CacheException([super.message = 'Local storage error. 💾', String? code])
      : super(code: code);
}

class PermissionException extends AppException {
  const PermissionException([super.message = 'Permission denied. 🚫', String? code])
      : super(code: code);
}

class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Request timed out after 15s. ⏳', String? code])
      : super(code: code);
}
