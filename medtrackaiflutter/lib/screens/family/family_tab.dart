import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../services/auth_service.dart';
import '../../core/utils/haptic_engine.dart';
import '../../widgets/shared/shared_widgets.dart';

// Modular Widgets
import 'widgets/caregiver_widgets.dart';
import 'widgets/monitoring_widgets.dart';
import 'widgets/add_cg_flow.dart';
import 'widgets/join_as_cg_view.dart';
import 'widgets/alert_log_widgets.dart';
import 'widgets/demo_widgets.dart';
import '../../widgets/common/premium_empty_state.dart';
import '../../widgets/common/paywall_sheet.dart';
import '../../widgets/shared/shared_widgets.dart';

enum FamilyView {
  hub,
  addStep1,
  addStep2,
  addStep3,
  dashboard,
  join,
  escalation
}

class FamilyTab extends StatefulWidget {
  const FamilyTab({super.key});

  @override
  State<FamilyTab> createState() => _FamilyTabState();
}

class _FamilyTabState extends State<FamilyTab> {
  FamilyView _view = FamilyView.hub;
  Caregiver? _newCg;
  String _inviteCode = '';
  Caregiver? _dashboardCg;
  MissedAlert? _alertDetail;

  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String _relation = 'Spouse';
  String _avatar = '👩';
  int _pivot = 1; // Default to Family Circle as per reference style
  int _alertDelay = 30;
  bool _isScrolled = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 10;
    if (scrolled != _isScrolled) {
      setState(() => _isScrolled = scrolled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final L = context.L;

    Widget child;
    if (_alertDetail != null) {
      child = AlertDetailView(
          key: const ValueKey('alertDetail'),
          alert: _alertDetail!,
          onBack: () => setState(() => _alertDetail = null),
          L: L);
    } else if (_dashboardCg != null) {
      child = ProtectorInsights(
          key: const ValueKey('dashboard'),
          cg: _dashboardCg!,
          state: state,
          onBack: () => setState(() => _dashboardCg = null),
          L: L);
    } else if (_view == FamilyView.join) {
      child = JoinAsCaregiverView(
          key: const ValueKey('join'),
          state: state,
          L: L,
          onBack: () => setState(() => _view = FamilyView.hub),
          onJoined: (cg) {
            setState(() => _view = FamilyView.hub);
          });
    } else {
      switch (_view) {
        case FamilyView.addStep1:
          child = AddCgStep1(
              key: const ValueKey('add1'),
              nameCtrl: _nameCtrl,
              contactCtrl: _contactCtrl,
              relation: _relation,
              avatar: _avatar,
              alertDelay: _alertDelay,
              onRelChange: (v) => setState(() => _relation = v),
              onAvatarChange: (v) => setState(() => _avatar = v),
              onDelayChange: (v) => setState(() => _alertDelay = v),
              L: L,
              onBack: () => setState(() => _view = FamilyView.hub),
              onNext: () async {
                final s = Provider.of<AppState>(context, listen: false);
                final patientUid = AuthService.uid ?? '';
                const colors = [
                  '#111111',
                  '#1A1A1A',
                  '#222222',
                  '#2A2A2A',
                  '#333333'
                ];
                final color = colors[s.caregivers.length % colors.length];
                final cg = Caregiver(
                  id: DateTime.now().millisecondsSinceEpoch,
                  name: _nameCtrl.text.trim(),
                  relation: _relation,
                  contact: _contactCtrl.text.trim(),
                  avatar: _avatar,
                  alertDelay: _alertDelay,
                  addedAt: todayStr(),
                  color: color,
                  patientUid: patientUid,
                );
                s.addCaregiver(cg);
                final code = await s.createInvite(cg);
                setState(() {
                  _newCg = cg;
                  _inviteCode = code;
                  _view = FamilyView.addStep2;
                });
              });
          break;
        case FamilyView.addStep2:
          child = AddCgStep2(
              key: const ValueKey('add2'),
              cg: _newCg!,
              inviteCode: _inviteCode,
              L: L,
              onNext: () {
                final state = Provider.of<AppState>(context, listen: false);
                state.activateCaregiver(_newCg!.id);
                setState(() => _view = FamilyView.addStep3);
              });
          break;
        case FamilyView.addStep3:
          child = AddCgStep3(
              key: const ValueKey('add3'),
              cg: _newCg!,
              L: L,
              onDone: () {
                setState(() {
                  _view = FamilyView.hub;
                  _nameCtrl.clear();
                  _contactCtrl.clear();
                });
              });
          break;
        case FamilyView.escalation:
          child = EscalationDemoView(
              key: const ValueKey('esc'),
              L: L,
              onBack: () => setState(() => _view = FamilyView.hub));
          break;
        default:
          child = HubView(
              key: const ValueKey('hub'),
              state: state,
              L: L,
              pivot: _pivot,
              isScrolled: _isScrolled,
              scrollController: _scrollController,
              onPivotChanged: (v) => setState(() => _pivot = v),
              onAddCg: () {
                if (state.isPremium) {
                  setState(() => _view = FamilyView.addStep1);
                } else {
                  PaywallSheet.show(context);
                }
              },
              onJoin: () {
                if (state.isPremium) {
                  setState(() => _view = FamilyView.join);
                } else {
                  PaywallSheet.show(context);
                }
              },
              onDashboard: (cg) => setState(() => _dashboardCg = cg),
              onAlertDetail: (a) => setState(() => _alertDetail = a),
              onMarkSeen: () => state.markAlertsAsSeen(),
              onEscalationDemo: () {
                if (state.isPremium) {
                  setState(() => _view = FamilyView.escalation);
                } else {
                  PaywallSheet.show(context);
                }
              });
      }
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (w, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
                  .animate(anim),
          child: w,
        ),
      ),
      child: child,
    );
  }
}

