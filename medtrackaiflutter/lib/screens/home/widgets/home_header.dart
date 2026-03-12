import 'package:flutter/material.dart';
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
      padding: EdgeInsets.fromLTRB(20, 16 + topPadding, 20, 16),
      color: L.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLogoAndActions(L),
          const SizedBox(height: 20),
          _buildWeekStrip(L),
        ],
      ),
    );
  }

  Widget _buildLogoAndActions(AppThemeColors L) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Image.asset('assets/images/home_logo.png', width: 40, height: 40),
          const SizedBox(width: 8),
          RichText(
              text: TextSpan(
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: L.text,
                letterSpacing: -0.5),
            children: [
              const TextSpan(text: 'Med '),
              TextSpan(text: 'AI', style: TextStyle(color: L.green)),
            ],
          )),
        ]),
        Row(children: [
          _HeaderActionBtn(
            onTap: onOpenStreak,
            child: Row(children: [
              Icon(Icons.local_fire_department_rounded,
                  color: L.amber, size: 18),
              const SizedBox(width: 4),
              Text('$streak',
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.2)),
            ]),
          ),
          const SizedBox(width: 8),
          _HeaderActionBtn(
            onTap: onOpenSettings,
            child: const Icon(Icons.settings_rounded,
                color: Colors.white, size: 18),
          ),
        ]),
      ],
    );
  }

  Widget _buildWeekStrip(AppThemeColors L) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final d = DateTime.now().subtract(Duration(days: 6 - i));
        final k = d.toIso8601String().substring(0, 10);
        final isT = k == todayStr();
        final ds = state.history[k] ?? [];
        final rate =
            ds.isEmpty ? 0.0 : ds.where((x) => x.taken).length / ds.length;
        final dayLabel = ['S', 'M', 'T', 'W', 'T', 'F', 'S'][d.weekday % 7];
        final dayNum = d.day;

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(dayLabel,
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isT ? L.text : L.sub)),
              const SizedBox(height: 4),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isT
                      ? const Color(0xFF111111)
                      : rate >= 0.8
                          ? L.greenLight
                          : Colors.transparent,
                  border: Border.all(
                      color: isT
                          ? const Color(0xFF111111)
                          : rate >= 0.8
                              ? L.green
                              : L.border,
                      width: 2),
                ),
                child: Center(
                  child: Text('$dayNum',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: isT ? FontWeight.w800 : FontWeight.w600,
                          color: isT
                              ? Colors.white
                              : rate >= 0.8
                                  ? L.green
                                  : L.sub)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _HeaderActionBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HeaderActionBtn({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(99),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
