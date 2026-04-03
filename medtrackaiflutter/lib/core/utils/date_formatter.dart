import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';

String todayStr() => formatDateKey(DateTime.now());

String formatDateKey(DateTime d) => d.toIso8601String().substring(0, 10);

int dayIdx() => DateTime.now().weekday % 7; // 0=Sun...6=Sat

String fmtTime(int h, int m, [BuildContext? context]) {
  final date = DateTime(2026, 1, 1, h, m);
  // Using context to get the current locale if available, else system default
  return DateFormat.jm(
          context != null ? Localizations.localeOf(context).toString() : null)
      .format(date);
}

String fmtCurrency(double amount, [BuildContext? context]) {
  // Automatically detects currency symbol based on locale (e.g. $ for US, £ for UK)
  final locale =
      context != null ? Localizations.localeOf(context).toString() : null;
  return NumberFormat.simpleCurrency(locale: locale).format(amount);
}

String fmtFullDate(DateTime d, [BuildContext? context]) {
  final locale =
      context != null ? Localizations.localeOf(context).toString() : null;
  return DateFormat.yMMMMd(locale).format(d);
}

String greet(BuildContext context) {
  final s = AppLocalizations.of(context)!;
  final h = DateTime.now().hour;
  if (h < 12) return s.goodMorning;
  if (h < 17) return s.goodAfternoon;
  return s.goodEvening;
}

int nowMins() => DateTime.now().hour * 60 + DateTime.now().minute;
