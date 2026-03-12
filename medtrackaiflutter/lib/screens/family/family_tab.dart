import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/app_state.dart';
import '../../models/models.dart';
import '../../models/constants.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../core/utils/date_formatter.dart';
import '../../services/auth_service.dart';

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
  // Add form
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String _relation = 'Spouse';
  String _avatar = '👩';
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
      child = _AlertDetailView(
          key: const ValueKey('alertDetail'),
          alert: _alertDetail!,
          onBack: () => setState(() => _alertDetail = null),
          L: L);
    } else if (_dashboardCg != null) {
      child = _ProtectorInsights(
          key: const ValueKey('dashboard'),
          cg: _dashboardCg!,
          state: state,
          onBack: () => setState(() => _dashboardCg = null),
          L: L);
    } else if (_view == FamilyView.join) {
      child = _JoinAsCaregiverView(
          key: const ValueKey('join'),
          onBack: () => setState(() => _view = FamilyView.hub),
          L: L);
    } else {
      switch (_view) {
        case FamilyView.addStep1:
          child = _AddCgStep1(
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
                // Write invite to Firestore so anyone with the code can join.
                await s.createInvite(cg);
                setState(() {
                  _newCg = cg;
                  _view = FamilyView.addStep2;
                });
              });
          break;
        case FamilyView.addStep2:
          child = _AddCgStep2(
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
          child = _AddCgStep3(
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
          child = _EscalationDemoView(
              key: const ValueKey('esc'),
              L: L,
              onBack: () => setState(() => _view = FamilyView.hub));
          break;
        default:
          child = _HubView(
              key: const ValueKey('hub'),
              state: state,
              L: L,
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

// ── Hub View ──────────────────────────────────────────────────────────
class _HubView extends StatelessWidget {
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onAddCg, onJoin, onMarkSeen, onEscalationDemo;
  final void Function(Caregiver) onDashboard;
  final void Function(MissedAlert) onAlertDetail;
  const _HubView(
      {super.key,
      required this.state,
      required this.L,
      required this.onAddCg,
      required this.onJoin,
      required this.onDashboard,
      required this.onAlertDetail,
      required this.onMarkSeen,
      required this.onEscalationDemo});

  @override
  Widget build(BuildContext context) {
    final activeCount =
        state.caregivers.where((c) => c.status == "active").length;
    final pendingCount =
        state.caregivers.where((c) => c.status == "pending").length;
    final unseenCount = state.missedAlerts.where((a) => !a.seen).length;

    return Scaffold(
      backgroundColor: L.bg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20 + 36,
                  left: 20,
                  right: 20,
                  bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Family',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: L.text,
                                    letterSpacing: -0.5)),
                            const SizedBox(height: 4),
                            Text(
                              activeCount > 0
                                  ? '$activeCount caregiver${activeCount > 1 ? "s" : ""} monitoring you'
                                  : 'Add a caregiver to get started',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: L.sub,
                                  fontWeight: FontWeight.w500),
                            ),
                            if (pendingCount > 0)
                              Text('· $pendingCount pending QR',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      color: L.sub,
                                      fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _HeaderBtn(
                            onTap: onJoin,
                            label: 'Join',
                            icon: Icons.camera_alt_rounded,
                            color: L.purple,
                            bg: L.purple.withValues(alpha: 0.1),
                          ),
                          const SizedBox(width: 8),
                          _HeaderBtn(
                            onTap: onAddCg,
                            label: 'Add',
                            icon: Icons.add_rounded,
                            color: Colors.white,
                            bg: L.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (unseenCount > 0)
                    GestureDetector(
                      onTap: onMarkSeen,
                      child: Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: L.redLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFCA5A5))),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: L.red, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(
                                '$unseenCount new missed-dose alert${unseenCount > 1 ? "s" : ""}',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: L.red)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Empty state
            if (state.caregivers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _HubView._buildEmptyState(L, onAddCg),
              )
            else ...[
              // Stats Grid (3-column)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                        child: _FamStatJSX(
                            emoji: '👥',
                            label: 'Active',
                            value: activeCount,
                            color: L.green)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _FamStatJSX(
                            emoji: '⏳',
                            label: 'Pending',
                            value: pendingCount,
                            color: L.amber)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _FamStatJSX(
                            emoji: '⚠️',
                            label: 'Alerts',
                            value: state.missedAlerts.length,
                            color: L.red)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Caregivers List Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CAREGIVERS',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: L.sub,
                              letterSpacing: 1.0)),
                      const SizedBox(height: 16),
                    ]),
              ),

              // Caregivers ListView
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.caregivers.length,
                  itemBuilder: (context, index) => _CaregiverCard(
                    cg: state.caregivers[index],
                    state: state,
                    L: L,
                    onDashboard: () => onDashboard(state.caregivers[index]),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Alert Log / Security Ledger
            if (state.missedAlerts.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
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
              ),
              const SizedBox(height: 16),
              // Alert Log ListView
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.missedAlerts.length,
                  itemBuilder: (context, index) => _AlertLogCard(
                    alert: state.missedAlerts[index],
                    L: L,
                    onTap: () => onAlertDetail(state.missedAlerts[index]),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // This is a placeholder for _buildEmptyState.
  // The actual implementation would depend on its original definition.
  // Assuming it's a static method or a separate widget.
  static Widget _buildEmptyState(AppThemeColors L, VoidCallback onAddCg) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: L.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No caregivers yet',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: L.text)),
          const SizedBox(height: 8),
          Text(
              'Add your first caregiver to start monitoring your medication adherence.',
              style:
                  TextStyle(fontFamily: 'Inter', fontSize: 13, color: L.sub)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onAddCg,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                  color: L.blue, borderRadius: BorderRadius.circular(10)),
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
}

class _HeaderBtn extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final Color color, bg;
  const _HeaderBtn(
      {required this.onTap,
      required this.label,
      required this.icon,
      required this.color,
      required this.bg});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ]),
        ),
      );
}

