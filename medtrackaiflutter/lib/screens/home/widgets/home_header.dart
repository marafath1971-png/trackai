import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/app_state.dart';
import '../../../../theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/shared/shared_widgets.dart';

// ══════════════════════════════════════════════
// HOME HEADER — Ultra-Minimal (Cal AI spirit)
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
    final s = AppLocalizations.of(context)!;
    final L = context.L;
    final name = state.profile?.name ?? s.greetingHero;
    final greeting = _greeting(name);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: (scrollOffset / 5).clamp(0, 20),
          sigmaY: (scrollOffset / 5).clamp(0, 20),
        ),
        child: AnimatedContainer(
          duration: 300.ms,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: L.bg.withValues(alpha: (scrollOffset / 50).clamp(0, 0.78)),
            border: Border(
              bottom: BorderSide(
                color: L.border.withValues(alpha: (scrollOffset / 100).clamp(0, 0.12)),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 20, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Greeting ──
                  Expanded(
                    child: GestureDetector(
                      onTap: onTap,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            greeting,
                            style: AppTypography.displaySmall.copyWith(
                              color: L.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideX(begin: -0.03, end: 0, curve: Curves.easeOutBack),
                          const SizedBox(height: 3),
                          Text(
                            _dateLabel(),
                            style: AppTypography.labelMedium.copyWith(
                              color: L.sub.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                              fontSize: 13,
                            ),
                          ).animate().fadeIn(duration: 600.ms, delay: 150.ms),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ── Streak pill ──
                  _StreakBtn(streak: streak, onTap: onOpenStreak),
                  const SizedBox(width: 10),
                  // ── Settings ──
                  _IconBtn(icon: Icons.tune_rounded, onTap: onOpenSettings, L: L),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _greeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, $name';
    if (hour < 17) return 'Good afternoon, $name';
    return 'Good evening, $name';
  }

  String _dateLabel() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

// ──────────────────────────────────────────────
// WEEK STRIP — now lives inline in the scroll feed
// ──────────────────────────────────────────────
class HomeWeekStrip extends StatelessWidget {
  final AppState state;

  const HomeWeekStrip({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: ShapeDecoration(
        color: L.fill.withValues(alpha: 0.07),
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: L.border.withValues(alpha: 0.06), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final d = DateTime.now().subtract(Duration(days: 6 - i));
          final k = d.toIso8601String().substring(0, 10);
          final isT = k == todayStr();
          final ds = state.history[k] ?? [];
          final rate = ds.isEmpty ? 0.0 : ds.where((x) => x.taken).length / ds.length;
          final isFuture = d.isAfter(DateTime.now());
          const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
          final dayLabel = dayLabels[d.weekday % 7];

          Color dotColor;
          if (isT) {
            dotColor = L.primary;
          } else if (isFuture) {
            dotColor = L.border.withValues(alpha: 0.2);
          } else if (rate >= 0.8) {
            dotColor = L.success;
          } else if (rate > 0) {
            dotColor = L.warning;
          } else {
            dotColor = L.error.withValues(alpha: 0.6);
          }

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayLabel,
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 11,
                    color: isT ? L.text : L.sub.withValues(alpha: 0.45),
                    fontWeight: isT ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 7),
                AnimatedContainer(
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isT ? L.primary : dotColor.withValues(alpha: 0.12),
                    border: Border.all(
                      color: isT ? Colors.transparent : dotColor.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: isT ? AppShadows.glow(L.primary, intensity: 0.18) : null,
                  ),
                  child: Center(
                    child: Text(
                      '${d.day}',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isT ? L.onPrimary : dotColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ).animate(delay: Duration(milliseconds: i * 35)).fadeIn().slideY(begin: 0.1, end: 0),
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
    final hasStreak = streak > 0;

    return BouncingButton(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 350.ms,
        padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
        decoration: BoxDecoration(
          color: hasStreak ? L.text : L.fill.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: hasStreak ? Colors.transparent : L.border.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: hasStreak
              ? [
                  BoxShadow(
                    color: L.text.withValues(alpha: 0.25),
                    blurRadius: 12,
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
                color: hasStreak ? Colors.white.withValues(alpha: 0.15) : L.fill.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_fire_department_rounded,
                size: 14,
                color: hasStreak ? L.bg : L.sub.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              hasStreak ? '$streak' : '0',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w900,
                color: hasStreak ? L.bg : L.sub.withValues(alpha: 0.5),
                fontSize: 14,
                letterSpacing: -0.5,
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
  final IconData icon;
  final VoidCallback onTap;
  final AppThemeColors L;
  const _IconBtn({required this.icon, required this.onTap, required this.L});

  @override
  Widget build(BuildContext context) {
    return BouncingButton(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: L.fill.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(color: L.border.withValues(alpha: 0.08), width: 1.5),
          boxShadow: AppShadows.subtle,
        ),
        child: Center(child: Icon(icon, size: 20, color: L.text.withValues(alpha: 0.8))),
      ),
    );
  }
}
