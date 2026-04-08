import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── TOP ROW: Main Progress + Adherence ──
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Progress Card (Bento Style)
              Expanded(
                flex: 6,
                child: _BentoMetricCard(
                  emoji: '📈',
                  iconColor: L.primary,
                  label: 'Daily Progress',
                  value: '${(dosePct * 100).round()}%',
                  unit: 'complete',
                  sublabel: '$takenCount of ${doses.length} doses taken',
                  sparklineData: _buildWeeklyData(state),
                  sparklineColor: L.primary,
                  L: L,
                ).animate().fadeIn(duration: 600.ms).scale(
                    begin: const Offset(0.98, 0.98), curve: Curves.easeOutBack),
              ),
              const SizedBox(width: AppSpacing.p12),
              // Secondary Stats Stacked
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Expanded(
                      child: _BentoSmallCard(
                        emoji: streak > 0 ? '🔥' : '❄️',
                        label: 'Streak',
                        value: '$streak days',
                        valueColor: L.warning,
                        L: L,
                      )
                          .animate(delay: 100.ms)
                          .fadeIn(duration: 600.ms)
                          .slideX(begin: 0.1, end: 0),
                    ),
                    const SizedBox(height: AppSpacing.p12),
                    Expanded(
                      child: _BentoSmallCard(
                        emoji: '📊',
                        label: 'Adherence',
                        value: '$adherence%',
                        valueColor: L.success,
                        L: L,
                      )
                          .animate(delay: 200.ms)
                          .fadeIn(duration: 600.ms)
                          .slideX(begin: 0.1, end: 0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.p12),

        // ── MIDDLE ROW: Next Dose (Full Width Premium) ──
        if (nextDose != null)
          _NextDoseCard(dose: nextDose, nowM: nowM, L: L)
              .animate(delay: 300.ms)
              .fadeIn(duration: 800.ms)
              .slideY(begin: 0.1, end: 0),

        const SizedBox(height: AppSpacing.p12),

        // ── BOTTOM ROW: BP + Mood ──
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BentoMetricCard(
                  emoji: '📦',
                  iconColor: const Color(0xFFEF5350),
                  label: 'Inventory',
                  value: '${state.getLowStockCount()}',
                  unit: 'low',
                  sublabel: state.getLowStockCount() == 0
                      ? 'Stocks healthy'
                      : '${state.getLowStockCount()} refill needed',
                  sparklineData: _buildStockData(state),
                  sparklineColor: const Color(0xFFEF5350),
                  L: L,
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.1, end: 0),
              ),
              const SizedBox(width: AppSpacing.p12),
              Expanded(
                child: _BentoMetricCard(
                  emoji: '☀️',
                  iconColor: const Color(0xFFF59E0B),
                  label: 'Mood',
                  value: state.getMoodSummary(
                    good: 'Good',
                    stable: 'Stable',
                    severe: 'Severe',
                    empty: '-',
                  )['value']!,
                  unit: state.getMoodSummary(
                    good: 'Good',
                    stable: 'Stable',
                    severe: 'Severe',
                    empty: '-',
                  )['unit']!,
                  sublabel: state.getMoodSummary(
                    good: 'Good',
                    stable: 'Stable',
                    severe: 'Severe',
                    empty: 'No logs',
                  )['sublabel']!,
                  sparklineData: state.getRecentSymptomStats(),
                  sparklineColor: const Color(0xFFF59E0B),
                  L: L,
                )
                    .animate(delay: 500.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.1, end: 0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<double> _buildWeeklyData(AppState state) {
    return List.generate(7, (i) {
      final d = DateTime.now().subtract(Duration(days: 6 - i));
      final k = d.toIso8601String().substring(0, 10);
      final ds = state.history[k] ?? [];
      if (ds.isEmpty) return 0.0;
      return ds.where((x) => x.taken).length / ds.length;
    });
  }

  List<double> _buildStockData(AppState state) {
    return state.inventoryHistory;
  }
}

// ─────────────────────────────────────────────────────────────
// BENTO METRIC CARD — with sparkline
// ─────────────────────────────────────────────────────────────
class _BentoMetricCard extends StatelessWidget {
  final String emoji;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;
  final String sublabel;
  final List<double> sparklineData;
  final Color sparklineColor;
  final AppThemeColors L;

  const _BentoMetricCard({
    required this.emoji,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
    required this.sublabel,
    required this.sparklineData,
    required this.sparklineColor,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableCard(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.p16),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(AppRadius.squircle),
          border:
              Border.all(color: L.border.withValues(alpha: 0.07), width: 0.5),
          boxShadow: AppShadows.neumorphic,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.s),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: AppSpacing.p8),
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.p12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: AppTypography.displaySmall.copyWith(
                    color: L.text,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    height: 1.0,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              sublabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: L.sub.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.p16),
            SizedBox(
              height: 32,
              child: CustomPaint(
                size: const Size(double.infinity, 32),
                painter: _SparklinePainter(
                  data: sparklineData,
                  color: sparklineColor,
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
// BENTO SMALL CARD
// ─────────────────────────────────────────────────────────────
class _BentoSmallCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color valueColor;
  final AppThemeColors L;

  const _BentoSmallCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableCard(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.p12),
        decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(AppRadius.squircle),
          border:
              Border.all(color: L.border.withValues(alpha: 0.07), width: 0.5),
          boxShadow: AppShadows.neumorphic,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.22, 1.22),
                  duration: 1600.ms,
                  curve: Curves.easeInOut,
                ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.titleLarge.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  label.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: L.sub.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w900,
                    fontSize: 10, // Standardized for micro-labels
                    letterSpacing: 0.5,
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
    // Contextual emoji: urgent ⚡, soon ⏰, scheduled 💊
    final doseEmoji = diff <= 15 ? '⚡' : (diff <= 60 ? '⏰' : '💊');
    final pulseMs = diff <= 15 ? 700 : (diff <= 60 ? 1000 : 1600);

    return _PressableCard(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.p16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(AppRadius.squircle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 32,
              offset: const Offset(0, 16),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Row(
          children: [
            // Animated emoji pill
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: L.onPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.m),
              ),
              child: Center(
                child: Text(
                  doseEmoji,
                  style: const TextStyle(fontSize: 26),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.25, 1.25),
                      duration: Duration(milliseconds: pulseMs),
                      curve: Curves.easeInOut,
                    ),
              ),
            ),
            const SizedBox(width: AppSpacing.p16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEXT DOSE',
                    style: AppTypography.labelSmall.copyWith(
                      color: L.onPrimary.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    dose.med.name,
                    style: AppTypography.headlineSmall.copyWith(
                      color: L.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.p12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: L.onPrimary,
                borderRadius: BorderRadius.circular(AppRadius.max),
              ),
              child: Text(
                timeLabel.toUpperCase(),
                style: AppTypography.labelMedium.copyWith(
                  color: L.primary,
                  fontWeight: FontWeight.w900,
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
// SPARKLINE PAINTER
// ─────────────────────────────────────────────────────────────
class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final w = size.width / (data.length - 1);
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * w;
      final y = size.height - (data[i].clamp(0, 1) * (size.height - 8) + 4);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * w;
        final prevY =
            size.height - (data[i - 1].clamp(0, 1) * (size.height - 8) + 4);
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
        fillPath.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Terminal point glow
    final lastX = size.width;
    final lastY = size.height - (data.last.clamp(0, 1) * (size.height - 8) + 4);
    canvas.drawCircle(Offset(lastX, lastY), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.data != data || old.color != color;
}

// ─────────────────────────────────────────────────────────────
// PRESSABLE CARD WRAPPER
// ─────────────────────────────────────────────────────────────
class _PressableCard extends StatefulWidget {
  final Widget child;
  const _PressableCard({required this.child});

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
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: 150.ms,
        curve: Curves.easeOutQuart,
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
  final Color? backgroundColor;

  const HeaderActionBtn(
      {super.key,
      required this.child,
      required this.onTap,
      this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.max),
          boxShadow: AppShadows.neumorphic,
        ),
        child: Center(child: child),
      ),
    );
  }
}