class _FamStatJSX extends StatelessWidget {
  final String emoji, label;
  final int value;
  final Color color;
  const _FamStatJSX(
      {required this.emoji,
      required this.label,
      required this.value,
      required this.color});
  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1))
          ]),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 6),
        Text('$value',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
                height: 1.0)),
        const SizedBox(height: 2),
        Text(label.toUpperCase(),
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: L.sub,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.04)),
      ]),
    );
  }
}


class _SimulateMissCard extends StatefulWidget {
  final AppThemeColors L;
  final VoidCallback onSimulate;
  const _SimulateMissCard({required this.L, required this.onSimulate});
  @override
  State<_SimulateMissCard> createState() => _SimulateMissCardState();
}

class _SimulateMissCardState extends State<_SimulateMissCard> {
  bool _simulating = false;
  @override
  Widget build(BuildContext context) {
    final L = widget.L;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1))
          ]),
      child: Column(children: [
        Row(children: [
          Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(10)),
              child: Center(
                  child: Icon(Icons.auto_awesome_rounded,
                      size: 15, color: L.purple))),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Test the alert system',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: L.text)),
                Text('Simulate a missed dose to preview the full escalation',
                    style: TextStyle(
                        fontFamily: 'Inter', fontSize: 12, color: L.sub)),
              ])),
        ]),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _simulating
              ? null
              : () async {
                  setState(() => _simulating = true);
                  await Future.delayed(const Duration(seconds: 1));
                  widget.onSimulate();
                  if (mounted) setState(() => _simulating = false);
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: _simulating
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (_simulating) ...[
                const Text('⚡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text('Sending escalation...',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: L.green)),
              ] else ...[
                Icon(Icons.notifications_active_rounded,
                    size: 14, color: L.purple),
                const SizedBox(width: 8),
                Text('Simulate Missed Dose',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: L.purple)),
              ]
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Caregiver Card ────────────────────────────────────────────────────
class _CaregiverCard extends StatefulWidget {
  final Caregiver cg;
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onDashboard;
  const _CaregiverCard(
      {required this.cg,
      required this.state,
      required this.L,
      required this.onDashboard});
  @override
  State<_CaregiverCard> createState() => _CaregiverCardState();
}

class _CaregiverCardState extends State<_CaregiverCard> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final cg = widget.cg;
    final L = widget.L;
    final isActive = cg.status == 'active';
    final isPending = cg.status == 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isActive ? L.green.withValues(alpha: 0.45) : L.border,
              width: 1.5)),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      color: hexToColor(cg.color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: hexToColor(cg.color).withValues(alpha: 0.25),
                          width: 2)),
                  child: Center(
                      child: Text(cg.avatar,
                          style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        Flexible(
                            child: Text(cg.name,
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: L.text),
                                overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: isActive
                                  ? L.greenLight
                                  : isPending
                                      ? const Color(0xFFFEF3C7)
                                      : L.fill,
                              borderRadius: BorderRadius.circular(99)),
                          child: Text(
                              isActive
                                  ? 'ACTIVE'
                                  : isPending
                                      ? 'AWAITING'
                                      : 'INACTIVE',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: isActive
                                      ? L.green
                                      : isPending
                                          ? L.amber
                                          : L.sub,
                                  letterSpacing: 0.04)),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text(
                          '${cg.relation}${cg.contact.isNotEmpty ? " · ${cg.contact}" : ""}',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: L.sub,
                              fontWeight: FontWeight.w500)),
                    ])),
                AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.chevron_right_rounded,
                        color: L.sub, size: 20)),
              ])),
        ),
        if (_expanded) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: [
              if (isPending) ...[
                const SizedBox(height: 14),
                Row(children: [
                  Container(
                    width: 70,
                    height: 70,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: L.border)),
                    child: QrImageView(data: cg.inviteUrl, size: 60),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('CODE',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: L.sub,
                                letterSpacing: 0.04)),
                        Text(cg.inviteCode,
                            style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: L.text,
                                letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        Text('${cg.name} scans this to join',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: L.sub)),
                      ])),
                ]),
              ],
              const SizedBox(height: 16),
              Row(children: [
                if (isActive) ...[
                  Expanded(
                      child: _CardBtnJSX(
                          label: 'View Dashboard',
                          icon: Icons.bar_chart_rounded,
                          onTap: widget.onDashboard,
                          bg: L.blue.withValues(alpha: 0.1),
                          textColor: L.blue)),
                  const SizedBox(width: 8),
                ] else ...[
                  Expanded(
                      child: _CardBtnJSX(
                          label: 'Resend Link',
                          icon: Icons.share_rounded,
                          onTap: () => Clipboard.setData(
                              ClipboardData(text: cg.inviteUrl)),
                          bg: L.bg,
                          textColor: L.sub)),
                  const SizedBox(width: 8),
                ],
                _IconButtonJSX(
                    icon: Icons.delete_outline_rounded,
                    onTap: () => widget.state.removeCaregiver(cg.id),
                    bg: L.redLight,
                    textColor: L.red),
              ]),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _CardBtnJSX extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color bg, textColor;
  const _CardBtnJSX(
      {required this.label,
      required this.icon,
      required this.onTap,
      required this.bg,
      required this.textColor});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
          ]),
        ),
      );
}

class _IconButtonJSX extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bg, textColor;
  const _IconButtonJSX(
      {required this.icon,
      required this.onTap,
      required this.bg,
      required this.textColor});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, size: 18, color: textColor),
        ),
      );
}

