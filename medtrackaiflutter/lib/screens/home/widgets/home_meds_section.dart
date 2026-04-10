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
      Row(
        children: [
          Container(
            width: 4,
            height: 12,
            decoration: BoxDecoration(
              color: L.text,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text('ACTIVE_PRESCRIPTIONS',
              style: AppTypography.labelSmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: L.text.withValues(alpha: 0.8),
                  letterSpacing: 2.5)),
        ],
      ),
      BouncingButton(
        onTap: onAdd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: L.text,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: L.text.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: L.card, size: 14),
              const SizedBox(width: 6),
              Text('ADD_NEW',
                  style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      color: L.card,
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
      title: 'PRECISION_LOG_EMPTY',
      subtitle: 'Scan clinical labels or manually enter medications to begin precision tracking.',
      icon: Icons.medication_rounded,
      actionLabel: 'SCAN_NEW_MEDICINE',
      onAction: onAdd,
    );
  }
}
