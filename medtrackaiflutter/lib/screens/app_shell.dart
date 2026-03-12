import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../domain/entities/entities.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/shared/shared_widgets.dart';
import 'home/home_tab.dart';
import 'scan/scan_tab.dart';
import 'alarms/alarms_tab.dart';
import 'family/family_tab.dart';
import 'history/history_tab.dart';

// ══════════════════════════════════════════════
// APP SHELL — Bottom nav + FAB + overlays
// ══════════════════════════════════════════════

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int _tab = 0; // 0=home, 1=history, 2=alarms, 3=family
  bool _showScan = false;
  bool _hideBanner = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final L = context.L;
    final isDark = state.darkMode;
    final unseenAlerts = state.missedAlerts.where((a) => !a.seen).length;
    final lowMeds = state.getLowMeds();


    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: L.bg,
        body: Stack(children: [
          // ── Main content (Animated Transitions)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _showScan
                ? ScanTab(
                    key: const ValueKey('scan_tab'),
                    onSave: (med) {
                      state.addMedicine(med);
                      setState(() {
                        _showScan = false;
                        _tab = 0;
                      });
                      state.showToast('💊 ${med.name} added!');
                    },
                    onClose: () => setState(() {
                      _showScan = false;
                    }),
                    onManualAdd: null,
                  )
                : SizedBox(
                    key: ValueKey('main_tab_$_tab'),
                    child: _buildTab(state),
                  ),
          ),

          // ── Low stock banner
          if (lowMeds.isNotEmpty && !_showScan && !_hideBanner)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: LowStockBanner(
                meds: lowMeds,
                onDismiss: () => setState(() => _hideBanner = true),
              ),
            ),

          // ── Toast
          if (state.toast != null)
            AppToast(message: state.toast!, type: state.toastType ?? 'success'),

          // ── Bottom nav
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNav(L, unseenAlerts),
          ),
        ]),
      ),
    );
  }

  Widget _buildTab(AppState state) {
    switch (_tab) {
      case 0:
        return HomeTab(
          onScan: () => setState(() => _showScan = true),
          onViewDashboard: () => setState(() => _tab = 1),
        );
      case 1:
        return const HistoryTab();
      case 2:
        return const AlarmsTab();
      case 3:
        return const FamilyTab();
      default:
        return HomeTab(
          onScan: () => setState(() => _showScan = true),
          onViewDashboard: () => setState(() => _tab = 1),
        );
    }
  }

  Widget _buildBottomNav(AppThemeColors L, int unseenAlerts) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final bg = isDark ? const Color(0xF7121218) : const Color(0xF7FFFFFF);
    final borderCol = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerRight,
      children: [
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                border: Border(top: BorderSide(color: borderCol, width: 1)),
              ),
              padding: EdgeInsets.only(
                top: 10,
                bottom: 28 + MediaQuery.of(context).padding.bottom,
                left: 0,
                right: 80, // Space for the FAB on the right
              ),
              child: Row(
                children: [
                  _buildNavItem(0, 'Home', Icons.home_rounded, L, unseenAlerts),
                  _buildNavItem(
                      1, 'History', Icons.history_rounded, L, unseenAlerts),
                  _buildNavItem(2, 'Alarms', Icons.notifications_rounded, L,
                      unseenAlerts),
                  _buildNavItem(
                      3, 'Family', Icons.people_rounded, L, unseenAlerts),
                ],
              ),
            ),
          ),
        ),
        // ── Right Side FAB
        Positioned(
          right: 16,
          top: -25, // Floats above the bar
          child: GestureDetector(
          onTap: () => setState(() => _showScan = true),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, AppThemeColors L,
      int unseenAlerts) {
    final selected = _tab == index;
    final cnt = index == 3 ? unseenAlerts : 0;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: 22, color: selected ? L.text : L.sub),
                  if (cnt > 0)
                    Positioned(
                      top: -3,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        constraints:
                            const BoxConstraints(minWidth: 14, minHeight: 14),
                        decoration: BoxDecoration(
                          color: AppColors.lRed,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: L.bg, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            cnt > 9 ? '9+' : cnt.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Inter',
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? L.text : L.sub,
                height: 1.0,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// LOW STOCK BANNER
// ══════════════════════════════════════════════
// LOW STOCK BANNER
// ══════════════════════════════════════════════

class LowStockBanner extends StatelessWidget {
  final List<dynamic> meds;
  final VoidCallback onDismiss;
  const LowStockBanner(
      {super.key, required this.meds, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final firstName = meds.isNotEmpty ? meds.first.name : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFBD0AF), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(children: [
        const Text('📦', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(
          '${meds.length > 1 ? "${meds.length} medicines" : firstName} running low — time to refill',
          style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFC2410C)),
        )),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onDismiss,
          child: const Icon(Icons.close, size: 16, color: Color(0xFFC2410C)),
        ),
      ]),
    );
  }
}
