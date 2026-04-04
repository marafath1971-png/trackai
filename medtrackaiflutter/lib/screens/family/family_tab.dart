import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/mesh_gradient.dart';
import '../../core/utils/haptic_engine.dart';

// Modular Widgets
import 'widgets/caregiver_widgets.dart';
import 'widgets/monitoring_widgets.dart';
import 'widgets/add_cg_flow.dart';
import 'widgets/join_as_cg_view.dart';
import 'widgets/alert_log_widgets.dart';
import 'widgets/demo_widgets.dart';
import '../../widgets/common/premium_empty_state.dart';
import '../../widgets/common/paywall_sheet.dart';
import '../../widgets/common/bouncing_button.dart';

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
                SizedBox(height: 150 + MediaQuery.of(context).padding.top),

                // ── HEADER CONTENT ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'FAMILY',
                            style: AppTypography.labelSmall.copyWith(
                                color: L.sub.withValues(alpha: 0.5),
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w900,
                                fontSize: 10),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text('/', style: TextStyle(color: L.sub.withValues(alpha: 0.3), fontSize: 10)),
                          ),
                          Text(
                            'CARE CIRCLE',
                            style: AppTypography.labelSmall.copyWith(
                                color: L.primary,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w900,
                                fontSize: 10),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms),
                      const SizedBox(height: 8),
                      Text(
                        'Protectors Hub',
                        style: AppTypography.displayLarge.copyWith(
                          color: L.text,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                      
                      const SizedBox(height: 16),
                      
                      // Circle Snapshot Bento (Cal AI Stats)
                      Row(
                        children: [
                          Expanded(
                            child: _CircleStatBento(
                              label: 'Protectors',
                              value: '$activeCount',
                              icon: Icons.shield_rounded,
                              L: L,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _CircleStatBento(
                              label: 'Monitoring',
                              value: unseenCount > 0 ? 'Urgent' : 'Secure',
                              icon: Icons.check_circle_rounded,
                              iconColor: unseenCount > 0 ? L.error : L.success,
                              L: L,
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
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: L.border.withValues(alpha: 0.1), width: 1.0),
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
                      ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.05, end: 0),
                      const SizedBox(height: 18),

                      if (unseenCount > 0)
                        BouncingButton(
                          onTap: onMarkSeen,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: L.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: L.error.withValues(alpha: 0.3),
                                  width: 1.0),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: L.error, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                      '$unseenCount urgent monitoring alerts',
                                      style: AppTypography.labelLarge.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: L.error)),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded,
                                    color: L.error, size: 14),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? L.text : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [BoxShadow(color: L.text.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: active ? L.card : L.sub.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: active ? FontWeight.w900 : FontWeight.w600,
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

    return AnimatedContainer(
      duration: 200.ms,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: L.bg.withValues(alpha: opacity * 0.95),
        border: Border(
            bottom: BorderSide(
                color: L.border.withValues(alpha: opacity * 0.4),
                width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Family Circle',
                    style: AppTypography.headlineLarge.copyWith(
                      color: L.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      letterSpacing: -1.0,
                    ),
                  ),
                  Text(
                    'Health is better shared',
                    style: AppTypography.bodySmall.copyWith(
                      color: L.sub,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onJoin,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: L.fill.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: L.border.withValues(alpha: 0.3)),
                ),
                child: Center(
                    child: Icon(Icons.qr_code_scanner_rounded,
                        size: 20, color: L.text)),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: L.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                    child: Icon(Icons.add_rounded, color: Colors.white, size: 22)),
              ),
            ),
          ],
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
  const _CircleStatBento({required this.label, required this.value, required this.icon, this.iconColor, required this.L});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: L.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: L.border.withValues(alpha: 0.5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor ?? L.sub.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(label, style: AppTypography.labelSmall.copyWith(color: L.sub, fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 12),
        Text(value, style: AppTypography.titleLarge.copyWith(color: L.text, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
      ],
    ),
  );
}