// ── Shared Add Caregiver Header ─────────────────────────────────────────
class _AddHeader extends StatelessWidget {
  final int step;
  final AppThemeColors L;
  final VoidCallback onBack;
  const _AddHeader({required this.step, required this.L, required this.onBack});
  @override
  Widget build(BuildContext context) {
    final title = step == 1
        ? "Add Caregiver"
        : step == 2
            ? "Share QR Code"
            : "Caregiver Active!";
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        GestureDetector(
            onTap: onBack,
            child: SizedBox(
                width: 24,
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: L.text, size: 18))),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: L.text)),
          Text('Step $step of 3',
              style:
                  TextStyle(fontFamily: 'Inter', fontSize: 12, color: L.sub)),
        ]),
      ]),
      const SizedBox(height: 24),
      Row(
          children: [1, 2, 3]
              .map((n) => Expanded(
                  child: Container(
                      margin: EdgeInsets.only(right: n == 3 ? 0 : 6),
                      height: 4,
                      decoration: BoxDecoration(
                          color: step >= n ? L.green : L.border,
                          borderRadius: BorderRadius.circular(99)))))
              .toList()),
      const SizedBox(height: 28),
    ]);
  }
}

// ── Add Caregiver Step 1 (info form) ──────────────────────────────────
class _AddCgStep1 extends StatelessWidget {
  final TextEditingController nameCtrl, contactCtrl;
  final String relation, avatar;
  final int alertDelay;
  final ValueChanged<String> onRelChange, onAvatarChange;
  final ValueChanged<int> onDelayChange;
  final AppThemeColors L;
  final VoidCallback onBack;
  final Future<void> Function() onNext;
  const _AddCgStep1(
      {super.key,
      required this.nameCtrl,
      required this.contactCtrl,
      required this.relation,
      required this.avatar,
      required this.alertDelay,
      required this.onRelChange,
      required this.onAvatarChange,
      required this.onDelayChange,
      required this.L,
      required this.onBack,
      required this.onNext});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: L.bg,
        body: SafeArea(
            child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AddHeader(step: 1, L: L, onBack: onBack),

                      // Avatar
                      Text('CHOOSE AVATAR',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: L.sub)),
                      const SizedBox(height: 8),
                      Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: kCgAvatars
                              .map((a) => GestureDetector(
                                    onTap: () => onAvatarChange(a),
                                    child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                            color: avatar == a
                                                ? L.greenLight
                                                : L.bg,
                                            borderRadius:
                                                BorderRadius.circular(13),
                                            border: Border.all(
                                                color: avatar == a
                                                    ? L.green
                                                    : L.border,
                                                width: 2)),
                                        child: Center(
                                            child: Text(a,
                                                style: const TextStyle(
                                                    fontSize: 22)))),
                                  ))
                              .toList()),
                      const SizedBox(height: 20),

                      // Name
                      Text('FULL NAME *',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: L.sub)),
                      const SizedBox(height: 6),
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                            color: L.card,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                                color: nameCtrl.text.isNotEmpty
                                    ? L.green
                                    : L.border,
                                width: 1.5)),
                        child: TextField(
                            controller: nameCtrl,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                color: L.text),
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'e.g. Sarah Johnson',
                                hintStyle: TextStyle(
                                    color: L.sub.withValues(alpha: 0.5)))),
                      ),

                      // Relationship
                      Text('RELATIONSHIP',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: L.sub)),
                      const SizedBox(height: 8),
                      Wrap(
                          spacing: 6,
                          runSpacing: 8,
                          children: [
                            'Spouse',
                            'Parent',
                            'Son',
                            'Daughter',
                            'Sibling',
                            'Friend',
                            'Doctor',
                            'Caregiver'
                          ]
                              .map((r) => GestureDetector(
                                    onTap: () => onRelChange(r),
                                    child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 13, vertical: 7),
                                        decoration: BoxDecoration(
                                            color: relation == r
                                                ? L.green
                                                : L.card,
                                            borderRadius:
                                                BorderRadius.circular(99),
                                            border: Border.all(
                                                color: relation == r
                                                    ? L.green
                                                    : L.border)),
                                        child: Text(r,
                                            style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: relation == r
                                                    ? Colors.white
                                                    : L.sub))),
                                  ))
                              .toList()),
                      const SizedBox(height: 16),

                      // Phone
                      Text('PHONE (OPTIONAL — FOR SMS BACKUP)',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: L.sub)),
                      const SizedBox(height: 6),
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                            color: L.card,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                                color: contactCtrl.text.isNotEmpty
                                    ? L.green
                                    : L.border,
                                width: 1.5)),
                        child: TextField(
                            controller: contactCtrl,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                color: L.text),
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: '+880 1XXX-XXXXXX',
                                hintStyle: TextStyle(
                                    color: L.sub.withValues(alpha: 0.5)))),
                      ),

                      // Alert Delay
                      Text('ALERT AFTER MISSED DOSE BY',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: L.sub)),
                      const SizedBox(height: 8),
                      Row(children: [
                        _DelayBtn(
                            delay: 0,
                            label: 'Now',
                            current: alertDelay,
                            onTap: onDelayChange,
                            L: L),
                        const SizedBox(width: 6),
                        _DelayBtn(
                            delay: 15,
                            label: '15 min',
                            current: alertDelay,
                            onTap: onDelayChange,
                            L: L),
                        const SizedBox(width: 6),
                        _DelayBtn(
                            delay: 30,
                            label: '30 min',
                            current: alertDelay,
                            onTap: onDelayChange,
                            L: L),
                        const SizedBox(width: 6),
                        _DelayBtn(
                            delay: 60,
                            label: '1 hour',
                            current: alertDelay,
                            onTap: onDelayChange,
                            L: L),
                      ]),
                      const SizedBox(height: 28),

                      GestureDetector(
                          onTap: nameCtrl.text.trim().isEmpty ? null : onNext,
                          child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: nameCtrl.text.trim().isEmpty
                                      ? L.border
                                      : L.green,
                                  borderRadius: BorderRadius.circular(16)),
                              child: Text('Generate QR Code →',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: nameCtrl.text.trim().isEmpty
                                          ? L.sub
                                          : Colors.white)))),
                    ]))),
      );
}

