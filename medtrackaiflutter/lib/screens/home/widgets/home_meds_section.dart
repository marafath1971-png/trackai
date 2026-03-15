import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

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
    final L = context.L;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: L.border.withValues(alpha: 0.1), width: 1.0),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: L.text.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.medication_liquid_rounded, size: 48, color: L.text.withValues(alpha: 0.2)),
            ),
            const SizedBox(height: 24),
            Text('No medications yet',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: L.text,
                    letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text('Scan a label or add manually to start tracking your adherence',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: L.sub,
                    height: 1.4,
                    fontWeight: FontWeight.w400),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: L.text,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt_rounded, color: L.bg, size: 18),
                    const SizedBox(width: 10),
                    Text('SCAN MEDICINE',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: L.bg,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
