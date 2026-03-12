
String todayStr() => DateTime.now().toIso8601String().substring(0, 10);

int dayIdx() => DateTime.now().weekday % 7; // 0=Sun...6=Sat

String fmtTime(int h, int m) {
  final h12 = h % 12 == 0 ? 12 : h % 12;
  final ampm = h >= 12 ? 'PM' : 'AM';
  return '$h12:${m.toString().padLeft(2, '0')} $ampm';
}

String greet() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

int nowMins() => DateTime.now().hour * 60 + DateTime.now().minute;
