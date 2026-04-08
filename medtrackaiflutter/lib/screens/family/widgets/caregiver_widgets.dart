import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/color_utils.dart';
import '../../../widgets/shared/shared_widgets.dart';

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
        padding: const EdgeInsets.all(AppSpacing.p20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.roundL,
          boxShadow: AppShadows.neumorphic,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with Subthe Glow
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isActive
                    ? LinearGradient(
                        colors: [
                          medColor.withValues(alpha: 0.8),
                          medColor.withValues(alpha: 0.1)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: isActive ? null : Border.all(color: L.border),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                            color: medColor.withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 0)
                      ]
                    : null,
              ),
              child: Padding(
                padding: EdgeInsets.all(isActive ? 2.0 : 0.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: L.card,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: medColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        cg.avatar,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),

            // Name & Relation
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cg.name,
                        style: AppTypography.titleLarge.copyWith(
                          color: L.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            cg.relation.toUpperCase(),
                            style: AppTypography.labelSmall.copyWith(
                              color: L.sub.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 1.0,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: L.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: L.success.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inventory_2_rounded,
                                      size: 8, color: L.success),
                                  const SizedBox(width: 4),
                                  Text('REFILL COORDINATOR',
                                      style: AppTypography.labelSmall.copyWith(
                                          fontSize: 10,
                                          color: L.success,
                                          fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: L.fill.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: L.text),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Latest Activity Snippet (Cal AI Ticker)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: L.fill.withValues(alpha: 0.4),
                borderRadius: AppRadius.roundXS,
              ),
              child: Row(
                children: [
                  Icon(Icons.radar_rounded,
                      size: 12, color: isActive ? L.success : L.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Latest Activity: ${isActive ? 'Active Monitoring • Stable' : 'Invite Sent • Waiting'}',
                      style: AppTypography.labelSmall.copyWith(
                        color: L.text.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Industrial Status Bar
            Container(
              height: 2,
              width: double.infinity,
              decoration: BoxDecoration(
                color: L.border.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(1),
              ),
              child: Row(
                children: [
                  Container(
                    width: isActive ? 100 : 40,
                    height: 2,
                    decoration: BoxDecoration(
                      color: isActive ? L.success : L.warning,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
      padding: const EdgeInsets.all(AppSpacing.p16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.roundM,
        boxShadow: AppShadows.neumorphic,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 14),
          Text(value.toString(),
              style: AppTypography.displayLarge.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: L.text,
                height: 1.0,
              )),
          const SizedBox(height: 2),
          Text(label.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                  color: L.sub,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3)),
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
        duration: 250.ms,
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? L.text : Colors.transparent,
          borderRadius: AppRadius.roundS,
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? L.bg : L.sub,
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(label,
                style: AppTypography.labelLarge.copyWith(
                    fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      );
}
