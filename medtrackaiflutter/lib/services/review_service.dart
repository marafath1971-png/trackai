import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/logger.dart';

class ReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;
  static const String _lastPromptKey = 'last_review_prompt_time';
  static const int _cooldownDays = 7;

  /// Requests a review if the device supports it and cooldown has passed.
  /// This should be called after a positive user milestone.
  static Future<void> requestReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPromptStr = prefs.getString(_lastPromptKey);
      
      if (lastPromptStr != null) {
        final lastPrompt = DateTime.parse(lastPromptStr);
        final diff = DateTime.now().difference(lastPrompt).inDays;
        if (diff < _cooldownDays) {
          appLogger.i("[ReviewService] Skipped: Cooldown active ($diff days passed, needs $_cooldownDays).");
          return;
        }
      }

      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        await prefs.setString(_lastPromptKey, DateTime.now().toIso8601String());
        appLogger.i("[ReviewService] In-app review requested successfully.");
      } else {
        appLogger.w("[ReviewService] In-app review is not available on this device.");
      }
    } catch (e) {
      appLogger.e("[ReviewService] Error requesting in-app review: $e");
    }
  }

  /// Opens the store listing for writing a review.
  static Future<void> openStoreReview() async {
    try {
      await _inAppReview.openStoreListing();
    } catch (e) {
      appLogger.e("Error opening store listing: $e");
    }
  }
}
