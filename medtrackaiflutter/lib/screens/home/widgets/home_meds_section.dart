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
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: L.text,
              letterSpacing: -0.3)),
      GestureDetector(
        onTap: onAdd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(99)),
          child: const Row(children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text('Add',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ]),
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
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.only(top: 20),
      decoration:
          BoxDecoration(color: L.card, borderRadius: BorderRadius.circular(20)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💊', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text('No medicines yet',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: L.text)),
            const SizedBox(height: 8),
            Text('Scan a medicine label or add manually to get started',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: L.sub,
                    height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(14)),
                child: const Text('📷 Scan Medicine',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
