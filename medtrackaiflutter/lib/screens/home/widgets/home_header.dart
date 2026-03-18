import 'package:flutter/material.dart';
import '../../../../widgets/common/unified_header.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../../../../core/utils/haptic_engine.dart';

class HomeHeader extends StatelessWidget {
  final AppState state;
  final int streak;
  final bool isScrolled;
  final VoidCallback onOpenStreak;
  final VoidCallback onOpenSettings;
  final VoidCallback? onTap;

  const HomeHeader({
    super.key,
    required this.state,
    required this.streak,
    this.isScrolled = false,
    required this.onOpenStreak,
    required this.onOpenSettings,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final name = state.profile?.name ?? "Hero";

    return UnifiedHeader(
      showBrand: true,
      isScrolled: isScrolled,
      onTap: onTap,
      title: name,
      subtitle: _getSubGreeting(),
      actions: [
        _StreakBtn(streak: streak, onTap: onOpenStreak),
        HeaderActionBtn(
          onTap: onOpenSettings,
          child: Icon(Icons.settings_rounded, color: L.text, size: 18),
        ),
      ],
      bottom: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildWeekStrip(context, L),
      ),
    );
  }


  String _getSubGreeting() {
    try {
      final hour = DateTime.now().hour;
      String timeGreeting;
      if (hour < 12) {
        timeGreeting = "Good Morning";
      } else if (hour < 17) {
        timeGreeting = "Good Afternoon";
      } else {
        timeGreeting = "Good Evening";
      }

      final doses = state.getDoses();
      final taken = doses.where((d) => state.takenToday[d.key] == true).length;
      final remaining = doses.length - taken;

      if (doses.isEmpty) return "$timeGreeting! Ready to start your health journey?";
      
      if (remaining == 0) {
        return "All doses taken today. You're a rockstar! 🌟";
      }
      
      if (taken == 0) {
        return "$timeGreeting. $remaining doses scheduled for today.";
      }

      return "Great progress! Just $remaining more to go today.";
    } catch (e) {
      return "Welcome back to your health dashboard.";
    }
  }

  Widget _buildWeekStrip(BuildContext context, AppThemeColors L) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final d = DateTime.now().subtract(Duration(days: 6 - i));
        final k = d.toIso8601String().substring(0, 10);
        final isT = k == todayStr();
        final ds = state.history[k] ?? [];
        final rate =
            ds.isEmpty ? 0.0 : ds.where((x) => x.taken).length / ds.length;
        final isFuture = d.isAfter(DateTime.now());
        final dayLabel = ['S', 'M', 'T', 'W', 'T', 'F', 'S'][d.weekday % 7];
        final dayNum = d.day;

        Color dotColor;
        Color textColor;
        Color borderColor;

        if (isT) {
          dotColor = L.primary;
          textColor = L.onPrimary;
          borderColor = L.primary;
        } else if (isFuture) {
          dotColor = Colors.transparent;
          textColor = L.sub.withValues(alpha: 0.4);
          borderColor = L.border.withValues(alpha: 0.3);
        } else if (rate >= 0.8) {
          dotColor = L.secondary.withValues(alpha: 0.15);
          textColor = L.secondary;
          borderColor = L.secondary.withValues(alpha: 0.5);
        } else if (rate > 0 && rate < 0.8) {
          dotColor = L.warning.withValues(alpha: 0.1);
          textColor = L.warning;
          borderColor = L.warning.withValues(alpha: 0.4);
        } else if (!isFuture && ds.isEmpty) {
          dotColor = Colors.transparent;
          textColor = L.sub;
          borderColor = L.border;
        } else {
          dotColor = L.error.withValues(alpha: 0.1);
          textColor = L.error;
          borderColor = L.error.withValues(alpha: 0.3);
        }

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(dayLabel,
                  style: AppTypography.labelLarge.copyWith(
                      fontSize: 11,
                      color: isT ? L.text : L.sub.withValues(alpha: 0.7))),
              const SizedBox(height: 5),
              AnimatedContainer(
                duration: 400.ms,
                curve: Curves.easeOutBack,
                width: 32,
                height: 32,
                  child: Stack(
                    children: [
                      if (isT)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: L.primary,
                            ),
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isT ? Colors.transparent : dotColor,
                          border: Border.all(
                              color: isT ? Colors.white.withValues(alpha: 0.1) : borderColor, 
                              width: 1.0),
                        ),
                        child: Center(
                          child: Text('$dayNum',
                              style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 12,
                                  fontWeight: isT ? FontWeight.w800 : FontWeight.w600,
                                  color: textColor)),
                        ),
                      ),
                    ],
                  ),
              ),
              const SizedBox(height: 4),
              if (!isFuture && !isT && rate > 0)
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rate >= 0.8 ? L.secondary : (rate >= 0.5 ? L.warning : L.error),
                  ),
                )
              else
                const SizedBox(height: 4),
            ],
          ),
        );
      }),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }
}

class _StreakBtn extends StatelessWidget {
  final int streak;
  final VoidCallback onTap;
  const _StreakBtn({required this.streak, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTap: () {
        HapticEngine.selection();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: streak > 0 
                  ? L.warning.withValues(alpha: 0.1) 
                  : L.text.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: streak > 0 
                    ? L.warning.withValues(alpha: 0.3) 
                    : L.border.withValues(alpha: 0.1),
                width: 1.0,
              ),
            ),
            child: Row(children: [
              Text(streak > 0 ? '🔥' : '❄️',
                  style: const TextStyle(fontSize: 14, height: 1.0)),
              const SizedBox(width: 6),
              Text('$streak',
                  style: AppTypography.titleLarge.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: streak > 0 ? L.warning : L.sub,
                      letterSpacing: -0.3)),
            ]),
          ),
        ),
      ),
    );
  }
}
