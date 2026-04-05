import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../domain/entities/medicine.dart';
import '../../../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../core/utils/refill_helper.dart';
import '../../../widgets/shared/shared_widgets.dart';

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
    final showGeneric = context
        .select<AppState, bool>((s) => s.profile?.showGenericNames ?? false);
    final displayName = (showGeneric && widget.med.genericName.isNotEmpty)
        ? widget.med.genericName
        : widget.med.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: BouncingButton(
        onTap: widget.onView,
        scaleFactor: 0.98,
        child: SquircleCard(
          padding: EdgeInsets.zero,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Section: Brand & Adherence
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Squircle Med Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: L.fill,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: L.border.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: Text(
                        _getCategoryEmoji(widget.med.category),
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
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
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              widget.med.dose.toUpperCase(),
                              style: AppTypography.labelSmall.copyWith(
                                color: L.sub,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                fontSize: 9,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: L.border,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              widget.med.form.toUpperCase(),
                              style: AppTypography.labelSmall.copyWith(
                                color: L.sub.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Adherence "Pill" (High Fidelity)
                  if (adh != -1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: L.text.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: L.border.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '$adh% ADH',
                        style: AppTypography.labelSmall.copyWith(
                          color: L.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 8,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Technical Segmented Inventory Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SegmentedStockBar(pct: pct, isLow: isLow, L: L),
            ),
            
            const SizedBox(height: 16),

            // ── Bottom Action Strip
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              decoration: BoxDecoration(
                color: L.fill.withValues(alpha: 0.3),
                border: Border(top: BorderSide(color: L.border.withValues(alpha: 0.3))),
              ),
              child: Row(
                children: [
                  Icon(
                    isLow ? Icons.error_outline_rounded : Icons.inventory_2_outlined,
                    size: 14,
                    color: isLow ? L.error : L.sub.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.med.count} UNITS_STABLE',
                    style: AppTypography.labelSmall.copyWith(
                      color: isLow ? L.error : L.sub.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      fontSize: 8,
                    ),
                  ),
                  const Spacer(),
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
        .slideX(begin: 0.05, end: 0, curve: Curves.easeOutQuart)
        .scale(begin: const Offset(0.98, 0.98), curve: Curves.easeOutQuart),
    );
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
