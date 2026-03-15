import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/shared/shared_widgets.dart';
import 'home/home_tab.dart';
import 'scan/scan_tab.dart';
import 'alarms/alarms_tab.dart';
import 'family/family_tab.dart';
import 'dashboard/dashboard_tab.dart';
import 'security/lock_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  int _tab = 0; // 0=home, 1=alarms, 2=family
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
      child: state.isLocked 
        ? const LockScreen()
        : Scaffold(
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
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.98, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                  ),
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
        );
      case 1:
        return const AlarmsTab();
      case 2:
        return const DashboardTab();
      case 3:
        return const FamilyTab();
      default:
        return HomeTab(
          onScan: () => setState(() => _showScan = true),
        );
    }
  }

  Widget _buildBottomNav(AppThemeColors L, int unseenAlerts) {
    final bg = L.card;
    return Container(
      margin: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerRight,
        children: [
          // Nav Bar
          Container(
            height: 68,
            margin: const EdgeInsets.only(right: 36),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: L.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                  spreadRadius: -8,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 0, 36, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, 'Home', Icons.grid_view_rounded, L, unseenAlerts),
                _buildNavItem(1, 'Alarms', Icons.alarm_rounded, L, unseenAlerts),
                _buildNavItem(2, 'Insights', Icons.analytics_rounded, L, unseenAlerts),
                _buildNavItem(3, 'Family', Icons.people_alt_rounded, L, unseenAlerts),
              ],
            ),
          ),
          // FAB — scan/add button
          Positioned(
            right: 0,
            top: -18,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() => _showScan = true);
              },
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [L.green, L.green.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: L.green.withValues(alpha: 0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.add_rounded,
                      color: Colors.black, size: 36),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                )
                .shimmer(
                  color: L.green.withValues(alpha: 0.2),
                  duration: 3000.ms,
                ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, AppThemeColors L,
      int unseenAlerts) {
    final selected = _tab == index;
    final cnt = index == 3 ? unseenAlerts : 0;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _tab = index);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selected
                          ? L.green.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: selected ? L.green : L.sub,
                    ),
                  ),
                  if (cnt > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.lRed,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: L.bg, width: 1.5),
                        ),
                        child: Text(
                          cnt > 9 ? '9+' : cnt.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ).animate().scale().fadeIn(),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected ? L.green : L.sub,
                  letterSpacing: -0.1,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


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
    final L = context.L;
    final firstName = meds.isNotEmpty ? meds.first.name : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: L.card2,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: L.green.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -2),
        ],
      ),
      child: Row(children: [
        const Text('📦', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(
          '${meds.length > 1 ? "${meds.length} medicines" : firstName} running low',
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: L.text),
        )),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onDismiss,
          child: Icon(Icons.close_rounded, size: 16, color: L.sub),
        ),
      ]),
    );
  }
}