class _DelayBtn extends StatelessWidget {
  final int delay, current;
  final String label;
  final ValueChanged<int> onTap;
  final AppThemeColors L;
  const _DelayBtn(
      {required this.delay,
      required this.current,
      required this.label,
      required this.onTap,
      required this.L});
  @override
  Widget build(BuildContext context) => Expanded(
          child: GestureDetector(
        onTap: () => onTap(delay),
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: current == delay ? L.green : L.card,
                borderRadius: BorderRadius.circular(11),
                border:
                    Border.all(color: current == delay ? L.green : L.border)),
            child: Text(label,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: current == delay ? Colors.white : L.sub))),
      ));
}

// ── Add Caregiver Step 2 (QR share) ──────────────────────────────────
class _AddCgStep2 extends StatefulWidget {
  final Caregiver cg;
  final AppThemeColors L;
  final VoidCallback onNext;
  const _AddCgStep2(
      {super.key, required this.cg, required this.L, required this.onNext});

  @override
  State<_AddCgStep2> createState() => _AddCgStep2State();
}

class _AddCgStep2State extends State<_AddCgStep2> {
  String _scanState = 'idle';

  void _simulateScan() async {
    setState(() => _scanState = 'scanning');
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _scanState = 'done');
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final cg = widget.cg;
    final L = widget.L;

    return Scaffold(
        backgroundColor: L.bg,
        body: SafeArea(
            child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AddHeader(
                          step: 2,
                          L: L,
                          onBack: () => setState(() => _scanState = 'idle')),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                            color: L.card,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x333C3C43),
                                  blurRadius: 0,
                                  spreadRadius: 0,
                                  offset: Offset(0, -0.5))
                            ]),
                        child: Row(children: [
                          Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                  color: L.greenLight,
                                  borderRadius: BorderRadius.circular(15)),
                              child: Center(
                                  child: Text(cg.avatar,
                                      style: const TextStyle(fontSize: 26)))),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(cg.name,
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: L.text)),
                                Text(
                                    '${cg.relation}${cg.contact.isNotEmpty ? ' · ${cg.contact}' : ''}',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: L.sub)),
                              ])),
                        ]),
                      ),
                      Text(
                          'Share the QR or invite code with ${cg.name}. They do not need to download the app to accept!',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: L.sub,
                              height: 1.5)),
                      const SizedBox(height: 24),
                      Center(
                          child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 14,
                                  offset: const Offset(0, 2))
                            ],
                            border: Border.all(color: L.border, width: 1.5)),
                        child: QrImageView(data: cg.inviteUrl, size: 210),
                      )),
                      const SizedBox(height: 28),
                      Center(
                          child: Text('OR USE INVITE CODE',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: L.sub,
                                  letterSpacing: 1.5))),
                      const SizedBox(height: 8),
                      Center(
                          child: Text(cg.inviteCode,
                              style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: L.text,
                                  letterSpacing: 3))),
                      const SizedBox(height: 12),
                      Center(
                          child: GestureDetector(
                        onTap: () => Clipboard.setData(
                            ClipboardData(text: cg.inviteUrl)),
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                                color: L.card,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: L.border)),
                            child: Text('📋 Copy Link',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: L.sub))),
                      )),
                      const SizedBox(height: 48),
                      GestureDetector(
                        onTap: _scanState == 'idle' ? _simulateScan : null,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color:
                                  _scanState == 'idle' ? L.green : L.greenLight,
                              borderRadius: BorderRadius.circular(14)),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_scanState == 'idle') ...[
                                  const Icon(Icons.camera_alt_rounded,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 8),
                                  const Text(
                                      'Simulate: Caregiver Scans This QR',
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: Colors.white)),
                                ] else if (_scanState == 'scanning') ...[
                                  const Text('⟳',
                                      style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Text('Scanning...',
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: L.green)),
                                ] else ...[
                                  const Text('✅ Activated!',
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: Colors.white)),
                                ]
                              ]),
                        ),
                      ),
                    ]))));
  }
}

class _HowItWorksRow extends StatelessWidget {
  final String emoji, title, desc;
  final bool isLast;
  final AppThemeColors L;
  const _HowItWorksRow(
      {required this.emoji,
      required this.title,
      required this.desc,
      required this.isLast,
      required this.L});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: L.border, width: 1))),
      child: Row(children: [
        SizedBox(
            width: 24,
            child: Text(emoji, style: const TextStyle(fontSize: 18))),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: L.text)),
          Text(desc,
              style:
                  TextStyle(fontFamily: 'Inter', fontSize: 12, color: L.sub)),
        ]))
      ]),
    );
  }
}

