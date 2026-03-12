import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class SmartStepper extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String label;
  final bool isSmall;

  const SmartStepper({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 9999,
    required this.onChanged,
    this.label = '',
    this.isSmall = false,
  });

  @override
  State<SmartStepper> createState() => _SmartStepperState();
}

class _SmartStepperState extends State<SmartStepper>
    with SingleTickerProviderStateMixin {
  late int _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant SmartStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value;
    }
  }

  void _update(int delta) {
    int next = _currentValue + delta;
    if (next < widget.min) next = widget.min;
    if (next > widget.max) next = widget.max;

    if (next != _currentValue) {
      HapticFeedback.lightImpact();
      setState(() => _currentValue = next);
      widget.onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      decoration: BoxDecoration(
        color: L.bg,
        borderRadius: BorderRadius.circular(widget.isSmall ? 10 : 16),
        boxShadow: widget.isSmall
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                  spreadRadius: -1,
                )
              ],
        border: Border.all(
            color: L.border.withValues(alpha: widget.isSmall ? 0.2 : 0.5),
            width: widget.isSmall ? 1.0 : 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            onTap: () => _update(-1),
            color: widget.isSmall ? L.fill : L.text,
            isLeft: true,
            isSmall: widget.isSmall,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: widget.isSmall ? 8 : 16),
            constraints: BoxConstraints(minWidth: widget.isSmall ? 40 : 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_currentValue',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: widget.isSmall ? 14 : 20,
                    fontWeight: FontWeight.w800,
                    color: L.text,
                    letterSpacing: -0.5,
                  ),
                ),
                if (widget.label.isNotEmpty) ...[
                  SizedBox(width: widget.isSmall ? 2 : 4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: widget.isSmall ? 11 : 14,
                      fontWeight: FontWeight.w600,
                      color: L.sub,
                    ),
                  )
                ]
              ],
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            onTap: () => _update(1),
            color: widget.isSmall
                ? const Color(0xFF111111)
                : (L.bg == const Color(0xFF111111)
                    ? const Color(0xFFE5E7EB)
                    : const Color(0xFF0F172A)),
            isLeft: false,
            isSmall: widget.isSmall,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool isLeft;
  final bool isSmall;

  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.isLeft,
    required this.isSmall,
  });

  @override
  State<_StepperButton> createState() => _StepperButtonState();
}

class _StepperButtonState extends State<_StepperButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(widget.isSmall ? 6 : 12),
        decoration: BoxDecoration(
          color: widget.isSmall
              ? widget.color
              : (_isPressed
                  ? widget.color.withValues(alpha: 0.08)
                  : Colors.transparent),
          borderRadius: BorderRadius.horizontal(
            left: widget.isLeft
                ? Radius.circular(widget.isSmall ? 10 : 16)
                : Radius.zero,
            right: !widget.isLeft
                ? Radius.circular(widget.isSmall ? 10 : 16)
                : Radius.zero,
          ),
        ),
        child: Icon(
          widget.icon,
          size: widget.isSmall ? 14 : 20,
          color: widget.isSmall
              ? (widget.color == const Color(0xFF111111)
                  ? Colors.white
                  : context.L.text)
              : widget.color.withValues(alpha: _isPressed ? 0.6 : 0.8),
        ),
      ),
    );
  }
}
