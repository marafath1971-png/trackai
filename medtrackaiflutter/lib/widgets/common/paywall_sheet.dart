import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';

class PaywallSheet extends StatefulWidget {
  const PaywallSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PaywallSheet(),
    );
  }

  @override
  State<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<PaywallSheet> {
  int _selIdx = 1; // Monthly by default

  final plans = [
    {'id': 'monthly', 'title': 'Monthly', 'price': '\$9.99', 'period': '/ month', 'desc': 'Flexible, cancel anytime'},
    {'id': 'annual', 'title': 'Annual', 'price': '\$59.99', 'period': '/ year', 'desc': 'Best value, SAVE 50%'},
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final L = context.L;

    return Container(
      decoration: BoxDecoration(
        color: L.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: L.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            'MedAI Pro',
            style: AppTypography.displayLarge.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock all premium features',
            style: AppTypography.bodyMedium.copyWith(color: L.sub),
          ),
          const SizedBox(height: 32),

          // Benefits
          _buildBenefit('🤖 Unlimited AI Health Insights', L),
          _buildBenefit('👥 Family Sharing & Monitoring', L),
          _buildBenefit('❄️ Streak Freeze Protection', L),
          _buildBenefit('📦 Unlimited Medications', L),
          const SizedBox(height: 32),

          // Plans
          ...plans.asMap().entries.map((e) {
            final isSel = _selIdx == e.key;
            return GestureDetector(
              onTap: () {
                HapticEngine.light();
                setState(() => _selIdx = e.key);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSel ? L.primary.withValues(alpha: 0.1) : L.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSel ? L.primary : L.border,
                    width: isSel ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.value['title']!,
                              style: AppTypography.titleLarge.copyWith(fontSize: 16)),
                          Text(e.value['desc']!,
                              style: AppTypography.labelSmall.copyWith(color: L.sub)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(e.value['price']!,
                            style: AppTypography.displayLarge.copyWith(fontSize: 20, color: isSel ? L.primary : L.text)),
                        Text(e.value['period']!,
                            style: AppTypography.labelSmall.copyWith(fontSize: 10, color: L.sub)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // CTA
          GestureDetector(
            onTap: () async {
              HapticEngine.light();
              final success = await state.purchasePremium(plans[_selIdx]['id']!);
              if (success && context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: L.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: L.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: state.isPurchasing
                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                  : Text(
                      'Try Free & Subscribe →',
                      textAlign: TextAlign.center,
                      style: AppTypography.titleLarge.copyWith(fontSize: 16, color: L.onPrimary),
                    ),
            ),
          ),
          
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                'Not now, maybe later',
                style: AppTypography.labelSmall.copyWith(color: L.sub),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(String text, AppThemeColors L) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: L.primary, size: 20),
          const SizedBox(width: 12),
          Text(text, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
