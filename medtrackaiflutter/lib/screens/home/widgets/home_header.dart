import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';

class HomeHeader extends StatelessWidget {
  final AppState state;
  final int streak;
  final VoidCallback onOpenStreak;
  final VoidCallback onOpenSettings;

  const HomeHeader({
    super.key,
    required this.state,
    required this.streak,
    required this.onOpenStreak,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        color: L.bg,
        border: Border(
          bottom: BorderSide(
            color: L.border.withValues(alpha: 0.1),
            width: 1.0,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 10 + topPadding, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLogoAndActions(L),
            const SizedBox(height: 14),
            _buildGreeting(L),
            const SizedBox(height: 20),
            _buildWeekStrip(context, L),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(AppThemeColors L) {
    final hour = DateTime.now().hour;
    String greeting = "Good morning";
    String emoji = "🌅";
    
    if (hour >= 12 && hour < 17) {
      greeting = "Good afternoon";
      emoji = "☀️";
    } else if (hour >= 17 && hour < 21) {
      greeting = "Good evening";
      emoji = "🌆";
    } else if (hour >= 21 || hour < 5) {
      greeting = "Good night";
      emoji = "🌙";
    }

    final name = state.profile?.name ?? "Hero";
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              greeting,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: L.sub,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "$name,",
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: L.text,
            letterSpacing: -0.8,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          _getSubGreeting(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: L.sub,
            height: 1.2,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  String _getSubGreeting() {
    final doses = state.getDoses();
    final taken = doses.where((d) => state.takenToday[d.key] == true).length;
    final remaining = doses.length - taken;
    final lowMeds = state.getLowMeds();

    if (lowMeds.isNotEmpty) {
      return "Refill needed: ${lowMeds.length} ${lowMeds.length == 1 ? 'medication' : 'medications'} running low.";
    }

    if (doses.isEmpty) return "Ready to start your health journey?";
    if (remaining == 0) return "You've completed all doses for today. Amazing! ✨";
    if (remaining == 1) return "Just 1 dose left to crush your day.";
    return "You have $remaining doses remaining today.";
  }

  Widget _buildLogoAndActions(AppThemeColors L) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Image.asset('assets/images/home_logo.png',
                  width: 26, height: 26),
            ),
          ),
          const SizedBox(width: 10),
          RichText(
              text: TextSpan(
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: L.text,
                letterSpacing: -0.5),
            children: [
              const TextSpan(text: 'Med'),
              TextSpan(
                  text: 'AI',
                  style: TextStyle(
                    color: L.text.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w900,
                  )),
            ],
          )),
        ]).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
        Row(children: [
          _StreakBtn(streak: streak, onTap: () {
            HapticFeedback.selectionClick();
            onOpenStreak();
          }),
          const SizedBox(width: 8),
          _HeaderActionBtn(
            onTap: () {
              HapticFeedback.selectionClick();
              onOpenSettings();
            },
            child: Icon(Icons.settings_rounded,
                color: L.text, size: 18),
          ),
        ]).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: 0.05),
      ],
    );
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
          dotColor = const Color(0xFF111111);
          textColor = Colors.white;
          borderColor = const Color(0xFF111111);
        } else if (isFuture) {
          dotColor = Colors.transparent;
          textColor = L.sub.withValues(alpha: 0.4);
          borderColor = L.border.withValues(alpha: 0.3);
        } else if (rate >= 0.8) {
          dotColor = L.green.withValues(alpha: 0.15);
          textColor = L.green;
          borderColor = L.green.withValues(alpha: 0.5);
        } else if (rate > 0 && rate < 0.8) {
          dotColor = L.amber.withValues(alpha: 0.1);
          textColor = L.amber;
          borderColor = L.amber.withValues(alpha: 0.4);
        } else if (!isFuture && ds.isEmpty) {
          dotColor = Colors.transparent;
          textColor = L.sub;
          borderColor = L.border;
        } else {
          dotColor = L.red.withValues(alpha: 0.1);
          textColor = L.red;
          borderColor = L.red.withValues(alpha: 0.3);
        }

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(dayLabel,
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isT ? L.text : L.sub.withValues(alpha: 0.7))),
              const SizedBox(height: 5),
              AnimatedContainer(
                duration: 400.ms,
                curve: Curves.easeOutBack,
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: isT
                      ? [
                          BoxShadow(
                            color: const Color(0xFF111111).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text('$dayNum',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: isT ? FontWeight.w900 : FontWeight.w600,
                          color: textColor)),
                ),
              ),
              const SizedBox(height: 4),
              if (!isFuture && !isT && rate > 0)
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rate >= 0.8 ? L.green : (rate >= 0.5 ? L.amber : L.red),
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
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: streak > 0 ? L.amber.withValues(alpha: 0.15) : L.fill,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: streak > 0 ? L.amber.withValues(alpha: 0.4) : L.border,
            width: 1.5,
          ),
        ),
        child: Row(children: [
          Text(streak > 0 ? '🔥' : '❄️',
              style: const TextStyle(fontSize: 14, height: 1.0)),
          const SizedBox(width: 6),
          Text('$streak',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: streak > 0 ? L.amber : L.sub,
                  letterSpacing: -0.3)),
        ]),
      ),
    );
  }
}

class _HeaderActionBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HeaderActionBtn({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: L.fill,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: L.border, width: 1),
        ),
        child: Center(child: child),
      ),
    );
  }
}
