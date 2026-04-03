import 'package:flutter/material.dart';
import '../../../providers/app_state.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/color_utils.dart';
import '../../../widgets/common/bouncing_button.dart';

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
  @override
  Widget build(BuildContext context) {
    final cg = widget.cg;
    final L = widget.L;
    final isActive = cg.status == 'active';
    final medColor = hexToColor(cg.color);
    return BouncingButton(
      onTap: widget.onDashboard,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: AppRadius.roundL,
          border: Border.all(color: L.border, width: 1.5),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: medColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: medColor.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child:
                        Text(cg.avatar, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                if (isActive)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: L.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: L.bg, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cg.name,
                      style: AppTypography.titleLarge.copyWith(
                          color: L.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(cg.relation,
                          style: AppTypography.bodySmall.copyWith(
                              color: L.sub, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? L.green.withValues(alpha: 0.1)
                              : L.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isActive ? 'ACTIVE' : 'PENDING',
                          style: AppTypography.labelLarge.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: isActive ? L.green : L.warning,
                              letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white24, size: 24),
          ],
        ),
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
  Widget build(BuildContext context) => BouncingButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(AppRadius.m)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
            Text(label,
                style: AppTypography.labelLarge
                    .copyWith(fontWeight: FontWeight.w600, color: textColor)),
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
  Widget build(BuildContext context) => BouncingButton(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(AppRadius.m)),
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
    final L = context.L;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: AppRadius.roundL,
        border: Border.all(color: L.border, width: 1.5),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 12),
          Text(value.toString(),
              style: AppTypography.displayLarge.copyWith(height: 1.0)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                    color: L.sub,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}

class PivotTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final AppThemeColors L;
  const PivotTab(
      {super.key,
      required this.label,
      required this.active,
      required this.onTap,
      required this.L});

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
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
  Widget build(BuildContext context) => BouncingButton(
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
                    fontSize: 15, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      );
}
