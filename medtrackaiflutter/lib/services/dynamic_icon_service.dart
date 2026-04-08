import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';
import '../core/utils/logger.dart';

class DynamicIconService {
  /// Toggle between different app icon styles.
  /// iconName can be: null (default), 'blue', 'dark', 'gold'
  static Future<void> setIcon(String? iconName) async {
    try {
      final bool isSupported =
          await FlutterDynamicIconPlus.supportsAlternateIcons;
      if (!isSupported) {
        appLogger.w('🏷️ Dynamic Icons not supported on this device');
        return;
      }

      // Check current icon
      final String? currentIcon =
          await FlutterDynamicIconPlus.alternateIconName;
      if (currentIcon == iconName) return;

      // Set new icon
      await FlutterDynamicIconPlus.setAlternateIconName(
        iconName: iconName,
      );

      appLogger.i('🏷️ App Icon changed to: ${iconName ?? 'Default'}');
    } catch (e) {
      appLogger.e('🏷️ Failed to change app icon', error: e);
    }
  }

  /// Get the current icon name
  static Future<String?> getCurrentIcon() async {
    try {
      return await FlutterDynamicIconPlus.alternateIconName;
    } catch (e) {
      return null;
    }
  }
}
