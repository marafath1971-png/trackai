import '../../core/utils/result.dart';
import '../entities/scan_result.dart';
import 'dart:io';

abstract class IScannerRepository {
  Future<Result<ScanResult>> scanImage(File imageFile);
}
