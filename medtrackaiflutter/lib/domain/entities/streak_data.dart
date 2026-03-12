class StreakData {
  final bool frozen;
  final bool freezeUsedWeek;

  const StreakData({this.frozen = false, this.freezeUsedWeek = false});

  Map<String, dynamic> toJson() =>
      {'frozen': frozen, 'freezeUsedWeek': freezeUsedWeek};
  factory StreakData.fromJson(Map<String, dynamic> j) => StreakData(
      frozen: j['frozen'] ?? false,
      freezeUsedWeek: j['freezeUsedWeek'] ?? false);
  StreakData copyWith({bool? frozen, bool? freezeUsedWeek}) => StreakData(
      frozen: frozen ?? this.frozen,
      freezeUsedWeek: freezeUsedWeek ?? this.freezeUsedWeek);
}
