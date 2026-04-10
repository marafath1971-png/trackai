import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/app_state.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/shared/shared_widgets.dart';

// ══════════════════════════════════════════════
// HOME HEADER — Cal AI style (2026 Neumorphic)
// ══════════════════════════════════════════════
class HomeHeader extends StatelessWidget {
  final AppState state;
  final int streak;
  final double scrollOffset;
  final VoidCallback onOpenStreak;
  final VoidCallback onOpenSettings;
  final VoidCallback? onTap;

  const HomeHeader({
    super.key,
    required this.state,
    required this.streak,
    this.scrollOffset = 0,
    required this.onOpenStreak,
    required this.onOpenSettings,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final isScrolled = scrollOffset > 20;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: (scrollOffset / 6).clamp(0, 15),
          sigmaY: (scrollOffset / 6).clamp(0, 15),
        ),
        child: AnimatedContainer(
          duration: 400.ms,
          curve: Curves.easeOutQuart,
          decoration: BoxDecoration(
            color: L.meshBg.withValues(alpha: (isScrolled ? 0.95 : 0.0)),
            border: Border(
              bottom: BorderSide(
                color: L.text.withValues(alpha: (scrollOffset / 400).clamp(0, 0.08)),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: onTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('', 
                          style: TextStyle(
                            fontSize: 24, 
                            color: L.text,
                            fontWeight: FontWeight.w400,
                          )),
                        const SizedBox(width: 6),
                        Text(
                          'Med AI',
                          style: AppTypography.titleLarge.copyWith(
                            color: L.text,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: -1.2,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0),
                  const Spacer(),
                  _ActionIconBtn(
                    icon: Icons.notifications_none_rounded, 
                    onTap: () {}, 
                    L: L,
                  ),
                  const SizedBox(width: 12),
                  _StreakBtn(streak: streak, onTap: onOpenStreak),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeWeekStrip extends StatelessWidget {
  final AppState state;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const HomeWeekStrip({
    super.key,
    required this.state,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    const dayLabels = ['W', 'T', 'F', 'S', 'S', 'M', 'T'];
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 3)); 

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final d = weekStart.add(Duration(days: i));
          final isSelected = d.year == selectedDate.year &&
              d.month == selectedDate.month &&
              d.day == selectedDate.day;
          final isToday = d.year == now.year &&
              d.month == now.month &&
              d.day == now.day;
          final isFuture = d.isAfter(now);

          return GestureDetector(
            onTap: () => onDateSelected(d),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayLabels[i],
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 11,
                    color: L.sub.withValues(alpha: 0.4),
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedContainer(
                  duration: 300.ms,
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected ? L.text : (isToday ? L.text.withValues(alpha: 0.1) : Colors.transparent),
                    shape: BoxShape.circle,
                    border: !isSelected && isToday
                      ? Border.all(color: L.text.withValues(alpha: 0.1), width: 1.5)
                      : null,
                  ),
                  child: Center(
                    child: Text(
                      '${d.day}',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 14,
                        color: isSelected ? L.bg : L.text.withValues(alpha: isFuture ? 0.3 : 0.8),
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ).animate(delay: (i * 40).ms).fadeIn().slideY(begin: 0.1, end: 0),
          );
        }),
      ),
    );
  }
}

class _StreakBtn extends StatelessWidget {
  final int streak;
  final VoidCallback onTap;
  const _StreakBtn({required this.streak, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return BouncingButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: L.text.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: L.text.withValues(alpha: 0.08), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 14, color: L.text.withValues(alpha: 0.8)),
            const SizedBox(width: 6),
            Text(
              '$streak',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w900,
                color: L.text,
                fontSize: 14,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final AppThemeColors L;
  const _ActionIconBtn(
      {required this.icon, required this.onTap, required this.L});

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: L.text.withValues(alpha: 0.04),
          shape: BoxShape.circle,
          border: Border.all(color: L.text.withValues(alpha: 0.05), width: 1),
        ),
        child: Center(
          child: Icon(icon, size: 20, color: L.text.withValues(alpha: 0.8)),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// ANIMATED GREETING — time-of-day sub-line
// ──────────────────────────────────────────────
class _AnimatedGreeting extends StatelessWidget {
  final AppState state;
  const _AnimatedGreeting({required this.state});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? '🌅 Good morning'
        : hour < 17
            ? '☀️ Good afternoon'
            : hour < 21
                ? '🌆 Good evening'
                : '🌙 Good night';
    final activeName = state.activeProfile?.name ?? state.profile?.name ?? '';
    final firstName = activeName.split(' ').first;
    final label =
        firstName.isNotEmpty ? '$greeting, $firstName!' : '$greeting!';

    return Text(
      label,
      style: AppTypography.labelSmall.copyWith(
        color: L.sub.withValues(alpha: 0.65),
        fontWeight: FontWeight.w800,
        fontSize: 13,
        letterSpacing: -0.2,
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideX(begin: -0.05, end: 0, curve: Curves.easeOutCubic);
  }
}