class HubView extends StatelessWidget {
  final AppState state;
  final AppThemeColors L;
  final int pivot;
  final bool isScrolled;
  final ScrollController scrollController;
  final ValueChanged<int> onPivotChanged;
  final VoidCallback onAddCg, onJoin, onMarkSeen, onEscalationDemo;
  final void Function(Caregiver) onDashboard;
  final void Function(MissedAlert) onAlertDetail;

  const HubView({
    super.key,
    required this.state,
    required this.L,
    required this.pivot,
    required this.isScrolled,
    required this.scrollController,
    required this.onPivotChanged,
    required this.onAddCg,
    required this.onJoin,
    required this.onDashboard,
    required this.onAlertDetail,
    required this.onMarkSeen,
    required this.onEscalationDemo,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount =
        state.caregivers.where((c) => c.status == "active").length;
    final unseenCount = state.missedAlerts.where((a) => !a.seen).length;

    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          // ── PREMIUM HEADER BACKGROUND ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: BoxDecoration(
                color: L.bg,
                border: Border(bottom: BorderSide(color: L.border.withValues(alpha: 0.5))),
              ),
            ),
          ),

          // ── SCROLLABLE CONTENT ──
          SingleChildScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 140 + MediaQuery.of(context).padding.top),

                // ── HUB CONTENT ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Protectors Hub',
                        style: AppTypography.headlineLarge.copyWith(
                          color: L.text,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                      
                      const SizedBox(height: 20),
                      
                      // Circle Snapshot Bento (High-Fidelity)
                      Row(
                        children: [
                          Expanded(
                            child: _CircleStatBento(
                              label: 'PROTECTORS',
                              value: '$activeCount',
                              icon: Icons.shield_rounded,
                              L: L,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _CircleStatBento(
                              label: 'MONITORING',
                              value: unseenCount > 0 ? 'URGENT' : 'SECURE',
                              icon: Icons.verified_user_rounded,
                              iconColor: unseenCount > 0 ? L.error : L.success,
                              L: L,
                              glow: unseenCount > 0,
                            ),
                          ),
                        ],
                      ).animate(delay: 200.ms).fadeIn(),

                      const SizedBox(height: 24),
                      
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: L.fill.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                _CompactPivotPill(
                                  label: 'Family',
                                  active: pivot == 1,
                                  onTap: () => onPivotChanged(1),
                                  L: L,
                                ),
                                const SizedBox(width: 4),
                                _CompactPivotPill(
                                  label: 'Care',
                                  active: pivot == 0,
                                  onTap: () => onPivotChanged(0),
                                  L: L,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      if (unseenCount > 0)
                        BouncingButton(
                          onTap: onMarkSeen,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: L.error,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(color: L.error.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_rounded, color: Colors.white, size: 24),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'URGENT MONITORING',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      Text(
                                        '$unseenCount missed medication alerts',
                                        style: AppTypography.titleMedium.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),

                      // CONTENT BASED ON PIVOT
                      if (pivot == 1) ...[
                        // FAMILY CIRCLE (Monitoring others)
                        if (state.monitoredPatients.isEmpty)
                          _buildEmptyMonitoringState(L, onJoin)
                              .animate()
                              .fadeIn(duration: 600.ms)
                        else ...[
                          ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.monitoredPatients.length,
                            itemBuilder: (context, index) {
                              final p = state.monitoredPatients[index];
                              return PatientCard(
                                patient: p,
                                state: state,
                                L: L,
                                onTap: () {
                                  onDashboard(Caregiver(
                                    id: 0,
                                    name: p['name'] ?? 'Patient',
                                    relation: p['relation'] ?? 'Family',
                                    patientUid: p['uid'],
                                    addedAt: p['addedAt'] ?? 'just now',
                                    avatar: p['avatar'] ?? '👤',
                                  ));
                                },
                              ).animate().fadeIn(
                                  delay: (100 + index * 50).ms, duration: 500.ms);
                            },
                          ),
                        ],
                      ] else ...[
                        // ACCOUNT SECURITY / MY CAREGIVERS
                        if (state.caregivers.isEmpty)
                          _buildEmptyState(L, onAddCg)
                              .animate()
                              .fadeIn(duration: 600.ms)
                        else ...[
                          ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.caregivers.length,
                            itemBuilder: (context, index) => CaregiverCard(
                              cg: state.caregivers[index],
                              state: state,
                              L: L,
                              onDashboard: () =>
                                  onDashboard(state.caregivers[index]),
                            ).animate().fadeIn(
                                delay: (100 + index * 50).ms, duration: 500.ms),
                          ),
                        ],
                      ],

                      const SizedBox(height: 32),

                      // ALERT LOG
                      if (state.missedAlerts.isNotEmpty) ...[
                        Text('Recent Activity',
                            style: AppTypography.titleLarge.copyWith(
                              color: L.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              letterSpacing: -0.3,
                            )),
                        const SizedBox(height: 14),
                        ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.missedAlerts.length,
                          itemBuilder: (context, index) => AlertLogCard(
                            alert: state.missedAlerts[index],
                            L: L,
                            onTap: () =>
                                onAlertDetail(state.missedAlerts[index]),
                          ).animate().fadeIn(
                              delay: (300 + index * 50).ms, duration: 500.ms),
                        ),
                      ],

                      const SizedBox(height: 24),
                      SimulateMissCard(L: L, onSimulate: onEscalationDemo),
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── PREMIUM HEADER ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _FamilyHeader(
              scrollOffset: scrollController.hasClients ? scrollController.offset : 0,
              L: L,
              onAdd: onAddCg,
              onJoin: onJoin,
            ),
          ),
        ],
      ),
      floatingActionButton: pivot == 1
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: FloatingActionButton.extended(
                onPressed: onAddCg,
                backgroundColor: L.text,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('Add Guardian',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
              ),
            ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildEmptyState(AppThemeColors L, VoidCallback onAddCg) {
    return PremiumEmptyState(
      title: 'No guardians found',
      subtitle:
          'Invite family or medical professionals to monitor your medication safety.',
      emoji: '🛡️',
      actionLabel: 'Invite Guardian',
      onAction: onAddCg,
    );
  }

  Widget _buildEmptyMonitoringState(AppThemeColors L, VoidCallback onJoin) {
    return PremiumEmptyState(
      title: 'Protect your family',
      subtitle:
          'Join as a caregiver to see real-time health updates for your loved ones.',
      emoji: '❤️',
      actionLabel: 'Join Circle',
      onAction: onJoin,
    );
  }
}

