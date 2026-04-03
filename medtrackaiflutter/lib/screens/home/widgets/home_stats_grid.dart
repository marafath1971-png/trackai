import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../../core/utils/haptic_engine.dart';

class HomeStatsGrid extends StatelessWidget {
  final AppState state;
  final List<DoseItem> doses;
  final int takenCount;
  final int remaining;
  final double dosePct;
  final Color ringCol;

  const HomeStatsGrid({
    super.key,
    required this.state,
    required this.doses,
    required this.takenCount,
    required this.remaining,
    required this.dosePct,
    required this.ringCol,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final adherence = (state.getAdherenceScore() * 100).round();
    final streak = state.getStreak();

    // Next upcoming dose
    final now = DateTime.now();
    final nowM = now.hour * 60 + now.minute;
    final takenToday = state.takenToday;
    final upcoming = doses.where((d) {
      final schedM = d.sched.h * 60 + d.sched.m;
      return !(takenToday[d.key] ?? false) && schedM >= nowM;
    }).toList()
      ..sort((a, b) =>
          (a.sched.h * 60 + a.sched.m).compareTo(b.sched.h * 60 + b.sched.m));

    final nextDose = upcoming.isNotEmpty ? upcoming.first : null;

    return Column(
      children: [
        // ── Row 1: Hero progress card + adherence card ──
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: _HeroProgressCard(
                  takenCount: takenCount,
                  total: doses.length,
                  dosePct: dosePct,
                  L: L,
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.12, end: 0, curve: Curves.easeOutQuart),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Expanded(
                      child: _AdherenceScoreCard(
                        adherence: adherence,
                        state: state,
                        L: L,
                      )
                          .animate(delay: 80.ms)
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: 0.12, end: 0, curve: Curves.easeOutQuart),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _StreakMiniCard(streak: streak, L: L)
                          .animate(delay: 160.ms)
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: 0.12, end: 0, curve: Curves.easeOutQuart),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Row 2: Next dose banner ──
        if (nextDose != null) ...[
          const SizedBox(height: 12),
          _NextDoseCard(dose: nextDose, nowM: nowM, L: L)
              .animate(delay: 240.ms)
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.12, end: 0, curve: Curves.easeOutQuart),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HERO PROGRESS CARD — large ring + dose count
// ─────────────────────────────────────────────────────────────
class _HeroProgressCard extends StatelessWidget {
  final int takenCount, total;
  final double dosePct;
  final AppThemeColors L;

  const _HeroProgressCard({
    required this.takenCount,
    required this.total,
    required this.dosePct,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    final allDone = dosePct == 1.0 && total > 0;
    final ringColor = allDone ? L.success : AppColors.primaryBlue;

    return _PressableCard(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(AppRadius.l),
          border: Border.all(color: L.border, width: 1.0),
          boxShadow: L.shadowSoft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: allDone ? L.success : AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "TODAY",
                  style: AppTypography.labelSmall.copyWith(
                    color: L.sub,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Animated ring — centrepiece
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: dosePct),
                duration: 1400.ms,
                curve: Curves.easeOutQuart,
                builder: (context, value, _) => _PremiumRing(
                  percent: value,
                  size: 100,
                  strokeWidth: 10.0,
                  color: ringColor,
                  bgColor: ringColor.withValues(alpha: 0.08),
                  label: '${(value * 100).round()}%',
                  sublabel: allDone ? '🌟' : null,
                  L: L,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Count row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$takenCount taken',
                      style: AppTypography.titleMedium.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      total == 0
                          ? 'No doses today'
                          : allDone
                              ? 'Perfect day!'
                              : '${total - takenCount} remaining',
                      style: AppTypography.labelSmall.copyWith(
                        color: allDone ? L.success : L.sub,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (allDone)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: L.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.max),
                      border: Border.all(
                          color: L.success.withValues(alpha: 0.25), width: 1),
                    ),
                    child: Text(
                      'All done!',
                      style: AppTypography.labelSmall.copyWith(
                        color: L.success,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ADHERENCE SCORE CARD
// ─────────────────────────────────────────────────────────────
class _AdherenceScoreCard extends StatelessWidget {
  final int adherence;
  final AppState state;
  final AppThemeColors L;

  const _AdherenceScoreCard({
    required this.adherence,
    required this.state,
    required this.L,
  });

  Color _color(int adh) {
    if (adh >= 85) return L.success;
    if (adh >= 65) return AppColors.primaryBlue;
    if (adh >= 40) return L.warning;
    return L.error;
  }

  String _label(int adh) {
    if (adh >= 85) return 'ELITE';
    if (adh >= 65) return 'GOOD';
    if (adh >= 40) return 'FAIR';
    return 'LOW';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(adherence);

    return _PressableCard(
      onTap: () {
        HapticEngine.selection();
        SharePlus.instance.share(
          ShareParams(
            text:
                "I'm staying on top of my health with MedAI! My adherence is $adherence% 📈 #MedAI",
            subject: "My Health Progress",
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(AppRadius.l),
          border: Border.all(color: L.border, width: 1.0),
          boxShadow: L.shadowSoft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _label(adherence),
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: adherence),
              duration: 1000.ms,
              curve: Curves.easeOutQuart,
              builder: (_, val, __) => Text(
                '$val%',
                style: AppTypography.headlineLarge.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  fontSize: 28,
                ),
              ),
            ),
            Text(
              '30-day score',
              style: AppTypography.labelSmall.copyWith(
                color: L.sub,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // Thin progress bar
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: adherence / 100.0),
              duration: 1000.ms,
              curve: Curves.easeOutQuart,
              builder: (_, val, __) => ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.max),
                child: Stack(
                  children: [
                    Container(
                      height: 4,
                      color: color.withValues(alpha: 0.12),
                    ),
                    FractionallySizedBox(
                      widthFactor: val.clamp(0.001, 1.0),
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(AppRadius.max),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STREAK MINI CARD
// ─────────────────────────────────────────────────────────────
class _StreakMiniCard extends StatelessWidget {
  final int streak;
  final AppThemeColors L;
  const _StreakMiniCard({required this.streak, required this.L});

  @override
  Widget build(BuildContext context) {
    final hasStreak = streak > 0;
    return _PressableCard(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasStreak
              ? L.warning.withValues(alpha: 0.08)
              : L.card,
          borderRadius: BorderRadius.circular(AppRadius.l),
          border: Border.all(
            color: hasStreak
                ? L.warning.withValues(alpha: 0.25)
                : L.border,
            width: 1.0,
          ),
          boxShadow: L.shadowSoft,
        ),
        child: Row(
          children: [
            Text(
              hasStreak ? '🔥' : '❄️',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  hasStreak ? '$streak day streak' : 'Start streak',
                  style: AppTypography.labelLarge.copyWith(
                    color: hasStreak ? L.warning : L.sub,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  hasStreak ? 'Keep going!' : 'Take a dose',
                  style: AppTypography.labelSmall.copyWith(
                    color: L.sub,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NEXT DOSE BANNER
// ─────────────────────────────────────────────────────────────
class _NextDoseCard extends StatelessWidget {
  final DoseItem dose;
  final int nowM;
  final AppThemeColors L;
  const _NextDoseCard(
      {required this.dose, required this.nowM, required this.L});

  @override
  Widget build(BuildContext context) {
    final schedMin = dose.sched.h * 60 + dose.sched.m;
    final diff = schedMin - nowM;
    final timeLabel = diff <= 60
        ? 'in $diff min'
        : 'at ${dose.sched.h}:${dose.sched.m.toString().padLeft(2, '0')}';

    return _PressableCard(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.l),
          border: Border.all(
              color: AppColors.primaryBlue.withValues(alpha: 0.18), width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.medication_rounded,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next: ${dose.med.name}',
                    style: AppTypography.titleMedium.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${dose.med.dose} · $timeLabel',
                    style: AppTypography.bodySmall.copyWith(
                      color: L.sub,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(AppRadius.max),
              ),
              child: Text(
                timeLabel,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PREMIUM RING — custom painter, clean + bold
// ─────────────────────────────────────────────────────────────
class _PremiumRing extends StatelessWidget {
  final double percent;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color bgColor;
  final String label;
  final String? sublabel;
  final AppThemeColors L;

  const _PremiumRing({
    required this.percent,
    required this.size,
    required this.strokeWidth,
    required this.color,
    required this.bgColor,
    required this.label,
    this.sublabel,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              percent: percent,
              color: color,
              bgColor: bgColor,
              strokeWidth: strokeWidth,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sublabel != null)
                Text(sublabel!, style: const TextStyle(fontSize: 16)),
              Text(
                label,
                style: AppTypography.titleMedium.copyWith(
                  color: L.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color bgColor;
  final double strokeWidth;

  _RingPainter({
    required this.percent,
    required this.color,
    required this.bgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;

    // Background track
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = bgColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (percent > 0) {
      // Foreground arc
      canvas.drawArc(
        rect,
        startAngle,
        math.pi * 2 * percent,
        false,
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.percent != percent ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}

// ─────────────────────────────────────────────────────────────
// PRESSABLE CARD WRAPPER
// ─────────────────────────────────────────────────────────────
class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _PressableCard({required this.child, this.onTap});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticEngine.selection();
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: 130.ms,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED HEADER ACTION BTN
// ─────────────────────────────────────────────────────────────
class HeaderActionBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const HeaderActionBtn({super.key, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}
