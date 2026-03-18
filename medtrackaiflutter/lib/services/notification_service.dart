import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/models.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

// ══════════════════════════════════════════════
// LOCAL NOTIFICATION SERVICE
// ══════════════════════════════════════════════

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final StreamController<String> actionStream =
      StreamController<String>.broadcast();

  static Future<void> init() async {
    await refreshTimeZone();

    const initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'med_action',
          actions: [
            DarwinNotificationAction.plain('take', 'Take Now'),
            DarwinNotificationAction.plain('snooze_10', 'Snooze 10m'),
            DarwinNotificationAction.plain('skip', 'Skip'),
          ],
        ),
      ],
    );
    final initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          final action = response.actionId ?? 'tap';
          actionStream.add('$action|${response.payload}');
        }
      },
    );
  }

  static Future<bool> requestPermission() async {
    // IOS
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
    }
    // Android (Tiramisu+)
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  static Future<void> scheduleWeeklyReminder({
    required Medicine med,
    required ScheduleEntry sched,
    required int dayIdx,
    required int notifId,
    required bool enableSound,
    required bool enableVibration,
    required bool isTakenToday,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'med_reminders',
      'Medicine Reminders',
      channelDescription: 'Scheduled reminders for taking your medication',
      importance: Importance.high,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('take', 'Take Now', showsUserInterface: true),
        AndroidNotificationAction('snooze_10', 'Snooze 10m',
            showsUserInterface: true),
        AndroidNotificationAction('skip', 'Skip',
            showsUserInterface: true, cancelNotification: true),
      ],
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: enableSound,
      categoryIdentifier: 'med_action',
    );
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final now = DateTime.now();
    int targetWeekday = dayIdx == 0 ? 7 : dayIdx;

    // Calculate base scheduled date
    var baseDate = DateTime(now.year, now.month, now.day, sched.h, sched.m);
    int daysUntilTarget = (targetWeekday - now.weekday + 7) % 7;

    // If it's scheduled for today, but the user already marked it as taken today,
    // we must push the baseDate +7 days into the future so it doesn't ring today at all.
    bool pushToNextWeek = false;
    if (daysUntilTarget == 0) {
      if (isTakenToday) {
        pushToNextWeek = true;
      } else if (baseDate.isBefore(now)) {
        pushToNextWeek = true;
      }
    }

    if (pushToNextWeek) {
      daysUntilTarget = 7;
    }

    baseDate = baseDate.add(Duration(days: daysUntilTarget));

    // Single notification logic (March 11th style)
    var scheduledDate = baseDate;
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    try {
      final payload = '${med.id}|${sched.h}|${sched.m}|${sched.label}';
      final title = '💊 Time to take ${med.name}';
      final body = '${med.dose} · ${sched.label}';

      await _plugin.zonedSchedule(
        id: notifId,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      await _plugin.show(
        id: notifId,
        title: '💊 ${med.name}',
        body: '${med.dose} · ${sched.label}',
        notificationDetails: details,
      );
    }
  }

  static Future<void> cancelAll() => _plugin.cancelAll();
  static Future<void> cancel(int id) => _plugin.cancel(id: id);

  static Future<void> showRefillAlert({required Medicine med}) async {
    const androidDetails = AndroidNotificationDetails(
      'refill_alerts',
      'Refill Alerts',
      channelDescription: 'Alerts when your medicine supply is running low',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails =
        DarwinNotificationDetails(presentAlert: true, presentSound: true);
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.show(
      id: med.id + 100000,
      title: '💊 Refill Required',
      body: 'Your supply of ${med.name} is low (${med.count} remaining).',
      notificationDetails: details,
    );
  }

  static Future<void> scheduleMorningSummary({
    required int totalDoses,
    required bool enableSound,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_summaries',
      'Daily Summaries',
      channelDescription: 'Morning summary of your medications for the day',
      importance: Importance.low,
      priority: Priority.low,
    );
    const iosDetails =
        DarwinNotificationDetails(presentAlert: true, presentSound: true);
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 8, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: 999999,
      title: 'Good morning! ☀️',
      body:
          'You have $totalDoses dose${totalDoses == 1 ? "" : "s"} scheduled for today.',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleOneOffReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    bool enableSound = true,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'one_off_reminders',
      'One-off Reminders',
      importance: Importance.high,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('take', 'Take Now',
            showsUserInterface: true),
        AndroidNotificationAction('skip', 'Skip',
            showsUserInterface: true),
      ],
    );
    final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: enableSound,
        categoryIdentifier: 'med_action');
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> refreshTimeZone() async {
    try {
      tz.initializeTimeZones();
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.toString();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback or ignore
    }
  }
}
