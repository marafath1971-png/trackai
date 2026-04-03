import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import '../../core/utils/logger.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      // In local_auth 3.0.1, authenticate is the main method, and it doesn't have AuthenticationOptions.
      // It takes direct parameters.
      // ignore: deprecated_member_use
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to unlock Med AI',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      appLogger.e('Biometric Error', error: e);
      return false;
    }
  }
}
