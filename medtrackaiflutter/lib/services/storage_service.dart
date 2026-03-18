import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/utils/logger.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadMedicineImage(String uid, File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('users').child(uid).child('medicines').child(fileName);
      
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      if (uploadTask.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL();
        appLogger.i('[StorageService] Image uploaded successfully: $downloadUrl');
        return downloadUrl;
      }
      return null;
    } catch (e) {
      appLogger.e('[StorageService] Image upload failed: $e');
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
