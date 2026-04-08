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
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: (scrollOffset / 5).clamp(0, 20),
          sigmaY: (scrollOffset / 5).clamp(0, 20),
        ),
        child: AnimatedContainer(
          duration: 300.ms,
          curve: Curves.easeOutCubic,
          // Neumorphic: pure white header that fades in on scroll
          decoration: BoxDecoration(
            color: L.card.withValues(alpha: (0.5 + (scrollOffset / 100).clamp(0, 0.5))),
            border: Border(
              bottom: BorderSide(
                color: L.text.withValues(alpha: (scrollOffset / 200).clamp(0, 0.04)),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 18, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: onTap,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: L.text,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text('💊', style: TextStyle(fontSize: 18)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: onTap,
                              child: Text(
                                'MedAI',
                                style: AppTypography.titleLarge.copyWith(
                                  color: L.text,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms),
                      const Spacer(),
                      _StreakBtn(streak: streak, onTap: onOpenStreak),
                      const SizedBox(width: 8),
                      _IconBtn(icon: '⚙️', onTap: onOpenSettings, L: L),
                    ],
                  ),
                  const SizedBox(height: 3),
                  _AnimatedGreeting(state: state),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// WEEK STRIP — Cal AI numbered date style
// ──────────────────────────────────────────────
class HomeWeekStrip extends StatelessWidget {
  final AppState state;

  const HomeWeekStrip({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final d = weekStart.add(Duration(days: i));
          final k = d.toIso8601String().substring(0, 10);
          final isT = k == todayStr();
          final isFuture = d.isAfter(DateTime.now());
          final ds = state.history[k] ?? [];
          final rate = ds.isEmpty ? 0.0 : ds.where((x) => x.taken).length / ds.length;

          Color bgColor;
          Color textColor;
          if (isT) {
            bgColor = L.text;
            textColor = L.card;
          } else if (!isFuture && ds.isNotEmpty && rate >= 0.8) {
            bgColor = const Color(0xFFDCFCE7);
            textColor = const Color(0xFF166534);
          } else if (!isFuture && ds.isNotEmpty && rate > 0) {
            bgColor = const Color(0xFFFEF9C3);
            textColor = const Color(0xFF92400E);
          } else if (!isFuture && ds.isNotEmpty) {
            bgColor = const Color(0xFFFEE2E2);
            textColor = const Color(0xFF991B1B);
          } else {
            bgColor = Colors.transparent;
            textColor = L.sub.withValues(alpha: 0.25);
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dayLabels[i],
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 11,
                  color: isT ? L.text : L.sub.withValues(alpha: 0.35),
                  fontWeight: isT ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: 400.ms,
                curve: Curves.easeOutBack,
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: isT ? null : Border.all(
                    color: isFuture
                        ? L.border.withValues(alpha: 0.06)
                        : L.border.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
                  boxShadow: isT
                      ? [BoxShadow(color: L.text.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${d.day}',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 12,
                      color: isT ? L.card : textColor,
                      fontWeight: isT ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideY(begin: 0.15, end: 0);
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
    final hasStreak = streak > 0;

    return BouncingButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
        decoration: BoxDecoration(
          color: hasStreak ? const Color(0xFFFFF7ED) : L.fill.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: hasStreak ? const Color(0xFFFED7AA) : L.border.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasStreak ? '🔥' : '🧊',
              style: const TextStyle(fontSize: 15),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(
               begin: const Offset(1.0, 1.0),
               end: const Offset(1.22, 1.22),
               duration: 1500.ms,
               curve: Curves.easeInOut,
             ),
            const SizedBox(width: 5),
            Text(
              hasStreak ? '$streak' : '0',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: hasStreak ? const Color(0xFFC2410C) : L.sub.withValues(alpha: 0.5),
                fontSize: 14,
                letterSpacing: -0.3,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  final AppThemeColors L;
  const _IconBtn({required this.icon, required this.onTap, required this.L});

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: L.card,
          shape: BoxShape.circle,
          boxShadow: AppShadows.neumorphic,
        ),
        child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
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
    final greeting = hour < 12 ? '🌅 Good morning'
        : hour < 17 ? '☀️ Good afternoon'
        : hour < 21 ? '🌆 Good evening'
        : '🌙 Good night';
    final firstName = (state.profile?.name ?? '').split(' ').first;
    final label = firstName.isNotEmpty ? '$greeting, $firstName!' : '$greeting!';

    return Text(
      label,
      style: AppTypography.labelSmall.copyWith(
        color: L.sub.withValues(alpha: 0.55),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 150.ms);
  }
}
