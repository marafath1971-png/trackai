import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/app_state.dart';
import '../../../../theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/shared/shared_widgets.dart';

// ══════════════════════════════════════════════
// HOME HEADER — "My Health" dashboard style
// ══════════════════════════════════════════════
class HomeHeader extends StatefulWidget {
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
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final L = context.L;
    final name = widget.state.profile?.name ?? s.greetingHero;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: (widget.scrollOffset / 5).clamp(0, 20),
          sigmaY: (widget.scrollOffset / 5).clamp(0, 20),
        ),
        child: AnimatedContainer(
          duration: 300.ms,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: L.bg.withValues(alpha: (widget.scrollOffset / 50).clamp(0, 0.7)),
            border: Border(
              bottom: BorderSide(
                color: L.border.withValues(alpha: (widget.scrollOffset / 100).clamp(0, 0.1)),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Top Bar: Title & Identity ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p24, vertical: AppSpacing.p12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'My Health',
                                style: AppTypography.displaySmall.copyWith(
                                  color: L.text,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 28,
                                  height: 1.1,
                                ),
                              ),
                            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0, curve: Curves.easeOutBack),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _getGreeting(name).toUpperCase(),
                                style: AppTypography.labelSmall.copyWith(
                                  color: L.sub.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  fontSize: 10,
                                ),
                              ),
                            ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                          ],
                        ),
                      ),
                      // Actions with Haptics
                      Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _StreakBtn(
                              streak: widget.streak,
                              onTap: widget.onOpenStreak,
                            ),
                            const SizedBox(width: AppSpacing.p12),
                            _IconBtn(
                              icon: Icons.dashboard_customize_outlined,
                              onTap: widget.onOpenSettings,
                              L: L,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Week Timeline ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.p20, 0, AppSpacing.p20, AppSpacing.p12),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.p8),
                    decoration: BoxDecoration(
                      color: L.fill.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: L.border.withValues(alpha: 0.05), width: 1.5),
                      boxShadow: L.shadowSoft,
                    ),
                    child: _buildWeekStrip(context, L),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getGreeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning, $name';
    if (hour < 17) return 'Afternoon, $name';
    return 'Evening, $name';
  }


  Widget _buildWeekStrip(BuildContext context, AppThemeColors L) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final d = DateTime.now().subtract(Duration(days: 6 - i));
        final k = d.toIso8601String().substring(0, 10);
        final isT = k == todayStr();
        final ds = widget.state.history[k] ?? [];
        final rate = ds.isEmpty ? 0.0 : ds.where((x) => x.taken).length / ds.length;
        final isFuture = d.isAfter(DateTime.now());
        final dayLabel = ['S', 'M', 'T', 'W', 'T', 'F', 'S'][d.weekday % 7];
        final dayNum = d.day;

        Color highlightColor;
        if (isT) {
          highlightColor = L.primary;
        } else if (isFuture) {
          highlightColor = L.border.withValues(alpha: 0.2);
        } else if (rate >= 0.8) {
          highlightColor = L.success;
        } else if (rate > 0) {
          highlightColor = L.warning;
        } else {
          highlightColor = L.error;
        }

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dayLabel,
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 10,
                  color: isT ? L.text : L.sub.withValues(alpha: 0.5),
                  fontWeight: isT ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: 400.ms,
                curve: Curves.easeOutBack,
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isT ? L.primary : highlightColor.withValues(alpha: 0.1),
                  border: Border.all(
                    color: isT ? Colors.transparent : highlightColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: isT ? AppShadows.glow(L.primary, intensity: 0.2) : null,
                ),
                child: Center(
                  child: Text(
                    '$dayNum',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isT ? L.onPrimary : highlightColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.1, end: 0),
        );
      }),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: hasStreak ? L.text : L.fill.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.max),
          border: Border.all(
            color: hasStreak ? L.text : L.border.withValues(alpha: 0.1),
            width: 1.2,
          ),
          boxShadow: hasStreak ? [
            BoxShadow(
              color: L.text.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Clinical Progress Dot (Cal AI Style)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: hasStreak ? L.bg : L.text.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                boxShadow: hasStreak ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ] : null,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                duration: 2.seconds,
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                curve: Curves.easeInOut,
              ),
            const SizedBox(width: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$streak',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  color: hasStreak ? L.bg : L.text,
                  fontSize: 14,
                  letterSpacing: -0.5,
                ),
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
          color: L.fill.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          border: Border.all(color: L.border.withValues(alpha: 0.05), width: 1.5),
          boxShadow: AppShadows.subtle,
        ),
        child: Center(child: Icon(icon, size: 20, color: L.text)),
      ),
    );
  }
}