// ── Add Caregiver Step 3 (confirmed) ─────────────────────────────────
class _AddCgStep3 extends StatelessWidget {
  final Caregiver cg;
  final AppThemeColors L;
  final VoidCallback onDone;
  const _AddCgStep3(
      {super.key, required this.cg, required this.L, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: L.bg,
        body: SafeArea(
            child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AddHeader(step: 3, L: L, onBack: onDone),
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFBBF7D0), width: 2)),
                        child: Row(children: [
                          Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                  color: L.greenLight,
                                  borderRadius: BorderRadius.circular(15)),
                              child: Center(
                                  child: Text(cg.avatar,
                                      style: const TextStyle(fontSize: 28)))),
                          const SizedBox(width: 16),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(cg.name,
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: L.text)),
                                Text(
                                    '${cg.relation}${cg.contact.isNotEmpty ? ' · ${cg.contact}' : ''}',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: L.sub)),
                              ])),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(99)),
                            child: Text('● Active',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: L.green,
                                    letterSpacing: 0.5)),
                          ),
                        ]),
                      ),
                      Text('THEY CAN NOW:',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                              color: L.sub)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: L.card,
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x333C3C43),
                                  blurRadius: 0,
                                  spreadRadius: 0,
                                  offset: Offset(0, -0.5))
                            ]),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _HowItWorksRow(
                                  emoji: '📊',
                                  title: 'See your daily adherence',
                                  desc: 'Live dashboard with today\'s doses',
                                  isLast: false,
                                  L: L),
                              _HowItWorksRow(
                                  emoji: '⚠️',
                                  title: 'Get missed-dose alerts',
                                  desc:
                                      'Notified after ${cg.alertDelay} min if you miss a dose',
                                  isLast: false,
                                  L: L),
                              _HowItWorksRow(
                                  emoji: '📋',
                                  title: 'View your medicine list',
                                  desc: 'All your medications at a glance',
                                  isLast: true,
                                  L: L),
                            ]),
                      ),
                      const SizedBox(height: 48),
                      GestureDetector(
                          onTap: onDone,
                          child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: L.green,
                                  borderRadius: BorderRadius.circular(16)),
                              child: const Text('Done',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: Colors.white)))),
                    ]))));
  }
}

class _WeeklyAdherenceChart extends StatelessWidget {
  final AppState state;
  final AppThemeColors L;
  const _WeeklyAdherenceChart({required this.state, required this.L});

  @override
  Widget build(BuildContext context) {
    // Generate last 7 days data
    final Map<String, double> weekData = {};
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final dayLabel =
          ['Mn', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'][date.weekday - 1];

      final doses = state.history[dateStr] ?? [];
      final sysExpected = state.activeMeds
          .where((m) => m.schedule
              .any((s) => s.enabled && s.days.contains(date.weekday % 7)))
          .length;

      double score = 0.0;
      if (sysExpected > 0) {
        final taken = doses.where((d) => d.taken).length;
        score = (taken / sysExpected).clamp(0.0, 1.0);
      } else if (doses.isNotEmpty) {
        score = 1.0;
      }
      weekData[dayLabel] = score;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: L.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Weekly Adherence',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: L.text)),
              const Spacer(),
              Icon(Icons.bar_chart_rounded, color: L.sub, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weekData.entries.map((e) {
              final pct = e.value;
              final height = 10.0 + (pct * 60.0);
              final color = pct >= 0.8
                  ? L.green
                  : pct > 0.0
                      ? L.amber
                      : L.bg;

              return Column(
                children: [
                  Container(
                    width: 28,
                    height: height,
                    decoration: BoxDecoration(
                      color: pct == 0.0 ? L.border : color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(e.key,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: L.sub,
                          fontWeight: FontWeight.w600)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ProtectorInsights extends StatelessWidget {
  final Caregiver cg;
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onBack;
  const _ProtectorInsights(
      {super.key,
      required this.cg,
      required this.state,
      required this.L,
      required this.onBack});

  @override
  Widget build(BuildContext context) {
    final streak = state.getStreak();

    return Scaffold(
      backgroundColor: L.bg,
      body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      GestureDetector(
                          onTap: onBack,
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              color: L.sub, size: 18)),
                      const SizedBox(width: 14),
                      Text('Protector Insights',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: L.text)),
                    ]),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: L.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: L.border)),
                      child: Row(children: [
                        Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                                color:
                                    hexToColor(cg.color).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(18)),
                            child: Center(
                                child: Text(cg.avatar,
                                    style: const TextStyle(fontSize: 34)))),
                        const SizedBox(width: 18),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(cg.name,
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: L.text,
                                      letterSpacing: -0.5)),
                              Text(
                                  '${cg.relation} Connected · Since ${cg.addedAt}',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      color: L.sub,
                                      fontWeight: FontWeight.w500)),
                            ])),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                          child: _FamStatJSX(
                              emoji: '📊',
                              label: 'Adherence',
                              value: 100,
                              color: 100 >= 80
                                  ? L.green
                                  : L.amber)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _FamStatJSX(
                              emoji: '🔥',
                              label: 'Streak',
                              value: streak,
                              color: const Color(0xFFF97316))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _FamStatJSX(
                              emoji: '💊',
                              label: 'Meds',
                              value: state.activeMeds.length,
                              color: L.blue)),
                    ]),
                    const SizedBox(height: 24),
                    _WeeklyAdherenceChart(state: state, L: L),
                    const SizedBox(height: 24),

                    const SizedBox(height: 32),
                    Text('REAL-TIME STATUS',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: L.sub,
                            letterSpacing: 1.0)),
                    const SizedBox(height: 12),
                    ...state.getDoses().map((d) {
                      final status = state.getDoseStatus(d);
                      final isTaken = status == DoseStatus.taken;
                      final isOverdue = status == DoseStatus.overdue ||
                          status == DoseStatus.missed;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: L.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: isOverdue
                                  ? L.red.withValues(alpha: 0.3)
                                  : L.border),
                        ),
                        child: Row(children: [
                          Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                  color: (isTaken
                                          ? L.green
                                          : isOverdue
                                              ? L.red
                                              : L.sub)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Center(
                                  child: Text(
                                      isTaken
                                          ? '✅'
                                          : isOverdue
                                              ? '⚠️'
                                              : '⏳',
                                      style: const TextStyle(fontSize: 18)))),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(d.med.name,
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: L.text)),
                                Text(
                                    '${fmtTime(d.sched.h, d.sched.m)} · ${d.sched.label}',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: L.sub,
                                        fontWeight: FontWeight.w500)),
                              ])),
                          if (isTaken)
                            Text('Taken ✓',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: L.green))
                          else if (isOverdue)
                            Text('MISSING',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: L.red))
                          else
                            Text('Upcoming',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: L.sub)),
                        ]),
                      );
                    }),
                    const SizedBox(height: 40),
                  ]))),
    );
  }
}

