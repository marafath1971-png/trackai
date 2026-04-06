import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/shared/shared_widgets.dart';
import '../core/utils/haptic_engine.dart';
import 'home/home_tab.dart';
import 'scan/scan_tab.dart';
import 'alarms/alarms_tab.dart';
import 'family/family_tab.dart';
import 'dashboard/dashboard_tab.dart';
import 'security/lock_screen.dart';
import '../services/analytics_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/common/medical_disclaimer_modal.dart';

// ══════════════════════════════════════════════
// APP SHELL — Bottom nav + FAB + overlays
// ══════════════════════════════════════════════
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _tab = 0;
  bool _showScan = false;
  bool _fabPressed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) MedicalDisclaimerModal.showIfNeeded(context);
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
      context.read<AppState>().lockApp();
    }
  }

  void _openScan() {
    HapticEngine.medium();
    setState(() => _showScan = true);
  }

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final isDark = context.select<AppState, bool>((s) => s.darkMode);
    final unseenAlerts = context.select<AppState, int>((s) => s.unseenAlertsCount);
    final lowMeds = context.select<AppState, List<Medicine>>((s) => s.getLowMeds());
    final isLocked = context.select<AppState, bool>((s) => s.isLocked);
    final toast = context.select<AppState, String?>((s) => s.toast);
    final toastType = context.select<AppState, String?>((s) => s.toastType);
    final bannerDismissed = context.select<AppState, bool>((s) => s.lowStockBannerDismissed);
    final isSyncing = context.select<AppState, bool>((s) => s.isMutating);
    final lastSynced = context.select<AppState, DateTime?>((s) => s.lastSyncedAt);

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: isLocked
          ? const LockScreen()
          : Scaffold(
              backgroundColor: L.meshBg,
              resizeToAvoidBottomInset: false,
              body: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── Main content ──
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

                  // ── Scan Overlay — High Detail ──
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
                        s.showToast('${med.name} added!');
                      },
                      onClose: () => setState(() => _showScan = false),
                    )
                        .animate()
                        .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                        .scale(
                          begin: const Offset(0.94, 0.94),
                          curve: Curves.easeOutBack,
                        ),

                  // ── Low stock banner ──
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

                  // ── Sync indicator ──
                  Positioned(
                    bottom: 110 + bottomPadding,
                    right: 20,
                    child: SyncStatusBanner(isSyncing: isSyncing, lastSynced: lastSynced)
                        .animate(target: isSyncing ? 1 : 0)
                        .fadeIn(duration: 300.ms)
                        .scale(begin: const Offset(0.8, 0.8))
                        .slideY(begin: 0.2, end: 0),
                  ),

                  // ── Toast ──
                  if (toast != null)
                    AppToast(message: toast, type: toastType ?? 'success'),

                  // ── Bottom Floating Island (Nav + Integrated FAB) ──
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutQuart,
                    left: 0,
                    right: 0,
                    bottom: _showScan ? -(100 + bottomPadding) : 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: _showScan ? 0 : 1,
                      child: _buildBottomIsland(L, unseenAlerts),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_tab) {
      case 0:
        return HomeTab(
          onScan: _openScan,
          onSwitchTab: (i) => setState(() => _tab = i),
        );
      case 1: return const AlarmsTab();
      case 2: return const DashboardTab();
      case 3: return const FamilyTab();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildBottomIsland(AppThemeColors L, int unseenAlerts) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 20 + bottomPadding),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ── The Nav Pill ──
          GestureDetector(
            onTap: () {}, // Block taps passing through
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  height: 66,
                  decoration: BoxDecoration(
                    color: L.card.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: L.border.withValues(alpha: 0.1), width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildNavItem(0, 'Home', Icons.home_rounded, L, 0),
                      _buildNavItem(1, 'Reminders', Icons.notification_important_rounded, L, unseenAlerts),
                      const SizedBox(width: 64), // Tightened FAB space
                      _buildNavItem(2, 'Health', Icons.insights_rounded, L, 0),
                      _buildNavItem(3, 'Circle', Icons.people_alt_rounded, L, 0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── The Integrated Scan FAB ──
          Positioned(
            top: -16,
            child: _MedScanFAB(
              pressed: _fabPressed,
              onTap: _openScan,
              onPressDown: () {
                HapticEngine.selection();
                setState(() => _fabPressed = true);
              },
              onPressUp: () => setState(() => _fabPressed = false),
            ),
          ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
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
            AnalyticsService.logScreenView(['Home', 'Reminders', 'Health', 'Circle'][index]);
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
                AnimatedContainer(
                  duration: 300.ms,
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? L.text.withValues(alpha: 0.06) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: selected ? L.text : L.sub.withValues(alpha: 0.3),
                  ),
                ),
                if (cnt > 0)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: L.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: L.card, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 9,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? L.text : L.sub.withValues(alpha: 0.3),
                letterSpacing: -0.1,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// MED SCAN FAB — Premium Island Style
// ══════════════════════════════════════════════
class _MedScanFAB extends StatelessWidget {
  final bool pressed;
  final VoidCallback onTap;
  final VoidCallback onPressDown;
  final VoidCallback onPressUp;

  const _MedScanFAB({
    required this.pressed,
    required this.onTap,
    required this.onPressDown,
    required this.onPressUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onTapDown: (_) => onPressDown(),
      onTapUp: (_) => onPressUp(),
      onTapCancel: onPressUp,
      child: AnimatedScale(
        scale: pressed ? 0.90 : 1.0,
        duration: 150.ms,
        curve: Curves.easeOutCubic,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.document_scanner_rounded, color: Colors.white, size: 24),
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
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: L.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_rounded, size: 16, color: L.error),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Running low',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: L.error,
                    fontSize: 13,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  meds.length > 1
                      ? '${meds.length} medicines need refill'
                      : '$firstName needs a refill',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: L.text.withValues(alpha: 0.8),
                    height: 1.2,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.close_rounded, size: 16, color: L.sub.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }
}
