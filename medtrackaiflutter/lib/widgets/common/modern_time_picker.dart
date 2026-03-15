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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: L.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
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
          const SizedBox(height: 24),
          Text(
            widget.title,
            style: TextStyle(
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
                    scrollController: FixedExtentScrollController(initialItem: _hour),
                    itemExtent: 45,
                    onSelectedItemChanged: (h) {
                      setState(() => _hour = h);
                      widget.onTimeChanged(TimeOfDay(hour: _hour, minute: _minute));
                    },
                    children: List.generate(24, (i) => Center(
                      child: Text(
                        i.toString().padLeft(2, '0'),
                        style: TextStyle(
                          color: L.text,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Inter',
                        ),
                      ),
                    )),
                  ),
                ),
                Text(":", style: TextStyle(color: L.text, fontSize: 24, fontWeight: FontWeight.w900)),
                // Minutes
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(initialItem: _minute),
                    itemExtent: 45,
                    onSelectedItemChanged: (m) {
                      setState(() => _minute = m);
                      widget.onTimeChanged(TimeOfDay(hour: _hour, minute: _minute));
                    },
                    children: List.generate(60, (i) => Center(
                      child: Text(
                        i.toString().padLeft(2, '0'),
                        style: TextStyle(
                          color: L.text,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Inter',
                        ),
                      ),
                    )),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.L.text,
                foregroundColor: context.L.bg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              child: const Text(
                "Set Time",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
