import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/premium_empty_state.dart';
import '../../../widgets/shared/shared_widgets.dart';
class HomeMedsHeader extends StatelessWidget {
  final VoidCallback onAdd;
  const HomeMedsHeader({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('ACTIVE_PRESCRIPTIONS',
          style: AppTypography.labelSmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: L.sub,
              letterSpacing: 2.0)),
      BouncingButton(
        onTap: onAdd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: ShapeDecoration(
            color: L.text.withValues(alpha: 0.05),
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: L.border.withValues(alpha: 0.2)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: L.text, size: 14),
              const SizedBox(width: 4),
              Text('ADD',
                  style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      color: L.text,
                      letterSpacing: 1.0)),
            ],
          ),
        ),
      ),
    ]);
  }
}

class HomeMedsEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const HomeMedsEmptyState({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return PremiumEmptyState(
      title: 'No medications yet',
      subtitle: 'Scan a label or add manually to start tracking your adherence',
      icon: Icons.medication_liquid_rounded,
      actionLabel: 'SCAN MEDICINE',
      onAction: onAdd,
    );
  }
}
