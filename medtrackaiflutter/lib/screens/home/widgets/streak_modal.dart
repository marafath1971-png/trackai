import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';
import '../../../services/share_service.dart';
import '../../../core/utils/haptic_engine.dart';
import '../../../providers/app_state.dart';

// ══════════════════════════════════════════════
// CONSISTENCY HUB (Cal AI Industrial Refined)
// ══════════════════════════════════════════════

class StreakModal extends StatelessWidget {
  final int streak;
  final Map<String, List<DoseEntry>> history;
  final StreakData streakData;
  final VoidCallback onClose;
  final VoidCallback onFreeze;

  const StreakModal(
      {super.key,
      required this.streak,
      required this.history,
      required this.streakData,
      required this.onClose,
      required this.onFreeze});

  static void show(BuildContext context, AppState state) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'StreakModal',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => StreakModal(
        streak: state.getStreak(),
        history: state.history,
        streakData: state.streakData,
        onClose: () => Navigator.of(ctx).pop(),
        onFreeze: () => state.useStreakFreeze(),
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0, 0.1), end: Offset.zero)
                .animate(
                    CurvedAnimation(parent: anim1, curve: Curves.easeOutQuart)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final size = MediaQuery.of(context).size;

    // Compute stats
    final allKeys = history.keys.toList()..sort();
    final totalDaysTracked = allKeys.length;
    final allEntries = history.values.expand((e) => e).toList();
    final totalTaken = allEntries.where((e) => e.taken).length;
    final totalDoses = allEntries.length;
    final overallAdh = totalDoses > 0 ? (totalTaken * 100 ~/ totalDoses) : 0;

    // Best streak
    int best = 0, cur = 0;
    String? prev;
    for (final k in allKeys) {
      final ds = history[k] ?? [];
      final rate = ds.isEmpty ? 0.0 : ds.where((x) => x.taken).length / ds.length;
      if (rate >= 0.8) {
        if (prev != null) {
          final diff = DateTime.parse(k).difference(DateTime.parse(prev)).inDays;
          cur = diff <= 1 ? cur + 1 : 1;
        } else {
          cur = 1;
        }
        if (cur > best) best = cur;
      } else {
        cur = 0;
      }
      prev = k;
    }

    final milestones = [
      {'d': 3, 'e': '🛡️', 'l': '3 Days', 'desc': 'Foundation established.'},
      {'d': 7, 'e': '⚡', 'l': '1 Week', 'desc': 'Biological rhythm sync.'},
      {'d': 14, 'e': '⚔️', 'l': '2 Weeks', 'desc': 'Efficacy optimization.'},
      {'d': 30, 'e': '🏆', 'l': '1 Month', 'desc': 'Therapeutic mastery.'},
      {'d': 60, 'e': '💎', 'l': '60 Days', 'desc': 'Unbreakable habit.'},
      {'d': 100, 'e': '👑', 'l': '100 Days', 'desc': 'Peak performance.'},
      {'d': 365, 'e': '🪐', 'l': '1 Year', 'desc': 'Legendary consistency.'},
    ];

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: size.width,
                constraints: BoxConstraints(
                  maxHeight: size.height * 0.92,
                  maxWidth: 450,
                ),
                decoration: BoxDecoration(
                  color: L.bg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border.all(color: L.border.withValues(alpha: 0.1), width: 0.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: L.text.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    _buildHeader(L),
                    Flexible(
                      child: RawScrollbar(
                        thumbColor: L.text.withValues(alpha: 0.1),
                        radius: const Radius.circular(10),
                        thickness: 4,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeroMetric(L, streak, best, overallAdh),
                              const SizedBox(height: 24),
                              _buildStatsGrid(L, totalDaysTracked, totalTaken, totalDoses),
                              const SizedBox(height: 32),
                              _buildSectionTitle(L, '30-DAY STABILITY MATRIX'),
                              const SizedBox(height: 16),
                              _Heatmap(history: history, L: L),
                              const SizedBox(height: 40),
                              _buildSectionTitle(L, 'ASCENSION PROGRESSION'),
                              const SizedBox(height: 20),
                              _AscensionTrack(milestones: milestones, currentStreak: streak),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildFooterActions(L, streak),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeColors L) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONSISTENCY HUB',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: L.sub,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Health Performance',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  color: L.text,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, color: L.text, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: L.fill.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(AppThemeColors L, int streak, int best, int adherence) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: L.text, // Monolith style
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: L.text.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT CHAIN',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: L.bg.withValues(alpha: 0.5),
                    letterSpacing: 1.5,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$streak',
                      style: AppTypography.displayLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: L.bg,
                        fontSize: 64,
                        letterSpacing: -4,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'DAYS',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: L.bg,
                        fontSize: 18,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: L.bg.withValues(alpha: 0.1),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MiniHeroStat(label: 'PEAK', val: '$best', L: L),
              const SizedBox(height: 16),
              _MiniHeroStat(label: 'QUALITY', val: '$adherence%', L: L),
            ],
          ),
        ],
      ),
    ).animate().scale(
          begin: const Offset(0.95, 0.95),
          duration: 500.ms,
          curve: Curves.easeOutBack,
        ).fadeIn();
  }

  Widget _buildStatsGrid(AppThemeColors L, int tracked, int taken, int logged) {
    return Row(
      children: [
        Expanded(child: _StatBox(label: 'Tracked', val: '$tracked', emoji: '📅', L: L)),
        const SizedBox(width: 12),
        Expanded(child: _StatBox(label: 'Achieved', val: '$taken', emoji: '✓', L: L)),
        const SizedBox(width: 12),
        Expanded(child: _StatBox(label: 'Registry', val: '$logged', emoji: '📊', L: L)),
      ],
    );
  }

  Widget _buildSectionTitle(AppThemeColors L, String title) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 11,
            color: L.sub,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: L.border.withValues(alpha: 0.1))),
      ],
    );
  }

  Widget _buildFooterActions(AppThemeColors L, int streak) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: L.bg,
        border: Border(top: BorderSide(color: L.border.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticEngine.selection();
                ShareService.shareStreak(streak);
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: L.text,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share_rounded, color: L.bg, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'SHARE PERFORMANCE',
                        style: AppTypography.labelLarge.copyWith(
                          color: L.bg,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniHeroStat extends StatelessWidget {
  final String label, val;
  final AppThemeColors L;
  const _MiniHeroStat({required this.label, required this.val, required this.L});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          val,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w900,
            color: L.bg,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w900,
            color: L.bg.withValues(alpha: 0.4),
            fontSize: 9,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, val;
  final String emoji;
  final AppThemeColors L;
  const _StatBox({required this.label, required this.val, required this.emoji, required this.L});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: L.border.withValues(alpha: 0.08), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          Text(
            val,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w900,
              color: L.text,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: L.sub,
              fontWeight: FontWeight.w900,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  final Map<String, List<DoseEntry>> history;
  final AppThemeColors L;
  const _Heatmap({required this.history, required this.L});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 28,
      itemBuilder: (c, i) {
        final d = today.subtract(Duration(days: 27 - i));
        final k = d.toIso8601String().substring(0, 10);
        final ds = history[k] ?? [];
        final rate = ds.isEmpty ? -1.0 : ds.where((e) => e.taken).length / ds.length;

        Color bg;
        if (rate < 0) {
          bg = L.fill.withValues(alpha: 0.5);
        } else if (rate >= 0.8) {
          bg = L.text; // Industrial Black/White
        } else if (rate > 0) {
          bg = L.text.withValues(alpha: 0.3);
        } else {
          bg = L.error.withValues(alpha: 0.2);
        }

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${d.day}',
              style: AppTypography.labelSmall.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: rate >= 0.8 ? L.bg : L.text.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AscensionTrack extends StatelessWidget {
  final List<Map<String, dynamic>> milestones;
  final int currentStreak;

  const _AscensionTrack({required this.milestones, required this.currentStreak});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: milestones.length,
      itemBuilder: (context, index) {
        final m = milestones[index];
        final target = m['d'] as int;
        final achieved = currentStreak >= target;
        final next = index < milestones.length - 1 ? milestones[index + 1]['d'] as int : target;
        final isNext = currentStreak < target && (index == 0 || currentStreak >= (milestones[index - 1]['d'] as int));

        return IntrinsicHeight(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: achieved ? L.text : L.fill,
                      shape: BoxShape.circle,
                      border: isNext ? Border.all(color: L.text, width: 2) : null,
                    ),
                    child: Center(
                      child: achieved 
                        ? Icon(Icons.check_rounded, color: L.bg, size: 16)
                        : Text(
                            m['e'] as String,
                            style: const TextStyle(fontSize: 14),
                          ),
                    ),
                  ),
                  if (index < milestones.length - 1)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: achieved ? L.text : L.fill,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            m['l'] as String,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: achieved || isNext ? L.text : L.sub,
                            ),
                          ),
                          if (isNext)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: L.text.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'NEXT',
                                style: AppTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9,
                                  color: L.text,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        achieved ? 'STABILITY UNLOCKED' : m['desc'] as String,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: achieved ? L.text.withValues(alpha: 0.6) : L.sub,
                        ),
                      ),
                      if (!achieved && isNext) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: currentStreak / target,
                            minHeight: 4,
                            backgroundColor: L.fill,
                            color: L.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${target - currentStreak} days remaining',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: L.text,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
