import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const _keyAlias = 'med_encryption_key_v1';

  static enc.Key? _currentKey;
  static enc.Encrypter? _encrypter;

  static Future<void> init() async {
    String? base64Key = await _storage.read(key: _keyAlias);

    if (base64Key == null) {
      // Generate a new 32-byte key
      final key = enc.Key.fromSecureRandom(32);
      base64Key = base64.encode(key.bytes);
      await _storage.write(key: _keyAlias, value: base64Key);
      _currentKey = key;
    } else {
      _currentKey = enc.Key(base64.decode(base64Key));
    }

    _encrypter = enc.Encrypter(enc.AES(_currentKey!, mode: enc.AESMode.gcm));
  }

  /// Encrypts a plaintext string. Returns Base64 string of IV + Ciphertext.
  static String encrypt(String plainText) {
    if (_encrypter == null) return plainText;
    if (plainText.isEmpty) return plainText;

    try {
      final iv = enc.IV.fromSecureRandom(12); // GCM standard IV size
      final encrypted = _encrypter!.encrypt(plainText, iv: iv);

      // Combine IV and Ciphertext for storage
      final combined = iv.bytes + encrypted.bytes;
      return base64.encode(combined);
    } catch (e) {
      debugPrint('Encryption failed: $e');
      return plainText; // Fail safe
    }
  }

  /// Decrypts a combined Base64 string (IV + Ciphertext).
  static String decrypt(String encryptedBase64) {
    if (_encrypter == null) return encryptedBase64;
    if (encryptedBase64.isEmpty) return encryptedBase64;
    if (encryptedBase64.trimLeft().startsWith('{')) {
      return encryptedBase64; // Plain JSON, skip decryption
    }

    // Quick check if it's even valid Base64 format
    final base64Regex = RegExp(r'^[a-zA-Z0-9\+/]*={0,2}$');
    if (!base64Regex
        .hasMatch(encryptedBase64.replaceAll('\n', '').replaceAll('\r', ''))) {
      return encryptedBase64;
    }

    try {
      final combinedBytes = base64.decode(encryptedBase64);
      if (combinedBytes.length < 12) return encryptedBase64; // Invalid

      final ivBytes = combinedBytes.sublist(0, 12);
      final cipherBytes = combinedBytes.sublist(12);

      final iv = enc.IV(ivBytes);
      final encrypted = enc.Encrypted(cipherBytes);

      return _encrypter!.decrypt(encrypted, iv: iv);
    } catch (e) {
      debugPrint('Decryption failed: $e');
      return encryptedBase64; // Return original if failed (might not be encrypted)
    }
  }
}
