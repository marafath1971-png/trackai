import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/shared/shared_widgets.dart';
import '../core/utils/haptic_engine.dart';
import 'home/home_tab.dart';
import 'home/widgets/streak_modal.dart';
import 'scan/scan_tab.dart';
import 'dashboard/dashboard_tab.dart';
import 'family/family_tab.dart';
import 'alarms/alarms_tab.dart';
import 'settings/global_settings_screen.dart';
import 'security/lock_screen.dart';
import '../services/analytics_service.dart';
import '../widgets/modals/dose_celebration_modal.dart';
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

    // Handle celebratory triggers
    context.read<AppState>().addListener(_handleCelebration);
  }

  void _handleCelebration() async {
    final state = context.read<AppState>();

    // First Priority: Streak Milestones
    final milestone = state.pendingMilestoneAnimation;
    if (milestone != null) {
      state.clearMilestone();
      HapticEngine.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) StreakModal.show(context, state);
      return;
    }

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
    final unseenAlerts =
        context.select<AppState, int>((s) => s.unseenAlertsCount);
    final lowMeds =
        context.select<AppState, List<Medicine>>((s) => s.getLowMeds());
    final isLocked = context.select<AppState, bool>((s) => s.isLocked);
    final toast = context.select<AppState, String?>((s) => s.toast);
    final toastType = context.select<AppState, String?>((s) => s.toastType);
    final bannerDismissed =
        context.select<AppState, bool>((s) => s.lowStockBannerDismissed);
    final isSyncing = context.select<AppState, bool>((s) => s.isMutating);
    final lastSynced =
        context.select<AppState, DateTime?>((s) => s.lastSyncedAt);

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: isLocked
          ? const LockScreen()
          : Scaffold(
              backgroundColor: L.meshBg,
              resizeToAvoidBottomInset: true,
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
                    Positioned.fill(
                      child: ScanTab(
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
                        onManualAdd: () => setState(() => _showScan = false),
                      )
                          .animate()
                          .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                          .scale(
                            begin: const Offset(0.94, 0.94),
                            curve: Curves.easeOutBack,
                          ),
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
                      ).animate().fadeIn(duration: 500.ms).slideY(
                          begin: -0.2, end: 0, curve: Curves.easeOutBack),
                    ),

                  // ── Sync indicator ──
                  Positioned(
                    bottom: 110 + bottomPadding,
                    right: 20,
                    child: SyncStatusBanner(
                            isSyncing: isSyncing, lastSynced: lastSynced)
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
      case 1:
        return const DashboardTab();
      case 2:
        return const AlarmsTab();
      case 3:
        return const FamilyTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomIsland(AppThemeColors L, int unseenAlerts) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = context.select<AppState, bool>((s) => s.darkMode);
    const labels = ['Home', 'Analytics', 'Alarms', 'Family'];
    const activeIcons = [
      Icons.home_filled,
      Icons.bar_chart_rounded,
      Icons.alarm_on_rounded,
      Icons.group_rounded
    ];
    const inactiveIcons = [
      Icons.home_outlined,
      Icons.bar_chart_outlined,
      Icons.alarm_outlined,
      Icons.group_outlined
    ];
    final badges = [0, 0, 0, unseenAlerts];

    return Container(
      height: 64 + bottomPadding,
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? L.meshBg : Colors.white,
        border: Border(
          top: BorderSide(
            color: L.border.withValues(alpha: isDark ? 0.12 : 0.05),
            width: 0.5,
          ),
        ),
      ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Nav Items ──
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      4,
                      (i) => _buildNavItem(
                        i,
                        activeIcons[i],
                        inactiveIcons[i],
                        labels[i],
                        L,
                        badges[i],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // ── Integrated FAB (Elevated) ──
                Transform.translate(
                  offset: const Offset(0, -42),
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
                ['Home', 'Analytics', 'Alarms', 'Family'][index]);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..scale(selected ? 1.05 : 1.0)
            ..translate(0.0, selected ? -2.0 : 0.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  selected ? activeIcon : inactiveIcon,
                  size: 24,
                  color: selected ? L.text : L.sub.withValues(alpha: 0.4),
                ),
                if (cnt > 0)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
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
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: selected ? L.text : L.sub.withValues(alpha: 0.4),
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
        scale: pressed ? 0.9 : 1.0,
        duration: 150.ms,
        curve: Curves.easeOutCubic,
        child: Container(
          width: 68,
          height: 68,
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1E),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .shimmer(duration: 2500.ms, color: Colors.white24)
         .scaleXY(end: 1.05, duration: 1500.ms, curve: Curves.easeInOutSine),
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
  const LowStockBanner(
      {super.key, required this.meds, required this.onDismiss});

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
            child:
                const Center(child: Text('📦', style: TextStyle(fontSize: 14))),
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
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Text('✕',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}
