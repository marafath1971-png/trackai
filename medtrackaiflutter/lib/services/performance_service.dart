import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';

class PerformanceService {
  static FirebasePerformance? get _perf {
    try {
      return FirebasePerformance.instance;
    } catch (_) {
      return null;
    }
  }

  /// Measure the time it takes for an async operation to complete.
  static Future<T> measure<T>(String name, Future<T> Function() action) async {
    final p = _perf;
    if (p == null) return action();

    final trace = p.newTrace(name);
    await trace.start();
    try {
      return await action();
    } finally {
      await trace.stop();
      if (kDebugMode) appLogger.d('[Performance] Stopped Trace: $name');
    }
  }

  /// Measure the time it takes for a sync operation to complete.
  static T measureSync<T>(String name, T Function() action) {
    final p = _perf;
    if (p == null) return action();

    final trace = p.newTrace(name);
    trace.start();
    try {
      return action();
    } finally {
      trace.stop();
      if (kDebugMode) appLogger.d('[Performance] Stopped Trace: $name');
    }
  }
}
