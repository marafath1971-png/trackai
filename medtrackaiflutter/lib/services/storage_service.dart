import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/utils/logger.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadMedicineImage(String uid, File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage
          .ref()
          .child('users')
          .child(uid)
          .child('medicines')
          .child(fileName);

      // 1. Wait for upload to COMPLETE before proceding, with a 15-second timeout
      final task = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await task.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw FirebaseException(
            plugin: 'firebase_storage',
            code: 'deadline-exceeded',
            message:
                'Image upload timed out after 15 seconds. Please check your network connection.',
          );
        },
      );

      if (snapshot.state == TaskState.success) {
        // 2. Wrap getDownloadURL in a small micro-delay or verification
        // for race conditions in some storage regions
        final downloadUrl = await ref.getDownloadURL();
        appLogger
            .i('[StorageService] Image uploaded successfully: $downloadUrl');
        return downloadUrl;
      }
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'canceled') {
        appLogger.w('[StorageService] Upload canceled by user/system.');
      } else {
        appLogger.e(
            '[StorageService] Image upload failed (${e.code}): ${e.message}');
      }
      return null;
    } catch (e) {
      appLogger.e('[StorageService] Unexpected upload error: $e');
      return null;
    }
  }

  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      appLogger.i('[StorageService] Image deleted successfully: $url');
    } catch (e) {
      appLogger.e('[StorageService] Image deletion failed: $e');
    }
  }
}
