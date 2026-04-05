import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/shared/shared_widgets.dart';
import '../domain/entities/entities.dart';
import '../core/utils/haptic_engine.dart';
import 'home/home_tab.dart';
import 'scan/scan_tab.dart';
import 'alarms/alarms_tab.dart';
import 'family/family_tab.dart';
import 'dashboard/dashboard_tab.dart';
import 'security/lock_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/common/medical_disclaimer_modal.dart';
import '../widgets/shared/shared_widgets.dart';

// APP SHELL — Bottom nav + FAB + overlays
// ══════════════════════════════════════════════
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _tab = 0; // 0=home, 1=alarms, 2=dashboard, 3=family
  bool _showScan = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Show medical disclaimer on first launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        MedicalDisclaimerModal.showIfNeeded(context);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Auto-lock when app goes completely to background.
      // We ignore 'inactive' so pulling down the notification center doesn't lock it.
      context.read<AppState>().lockApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    // Granular selection
    final isDark = context.select<AppState, bool>((s) => s.darkMode);
    final unseenAlerts =
        context.select<AppState, int>((s) => s.unseenAlertsCount);
    final lowMeds =
        context.select<AppState, List<Medicine>>((s) => s.getLowMeds());
    final isLocked = context.select<AppState, bool>((s) => s.isLocked);
    final toast = context.select<AppState, String?>((s) => s.toast);
    final toastType = context.select<AppState, String?>((s) => s.toastType);
    final bannerDismissed = context.select<AppState, bool>((s) => s.lowStockBannerDismissed);
    final allSchedules = context.select<AppState, int>((s) => s.getAllSchedules().length);
    final medsCount = context.select<AppState, int>((s) => s.meds.length);
    final isSyncing = context.select<AppState, bool>((s) => s.isMutating);
    final lastSynced = context.select<AppState, DateTime?>((s) => s.lastSyncedAt);
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: isLocked
          ? const LockScreen()
          : Scaffold(
              backgroundColor: L.meshBg,
              resizeToAvoidBottomInset: false,
              body: Stack(children: [
                // ── Main content (Animated Transitions) ──
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: 350.ms,
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.01),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_tab),
                      child: _buildCurrentTab(),
                    ),
                  ),
                ),

                // ── Scan Overlay (Modal-like) ──
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
                    onClose: () => setState(() => _showScan = false),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                      .scale(
                        begin: const Offset(0.92, 0.92),
                        curve: Curves.easeOutBack,
                      ),

                // ── Low stock banner (Floating Pill) ──
                if (lowMeds.isNotEmpty && !_showScan && !bannerDismissed)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + AppSpacing.p12,
                    left: AppSpacing.p16,
                    right: AppSpacing.p16,
                    child: LowStockBanner(
                      meds: lowMeds,
                      onDismiss: () => context.read<AppState>().dismissLowStockBanner(),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: -0.2, end: 0, curve: Curves.easeOutBack),
                  ),

                // ── Sync Status (Subtle floating indicator at bottom-right) ──
                Positioned(
                  bottom: 110 + MediaQuery.of(context).padding.bottom,
                  right: 20,
                  child: SyncStatusBanner(isSyncing: isSyncing, lastSynced: lastSynced)
                      .animate(target: isSyncing ? 1 : 0)
                      .fadeIn(duration: 300.ms)
                      .scale(begin: const Offset(0.8, 0.8))
                      .slideY(begin: 0.2, end: 0),
                ),

                // ── Toast (Status Pill) ──
                if (toast != null)
                  AppToast(message: toast, type: toastType ?? 'success'),

                // ── Bottom nav ──
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutQuart,
                  left: 0,
                  right: 0,
                  bottom: _showScan ? -120 : 0, // Slide down out of view
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _showScan ? 0 : 1,
                    child: _buildBottomNav(L, unseenAlerts, medsCount, allSchedules),
                  ),
                ),
              ]),
            ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_tab) {
      case 0: return HomeTab(onScan: () => setState(() => _showScan = true), onSwitchTab: (i) => setState(() => _tab = i));
      case 1: return const AlarmsTab();
      case 2: return const DashboardTab();
      case 3: return const FamilyTab();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNav(AppThemeColors L, int unseenAlerts, int medsCount, int allSchedules) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      margin: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: 24 + bottomPadding,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // --- FLOATING GLASS BAR ---
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: L.card.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: L.border.withValues(alpha: 0.1), width: 1.5),
                  boxShadow: L.shadowSoft,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(0, 'HOME', Icons.grid_view_rounded, L, 0),
                      _buildNavItem(1, 'ALARMS', Icons.alarm_rounded, L, unseenAlerts),
                      const SizedBox(width: 60), // Space for FAB
                      _buildNavItem(2, 'DATA', Icons.analytics_rounded, L, 0),
                      _buildNavItem(3, 'PEOPLE', Icons.people_alt_rounded, L, unseenAlerts),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // --- CENTERED FAB ---
          Positioned(
            bottom: 12,
            child: BouncingButton(
              onTap: () {
                HapticEngine.medium();
                setState(() => _showScan = true);
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppGradients.main,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: L.primary.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2),
                    BoxShadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: -5),
                  ],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.add_rounded, color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, AppThemeColors L, int cnt) {
    final selected = _tab == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_tab != index) {
            HapticEngine.selection();
            setState(() => _tab = index);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: selected ? L.text : L.sub.withValues(alpha: 0.35),
                ).animate(target: selected ? 1 : 0).scale(
                      duration: 400.ms,
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                    ).shake(duration: 400.ms, hz: 4),
                if (cnt > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: L.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: L.card, width: 1.5),
                        boxShadow: [BoxShadow(color: L.error.withValues(alpha: 0.3), blurRadius: 4)],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: selected ? L.text : L.sub.withValues(alpha: 0.35),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ── UPGRADED LOW STOCK BANNER (Floating Pill) ──
class LowStockBanner extends StatelessWidget {
  final List<Medicine> meds;
  final VoidCallback onDismiss;
  const LowStockBanner({super.key, required this.meds, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final firstName = meds.isNotEmpty ? meds.first.name : '';
    
    return SquircleCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.inventory_2_rounded, size: 18, color: L.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LOW_STOCK_ALERT',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: L.error,
                    fontSize: 8,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  '${meds.length > 1 ? "${meds.length} meds" : firstName} need refill',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    color: L.text,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          BouncingButton(
            onTap: onDismiss,
            child: Icon(Icons.close_rounded, size: 16, color: L.sub),
          ),
        ],
      ),
    );
  }
}