// ── Join as Caregiver ─────────────────────────────────────────────────
class _JoinAsCaregiverView extends StatefulWidget {
  final AppThemeColors L;
  final VoidCallback onBack;
  const _JoinAsCaregiverView(
      {super.key, required this.L, required this.onBack});
  @override
  State<_JoinAsCaregiverView> createState() => _JoinAsCaregiverViewState();
}

class _JoinAsCaregiverViewState extends State<_JoinAsCaregiverView> {
  final _codeCtrl = TextEditingController();
  final _scannerCtrl = MobileScannerController();
  bool _error = false;
  bool _loading = false;
  bool _scanning = false;
  String _errorMsg = 'Code not found or expired.';
  int _tab = 0; // 0: QR, 1: Code
  String _scanState = 'idle';

  @override
  void dispose() {
    _codeCtrl.dispose();
    _scannerCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture, AppState state) async {
    if (_scanning) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null &&
          (code.startsWith('MT-') || code.contains('family/join/'))) {
        setState(() => _scanning = true);
        String inviteCode = code;
        if (code.contains('join/')) {
          inviteCode = code.split('/').last;
        }
        setState(() => _scanState = 'done');
        Caregiver? match = await state.lookupInvite(inviteCode);
        if (match != null) {
          await state.joinForce(match.patientUid, match.id);
          if (!mounted) return;
          widget.onBack();
        } else {
          setState(() {
            _scanning = false;
            _scanState = 'idle';
            _error = true;
            _errorMsg = 'Invalid or expired QR code.';
          });
        }
        break;
      }
    }
  }

  void _joinViaCode(AppState state) async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length < 6) {
      setState(() {
        _error = true;
        _errorMsg = 'Please enter a valid 6-character code.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = false;
    });
    final normalised = code.startsWith('MT-') ? code : 'MT-$code';
    Caregiver? match = await state.lookupInvite(normalised);
    match ??= state.caregivers
        .where(
          (c) =>
              c.status == 'pending' &&
              (c.inviteCode == normalised || c.inviteCode == code),
        )
        .cast<Caregiver?>()
        .firstOrNull;
    if (!mounted) return;
    if (match != null) {
      setState(() => _loading = false);
      await state.joinForce(match.patientUid, match.id);
      widget.onBack();
    } else {
      setState(() {
        _loading = false;
        _error = true;
        _errorMsg =
            'Invite code not found or has expired. Ask the patient to resend.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = widget.L;
    final state = Provider.of<AppState>(context);
    final pendingCgs =
        state.caregivers.where((c) => c.status == 'pending').toList();

    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onBack,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(
                top: 28,
                left: 24,
                right: 24,
                bottom: 52 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
                color: L.card,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20))),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Join as Caregiver',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: L.text,
                                      letterSpacing: -0.3)),
                              Text('Scan a unique QR code or enter invite code',
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: L.sub)),
                            ]),
                        GestureDetector(
                            onTap: widget.onBack,
                            child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                    color: L.bg,
                                    borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.close_rounded,
                                    color: L.sub, size: 18))),
                      ]),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: L.bg, borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      Expanded(
                          child: _JoinTab(
                              label: '📷 Scan QR',
                              active: _tab == 0,
                              onTap: () => setState(() => _tab = 0))),
                      Expanded(
                          child: _JoinTab(
                              label: '🔑 Enter Code',
                              active: _tab == 1,
                              onTap: () => setState(() => _tab = 1))),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  if (_tab == 0) ...[
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _scanState == 'done' ? L.green : L.border,
                            width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          children: [
                            MobileScanner(
                              controller: _scannerCtrl,
                              onDetect: (cap) => _onDetect(cap, state),
                            ),
                            Center(
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                      width: 2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            if (_scanning)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(
                                            color: Colors.white),
                                        SizedBox(height: 12),
                                        Text('Processing QR...',
                                            style: TextStyle(
                                                fontFamily: 'Inter',
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Point your camera at the invite QR code shown on the patient\'s device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: L.sub,
                          height: 1.5),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: L.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: L.border, width: 1.5)),
                      child: Text.rich(TextSpan(children: [
                        TextSpan(
                            text: '📱 Caregiver taps ',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: L.sub,
                                height: 1.5)),
                        const TextSpan(
                            text: '"Join as Caregiver"',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8B5CF6),
                                height: 1.5)),
                        TextSpan(
                            text:
                                ' in their app and types the MT-XXXXXX code you shared.',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: L.sub,
                                height: 1.5)),
                      ])),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                          color: L.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: _error
                                  ? L.red
                                  : _codeCtrl.text.isNotEmpty
                                      ? const Color(0xFF8B5CF6)
                                      : L.border,
                              width: 1.5)),
                      child: TextField(
                        controller: _codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: L.text,
                            letterSpacing: 2),
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'MT-A1B2C3',
                            hintStyle: TextStyle(
                                color: L.sub.withValues(alpha: 0.5),
                                letterSpacing: 2)),
                        onChanged: (v) {
                          setState(() => _error = false);
                        },
                      ),
                    ),
                    if (_error)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text('⚠️ $_errorMsg',
                              style: TextStyle(
                                  color: L.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Inter'))),
                    if (pendingCgs.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('TAP TO AUTOFILL CODE',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: L.sub,
                              letterSpacing: 1.0)),
                      const SizedBox(height: 8),
                      ...pendingCgs.map((cg) => GestureDetector(
                            onTap: () => setState(() {
                              _codeCtrl.text = cg.inviteCode;
                              _error = false;
                            }),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                  color: _codeCtrl.text == cg.inviteCode
                                      ? const Color(0xFFEDE9FE)
                                      : L.bg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: _codeCtrl.text == cg.inviteCode
                                          ? const Color(0xFF8B5CF6)
                                          : L.border,
                                      width: 1.5)),
                              child: Row(children: [
                                Text(cg.avatar,
                                    style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(cg.name,
                                          style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: L.text)),
                                      Text(cg.inviteCode,
                                          style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF8B5CF6),
                                              letterSpacing: 1.0)),
                                    ])),
                                Text('autofill →',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: L.sub)),
                              ]),
                            ),
                          )),
                      const SizedBox(height: 10),
                    ],
                    GestureDetector(
                      onTap: (!_loading && _codeCtrl.text.trim().length >= 6)
                          ? () => _joinViaCode(state)
                          : null,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              (!_loading && _codeCtrl.text.trim().length >= 6)
                                  ? const Color(0xFF8B5CF6)
                                  : const Color(0xFFDDD6FE),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Text('Activate Caregiver ✓',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Colors.white)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _JoinTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _JoinTab(
      {required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
              color: active ? context.L.card : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: active
                  ? [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.09),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ]
                  : []),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? context.L.text : context.L.sub)),
          ),
        ),
      );
}

