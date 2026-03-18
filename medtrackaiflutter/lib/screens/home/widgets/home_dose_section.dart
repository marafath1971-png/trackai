import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/haptic_engine.dart';

class DoseCard extends StatefulWidget {
  final DoseItem dose;
  final bool taken;
  final bool overdue;
  final bool isNext;
  final AppThemeColors L;
  final VoidCallback onTake;
  final VoidCallback onSnooze;
  final VoidCallback onTap;

  const DoseCard(
      {super.key,
      required this.dose,
      required this.taken,
      required this.overdue,
      this.isNext = false,
      required this.L,
      required this.onTake,
      required this.onSnooze,
      required this.onTap});

  @override
  State<DoseCard> createState() => _DoseCardState();
}

class _DoseCardState extends State<DoseCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final medColor = hexToColor(widget.dose.med.color);

    return Dismissible(
      key: ValueKey('dose_${widget.dose.key}'),
      direction: widget.taken ? DismissDirection.none : DismissDirection.horizontal,
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          HapticEngine.doseTaken();
          widget.onTake();
        } else {
          HapticEngine.light();
          widget.onSnooze();
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticEngine.doseTaken();
          widget.onTake();
        } else {
          HapticEngine.light();
          widget.onSnooze();
        }
        return false; // Prevent removal from tree
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
            color: widget.L.text, borderRadius: BorderRadius.circular(24)),
        child: Icon(Icons.check_rounded, color: widget.L.bg, size: 24),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
            color: widget.L.sub.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24)),
        child: Icon(Icons.more_horiz_rounded, color: widget.L.text, size: 24),
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.taken
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap();
              },
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: widget.taken
                  ? widget.L.bg
                  : (widget.overdue
                      ? widget.L.text.withValues(alpha: 0.03)
                      : widget.L.card),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.isNext
                    ? widget.L.text.withValues(alpha: 0.4)
                    : widget.taken
                        ? widget.L.border.withValues(alpha: 0.05)
                        : widget.L.border.withValues(alpha: 0.1),
                width: 1.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(fmtTime(widget.dose.sched.h, widget.dose.sched.m, context),
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: widget.taken
                                ? widget.L.sub.withValues(alpha: 0.4)
                                : widget.L.text,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 1),
                    Row(children: [
                      Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                              color: medColor, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(widget.dose.sched.label,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: widget.L.sub)),
                    ]),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      Text(widget.dose.med.name,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: widget.taken
                                  ? widget.L.sub.withValues(alpha: 0.3)
                                  : widget.L.text,
                              decoration: widget.taken
                                  ? TextDecoration.lineThrough
                                  : null,
                              letterSpacing: -0.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 1),
                      Text(widget.dose.med.dose,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: widget.L.sub,
                              letterSpacing: 0.1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ])),
                if (widget.taken)
                  Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: widget.L.text.withValues(alpha: 0.05),
                          shape: BoxShape.circle),
                      child: Icon(Icons.check_rounded,
                          color: widget.L.text, size: 14))
                else if (widget.overdue)
                  _StatusBadge(dose: widget.dose, L: widget.L)
                else if (widget.isNext)
                  Text('NEXT',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: widget.L.text,
                          letterSpacing: 0.5))
                else
                  Text('TAKE',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: widget.L.sub.withValues(alpha: 0.4),
                          letterSpacing: 0.5)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DoseItem dose;
  final AppThemeColors L;
  const _StatusBadge({required this.dose, required this.L});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: L.text,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'LATE',
        style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: L.bg,
            letterSpacing: 0.5),
      ),
    );
  }
}

