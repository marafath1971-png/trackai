import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/premium_empty_state.dart';

class HomeMedsHeader extends StatelessWidget {
  final VoidCallback onAdd;
  const HomeMedsHeader({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('My Medicines',
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: L.text,
              letterSpacing: -0.5)),
      TextButton.icon(
        onPressed: onAdd,
        icon: Icon(Icons.add_rounded, color: L.bg, size: 16),
        label: Text('ADD', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: L.bg, letterSpacing: 0.5)),
        style: TextButton.styleFrom(
          backgroundColor: L.text,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
