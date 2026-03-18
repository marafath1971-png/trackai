import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../core/utils/logger.dart';

class GlobalErrorBoundary extends StatefulWidget {
  final Widget child;

  const GlobalErrorBoundary({super.key, required this.child});

  @override
  State<GlobalErrorBoundary> createState() => _GlobalErrorBoundaryState();
}

class _GlobalErrorBoundaryState extends State<GlobalErrorBoundary> {
  bool _hasError = false;
  Object? _lastError;

  @override
  void initState() {
    super.initState();
    // Configure Flutter's built-in error display to be silent in production
    // and rely on our boundary for the UI.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      _handleError(details.exception, details.stack ?? StackTrace.current);
      return const SizedBox.shrink();
    };
  }

  void _handleError(Object error, StackTrace stack) {
    appLogger.e('[GlobalErrorBoundary] Caught exception: $error', stackTrace: stack);
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    if (mounted) {
      setState(() {
        _hasError = true;
        _lastError = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '✨',
                      style: TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Something went wrong',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "We've encountered an unexpected issue. Don't worry, your data is safe. Please restart the app.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _ActionButton(
                      label: 'RESTART APP',
                      onTap: () => SystemNavigator.pop(),
                      primary: true,
                    ),
                    const SizedBox(height: 16),
                    if (_lastError != null)
                      Text(
                        'Technical snippet: ${_lastError.toString().split('\n').first}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: Colors.white24,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: primary ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: primary ? null : Border.all(color: Colors.white24),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: primary ? Colors.black : Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
