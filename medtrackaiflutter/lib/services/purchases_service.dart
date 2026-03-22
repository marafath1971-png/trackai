import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class PurchasesService {
  static const String _appleApiKey = 'goog_placeholder_apple'; // TODO: Replace with real Apple API Key
  static const String _googleApiKey = 'goog_placeholder_google'; // TODO: Replace with real Google API Key

  /// Set this to false and provide real API keys above to enable live production payments.
  static const bool _isMock = true; 

  static Future<void> init() async {
    if (_isMock) {
      debugPrint('💰 RevenueCat: Running in MOCK mode');
      return;
    }

    await Purchases.setLogLevel(LogLevel.debug);

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
      debugPrint('💰 RevenueCat Error: $e');
      return false;
    }
  }

  static Future<bool> purchasePackage(String packageId) async {
    if (_isMock) {
      // Simulate purchase delay
      await Future.delayed(const Duration(seconds: 2));
      debugPrint('💰 RevenueCat Mock: Purchased $packageId');
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
        debugPrint('💰 RevenueCat Purchase Error: ${e.message}');
      }
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    if (_isMock) {
      debugPrint('💰 RevenueCat Mock: restorePurchases called');
      return false; // In mock, assume no active subscriptions by default
    }
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all['premium']?.isActive ?? false;
    } catch (e) {
      debugPrint('💰 RevenueCat Restore Error: $e');
      return false;
    }
  }

  static Future<void> manageSubscriptions() async {
    debugPrint('💰 RevenueCat: Please manage subscriptions in App Store / Play Store settings.');
  }
}
