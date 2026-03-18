import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/shared/shared_widgets.dart';
import '../domain/entities/entities.dart';
import 'home/home_tab.dart';
import 'scan/scan_tab.dart';
import 'alarms/alarms_tab.dart';
import 'family/family_tab.dart';
import 'dashboard/dashboard_tab.dart';
import 'security/lock_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final L = context.L;
    // Granular selection
    final isDark = context.select<AppState, bool>((s) => s.darkMode);
    final unseenAlerts = context.select<AppState, int>((s) => s.unseenAlertsCount);
    final lowMeds = context.select<AppState, List<Medicine>>((s) => s.getLowMeds());
    final isLocked = context.select<AppState, bool>((s) => s.isLocked);
    final toast = context.select<AppState, String?>((s) => s.toast);
    final toastType = context.select<AppState, String?>((s) => s.toastType);


    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: isLocked 
        ? const LockScreen()
        : Scaffold(
            backgroundColor: L.bg,
            body: Stack(children: [
          // ── Main content (Animated Transitions)
          Stack(
            children: [
              IndexedStack(
                index: _tab,
                children: [
                  HomeTab(onScan: () => setState(() => _showScan = true)),
                  const AlarmsTab(),
                  const DashboardTab(),
                  const FamilyTab(),
                ],
              ),

              // ── Scan Overlay (Modal-like)
              if (_showScan)
                ScanTab(
                  key: const ValueKey('scan_tab'),
                  onSave: (med) {
                    final s = context.read<AppState>();
                    s.addMedicine(med);
                    setState(() {
                      _showScan = false;
                      _tab = 0;
                    });
                    s.showToast('💊 ${med.name} added!');
                  },
                  onClose: () => setState(() {
                    _showScan = false;
                  }),
                  onManualAdd: null,
                ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95)),
            ],
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
          if (toast != null)
            AppToast(message: toast, type: toastType ?? 'success'),

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
              borderRadius: BorderRadius.circular(AppRadius.l),
              border: Border.all(color: L.border, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                  spreadRadius: -8,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(12, 0, 32, 0),
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
                    colors: [L.secondary, L.secondary.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: L.secondary.withValues(alpha: 0.3),
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
                      color: Colors.white, size: 36),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                )
                .shimmer(
                  color: L.secondary.withValues(alpha: 0.2),
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
                          ? L.secondary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.m),
                    ),
                      child: Opacity(
                        opacity: selected ? 1.0 : 0.0,
                        child: Icon(
                          icon,
                          size: 22,
                          color: selected ? L.secondary : L.text.withValues(alpha: 0.7),
                        ).animate(target: selected ? 1 : 0)
                         .scale(duration: 200.ms, curve: Curves.easeOutBack)
                         .tint(color: L.secondary, duration: 200.ms),
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
                          color: L.error,
                          borderRadius: BorderRadius.circular(AppRadius.s),
                          border: Border.all(color: L.bg, width: 1.0),
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
                  color: selected ? L.secondary : L.sub,
                  letterSpacing: -0.1,
                ),
                child: Text(label),
              ).animate(target: selected ? 1 : 0)
               .scale(duration: 200.ms, begin: const Offset(1, 1), end: const Offset(1.1, 1.1))
               .moveY(begin: 0, end: -2, duration: 200.ms),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: L.card.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: L.error.withValues(alpha: 0.2), width: 1.0),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 25,
              offset: const Offset(0, 12),
              spreadRadius: -5),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: L.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.inventory_2_rounded, size: 18, color: L.error),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Stock Alert',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: L.error,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '${meds.length > 1 ? "${meds.length} medicines" : firstName} running low',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: L.text,
                  letterSpacing: -0.3),
            ),
          ],
        )),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onDismiss,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: L.fill,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close_rounded, size: 14, color: L.sub),
          ),
        ),
      ]),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }
}

