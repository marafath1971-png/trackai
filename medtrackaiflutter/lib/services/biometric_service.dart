import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import '../../core/utils/logger.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> canCheckBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      appLogger.e('Biometric Check Error', error: e);
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      final canCheck = await canCheckBiometrics();
      if (!canCheck) {
        appLogger.w('Biometrics not available or supported');
        return false;
      }

      return await _auth.authenticate(
        localizedReason: 'Please authenticate to unlock MedAI',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      appLogger.e('Biometric Auth Error', error: e);
      return false;
    } catch (e) {
      appLogger.e('Unexpected Biometric Error', error: e);
      return false;
    }
  }
}
