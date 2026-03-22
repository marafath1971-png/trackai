import 'package:in_app_review/in_app_review.dart';
import '../core/utils/logger.dart';

class ReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;

  /// Requests a review if the device supports it.
  /// This should be called after a positive user milestone.
  static Future<void> requestReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        appLogger.i("In-app review requested successfully.");
      } else {
        appLogger.w("In-app review is not available on this device.");
      }
    } catch (e) {
      appLogger.e("Error requesting in-app review: $e");
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
