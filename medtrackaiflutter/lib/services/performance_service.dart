import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';

class PerformanceService {
  static final FirebasePerformance _perf = FirebasePerformance.instance;

  /// Start a custom trace for a specific action (e.g., 'medicine_scan_trace')
  static Future<Trace> startTrace(String name) async {
    final trace = _perf.newTrace(name);
    await trace.start();
    if (kDebugMode) appLogger.d('[Performance] Started Trace: $name');
    return trace;
  }

  /// Measure the time it takes for an async operation to complete.
  static Future<T> measure<T>(String name, Future<T> Function() action) async {
    final trace = await startTrace(name);
    try {
      final result = await action();
      return result;
    } finally {
      await trace.stop();
      if (kDebugMode) appLogger.d('[Performance] Stopped Trace: $name');
    }
  }
}