// ── Alert Detail View ─────────────────────────────────────────────────
class _AlertDetailView extends StatelessWidget {
  final MissedAlert alert;
  final AppThemeColors L;
  final VoidCallback onBack;
  const _AlertDetailView(
      {super.key, required this.alert, required this.L, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: L.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Alert Detail',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: L.text,
                          letterSpacing: -0.3)),
                  IconButton(
                      onPressed: onBack,
                      icon: Icon(Icons.close_rounded, color: L.sub, size: 24)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: L.redLight,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFFCA5A5))),
                child: Row(children: [
                  const Text('⚠️', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(alert.medName,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: L.red)),
                        Text('Missed ${alert.doseLabel} at ${alert.time}',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: L.sub)),
                      ])),
                ]),
              ),
              const SizedBox(height: 24),
              Text('ESCALATION PATH',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: L.sub,
                      letterSpacing: 1.0)),
              const SizedBox(height: 12),
              _EscalationTimeline(activeStep: 4, L: L),
              const SizedBox(height: 24),
              Text('CAREGIVERS NOTIFIED',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: L.sub,
                      letterSpacing: 1.0)),
              const SizedBox(height: 12),
              ...alert.caregivers.map((cg) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: L.card,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1))
                        ]),
                    child: Row(children: [
                      Text(cg.avatar, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(cg.name,
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: L.text)),
                            Text(
                                cg.contact.isNotEmpty
                                    ? cg.contact
                                    : cg.relation,
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: L.sub)),
                          ])),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: L.greenLight,
                            borderRadius: BorderRadius.circular(99)),
                        child: Text('SENT ✓',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: L.green,
                                letterSpacing: 0.04)),
                      ),
                    ]),
                  )),
              const SizedBox(height: 24),
              Text('MESSAGE SENT',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: L.sub,
                      letterSpacing: 1.0)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFF1C1917),
                    borderRadius: BorderRadius.circular(16)),
                child: RichText(
                    text: TextSpan(
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Color(0xFFFEF2F2),
                            height: 1.7),
                        children: [
                      const TextSpan(text: '⚠️ '),
                      const TextSpan(
                          text: 'Sarah J.',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const TextSpan(text: ' missed their '),
                      TextSpan(
                          text: '${alert.doseLabel} dose of ${alert.medName}',
                          style: const TextStyle(
                              color: Color(0xFFFCA5A5),
                              fontWeight: FontWeight.w700)),
                      TextSpan(
                          text: ' at ${alert.time}.\nPlease check on them. 🙏'),
                    ])),
              ),
              const SizedBox(height: 16),
              Center(
                  child: Text(alert.timestamp,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: L.sub.withValues(alpha: 0.6)))),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Alert Log Card ────────────────────────────────────────────────────
class _AlertLogCard extends StatelessWidget {
  final MissedAlert alert;
  final AppThemeColors L;
  final VoidCallback onTap;
  const _AlertLogCard(
      {required this.alert, required this.L, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: alert.seen ? L.border : L.red.withValues(alpha: 0.5),
                  width: 1.5)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: L.redLight, borderRadius: BorderRadius.circular(11)),
              child: Center(
                  child: Icon(Icons.warning_amber_rounded,
                      size: 17, color: L.red)),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(alert.medName,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: L.text)),
                  const SizedBox(height: 2),
                  Text(
                      'Missed ${alert.doseLabel} at ${alert.time} · ${alert.caregivers.length} notified',
                      style: TextStyle(
                          fontFamily: 'Inter', fontSize: 12, color: L.sub)),
                  const SizedBox(height: 3),
                  Text(alert.timestamp,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: L.sub.withValues(alpha: 0.7))),
                ])),
            if (!alert.seen)
              Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(top: 4),
                  decoration:
                      BoxDecoration(color: L.red, shape: BoxShape.circle)),
            Icon(Icons.chevron_right_rounded,
                color: L.sub, size: 20, weight: 800),
          ]),
        ),
      );
}

// ── Escalation Demo View ─────────────────────────────────────────────
class _EscalationDemoView extends StatefulWidget {
  final AppThemeColors L;
  final VoidCallback onBack;
  const _EscalationDemoView({super.key, required this.L, required this.onBack});

