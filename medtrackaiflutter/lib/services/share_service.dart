import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../core/utils/logger.dart';

/// Centralized share service for all viral sharing mechanics.
class ShareService {
  // ── App Store URLs (replace with real ones before launch) ──
  static const String _appStoreUrl =
      'https://apps.apple.com/app/med-ai/id000000000';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.medai.app';

  static String get downloadUrl =>
      Platform.isIOS ? _appStoreUrl : _playStoreUrl;

  /// Share a plain text message with optional subject.
  static Future<void> shareText(String text, {String? subject}) async {
    try {
      // ignore: deprecated_member_use
      await Share.share(
        text,
        subject: subject,
      );
    } catch (e) {
      appLogger.e('[ShareService] shareText failed', error: e);
    }
  }

  /// Share a referral invite message.
  static Future<void> shareReferral(String referralCode,
      {String? userName}) async {
    final name = userName ?? 'Someone';
    final message = '$name uses Med AI to never miss a dose.\n\n'
        'Try it free with code: $referralCode\n'
        '14-day premium trial included!\n\n'
        '$downloadUrl';
    await shareText(message, subject: 'Join me on Med AI');
  }

  /// Share an achievement milestone (streak, adherence, etc.)
  static Future<void> shareAchievement({
    required String title,
    required String subtitle,
    String? emoji,
  }) async {
    final emojiStr = emoji ?? '🏆';
    final message = '$emojiStr $title\n'
        '$subtitle\n\n'
        'Track your medications with Med AI\n'
        '$downloadUrl';
    await shareText(message, subject: title);
  }

  /// Share a streak milestone.
  static Future<void> shareStreak(int streakDays) async {
    String tier;
    String emoji;
    if (streakDays >= 365) {
      tier = 'Legendary';
      emoji = '🌟';
    } else if (streakDays >= 100) {
      tier = 'Diamond';
      emoji = '👑';
    } else if (streakDays >= 60) {
      tier = 'Platinum';
      emoji = '💎';
    } else if (streakDays >= 30) {
      tier = 'Gold';
      emoji = '🏆';
    } else if (streakDays >= 14) {
      tier = 'Silver';
      emoji = '🏅';
    } else if (streakDays >= 7) {
      tier = 'Bronze';
      emoji = '⚡';
    } else {
      tier = 'Starter';
      emoji = '🌱';
    }

    await shareAchievement(
      title: '$streakDays-Day Streak!',
      subtitle:
          '$tier tier achieved! I\'m taking my medications consistently with Med AI.',
      emoji: emoji,
    );
  }

  /// Share a scan result (medicine identified).
  static Future<void> shareScanResult(String medicineName) async {
    await shareAchievement(
      title: 'Medicine Identified: $medicineName',
      subtitle: 'I just scanned my medicine with AI and got instant details!',
      emoji: '🔬',
    );
  }

  /// Share adherence achievement.
  static Future<void> shareAdherence(int percentage) async {
    String message;
    if (percentage >= 95) {
      message = 'Perfect adherence! I\'m a medication champion!';
    } else if (percentage >= 80) {
      message = 'Strong adherence this month. Staying on track!';
    } else {
      message = 'Working on improving my medication adherence!';
    }
    await shareAchievement(
      title: '$percentage% Medication Adherence',
      subtitle: message,
      emoji: '📊',
    );
  }

  /// Capture a widget as an image and share it.
  static Future<void> shareWidgetAsImage(
    GlobalKey repaintKey, {
    String? text,
    String? subject,
  }) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await path_provider.getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/medai_achievement_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      // ignore: deprecated_member_use
      await Share.share(
        text ?? 'Check out my achievement on Med AI! $downloadUrl',
        subject: subject ?? 'My Med AI Achievement',
        // In share_plus 10+, files are shared via shareXFiles
      );
      if (text == null && [XFile(file.path)].isNotEmpty) {
        // ignore: deprecated_member_use
        await Share.shareXFiles([XFile(file.path)],
            text: text, subject: subject);
      }
    } catch (e) {
      appLogger.e('[ShareService] shareWidgetAsImage failed', error: e);
      // Fallback to text-only share
      if (text != null) await shareText(text, subject: subject);
    }
  }
}
