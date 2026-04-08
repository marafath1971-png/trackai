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
import '../widgets/modals/dose_celebration_modal.dart';

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

    // Handle celebratory triggers
    context.read<AppState>().addListener(_handleCelebration);
  }

  void _handleCelebration() {
    final state = context.read<AppState>();
    final medName = state.pendingCelebrationMedName;
    if (medName != null) {
      state.clearCelebration();
      DoseCelebrationModal.show(context, medName);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<AppState>().removeListener(_handleCelebration);
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
                              begin: const Offset(0, 0.02),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
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
                        onDismiss: () {
                          HapticEngine.medium();
                          context.read<AppState>().dismissLowStockBanner();
                        },
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
    final isDark = context.select<AppState, bool>((s) => s.darkMode);
    const labels = ['Home', 'Alarms', 'Health', 'Circle'];
    const activeIcons = [Icons.home_rounded, Icons.notifications_rounded, Icons.bar_chart_rounded, Icons.people_rounded];
    const inactiveIcons = [Icons.home_outlined, Icons.notifications_outlined, Icons.bar_chart_outlined, Icons.people_outline_rounded];
    final badges = [0, unseenAlerts, 0, 0];

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Nav Pill ──
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF1C1C1E) : Colors.white).withValues(alpha: isDark ? 0.88 : 0.95),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: L.border.withValues(alpha: isDark ? 0.12 : 0.07),
                      width: 0.5,
                    ),
                    boxShadow: AppShadows.navBar,
                  ),
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final itemW = constraints.maxWidth / 4;
                      return Stack(
                        children: [
                          // Animated sliding background pill
                          AnimatedPositioned(
                            duration: 280.ms,
                            curve: Curves.easeOutCubic,
                            left: _tab * itemW + (itemW - 44) / 2,
                            top: (68 - 38) / 2,
                            child: Container(
                              width: 44,
                              height: 38,
                              decoration: BoxDecoration(
                                color: L.text.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          // Nav items
                          Row(
                            children: List.generate(4, (i) => _buildNavItem(
                              i, activeIcons[i], inactiveIcons[i],
                              labels[i], L, badges[i],
                            )),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── Detached FAB — right side, slightly raised ──
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _MedScanFAB(
              pressed: _fabPressed,
              onTap: _openScan,
              onPressDown: () {
                HapticEngine.selection();
                setState(() => _fabPressed = true);
              },
              onPressUp: () => setState(() => _fabPressed = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon,
      String label, AppThemeColors L, int cnt) {
    final selected = _tab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_tab != index) {
            HapticEngine.selection();
            setState(() => _tab = index);
            AnalyticsService.logScreenView(
                ['Home', 'Reminders', 'Health', 'Circle'][index]);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: selected ? 1.0 : 0.95,
          duration: 200.ms,
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: 180.ms,
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Icon(
                      selected ? activeIcon : inactiveIcon,
                      key: ValueKey(selected),
                      size: 22,
                      color: selected ? L.text : L.sub.withValues(alpha: 0.35),
                    ),
                  ),
                  if (cnt > 0)
                    Positioned(
                      top: -3,
                      right: -6,
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
              const SizedBox(height: 4),
              AnimatedOpacity(
                duration: 180.ms,
                opacity: selected ? 1.0 : 0.0,
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: L.text,
                    fontSize: 9,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
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
        scale: pressed ? 0.88 : 1.0,
        duration: 150.ms,
        curve: Curves.easeOutCubic,
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            gradient: AppGradients.main,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Text('✨', style: TextStyle(fontSize: 28)),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 3.seconds, color: Colors.white.withValues(alpha: 0.10)),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: L.border.withValues(alpha: 0.08), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: L.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('📦', style: TextStyle(fontSize: 14))),
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
            child: const Text('✕', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey)),
          ),
          ),
        ],
      ),
    );
  }
}
