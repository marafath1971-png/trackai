import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../widgets/common/unified_header.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/app_state.dart';
import '../../../../theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/common/bouncing_button.dart';

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
    final s = AppLocalizations.of(context)!;
    final L = context.L;
    final name = state.profile?.name ?? s.greetingHero;

    return UnifiedHeader(
      showBrand: false,
      leading: Image.asset(
        'assets/images/home_logo.png',
        width: 32,
        height: 32,
        fit: BoxFit.contain,
      ),
      isScrolled: isScrolled,
      onTap: onTap,
      titleWidget: Row(
        children: [
          Text(
            s.hiUser(name),
            style: AppTypography.headlineLarge.copyWith(
              color: L.text,
              letterSpacing: -1.2,
              fontWeight: FontWeight.w900,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.08, end: 0),
          if (state.profile?.isPremium ?? false) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: L.success,
                borderRadius: BorderRadius.circular(6),
                boxShadow: AppShadows.glow(L.success, intensity: 0.2),
              ),
              child: Text(
                'PRO',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            )
                .animate(delay: 500.ms)
                .scale(duration: 400.ms, curve: Curves.easeOutBack),
          ],
        ],
      ),
      subtitle: _getCompactStatus(s),
      actions: [
        _StreakBtn(streak: streak, onTap: onOpenStreak),
        HeaderActionBtn(
          onTap: onOpenSettings,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: L.fill.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: L.border.withValues(alpha: 0.1), width: 1),
            ),
            child: Icon(Icons.settings_rounded, color: L.text, size: 20),
          ),
        ),
      ],
      bottom: Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 4),
        child: _buildWeekStrip(context, L),
      ),
    );
  }

  String _getCompactStatus(AppLocalizations s) {
    final doses = state.getDoses();
    final takenToday = state.takenToday;
    final now = DateTime.now();
    final nowM = now.hour * 60 + now.minute;

    final upcoming = doses.where((d) {
      final schedM = d.sched.h * 60 + d.sched.m;
      return !(takenToday[d.key] ?? false) && schedM >= nowM;
    }).toList();

    upcoming.sort((a, b) =>
        (a.sched.h * 60 + a.sched.m).compareTo(b.sched.h * 60 + b.sched.m));

    if (doses.isEmpty) return s.startJourney;

    if (upcoming.isNotEmpty) {
      final next = upcoming.first;
      final diff = (next.sched.h * 60 + next.sched.m) - nowM;
      if (diff <= 60) {
        return 'Next dose: ${next.med.name} in $diff mins';
      }
      return 'Next dose at ${next.sched.label}';
    }

    final taken = doses.where((d) => takenToday[d.key] == true).length;
    final remaining = doses.length - taken;

    if (remaining == 0) return s.allDosesTaken;

    final isOverdue = doses.any((d) {
      final schedM = d.sched.h * 60 + d.sched.m;
      return !(takenToday[d.key] ?? false) && nowM > schedM + 5;
    });

    if (isOverdue) return s.dosesOverdue(remaining);
    return s.dosesLeft(remaining);
  }

  Widget _buildWeekStrip(BuildContext context, AppThemeColors L) {
    return SizedBox(
      height: 72,
      child: Row(
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
            textColor = L.sub.withValues(alpha: 0.3);
            borderColor = L.border.withValues(alpha: 0.1);
          } else if (rate >= 0.8) {
            dotColor = L.success.withValues(alpha: 0.15);
            textColor = L.success;
            borderColor = L.success.withValues(alpha: 0.3);
          } else if (rate > 0 && rate < 0.8) {
            dotColor = L.warning.withValues(alpha: 0.1);
            textColor = L.warning;
            borderColor = L.warning.withValues(alpha: 0.3);
          } else if (!isFuture && ds.isEmpty) {
            dotColor = Colors.transparent;
            textColor = L.sub.withValues(alpha: 0.4);
            borderColor = L.border.withValues(alpha: 0.3);
          } else {
            dotColor = L.error.withValues(alpha: 0.1);
            textColor = L.error;
            borderColor = L.error.withValues(alpha: 0.2);
          }

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(dayLabel,
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 10,
                      color: isT ? L.text : L.sub.withValues(alpha: 0.5),
                      fontWeight: isT ? FontWeight.w900 : FontWeight.w600,
                      letterSpacing: 0.5,
                    )),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: 350.ms,
                  curve: Curves.easeOutCubic,
                  width: 36,
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isT)
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: L.primary,
                            boxShadow:
                                AppShadows.glow(L.primary, intensity: 0.3),
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                              begin: const Offset(1, 1),
                              end: const Offset(1.1, 1.1),
                              duration: 1200.ms,
                              curve: Curves.easeInOut,
                            ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isT ? Colors.transparent : dotColor,
                          border: Border.all(
                            color: isT ? Colors.transparent : borderColor,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$dayNum',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight:
                                  isT ? FontWeight.w900 : FontWeight.w700,
                              color: textColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                if (!isFuture && !isT && rate > 0)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rate >= 0.8
                          ? L.success
                          : (rate >= 0.5 ? L.warning : L.error),
                      boxShadow: [
                        if (rate >= 0.8)
                          BoxShadow(
                              color: L.success.withValues(alpha: 0.5),
                              blurRadius: 4),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 5),
              ],
            ),
          )
              .animate(delay: Duration(milliseconds: 100 + i * 40))
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuart);
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
        duration: 400.ms,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: hasStreak
              ? AppGradients.warningAmber
              : LinearGradient(colors: [
                  L.fill.withValues(alpha: 0.1),
                  L.fill.withValues(alpha: 0.1)
                ]),
          borderRadius: BorderRadius.circular(AppRadius.max),
          border: Border.all(
            color: hasStreak
                ? Colors.white.withValues(alpha: 0.2)
                : L.border.withValues(alpha: 0.1),
            width: 1.0,
          ),
          boxShadow:
              hasStreak ? AppShadows.glow(L.warning, intensity: 0.2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasStreak ? '🔥' : '❄️',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 8),
            Text(
              '$streak',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w900,
                color: hasStreak ? Colors.white : L.sub,
                letterSpacing: -0.5,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: 150.ms)
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, end: 0);
  }
}
