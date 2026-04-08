import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/haptic_engine.dart';
import '../shared/shared_widgets.dart';
import '../common/app_loading_indicator.dart';

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
    {
      'id': 'monthly',
      'title': 'Monthly',
      'price': '\$9.99',
      'period': '/ month',
      'desc': 'Flexible, cancel anytime'
    },
    {
      'id': 'annual',
      'title': 'Annual',
      'price': '\$59.99',
      'period': '/ year',
      'desc': 'Best value, SAVE 50%'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final L = context.L;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, -10),
          )
        ],
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
            style: AppTypography.displayLarge.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock elite safety intelligence',
            style: AppTypography.bodyMedium.copyWith(
              color: L.sub,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          // Social Proof / Trust Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: L.success.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.neumorphic,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, color: L.success, size: 14),
                const SizedBox(width: 8),
                Text(
                  '10,000+ USERS PROTECTED',
                  style: AppTypography.labelSmall.copyWith(
                    color: L.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Benefits
          _buildBenefit('🤖 Unlimited AI Safety Profiling', L),
          _buildBenefit('👥 Family Monitoring & Caregiver Alerts', L),
          _buildBenefit('🛡️ Professional Interaction Checks', L),
          _buildBenefit('📦 Complete Inventory Management', L),
          const SizedBox(height: 32),

          // Plans
          ...plans.asMap().entries.map((e) {
            final isSel = _selIdx == e.key;
            return BouncingButton(
              onTap: () {
                HapticEngine.light();
                setState(() => _selIdx = e.key);
              },
              scaleFactor: 0.98,
              child: AnimatedContainer(
                duration: 300.ms,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppShadows.neumorphic,
                  border:
                      isSel ? Border.all(color: Colors.black, width: 2) : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.value['title']!,
                              style: AppTypography.titleLarge.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isSel ? Colors.black : L.text,
                              )),
                          const SizedBox(height: 2),
                          Text(e.value['desc']!,
                              style: AppTypography.labelSmall.copyWith(
                                color: L.sub,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(e.value['price']!,
                            style: AppTypography.displayLarge.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: isSel ? Colors.black : L.text)),
                        Text(e.value['period']!,
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 10,
                              color: L.sub,
                              fontWeight: FontWeight.w800,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // CTA
          BouncingButton(
            onTap: state.isPurchasing
                ? null
                : () async {
                    HapticEngine.light();
                    final success =
                        await state.purchasePremium(plans[_selIdx]['id']!);
                    if (success && context.mounted) {
                      Navigator.pop(context);
                    }
                  },
            scaleFactor: 0.95,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: state.isPurchasing
                  ? const Center(child: AppLoadingIndicator(size: 24))
                  : Text(
                      'START PRO MEMBERSHIP →',
                      textAlign: TextAlign.center,
                      style: AppTypography.titleLarge.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),
          Center(
            child: BouncingButton(
              onTap: () => Navigator.pop(context),
              scaleFactor: 0.98,
              child: Text(
                'NOT NOW, MAYBE LATER',
                style: AppTypography.labelSmall.copyWith(
                  color: L.sub.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
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
          Text(text,
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
