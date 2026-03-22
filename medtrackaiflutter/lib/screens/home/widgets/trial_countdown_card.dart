import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_state.dart';
import 'package:provider/provider.dart';

class TrialCountdownCard extends StatelessWidget {
  const TrialCountdownCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final profile = state.profile;
    
    if (profile == null || !profile.isPremium) return const SizedBox.shrink();

    // Calculate trial remaining
    const trialDuration = Duration(days: 7);
    final elapsed = DateTime.now().difference(profile.createdAt);
    final remaining = trialDuration - elapsed;
    
    // Only show if trial is active (0 to 7 days)
    if (remaining.isNegative || elapsed.inDays >= 7) return const SizedBox.shrink();

    final daysLeft = remaining.inDays;
    final progress = (7 - daysLeft) / 7.0;
    final L = context.L;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: L.border, width: 1.5),
        boxShadow: L.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: L.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.timer_outlined, color: L.green, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pro Trial Active 💎",
                      style: TextStyle(
                        color: L.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      daysLeft == 0 
                          ? "Ends today! Don't lose access."
                          : "$daysLeft days remaining in your trial",
                      style: TextStyle(
                        color: L.sub,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => state.purchasePremium('pro_monthly'), // Re-trigger purchase to keep it
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: L.text,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Keep Pro",
                    style: TextStyle(
                      color: L.bg,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: L.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              AnimatedContainer(
                duration: 800.ms,
                height: 6,
                width: (MediaQuery.of(context).size.width - 80) * (1 - progress),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [L.green, L.green.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: L.green.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
