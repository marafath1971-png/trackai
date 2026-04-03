import 'dart:async';
import 'package:app_links/app_links.dart';
import '../core/utils/logger.dart';

/// Service to handle incoming App Links (Deep Links) for referrals and invites.
class LinkService {
  static final LinkService _instance = LinkService._internal();
  factory LinkService() => _instance;
  LinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription? _sub;

  /// Callback for when a join code is detected.
  Function(String)? onJoinCodeDetected;

  /// Callback for when a referral code is detected.
  Function(String)? onReferralDetected;

  /// Initialize deep link listening.
  Future<void> init() async {
    // 1. Check for initial link (app opened via link from cold start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      appLogger.e('[LinkService] Failed to get initial app link: $e');
    }

    // 2. Listen for incoming links while app is in foreground/background
    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (err) => appLogger.e('[LinkService] Link stream error: $err'),
    );
  }

  void _handleUri(Uri uri) {
    appLogger.i('[LinkService] Received link: $uri');

    if (uri.pathSegments.isNotEmpty) {
      final first = uri.pathSegments.first;

      if (first == 'j' || first == 'join') {
        String? code;
        if (uri.queryParameters.containsKey('code')) {
          code = uri.queryParameters['code'];
        } else if (uri.pathSegments.length >= 2) {
          code = uri.pathSegments[1];
        }

        if (code != null && code.isNotEmpty) {
          appLogger.i('[LinkService] Join code detected: $code');
          onJoinCodeDetected?.call(code);
        }
      } else if (first == 'r' || first == 'ref') {
        String? code;
        if (uri.pathSegments.length >= 2) {
          code = uri.pathSegments[1];
        }
        if (code != null && code.isNotEmpty) {
          appLogger.i('[LinkService] Referral code detected: $code');
          onReferralDetected?.call(code);
        }
      }
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
