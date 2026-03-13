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
        );
      case 1:
        return const AlarmsTab();
      case 2:
        return const FamilyTab();
      default:
        return HomeTab(
          onScan: () => setState(() => _showScan = true),
        );
    }
  }

  Widget _buildBottomNav(AppThemeColors L, int unseenAlerts) {
    final state = context.watch<AppState>();
    final isDark = state.darkMode;
    final bg = isDark ? const Color(0xFF111111) : Colors.white;
    final borderCol = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.1);

    return Container(
      margin: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerRight, // Changed to right
        children: [
          // Nav Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 72,
                margin: const EdgeInsets.only(right: 40), // Offset for FAB on right
                decoration: BoxDecoration(
                  color: bg.withOpacity(0.85),
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(32), right: Radius.circular(16)),
                  border: Border.all(color: borderCol, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 0, 40, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(0, 'Home', Icons.grid_view_rounded, L, unseenAlerts),
                    _buildNavItem(1, 'Alarms', Icons.notifications_active_rounded, L, unseenAlerts),
                    _buildNavItem(2, 'Family', Icons.people_alt_rounded, L, unseenAlerts),
                  ],
                ),
              ),
            ),
          ),
          // ── Right-positioned FAB
          Positioned(
            right: 0,
            top: -20, // Slightly higher
            child: GestureDetector(
              onTap: () => setState(() => _showScan = true),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF111111), // Black color
                  shape: BoxShape.circle,
                  border: Border.all(color: borderCol, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.add_rounded, color: Colors.white, size: 36),
                ),
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
    final cnt = index == 2 ? unseenAlerts : 0;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: selected ? const Color(0xFFA3E635) : L.sub,
                )
                    .animate(target: selected ? 1 : 0)
                    .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15))
                    .shimmer(delay: 400.ms, duration: 1200.ms),
                if (cnt > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.lRed,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: L.bg, width: 2),
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
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? L.text : L.sub.withOpacity(0.7),
                letterSpacing: -0.2,
              ),
            ).animate(target: selected ? 1 : 0).fadeIn(delay: 100.ms),
          ],
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
    final firstName = meds.isNotEmpty ? meds.first.name : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFBD0AF), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
