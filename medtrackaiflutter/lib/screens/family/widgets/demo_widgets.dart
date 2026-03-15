import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class SimulateMissCard extends StatefulWidget {
  final AppThemeColors L;
  final VoidCallback onSimulate;
  const SimulateMissCard({super.key, required this.L, required this.onSimulate});
  @override
  State<SimulateMissCard> createState() => _SimulateMissCardState();
}

class _SimulateMissCardState extends State<SimulateMissCard> {
  bool _simulating = false;
  @override
  Widget build(BuildContext context) {
    final L = widget.L;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1))
          ]),
      child: Column(children: [
        Row(children: [
          Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(24)),
              child: Center(
                  child: Icon(Icons.auto_awesome_rounded,
                      size: 15, color: L.purple))),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Test Alert Cycle',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: L.text)),
                Text('Simulate a missed dose alert',
                    style: TextStyle(
                        fontFamily: 'Inter', fontSize: 11, color: L.sub)),
              ])),
          GestureDetector(
            onTap: _simulating
                ? null
                : () async {
                    setState(() => _simulating = true);
                    widget.onSimulate();
                    await Future.delayed(const Duration(seconds: 1));
                    if (mounted) setState(() => _simulating = false);
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: _simulating ? L.border : const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(_simulating ? 'Sending...' : 'Trigger',
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          )
        ]),
      ]),
    );
  }
}
