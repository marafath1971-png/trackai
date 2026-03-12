import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../widgets/shared/shared_widgets.dart';
import 'package:provider/provider.dart';

class DoseCard extends StatefulWidget {
  final DoseItem dose;
  final bool taken;
  final bool overdue;
  final bool isNext;
  final AppThemeColors L;
  final VoidCallback onTap;

  const DoseCard(
      {super.key,
      required this.dose,
      required this.taken,
      required this.overdue,
      this.isNext = false,
      required this.L,
      required this.onTap});

  @override
  State<DoseCard> createState() => _DoseCardState();
}

class _DoseCardState extends State<DoseCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final medColor = hexToColor(widget.dose.med.color);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity:
                (value.isNaN || value.isInfinite) ? 0.0 : value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.taken
            ? null
            : () {
                HapticFeedback.lightImpact();
                widget.onTap();
              },
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: widget.taken
                  ? widget.L.card.withValues(alpha: 0.5)
                  : (widget.overdue
                      ? widget.L.red.withValues(alpha: 0.08)
                      : widget.L.card),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isNext
                    ? widget.L.blue.withValues(alpha: 0.8)
                    : widget.taken
                        ? widget.L.green.withValues(alpha: 0.4)
                        : (widget.overdue
                            ? widget.L.red.withValues(alpha: 0.6)
                            : widget.L.border),
                width:
                    widget.taken || widget.overdue || widget.isNext ? 1.5 : 0.5,
              ),
              boxShadow: widget.taken
                  ? []
                  : [
                      BoxShadow(
                          color: widget.isNext
                              ? widget.L.blue.withValues(alpha: 0.15)
                              : (widget.overdue
                                  ? widget.L.red.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.04)),
                          blurRadius: widget.isNext ? 12 : 4,
                          offset: const Offset(0, 1))
                    ],
            ),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(fmtTime(widget.dose.sched.h, widget.dose.sched.m),
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: widget.taken
                            ? widget.L.sub
                            : (widget.overdue ? widget.L.red : widget.L.text),
                        letterSpacing: -0.3)),
                Row(children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: medColor, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(widget.dose.sched.label,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: widget.L.sub)),
                ]),
              ]),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(widget.dose.med.name,
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: widget.taken
                                      ? widget.L.sub
                                      : widget.L.text,
                                  decoration: widget.taken
                                      ? TextDecoration.lineThrough
                                      : null),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                            '${widget.dose.med.dose}',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: widget.L.sub),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(width: 8),
                        // Stock badge inside the dose card
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: widget.L.fill,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                               const Text('💊',
                                  style: TextStyle(fontSize: 8)),
                              const SizedBox(width: 2),
                              Text(
                                '${widget.dose.med.count} left',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: widget.dose.med.count <=
                                            widget.dose.med.refillAt
                                        ? widget.L.red
                                        : widget.L.sub),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ])),
              if (widget.taken)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.elasticOut,
                      builder: (context, val, child) => Transform.scale(
                        scale: val,
                        child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                color: widget.L.greenLight,
                                shape: BoxShape.circle),
                            child: Icon(Icons.check_rounded,
                                color: widget.L.green, size: 16)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Taken',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: widget.L.green),
                    ),
                  ],
                )
              else if (widget.overdue)
                _StatusBadge(dose: widget.dose, L: widget.L)
              else if (widget.isNext)
                AppBadge(
                    text: 'Up Next',
                    bg: widget.L.blue.withValues(alpha: 0.1),
                    textColor: widget.L.blue)
              else
                const AppBadge(
                    text: 'Take',
                    bg: Color(0xFF111111),
                    textColor: Colors.white),
            ]),
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
    final state = context.watch<AppState>();
    final guidance = state.getDoseGuidance(dose);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBadge(text: 'Overdue', bg: L.redLight, textColor: L.red),
          if (guidance.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                guidance,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: L.red),
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
