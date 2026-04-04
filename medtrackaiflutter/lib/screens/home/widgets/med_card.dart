import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../domain/entities/medicine.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/color_utils.dart';
import '../../../widgets/common/bouncing_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../core/utils/refill_helper.dart';

class MedCard extends StatefulWidget {
  final Medicine med;
  final VoidCallback onView;
  final VoidCallback onEdit;

  const MedCard({
    super.key,
    required this.med,
    required this.onView,
    required this.onEdit,
  });

  @override
  State<MedCard> createState() => _MedCardState();
}

class _MedCardState extends State<MedCard> {


  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final adh = context
        .select<AppState, int>((s) => s.getAdherenceForMed(widget.med.id));
    final pct = widget.med.totalCount > 0
        ? (widget.med.count / widget.med.totalCount).clamp(0.0, 1.0)
        : 0.0;
    final isLow = RefillHelper.isCriticallyLow(widget.med);
    final medColor = hexToColor(widget.med.color);
    final showGeneric = context
        .select<AppState, bool>((s) => s.profile?.showGenericNames ?? false);
    final displayName = (showGeneric && widget.med.genericName.isNotEmpty)
        ? widget.med.genericName
        : widget.med.name;

    return BouncingButton(
      onTap: widget.onView,
      scaleFactor: 0.98,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.p20),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: L.border.withValues(alpha: 0.15), width: 1.0),
        ),

        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Section: Brand & Adherence
            Padding(
              padding: const EdgeInsets.all(AppSpacing.p16),
              child: Row(
                children: [
                  // Holographic-style Med Icon
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: medColor.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(AppRadius.l),
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: medColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            _getCategoryEmoji(widget.med.category),
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),

                      if (isLow)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: L.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: L.card, width: 2),
                            ),
                          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.2, 1.2),
                                duration: 800.ms,
                              ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.p16),
                  
                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headlineSmall.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              widget.med.dose,
                              style: AppTypography.labelSmall.copyWith(
                                color: L.sub,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.p8),
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: L.sub.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              widget.med.form.toUpperCase(),
                              style: AppTypography.labelSmall.copyWith(
                                color: L.sub.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Adherence "Pill"
                  if (adh != -1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (adh >= 80 ? L.success : L.warning).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.max),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            adh >= 80 ? Icons.trending_up_rounded : Icons.trending_flat_rounded,
                            size: 12,
                            color: adh >= 80 ? L.success : L.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$adh%',
                            style: AppTypography.labelMedium.copyWith(
                              color: adh >= 80 ? L.success : L.warning,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ── Middle Section: Inventory Status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.p12),
                decoration: BoxDecoration(
                  color: L.fill.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_rounded,
                              size: 12,
                              color: isLow ? L.error : L.sub,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isLow ? 'CRITICALLY LOW' : 'STOCK LEVEL',
                              style: AppTypography.labelSmall.copyWith(
                                color: isLow ? L.error : L.sub,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${widget.med.count} LEFT',
                          style: AppTypography.labelMedium.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.p8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.max),
                      child: Container(
                        height: 4,
                        width: double.infinity,
                        color: L.fill.withValues(alpha: 0.1),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: pct,
                          child: Container(
                            decoration: BoxDecoration(
                              color: medColor,
                              borderRadius: BorderRadius.circular(AppRadius.max),
                            ),
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.p12),

            // ── Bottom Action Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p8, vertical: AppSpacing.p8),
              decoration: BoxDecoration(
                color: L.text.withValues(alpha: 0.02),
                border: Border(top: BorderSide(color: L.border.withValues(alpha: 0.3))),
              ),
              child: Row(
                children: [
                  BouncingButton(
                    onTap: widget.onView,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p8),
                      child: Text(
                        'VIEW DETAILS',
                        style: AppTypography.labelSmall.copyWith(
                          color: L.sub.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),

                      ),
                    ),
                  ),
                  const Spacer(),
                  // Premium Inventory Controls
                  Container(
                    decoration: BoxDecoration(
                      color: L.fill.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.max),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _StepBtn(
                          icon: Icons.remove_rounded,
                          onTap: () {
                            HapticEngine.selection();
                            context.read<AppState>().updateMed(widget.med.id,
                                count: (widget.med.count - 1).clamp(0, 999));
                          },
                          color: L.text,
                          bg: L.card,
                        ),
                        const SizedBox(width: AppSpacing.p12),
                        Text(
                          '${widget.med.count}',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w900,
                            color: L.text,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.p12),
                        _StepBtn(
                          icon: Icons.add_rounded,
                          onTap: () {
                            HapticEngine.success();
                            context.read<AppState>().updateMed(widget.med.id,
                                count: (widget.med.count + 1).clamp(0, 999));
                          },
                          color: Colors.white,
                          bg: L.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuart);
  }


  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'tablet':
      case 'pill':
        return '💊';
      case 'liquid':
      case 'syrup':
        return '💧';
      case 'spray':
        return '💨';
      case 'injection':
        return '💉';
      default:
        return '💊';
    }
  }
}


// ─────────────────────────────────────────────────────────────
// STEP BUTTON (+ / -)
// ─────────────────────────────────────────────────────────────
class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color, bg;
  const _StepBtn(
      {required this.icon,
      required this.onTap,
      required this.color,
      required this.bg});
  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return BouncingButton(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: bg == L.primary 
              ? AppShadows.glow(L.primary, intensity: 0.1) 
              : AppShadows.subtle,
          border: Border.all(color: L.border.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Center(child: Icon(icon, size: 20, color: color)),
      ),
    );
  }
}
