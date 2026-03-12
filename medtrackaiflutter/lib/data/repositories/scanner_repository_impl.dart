import 'dart:io';
import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/scanner_repository.dart';
import '../../core/utils/result.dart';
import '../../services/gemini_service.dart';

class ScannerRepositoryImpl implements IScannerRepository {
  @override
  Future<Result<ScanResult>> scanImage(File imageFile) async {
    return await GeminiService.scanMedicine(imageFile);
  }
}
