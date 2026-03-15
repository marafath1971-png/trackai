import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../services/auth_service.dart';

// Modular Widgets
import 'widgets/caregiver_widgets.dart';
import 'widgets/monitoring_widgets.dart';
import 'widgets/add_cg_flow.dart';
import 'widgets/join_as_cg_view.dart';
import 'widgets/alert_log_widgets.dart';
import 'widgets/demo_widgets.dart';

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
  Caregiver? _dashboardCg;
  MissedAlert? _alertDetail;
  
  // Add form controllers and state
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String _relation = 'Spouse';
  String _avatar = '👩';
  int _pivot = 0; // 0: Account Security, 1: Family Circle
  int _alertDelay = 30;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
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
               SnackBar(content: Text('Joined as caregiver for ${cg.name}!'))
             );
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
                  '#6366F1',
                  '#10B981',
                  '#F59E0B',
                  '#F43F5E',
                  '#8B5CF6'
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
                await s.createInvite(cg);
                setState(() {
                  _newCg = cg;
                  _view = FamilyView.addStep2;
                });
              });
          break;
        case FamilyView.addStep2:
          child = AddCgStep2(
              key: const ValueKey('add2'),
              cg: _newCg!,
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
              onPivotChanged: (v) => setState(() => _pivot = v),
              onAddCg: () => setState(() => _view = FamilyView.addStep1),
              onJoin: () => setState(() => _view = FamilyView.join),
              onDashboard: (cg) => setState(() => _dashboardCg = cg),
              onAlertDetail: (a) => setState(() => _alertDetail = a),
              onMarkSeen: () => state.markAlertsAsSeen(),
              onEscalationDemo: () =>
                  setState(() => _view = FamilyView.escalation));
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
  final ValueChanged<int> onPivotChanged;
  final VoidCallback onAddCg, onJoin, onMarkSeen, onEscalationDemo;
  final void Function(Caregiver) onDashboard;
  final void Function(MissedAlert) onAlertDetail;
  
  const HubView({
    super.key,
    required this.state,
    required this.L,
    required this.pivot,
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
    final activeCount = state.caregivers.where((c) => c.status == "active").length;
    final pendingCount = state.caregivers.where((c) => c.status == "pending").length;
    final unseenCount = state.missedAlerts.where((a) => !a.seen).length;

    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          Scrollbar(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              child: Column(
                children: [
                SizedBox(height: 140 + MediaQuery.of(context).padding.top),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      if (unseenCount > 0)
                        GestureDetector(
                          onTap: onMarkSeen,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                                color: L.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: L.red.withValues(alpha: 0.3))),
                            child: Row(
                              children: [
                                Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(color: L.red, shape: BoxShape.circle)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                      '$unseenCount new missed-dose alert${unseenCount > 1 ? "s" : ""}',
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: L.red)),
                                ),
                                Icon(Icons.chevron_right_rounded, color: L.red, size: 20),
                              ],
                            ),
                          ),
                        ),
                      
                      // PIVOT SELECTOR
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: L.card,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: L.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: PivotTab(
                                label: 'Account Security',
                                active: pivot == 0,
                                onTap: () {
                                  HapticFeedback.lightImpact();
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
                                  HapticFeedback.lightImpact();
                                  onPivotChanged(1);
                                },
                                L: L,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade(delay: 100.ms).slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 24),

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
                                      color: L.green).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: FamStatJSX(
                                      emoji: '⏳',
                                      label: 'Pending',
                                      value: pendingCount,
                                      color: L.amber).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: FamStatJSX(
                                      emoji: '⚠️',
                                      label: 'Alerts',
                                      value: state.missedAlerts.length,
                                      color: L.red).animate().fade(delay: 500.ms).slideY(begin: 0.2, end: 0)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('MY CAREGIVERS',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: L.sub,
                                        letterSpacing: 1.0)),
                                const SizedBox(height: 16),
                                ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: state.caregivers.length,
                                  itemBuilder: (context, index) => CaregiverCard(
                                    cg: state.caregivers[index],
                                    state: state,
                                    L: L,
                                    onDashboard: () => onDashboard(state.caregivers[index]),
                                  ).animate().fade(delay: (600 + index * 50).ms).slideY(begin: 0.1, end: 0),
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
                                Text('PROTECTING (${state.monitoredPatients.length})',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: L.sub,
                                        letterSpacing: 1.0)),
                                const SizedBox(height: 16),
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
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: L.sub,
                                    letterSpacing: 1.0)),
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
                            onTap: () => onAlertDetail(state.missedAlerts[index]),
                          ).animate().fade(delay: (400 + index * 50).ms).slideY(begin: 0.1, end: 0),
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

          // --- FLOATING HEADER ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 60 + MediaQuery.of(context).padding.top, 24, 20),
              decoration: BoxDecoration(
                color: L.bg,
                border: Border(
                  bottom: BorderSide(color: L.border, width: 1.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Family Circle',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: L.text,
                              letterSpacing: -1.2)),
                      const SizedBox(height: 4),
                      Text(
                        activeCount > 0
                            ? '$activeCount caregivers monitoring you'
                            : 'Protect your health together',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: L.sub,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      HeaderBtn(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          onJoin();
                        },
                        label: 'Join',
                        icon: Icons.qr_code_scanner_rounded,
                        color: L.purple,
                        bg: L.purple.withValues(alpha: 0.1),
                      ),
                      const SizedBox(width: 10),
                      HeaderBtn(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          onAddCg();
                        },
                        label: 'Add',
                        icon: Icons.add_rounded,
                        color: Colors.white,
                        bg: L.card2,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppThemeColors L, VoidCallback onAddCg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: L.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No caregivers yet',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: L.text)),
          const SizedBox(height: 8),
          Text(
              'Add your first caregiver to start monitoring your medication adherence and get emergency alerts.',
              style:
                  TextStyle(fontFamily: 'Inter', fontSize: 14, color: L.sub, height: 1.5)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onAddCg,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                  color: L.card2, borderRadius: BorderRadius.circular(24)),
              child: const Text('Add Caregiver',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMonitoringState(AppThemeColors L, VoidCallback onJoin) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: L.purple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_outlined, color: L.purple, size: 40),
          ),
          const SizedBox(height: 20),
          Text('No Protected People',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: L.text)),
          const SizedBox(height: 8),
          Text(
            'Join as a caregiver to monitor your family members\' health in real-time.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: L.sub,
                height: 1.5),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onJoin,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: L.purple,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text('Join as Caregiver',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
