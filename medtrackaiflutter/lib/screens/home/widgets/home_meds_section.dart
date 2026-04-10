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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        'Recently uploaded',
        style: AppTypography.titleLarge.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: L.text,
          letterSpacing: -0.5,
        ),
      ),
    );
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