  @override
  State<_EscalationDemoView> createState() => _EscalationDemoViewState();
}

class _EscalationDemoViewState extends State<_EscalationDemoView> {
  int _step = 1;

  @override
  Widget build(BuildContext context) {
    final L = widget.L;

    return Scaffold(
      backgroundColor: L.bg,
      body: Stack(
        children: [
          SafeArea(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          GestureDetector(
                              onTap: widget.onBack,
                              child: Icon(Icons.arrow_back_ios_new_rounded,
                                  color: L.sub, size: 18)),
                          const SizedBox(width: 12),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Escalation Logic',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: L.text)),
                                Text(
                                    'How missed doses trigger caregiver alerts',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: L.sub))
                              ])
                        ]),
                        const SizedBox(height: 32),
                        _EscalationTimeline(activeStep: _step, L: L),
                        const SizedBox(height: 32),
                        Row(children: [
                          Expanded(
                              child: GestureDetector(
                            onTap: _step <= 1
                                ? null
                                : () => setState(() => _step--),
                            child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: _step <= 1 ? L.border : L.card,
                                    borderRadius: BorderRadius.circular(14)),
                                child: Text('← Back',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _step <= 1 ? L.sub : L.text))),
                          )),
                          const SizedBox(width: 10),
                          Expanded(
                              flex: 2,
                              child: GestureDetector(
                                onTap: _step >= 4
                                    ? null
                                    : () {
                                        setState(() => _step++);
                                        if (_step == 4) {
                                          // Show a snackbar as a "Mock Push Notification"
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              backgroundColor:
                                                  Colors.transparent,
                                              elevation: 0,
                                              duration:
                                                  const Duration(seconds: 4),
                                              content: Container(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF1C1917),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                                alpha: 0.3),
                                                        blurRadius: 10,
                                                        offset:
                                                            const Offset(0, 4))
                                                  ],
                                                ),
                                                child: Row(children: [
                                                  const Text('⚠️',
                                                      style: TextStyle(
                                                          fontSize: 24)),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                      child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                        Text('CRITICAL ALERT',
                                                            style: TextStyle(
                                                                fontFamily:
                                                                    'Inter',
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                                color: L.red,
                                                                letterSpacing:
                                                                    1.0)),
                                                        const Text(
                                                            'Sarah J. missed their BP medication. Please check on them immediately.',
                                                            style: TextStyle(
                                                                fontFamily:
                                                                    'Inter',
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .white)),
                                                      ])),
                                                ]),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: _step >= 4 ? L.border : L.green,
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    child: Text(
                                        _step >= 4
                                            ? 'Full flow shown ✓'
                                            : 'Next step →',
                                        style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: _step >= 4
                                                ? L.sub
                                                : Colors.white))),
                              )),
                        ]),
                        if (_step == 4) ...[
                          const SizedBox(height: 16),
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 500),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, val, child) => Opacity(
                                opacity: val,
                                child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - val)),
                                    child: child)),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: L.redLight,
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                      color: const Color(0xFFFCA5A5))),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('⚠️ Alert message sent:',
                                        style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: L.red)),
                                    const SizedBox(height: 6),
                                    RichText(
                                        text: TextSpan(
                                            style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 13,
                                                color: L.text,
                                                height: 1.5),
                                            children: const [
                                          TextSpan(
                                              text:
                                                  '"Your family member missed their '),
                                          TextSpan(
                                              text:
                                                  '8:00 PM blood pressure medicine',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700)),
                                          TextSpan(
                                              text:
                                                  '. Please check on them. 🙏"'),
                                        ])),
                                  ]),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: L.card,
                              borderRadius: BorderRadius.circular(13)),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('⏱️ Default alert delay: 30 minutes',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: L.text)),
                                const SizedBox(height: 4),
                                Text(
                                    'Configurable per caregiver (0 min → 1 hour)',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: L.sub)),
                              ]),
                        )
                      ]))),
        ],
      ),
    );
  }
}

class _EscalationTimeline extends StatelessWidget {
  final int activeStep;
  final AppThemeColors L;
  const _EscalationTimeline({required this.activeStep, required this.L});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'title': 'Dose time arrives',
        'detail': '8:00 PM',
        'icon': '🔔',
        'color': L.blue
      },
      {
        'title': 'User snoozed',
        'detail': 'Snooze 10 min',
        'icon': '😴',
        'color': L.amber
      },
      {
        'title': 'No action taken',
        'detail': '30 min limit reached',
        'icon': '❌',
        'color': const Color(0xFFF97316)
      },
      {
        'title': 'Caregivers alerted',
        'detail': '⚠️ Alert delivered',
        'icon': '⚠️',
        'color': L.red
      },
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        final isActive = activeStep > i;
        final isLast = i == steps.length - 1;
        final color = steps[i]['color'] as Color;

        return IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Column(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: isActive ? color.withValues(alpha: 0.15) : L.fill,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                        color:
                            isActive ? color.withValues(alpha: 0.3) : L.border,
                        width: 2)),
                child: Center(
                    child: Text(steps[i]['icon'] as String,
                        style: const TextStyle(fontSize: 14))),
              ),
              if (!isLast)
                Expanded(
                    child: Container(
                        width: 2,
                        color:
                            isActive ? color.withValues(alpha: 0.3) : L.border,
                        margin: const EdgeInsets.symmetric(vertical: 4))),
            ]),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(steps[i]['title'] as String,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isActive ? L.text : L.sub)),
                      const SizedBox(height: 2),
                      Text(steps[i]['detail'] as String,
                          style: TextStyle(
                              fontFamily: 'Inter', fontSize: 13, color: L.sub)),
                    ]),
              ),
            ),
          ]),
        );
      }),
    );
  }
}

