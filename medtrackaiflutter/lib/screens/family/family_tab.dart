import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../services/auth_service.dart';
import '../../core/utils/haptic_engine.dart';

// Modular Widgets
import 'widgets/caregiver_widgets.dart';
import 'widgets/monitoring_widgets.dart';
import 'widgets/add_cg_flow.dart';
import 'widgets/join_as_cg_view.dart';
import 'widgets/alert_log_widgets.dart';
import 'widgets/demo_widgets.dart';
import '../../widgets/common/unified_header.dart';
import '../../widgets/common/premium_empty_state.dart';
import '../../widgets/common/paywall_sheet.dart';
import '../../widgets/common/bouncing_button.dart';

// ══════════════════════════════════════════════
// FAMILY HUB TAB
// ══════════════════════════════════════════════

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

  // Add form controllers and state
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String _relation = 'Spouse';
  String _avatar = '👩';
  int _pivot = 0; // 0: Account Security, 1: Family Circle
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
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Joined as caregiver for ${cg.name}!')));
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
    final pendingCount =
        state.caregivers.where((c) => c.status == "pending").length;
    final unseenCount = state.missedAlerts.where((a) => !a.seen).length;

    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          Scrollbar(
            controller: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              child: Column(
                children: [
                  SizedBox(height: 110 + MediaQuery.of(context).padding.top),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding),
                    child: Column(
                      children: [
                        if (unseenCount > 0)
                          BouncingButton(
                            onTap: onMarkSeen,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: L.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: L.error.withValues(alpha: 0.5),
                                    width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                          color: L.error,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: L.error
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            )
                                          ])),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                        '$unseenCount new missed-dose alert${unseenCount > 1 ? "s" : ""}',
                                        style: AppTypography.labelLarge
                                            .copyWith(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: L.error,
                                                letterSpacing: 0.2)),
                                  ),
                                  Icon(Icons.chevron_right_rounded,
                                      color: L.error, size: 22),
                                ],
                              ),
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .shimmer(
                                  duration: 2.seconds,
                                  color: L.error.withValues(alpha: 0.1)),

                        // PIVOT SELECTOR
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: L.card,
                            borderRadius: BorderRadius.circular(AppRadius.l),
                            border: Border.all(color: L.border, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: PivotTab(
                                  label: 'Account Security',
                                  active: pivot == 0,
                                  onTap: () {
                                    HapticEngine.selection();
                                    onPivotChanged(0);
                                  },
                                  L: L,
                                ),
                              ),
                              Expanded(
                                child: PivotTab(
                                  label: 'Family Circle',
                                  active: pivot == 1,
                                  onTap: () {
                                    HapticEngine.selection();
                                    onPivotChanged(1);
                                  },
                                  L: L,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fade(delay: 100.ms)
                            .slideY(begin: 0.1, end: 0),

                        const SizedBox(height: AppSpacing.l),

                        if (pivot == 0) ...[
                          if (state.caregivers.isEmpty)
                            _buildEmptyState(L, onAddCg)
                          else ...[
                            Row(
                              children: [
                                Expanded(
                                    child: FamStatJSX(
                                            emoji: '👥',
                                            label: 'Active',
                                            value: activeCount,
                                            color: L.secondary)
                                        .animate()
                                        .fade(delay: 300.ms)
                                        .slideY(begin: 0.2, end: 0)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: FamStatJSX(
                                            emoji: '⏳',
                                            label: 'Pending',
                                            value: pendingCount,
                                            color: L.warning)
                                        .animate()
                                        .fade(delay: 400.ms)
                                        .slideY(begin: 0.2, end: 0)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: FamStatJSX(
                                            emoji: '⚠️',
                                            label: 'Alerts',
                                            value: state.missedAlerts.length,
                                            color: L.error)
                                        .animate()
                                        .fade(delay: 500.ms)
                                        .slideY(begin: 0.2, end: 0)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('MY CAREGIVERS',
                                      style: AppTypography.labelLarge.copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: L.sub,
                                          letterSpacing: 1.5)),
                                  const SizedBox(height: 16),
                                  ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: state.caregivers.length,
                                    itemBuilder: (context, index) =>
                                        CaregiverCard(
                                      cg: state.caregivers[index],
                                      state: state,
                                      L: L,
                                      onDashboard: () =>
                                          onDashboard(state.caregivers[index]),
                                    )
                                            .animate()
                                            .fade(delay: (600 + index * 50).ms)
                                            .slideY(begin: 0.1, end: 0),
                                  ),
                                ]),
                          ],
                        ] else ...[
                          if (state.monitoredPatients.isEmpty)
                            _buildEmptyMonitoringState(L, onJoin)
                          else ...[
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'PROTECTING (${state.monitoredPatients.length})',
                                      style: AppTypography.labelLarge.copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: L.sub,
                                          letterSpacing: 1.5)),
                                  const SizedBox(height: 16),
                                  ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
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
                                      );
                                    },
                                  ),
                                ]),
                          ],
                        ],
                        const SizedBox(height: 32),

                        // ALERT LOG
                        if (state.missedAlerts.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ALERT LOG',
                                  style: AppTypography.labelLarge.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: L.sub,
                                      letterSpacing: 1.5)),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                            )
                                .animate()
                                .fade(delay: (400 + index * 50).ms)
                                .slideY(begin: 0.1, end: 0),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SimulateMissCard(L: L, onSimulate: onEscalationDemo),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: UnifiedHeader(
              isScrolled: isScrolled,
              showProBadge: !state.isPremium,
              title: 'Family Circle',
              subtitle: activeCount > 0
                  ? '$activeCount caregivers monitoring you'
                  : 'Protect your health together',
              actions: [
                HeaderActionBtn(
                  onTap: onJoin,
                  child: Icon(Icons.qr_code_scanner_rounded,
                      color: L.text, size: 18),
                ),
                HeaderActionBtn(
                  onTap: onAddCg,
                  backgroundColor: L.text,
                  child: Icon(Icons.add_rounded, color: L.bg, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppThemeColors L, VoidCallback onAddCg) {
    return PremiumEmptyState(
      title: 'No caregivers yet',
      subtitle:
          'Add your first caregiver to start monitoring your medication adherence and get emergency alerts.',
      emoji: '👥',
      actionLabel: 'Add Caregiver',
      onAction: onAddCg,
    );
  }

  Widget _buildEmptyMonitoringState(AppThemeColors L, VoidCallback onJoin) {
    return PremiumEmptyState(
      title: 'No Protected People',
      subtitle:
          'Join as a caregiver to monitor your family members\' health in real-time.',
      icon: Icons.shield_outlined,
      actionLabel: 'Join as Caregiver',
      onAction: onJoin,
    );
  }
}
