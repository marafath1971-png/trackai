import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/encryption_service.dart';
import '../../core/utils/logger.dart';

class LocalDataSource {
  final SharedPreferences _prefs;

  SharedPreferences get prefs => _prefs;

  LocalDataSource(this._prefs);

  Future<void> setString(String key, String value, {bool encrypt = false}) {
    String s = value;
    if (encrypt) s = EncryptionService.encrypt(s);
    return _prefs.setString(key, s);
  }

  String? getString(String key, {bool decrypt = false}) {
    String? s = _prefs.getString(key);
    if (s != null && decrypt) s = EncryptionService.decrypt(s);
    return s;
  }

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  bool? getBool(String key) => _prefs.getBool(key);

  Future<void> remove(String key) => _prefs.remove(key);

  // Helper for JSON
  Future<void> setJson(String key, dynamic value, {bool encrypt = false}) {
    String s = jsonEncode(value);
    if (encrypt) s = EncryptionService.encrypt(s);
    return _prefs.setString(key, s);
  }

  dynamic getJson(String key, {bool decrypt = false}) {
    String? s = _prefs.getString(key);
    if (s != null && decrypt) {
      // It is possible the format is unencrypted from previous versions
      try {
        s = EncryptionService.decrypt(s);
        return jsonDecode(s);
      } catch (e) {
        // If decryption fails, the data is either corrupted or unauthorized.
        // Returning null is safer than falling back to plaintext.
        appLogger.e('[LocalDataSource] Decryption failed for key $key',
            error: e);
        return null;
      }
    }
    return s != null ? jsonDecode(s) : null;
  }
}
