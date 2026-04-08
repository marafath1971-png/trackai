import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/utils/logger.dart';

class PurchasesService {
  static String get _appleApiKey =>
      dotenv.env['RC_APPLE_KEY'] ?? 're_your_real_apple_key_here';
  static String get _googleApiKey =>
      dotenv.env['RC_GOOGLE_KEY'] ?? 're_your_real_google_key_here';

  /// If RC_IS_MOCK is set to true in .env, or if keys are missing, we bypass real payments
  static bool get _isMock {
    final mockFlag = dotenv.env['RC_IS_MOCK']?.toLowerCase() == 'true';
    final missingKeys = _appleApiKey.startsWith('re_your_real_') || _googleApiKey.startsWith('re_your_real_');
    return mockFlag || missingKeys;
  }

  static Future<void> init() async {
    if (_isMock) {
      appLogger.i(
          '💰 RevenueCat: Running in MOCK mode (RC_IS_MOCK=true or generic keys detected)');
      return;
    }

    await Purchases.setLogLevel(LogLevel.info);

    PurchasesConfiguration? configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_googleApiKey);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(_appleApiKey);
    }

    if (configuration != null) {
      await Purchases.configure(configuration);
    }
  }

  static Future<bool> isPremium() async {
    if (_isMock) return false; // Default to false in mock
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['premium']?.isActive ?? false;
    } catch (e) {
      appLogger.e('💰 RevenueCat Error', error: e);
      return false;
    }
  }

  static Future<bool> purchasePackage(String packageId) async {
    if (_isMock) {
      // Simulate purchase delay
      await Future.delayed(const Duration(seconds: 2));
      appLogger.i('💰 RevenueCat Mock: Purchased $packageId');
      return true;
    }

    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings.current?.getPackage(packageId);

      if (package != null) {
        final customerInfo = await Purchases.purchasePackage(package);
        return customerInfo.entitlements.all['premium']?.isActive ?? false;
      }
      return false;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        appLogger.e('💰 RevenueCat Purchase Error', error: e);
      }
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    if (_isMock) {
      appLogger.i('💰 RevenueCat Mock: restorePurchases called');
      return false; // In mock, assume no active subscriptions by default
    }
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all['premium']?.isActive ?? false;
    } catch (e) {
      appLogger.e('💰 RevenueCat Restore Error', error: e);
      return false;
    }
  }

  static Future<void> manageSubscriptions() async {
    appLogger.i(
        '💰 RevenueCat: Please manage subscriptions in App Store / Play Store settings.');
  }
}
