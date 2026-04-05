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
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isLow ? L.error : L.border, 
            width: 1.5,
          ), // Industrial border (Red if low)
          // No shadows for clean Cal AI look
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Section: Brand & Adherence
            Padding(
              padding: const EdgeInsets.all(AppSpacing.p20),
              child: Row(
                children: [
                  // Industrial Med Icon
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: L.text.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: L.border),
                        ),
                        child: Center(
                          child: Text(
                            _getCategoryEmoji(widget.med.category),
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -5,
                        right: -5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: L.text,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'REF',
                            style: AppTypography.labelSmall.copyWith(
                              color: L.bg,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
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
                          displayName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.displaySmall.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              widget.med.dose.toUpperCase(),
                              style: AppTypography.labelSmall.copyWith(
                                color: L.sub.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.p8),
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: L.sub.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              widget.med.form.toUpperCase(),
                              style: AppTypography.labelSmall.copyWith(
                                color: L.sub.withValues(alpha: 0.4),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Adherence "Pill" (Monochrome)
                  if (adh != -1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: L.text.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: L.border.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        '$adh% ADH',
                        style: AppTypography.labelSmall.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Technical Segmented Inventory Bar (Industrial)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SegmentedStockBar(pct: pct, isLow: isLow, L: L),
            ),
            
            const SizedBox(height: AppSpacing.p12),

            // ── Bottom Action Strip
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 8, bottom: 8),
              child: Row(
                children: [
                  Text(
                    '${widget.med.count} UNITS LEFT',
                    style: AppTypography.labelSmall.copyWith(
                      color: isLow ? L.error : L.sub.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  // Premium Inventory Controls (Industrial)
                   Row(
                    children: [
                      _StepBtn(
                        icon: Icons.remove_rounded,
                        onTap: () {
                          HapticEngine.selection();
                          context.read<AppState>().updateMed(widget.med.id,
                              count: (widget.med.count - 1).clamp(0, 999));
                        },
                      ),
                      const SizedBox(width: 8),
                      _StepBtn(
                        icon: Icons.add_rounded,
                        onTap: () {
                          HapticEngine.success();
                          context.read<AppState>().updateMed(widget.med.id,
                              count: (widget.med.count + 1).clamp(0, 999));
                        },
                      ),
                    ],
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
  const _StepBtn({
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return BouncingButton(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 40, // Slightly more rectangular for industrial look
        decoration: BoxDecoration(
          color: L.text.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: L.border, width: 1.5),
        ),
        child: Center(child: Icon(icon, size: 20, color: L.text)),
      ),
    );
  }
}

class _SegmentedStockBar extends StatelessWidget {
  final double pct;
  final bool isLow;
  final AppThemeColors L;
  const _SegmentedStockBar({required this.pct, required this.isLow, required this.L});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(24, (index) {
        final threshold = index / 24;
        final isActive = pct > threshold;
        return Expanded(
          child: Container(
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: isActive 
                  ? (isLow ? L.error : L.text) 
                  : L.border.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      }),
    );
  }
}
