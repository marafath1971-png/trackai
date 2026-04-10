import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/app_state.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/shared/shared_widgets.dart';

// ══════════════════════════════════════════════
// HOME HEADER — Cal AI 2026 Premium Style
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

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: L.meshBg.withValues(alpha: isScrolled ? 0.9 : 0.0),
        border: Border(
          bottom: BorderSide(
            color: L.border
                .withValues(alpha: (scrollOffset / 300).clamp(0.0, 0.05)),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Row(
          children: [
            // ── Logo + Brand ──
            GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  const Icon(Icons.apple, size: 28, color: Colors.black), // Using apple icon as placeholder/style reference
                  const SizedBox(width: 8),
                  Text(
                    'MedTrack AI',
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // ── Notification Bell ──
            GestureDetector(
              onTap: onOpenSettings, // Reusing settings callback for now
              child: Stack(
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 28, color: L.text),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981), // matching the notification dot color in image
                        shape: BoxShape.circle,
                        border: Border.all(color: L.bg, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
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
          final isToday =
              d.year == now.year && d.month == now.month && d.day == now.day;
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
                    color: isSelected
                        ? L.text
                        : (isToday
                            ? L.text.withValues(alpha: 0.1)
                            : Colors.transparent),
                    shape: BoxShape.circle,
                    border: !isSelected && isToday
                        ? Border.all(
                            color: L.text.withValues(alpha: 0.1), width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${d.day}',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 14,
                        color: isSelected
                            ? L.bg
                            : L.text.withValues(alpha: isFuture ? 0.3 : 0.8),
                        fontWeight:
                            isSelected ? FontWeight.w900 : FontWeight.w700,
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

class _StreakBadge extends StatelessWidget {
  final int streak;
  final VoidCallback onTap;
  const _StreakBadge({required this.streak, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final isHighStreak = streak >= 7;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isHighStreak
                ? [const Color(0xFFF59E0B), const Color(0xFFEF4444)]
                : [L.card, L.card],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighStreak
                ? Colors.white.withValues(alpha: 0.2)
                : L.border.withValues(alpha: 0.1),
            width: 0.5,
          ),
          boxShadow: isHighStreak
              ? [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isHighStreak ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isHighStreak
                    ? Icons.local_fire_department_rounded
                    : Icons.local_fire_department_outlined,
                size: 14,
                color:
                    isHighStreak ? Colors.white : L.text.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$streak',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w900,
                color: isHighStreak ? Colors.white : L.text,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'days',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: isHighStreak
                    ? Colors.white.withValues(alpha: 0.8)
                    : L.sub.withValues(alpha: 0.5),
                fontSize: 10,
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
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideX(begin: -0.05, end: 0, curve: Curves.easeOutCubic);
  }
}
