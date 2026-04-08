import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../theme/app_theme.dart';

class ModernTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onTimeChanged;
  final String title;

  const ModernTimePicker({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
    this.title = "Select Time",
  });

  @override
  State<ModernTimePicker> createState() => _ModernTimePickerState();

  static Future<TimeOfDay?> show(
    BuildContext context, {
    required TimeOfDay initialTime,
    String title = "Select Time",
  }) async {
    TimeOfDay? selectedTime = initialTime;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ModernTimePicker(
        initialTime: initialTime,
        title: title,
        onTimeChanged: (t) => selectedTime = t,
      ),
    );
    return selectedTime;
  }
}

class _ModernTimePickerState extends State<ModernTimePicker> {
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding, vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, -10),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: L.border.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Text(
            widget.title,
            style: AppTypography.headlineLarge.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: L.text,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hours
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: _hour % 12 == 0 ? 11 : (_hour % 12) - 1,
                    ),
                    itemExtent: 45,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        final h12 = index + 1;
                        if (_hour >= 12) {
                          _hour = h12 == 12 ? 12 : h12 + 12;
                        } else {
                          _hour = h12 == 12 ? 0 : h12;
                        }
                      });
                      widget.onTimeChanged(
                          TimeOfDay(hour: _hour, minute: _minute));
                    },
                    children: List.generate(
                        12,
                        (i) => Center(
                              child: Text(
                                (i + 1).toString().padLeft(2, '0'),
                                style: AppTypography.displayMedium.copyWith(
                                  color: L.text,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            )),
                  ),
                ),
                Text(":",
                    style: AppTypography.displayMedium.copyWith(
                        color: L.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
                // Minutes
                Expanded(
                  child: CupertinoPicker(
                    scrollController:
                        FixedExtentScrollController(initialItem: _minute),
                    itemExtent: 45,
                    onSelectedItemChanged: (m) {
                      setState(() => _minute = m);
                      widget.onTimeChanged(
                          TimeOfDay(hour: _hour, minute: _minute));
                    },
                    children: List.generate(
                        60,
                        (i) => Center(
                              child: Text(
                                i.toString().padLeft(2, '0'),
                                style: AppTypography.displayMedium.copyWith(
                                  color: L.text,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            )),
                  ),
                ),
                const SizedBox(width: 8),
                // AM/PM
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                        initialItem: _hour >= 12 ? 1 : 0),
                    itemExtent: 45,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        final isPm = index == 1;
                        final h12 = _hour % 12 == 0 ? 12 : _hour % 12;
                        if (isPm) {
                          _hour = h12 == 12 ? 12 : h12 + 12;
                        } else {
                          _hour = h12 == 12 ? 0 : h12;
                        }
                      });
                      widget.onTimeChanged(
                          TimeOfDay(hour: _hour, minute: _minute));
                    },
                    children: [
                      Center(
                          child: Text("AM",
                              style: AppTypography.titleLarge.copyWith(
                                  color: L.text,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800))),
                      Center(
                          child: Text("PM",
                              style: AppTypography.titleLarge.copyWith(
                                  color: L.text,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Center(
                child: Text(
                  "Set Time",
                  style: AppTypography.labelLarge.copyWith(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
        ],
      ),
    );
  }
}