class _CompactPivotPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final AppThemeColors L;

  const _CompactPivotPill({
    required this.label,
    required this.active,
    required this.onTap,
    required this.L,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticEngine.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: 250.ms,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? L.text : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: active ? L.bg : L.sub.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _FamilyHeader extends StatelessWidget {
  final double scrollOffset;
  final AppThemeColors L;
  final VoidCallback onAdd, onJoin;

  const _FamilyHeader({
    required this.scrollOffset,
    required this.L,
    required this.onAdd,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final double opacity = (scrollOffset / 60).clamp(0.0, 1.0);
    final topPad = MediaQuery.of(context).padding.top;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AnimatedContainer(
          duration: 200.ms,
          padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 16),
          decoration: BoxDecoration(
            color: L.bg.withValues(alpha: opacity * 0.8),
            border: Border(
                bottom: BorderSide(
                    color: L.border.withValues(alpha: opacity * 0.08),
                    width: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FAMILY',
                      style: AppTypography.labelSmall.copyWith(
                        color: L.sub.withValues(alpha: 0.4),
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'Circle',
                      style: AppTypography.headlineMedium.copyWith(
                        color: L.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                        height: 1.1,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ],
                ),
              ),
              BouncingButton(
                onTap: onJoin,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: L.fill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                      child: Icon(Icons.qr_code_scanner_rounded,
                          size: 20, color: L.text)),
                ),
              ),
              const SizedBox(width: 10),
              BouncingButton(
                onTap: onAdd,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: L.text,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: L.text.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Center(
                      child: Icon(Icons.add_rounded, color: L.bg, size: 24)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleStatBento extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? iconColor;
  final AppThemeColors L;
  final bool glow;
  const _CircleStatBento({required this.label, required this.value, required this.icon, this.iconColor, required this.L, this.glow = false});
  @override
  Widget build(BuildContext context) => SquircleCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (iconColor ?? L.primary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: iconColor ?? L.primary),
            ),
            const SizedBox(width: 10),
            Text(label, style: AppTypography.labelSmall.copyWith(
              color: L.sub.withValues(alpha: 0.4), 
              fontWeight: FontWeight.w900, 
              fontSize: 9, 
              letterSpacing: 1.0)),
          ],
        ),
        const SizedBox(height: 16),
        Text(value, style: AppTypography.displaySmall.copyWith(
          color: L.text, 
          fontWeight: FontWeight.w900, 
          fontSize: 22, 
          letterSpacing: -0.5,
          height: 1.0,
        )),
      ],
    ),
  );
}
