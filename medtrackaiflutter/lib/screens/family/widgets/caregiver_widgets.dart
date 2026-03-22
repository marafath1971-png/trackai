import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../providers/app_state.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/haptic_engine.dart';

class CaregiverCard extends StatefulWidget {
  final Caregiver cg;
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onDashboard;
  const CaregiverCard(
      {super.key,
      required this.cg,
      required this.state,
      required this.L,
      required this.onDashboard});
  @override
  State<CaregiverCard> createState() => _CaregiverCardState();
}

class _CaregiverCardState extends State<CaregiverCard> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final cg = widget.cg;
    final L = widget.L;
    final isActive = cg.status == 'active';
    final isPending = cg.status == 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      decoration: BoxDecoration(
          color: L.card,
          borderRadius: AppRadius.roundL,
          border: Border.all(
              color: isActive ? L.secondary.withValues(alpha: 0.3) : L.border,
              width: 1.0),
          boxShadow: L.shadowSoft),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.l),
        child: Column(children: [
          GestureDetector(
            onTap: () {
              HapticEngine.light();
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                        color: hexToColor(cg.color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: hexToColor(cg.color).withValues(alpha: 0.3),
                            width: 1.0)),
                    child: Center(
                        child: Text(cg.avatar,
                            style: const TextStyle(fontSize: 28))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          Flexible(
                              child: Text(cg.name,
                                  style: AppTypography.titleLarge.copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: L.text),
                                  overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: isActive
                                    ? L.secondary.withValues(alpha: 0.1)
                                    : isPending
                                        ? L.warning.withValues(alpha: 0.1)
                                        : L.fill,
                                borderRadius: BorderRadius.circular(AppRadius.m)),
                            child: Text(
                                isActive
                                    ? 'ACTIVE'
                                    : isPending
                                        ? 'AWAITING'
                                        : 'INACTIVE',
                                style: AppTypography.labelLarge.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isActive
                                        ? L.secondary
                                        : isPending
                                            ? L.warning
                                            : L.sub,
                                    letterSpacing: 0.5)),
                          ),
                        ]),
                        const SizedBox(height: 4),
                        Text(
                            '${cg.relation}${cg.contact.isNotEmpty ? " · ${cg.contact}" : ""}',
                            style: AppTypography.bodySmall.copyWith(
                                fontSize: 13,
                                color: L.sub,
                                fontWeight: FontWeight.w500)),
                      ])),
                  AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(Icons.chevron_right_rounded,
                          color: L.sub.withValues(alpha: 0.5), size: 24)),
                ])),
          ),
          if (_expanded) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(children: [
                if (isPending) ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    Container(
                      width: 70,
                      height: 70,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: L.border)),
                      child: QrImageView(data: cg.inviteUrl, size: 60),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('CODE',
                              style: AppTypography.labelLarge.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: L.sub,
                                  letterSpacing: 0.04)),
                          Text(cg.inviteCode,
                              style: AppTypography.displayLarge.copyWith(
                                  fontFamily: 'monospace',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: L.text,
                                  letterSpacing: 1.5)),
                          const SizedBox(height: 4),
                          Text('${cg.name} scans this to join',
                              style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: L.sub)),
                        ])),
                  ]),
                ],
                const SizedBox(height: 16),
                Row(children: [
                  if (isActive) ...[
                    Expanded(
                        child: CardBtn(
                            label: 'View Dashboard',
                            icon: Icons.bar_chart_rounded,
                            onTap: widget.onDashboard,
                            bg: L.fill,
                            textColor: L.text)),
                    const SizedBox(width: 8),
                  ] else ...[
                    Expanded(
                        child: CardBtn(
                            label: 'Resend Link',
                            icon: Icons.share_rounded,
                            onTap: () => Clipboard.setData(
                                ClipboardData(text: cg.inviteUrl)),
                            bg: L.bg,
                            textColor: L.sub)),
                    const SizedBox(width: 8),
                  ],
                  IconButtonJSX(
                      icon: Icons.delete_outline_rounded,
                      onTap: () => widget.state.removeCaregiver(cg.id),
                      bg: L.error.withValues(alpha: 0.1),
                      textColor: L.error),
                ]),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

class CardBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color bg, textColor;
  const CardBtn(
      {super.key,
      required this.label,
      required this.icon,
      required this.onTap,
      required this.bg,
      required this.textColor});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.m)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
            Text(label,
                style: AppTypography.labelLarge.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
          ]),
        ),
      );
}

class IconButtonJSX extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bg, textColor;
  const IconButtonJSX(
      {super.key,
      required this.icon,
      required this.onTap,
      required this.bg,
      required this.textColor});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.m)),
          child: Icon(icon, size: 18, color: textColor),
        ),
      );
}

class FamStatJSX extends StatelessWidget {
  final String emoji, label;
  final int value;
  final Color color;
  const FamStatJSX(
      {super.key,
      required this.emoji,
      required this.label,
      required this.value,
      required this.color});
  @override
  Widget build(BuildContext context) {
    // Note: We need AppThemeColors but here we can just use the provided color
    // or try to get L from context if available. 
    // For consistency with original code, let's use the context helper if possible.
    final L = context.L;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
          color: L.card,
          borderRadius: AppRadius.roundL,
          border: Border.all(color: L.border),
          boxShadow: L.shadowSoft),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 12),
          Text('$value',
              style: AppTypography.displayLarge.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -1.0,
                  height: 1.0)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label.toUpperCase(),
                style: AppTypography.labelLarge.copyWith(
                    fontSize: 10,
                    color: L.sub,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
          ),
        ]),
      ),
    );
  }
}

class PivotTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final AppThemeColors L;
  const PivotTab({super.key, required this.label, required this.active, required this.onTap, required this.L});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: active ? L.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.m),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              fontSize: 13,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active ? L.onPrimary : L.sub,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
      ),
    );
  }
}

class HeaderBtn extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final Color color, bg;
  const HeaderBtn(
      {super.key,
      required this.onTap,
      required this.label,
      required this.icon,
      required this.color,
      required this.bg});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24)),
          child: Row(children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: AppTypography.labelLarge.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ]),
        ),
      );
}
