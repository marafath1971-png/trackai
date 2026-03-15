import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../providers/app_state.dart';
import '../../../models/models.dart';
import '../../../theme/app_theme.dart';
import '../../../core/utils/color_utils.dart';
import '../../../widgets/shared/shared_widgets.dart';
import '../../settings/privacy_policy_screen.dart';
import '../../../services/export_service.dart';

class SettingsModal extends StatefulWidget {
  final VoidCallback onClose;
  const SettingsModal({super.key, required this.onClose});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  String _activeTab = 'profile'; // profile | stats | app | data
  final String ff = 'Inter';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final L = context.L;
    final size = MediaQuery.of(context).size;

    final tabs = [
      {'id': 'profile', 'label': 'Profile', 'icon': '👤'},
      {'id': 'stats', 'label': 'Stats', 'icon': '📊'},
      {'id': 'app', 'label': 'App', 'icon': '⚙️'},
      {'id': 'data', 'label': 'Data', 'icon': '🗂️'},
    ];

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              height: size.height * 0.92,
              width: size.width,
              constraints: const BoxConstraints(maxWidth: 430),
              decoration: BoxDecoration(
                  color: L.bg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border.all(color: L.border, width: 1.5)),
              child: Column(children: [
                const SizedBox(height: 10),
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: L.border,
                            borderRadius: BorderRadius.circular(99)))),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Settings',
                            style: TextStyle(
                                fontFamily: ff,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: L.text,
                                letterSpacing: -0.7)),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: L.fill, shape: BoxShape.circle),
                            child: Center(
                                child: Icon(Icons.close_rounded,
                                    color: L.sub, size: 22)),
                          ),
                        ),
                      ]).animate().fade(duration: 400.ms).slideY(begin: -0.1, end: 0),
                ),
                // Tab Bar
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                      children: tabs.map((t) {
                    final isAct = _activeTab == t['id'];
                    final idx = tabs.indexOf(t);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _activeTab = t['id'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                              color: isAct ? const Color(0xFF111111) : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: isAct ? Colors.white.withValues(alpha: 0.15) : L.border.withValues(alpha: 0.3)
                              )),
                          child: Row(children: [
                            Text(t['icon']!,
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Text(t['label']!,
                                style: TextStyle(
                                    fontFamily: ff,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isAct ? Colors.white : L.text)),
                          ]),
                        ),
                      ).animate().fade(delay: (idx * 50).ms).scale(begin: const Offset(0.9, 0.9)),
                    );
                  }).toList()),
                ),
                // Content
                Expanded(child: _buildContent(state, L)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppState state, AppThemeColors L) {
    switch (_activeTab) {
      case 'profile':
        return _ProfileTab(state: state, L: L, ff: ff);
      case 'stats':
        return _StatsTab(state: state, L: L, ff: ff);
      case 'app':
        return _AppTab(state: state, L: L, ff: ff, onClose: widget.onClose);
      case 'data':
        return _DataTab(state: state, L: L, ff: ff, onClose: widget.onClose);
      default:
        return Container();
    }
  }
}

// ── Shared Subview Components ────────────────────────────────────────────────

class SRow extends StatelessWidget {
  final dynamic icon; // String or IconData
  final Color iconBg;
  final String label;
  final String? sub;
  final Widget? right;
  final VoidCallback? onClick;
  final bool border;

  const SRow(
      {super.key,
      required this.icon,
      this.iconBg = const Color(0xFF111111),
      required this.label,
      this.sub,
      this.right,
      this.onClick,
      this.border = true,
      this.first = false,
      this.last = false});

  final bool first, last;

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return GestureDetector(
      onTap: onClick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.only(
            topLeft: first ? const Radius.circular(30) : Radius.zero,
            topRight: first ? const Radius.circular(30) : Radius.zero,
            bottomLeft: last ? const Radius.circular(30) : Radius.zero,
            bottomRight: last ? const Radius.circular(30) : Radius.zero,
          ),
          border: border
              ? Border(bottom: BorderSide(color: L.border.withValues(alpha: 0.3), width: 0.5))
              : null,
        ),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(16)),
            child: Center(
                child: icon is String
                    ? Text(icon as String, style: const TextStyle(fontSize: 16))
                    : Icon(icon as IconData, size: 15, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                if (sub != null)
                  Text(sub!,
                      style: TextStyle(
                          fontFamily: 'Inter', fontSize: 12, color: L.sub)),
              ])),
          if (right != null)
            right!
          else if (onClick != null)
            Icon(Icons.chevron_right_rounded, size: 16, color: L.sub),
        ]),
      ),
    );
  }
}

class Section extends StatelessWidget {
  final String? title;
  final Widget child;
  const Section({super.key, this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Text(title!.toUpperCase(),
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: L.sub)),
        ),
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            color: L.card,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: L.border.withValues(alpha: 0.3), width: 1.0)),
        child: child,
      ),
      const SizedBox(height: 24),
    ]);
  }
}

// ── Profile Tab ──────────────────────────────────────────────────────────────

class _ProfileTab extends StatefulWidget {
  final AppState state;
  final AppThemeColors L;
  final String ff;
  const _ProfileTab({required this.state, required this.L, required this.ff});
  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  String? _genderInput;
  String? _goalInput;
  bool _editing = false;

  final genders = ["Male", "Female", "Non-binary", "Prefer not to say"];
  final goals = [
    "Manage chronic condition",
    "Stay on top of prescriptions",
    "Support family member",
    "Post-surgery recovery",
    "General wellness",
    "Mental health support"
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.state.profile;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _ageCtrl = TextEditingController(text: p?.age ?? '');
    _genderInput = p?.gender;
    _goalInput = p?.goal;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.state.profile;
    final L = widget.L;
    final ff = widget.ff;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      child: Column(children: [
        // Avatar + Name Hero
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: L.border, width: 0.5)),
          child: Row(children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(24)),
              child: Center(
                  child: Text(p?.avatar ?? '😊',
                      style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(p?.name ?? 'Your Name',
                      style: TextStyle(
                          fontFamily: ff,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: L.text,
                          letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  Text(
                      '${p?.age != null && p!.age.isNotEmpty ? "Age ${p.age}" : "Age not set"}${p?.gender != null && p!.gender.isNotEmpty ? " · ${p.gender}" : ""}',
                      style: TextStyle(
                          fontFamily: ff, fontSize: 13, color: L.sub)),
                ])),
            if (!_editing)
              GestureDetector(
                onTap: () => setState(() => _editing = true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(24)),
                  child: const Text('Edit',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
          ]),
        ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 20),

        if (_editing) ...[
          Section(
              title: 'Edit Profile',
              child: Column(children: [
                _EditField(
                    label: 'Name',
                    ctrl: _nameCtrl,
                    placeholder: 'Your name',
                    L: L,
                    ff: ff),
                _EditField(
                    label: 'Age',
                    ctrl: _ageCtrl,
                    placeholder: 'e.g. 35',
                    L: L,
                    ff: ff,
                    keyboard: TextInputType.number,
                    border: false),
              ])),
          Section(
              title: 'Gender',
              child: Column(
                  children: genders
                      .asMap()
                      .entries
                      .map((e) => _SelectRow(
                          label: e.value,
                          isSel: _genderInput == e.value,
                          onClick: () => setState(() => _genderInput = e.value),
                          L: L,
                          ff: ff,
                          first: e.key == 0,
                          last: e.key == genders.length - 1,
                          border: e.key < genders.length - 1))
                      .toList())),
          Section(
              title: 'Primary Goal',
              child: Column(
                  children: goals
                      .asMap()
                      .entries
                      .map((e) => _SelectRow(
                          label: e.value,
                          isSel: _goalInput == e.value,
                          onClick: () => setState(() => _goalInput = e.value),
                          L: L,
                          ff: ff,
                          first: e.key == 0,
                          last: e.key == goals.length - 1,
                          border: e.key < goals.length - 1))
                      .toList())),
          Row(children: [
            Expanded(
                child: GestureDetector(
              onTap: () => setState(() {
                _editing = false;
                _nameCtrl.text = p?.name ?? '';
                _ageCtrl.text = p?.age ?? '';
                _genderInput = p?.gender;
                _goalInput = p?.goal;
              }),
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                      color: L.fill, borderRadius: BorderRadius.circular(24)),
                  child: Center(
                      child: Text('Cancel',
                          style: TextStyle(
                              fontFamily: ff,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: L.text)))),
            )),
            const SizedBox(width: 8),
            Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    final newProfile = p?.copyWith(
                            name: _nameCtrl.text,
                            age: _ageCtrl.text,
                            gender: _genderInput,
                            goal: _goalInput) ??
                        UserProfile(
                            name: _nameCtrl.text,
                            age: _ageCtrl.text,
                            gender: _genderInput ?? '',
                            goal: _goalInput ?? '',
                            avatar: '😊',
                            conditions: const [],
                            notifPerm: true);
                    widget.state.saveProfile(newProfile);
                    setState(() => _editing = false);
                  },
                  child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(24)),
                      child: const Center(
                          child: Text('Save Changes',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)))),
                )),
          ]),
        ] else ...[
          Section(
              title: 'Your Info',
              child: Column(children: [
                SRow(
                    icon: '🎯',
                    label: 'Health Goal',
                    sub: p?.goal ?? 'Not set',
                    first: true,
                    border: true),
                SRow(
                    icon: '🩺',
                    label: 'Conditions',
                    sub: p?.conditions.isNotEmpty == true
                        ? p!.conditions.join(", ")
                        : 'Not set',
                    border: true),
                SRow(
                    icon: '🎂',
                    label: 'Age',
                    sub: p?.age != null && p!.age.isNotEmpty
                        ? '${p.age} years old'
                        : 'Not set',
                    border: true),
                SRow(
                    icon: '🧬',
                    label: 'Gender',
                    sub: p?.gender ?? 'Not set',
                    last: true,
                    border: false),
              ])),
        ],
      ]),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label, placeholder;
  final TextEditingController ctrl;
  final AppThemeColors L;
  final String ff;
  final TextInputType keyboard;
  final bool border;
  const _EditField(
      {required this.label,
      required this.ctrl,
      required this.placeholder,
      required this.L,
      required this.ff,
      this.keyboard = TextInputType.text,
      this.border = true});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: L.card,
          border: border
              ? Border(bottom: BorderSide(color: L.border, width: 0.5))
              : null),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(),
            style: TextStyle(
                fontFamily: ff,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: L.sub)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: TextStyle(
              fontFamily: ff,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: L.text),
          decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: L.sub),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero),
        ),
      ]),
    );
  }
}

class _SelectRow extends StatelessWidget {
  final String label;
  final bool isSel, border;
  final VoidCallback onClick;
  final AppThemeColors L;
  final String ff;
  const _SelectRow(
      {required this.label,
      required this.isSel,
      required this.onClick,
      required this.L,
      required this.ff,
      this.border = true,
      this.first = false,
      this.last = false});

  final bool first, last;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: first ? const Radius.circular(30) : Radius.zero,
              topRight: first ? const Radius.circular(30) : Radius.zero,
              bottomLeft: last ? const Radius.circular(30) : Radius.zero,
              bottomRight: last ? const Radius.circular(30) : Radius.zero,
            ),
            border: border
                ? Border(bottom: BorderSide(color: L.border, width: 0.5))
                : null),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: TextStyle(
                  fontFamily: ff,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: L.text)),
          if (isSel)
            const Icon(Icons.check_rounded, color: Color(0xFF111111), size: 16),
        ]),
      ),
    );
  }
}

// ── Stats Tab ──────────────────────────────────────────────────────────────
class _StatsTab extends StatelessWidget {
  final AppState state;
  final AppThemeColors L;
  final String ff;
  const _StatsTab({required this.state, required this.L, required this.ff});

  @override
  Widget build(BuildContext context) {
    final allEntries = state.history.values.expand((e) => e).toList();
    final taken = allEntries.where((e) => e.taken).length;
    final total = allEntries.length;
    final overallAdh = total > 0 ? (taken * 100 ~/ total) : 0;
    final streak = state.getStreak();
    final daysTracked = state.history.keys.length;

    // Last 7-day adherence
    final today = DateTime.now();
    final last7Keys = List.generate(
        7,
        (i) => today
            .subtract(Duration(days: i))
            .toIso8601String()
            .substring(0, 10));
    final last7Entries =
        last7Keys.expand((k) => state.history[k] ?? []).toList();
    final last7Adh = last7Entries.isNotEmpty
        ? (last7Entries.where((e) => e.taken).length *
            100 ~/
            last7Entries.length)
        : 0;

    final weekData = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      final k = d.toIso8601String().substring(0, 10);
      final ds = state.history[k] ?? [];
      final rate =
          ds.isEmpty ? 0.0 : ds.where((x) => x.taken).length / ds.length;
      return {
        'day': ['S', 'M', 'T', 'W', 'T', 'F', 'S'][d.weekday % 7],
        'rate': rate
      };
    });

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      child: Column(children: [
        // Adherence Hero
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(24)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('OVERALL ADHERENCE',
                style: TextStyle(
                    fontFamily: ff,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.45),
                    letterSpacing: 0.8)),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$overallAdh%',
                  style: TextStyle(
                      fontFamily: ff,
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -3,
                      height: 1.0)),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(overallAdh >= 80 ? 'EXCELLENT' : (overallAdh >= 60 ? 'STABLE' : 'KEEP GOING'),
                    style: TextStyle(
                        fontFamily: ff,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: overallAdh >= 80
                            ? const Color(0xFF34C759)
                            : (overallAdh >= 60
                                ? const Color(0xFFFF9500)
                                : const Color(0xFFFF453A)))),
              ),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                  value: overallAdh / 100.0,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  color: overallAdh >= 80
                      ? const Color(0xFF34C759)
                      : (overallAdh >= 60
                          ? const Color(0xFFFF9500)
                          : const Color(0xFFFF453A))),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.4,
          children: [
            _StatCard(
                label: 'Doses Taken',
                val: '$taken',
                sub: 'of $total total',
                emoji: '✅',
                L: L,
                ff: ff).animate().fade(delay: 100.ms).slideY(begin: 0.2, end: 0),
            _StatCard(
                label: '7-Day Rate',
                val: '$last7Adh%',
                sub: 'Last 7 days',
                emoji: '📈',
                L: L,
                ff: ff).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),
            _StatCard(
                label: 'Current Streak',
                val: '${streak}d',
                sub: 'days in a row',
                emoji: '🔥',
                L: L,
                ff: ff).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),
                _StatCard(
                    label: 'Days Tracked',
                    val: '$daysTracked',
                    sub: 'days of data',
                    emoji: '📅',
                    L: L,
                    ff: ff).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0),
              ],
            ),
        const SizedBox(height: 16),

        // Weekly Bar Chart
        Section(
            title: 'This Week',
            child: Container(
              padding: const EdgeInsets.all(16),
              color: L.card,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: weekData.map((w) {
                  final rate = w['rate'] as double;
                  return Expanded(
                    child: Column(children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: (rate * 60).clamp(8, 60),
                        decoration: BoxDecoration(
                            color: rate >= 0.8
                                ? const Color(0xFF111111)
                                : (rate > 0 ? const Color(0xFFFF9500) : L.fill),
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      const SizedBox(height: 6),
                      Text(w['day'] as String,
                          style: TextStyle(
                              fontFamily: ff,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: L.sub)),
                    ]),
                  );
                }).toList(),
              ),
            )),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, val, sub, emoji, ff;
  final AppThemeColors L;
  const _StatCard(
      {required this.label,
      required this.val,
      required this.sub,
      required this.emoji,
      required this.L,
      required this.ff});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: L.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: L.border, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const Spacer(),
        Text(val,
            style: TextStyle(
                fontFamily: ff,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: L.text,
                letterSpacing: -1)),
        Text(label,
            style: TextStyle(
                fontFamily: ff,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: L.sub)),
        Text(sub, style: TextStyle(fontFamily: ff, fontSize: 10, color: L.sub)),
      ]),
    );
  }
}

// ── App Tab ──────────────────────────────────────────────────────────────

class _AppTab extends StatefulWidget {
  final AppState state;
  final AppThemeColors L;
  final String ff;
  final VoidCallback onClose;
  const _AppTab(
      {required this.state,
      required this.L,
      required this.ff,
      required this.onClose});
  @override
  State<_AppTab> createState() => _AppTabState();
}

class _AppTabState extends State<_AppTab> {
  int _leadMins = 0;
  final _leadOpts = [
    {"v": 0, "l": "On time"},
    {"v": 5, "l": "5 min early"},
    {"v": 10, "l": "10 min early"},
    {"v": 15, "l": "15 min early"}
  ];

  @override
  Widget build(BuildContext context) {
    final L = widget.L;
    final ff = widget.ff;
    final state = widget.state;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      child: Column(children: [
        Section(
            title: 'Notifications',
            child: Column(children: [
              SRow(
                  icon: Icons.notifications_active_outlined,
                  iconBg: const Color(0xFFEF4444),
                  label: 'Dose Reminders',
                  sub: 'Get notified when it\'s time',
                  right: AppToggle(
                      value: state.profile?.notifPerm ?? true,
                      onChanged: (v) {
                        if (state.profile != null) {
                          state.saveProfile(
                              state.profile!.copyWith(notifPerm: v));
                        }
                      }),
                  first: true,
                  border: true),
              SRow(
                  icon: Icons.flash_on_outlined,
                  iconBg: const Color(0xFFF59E0B),
                  label: 'Sound & Haptics',
                  sub: 'Vibrate and play sound',
                  right: AppToggle(
                      value: state.profile?.notifSound ?? true,
                      onChanged: (v) {
                        if (state.profile != null) {
                          state.saveProfile(
                              state.profile!.copyWith(notifSound: v));
                        }
                      }),
                  border: true),
              SRow(
                  icon: Icons.access_time_outlined,
                  iconBg: const Color(0xFF6366F1),
                  label: 'Refill Alerts',
                  sub: 'Alert when meds run low',
                  right: AppToggle(
                      value: state.profile?.notifRefill ?? true,
                      onChanged: (v) {
                        if (state.profile != null) {
                          state.saveProfile(
                              state.profile!.copyWith(notifRefill: v));
                        }
                      }),
                  last: true,
                  border: false),
            ])),
        Section(
            title: 'Reminder Timing',
            child: Column(
                children: _leadOpts.asMap().entries.map((e) {
              final o = e.value;
              return _SelectRow(
                  label: o['l'] as String,
                  isSel: _leadMins == o['v'],
                  onClick: () => setState(() => _leadMins = o['v'] as int),
                  L: L,
                  ff: ff,
                  first: e.key == 0,
                  last: e.key == _leadOpts.length - 1,
                  border: e.key < _leadOpts.length - 1);
            }).toList())),
        Section(
            title: 'Appearance',
            child: SRow(
                icon: state.darkMode
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                iconBg: state.darkMode
                    ? const Color(0xFF5856D6)
                    : const Color(0xFFF59E0B),
                label: 'Dark Mode',
                sub: state.darkMode ? 'Using dark theme' : 'Using light theme',
                right: AppToggle(
                    value: state.darkMode,
                    onChanged: (_) => state.toggleDarkMode()),
                border: false)),
        Section(
            title: 'Personalization',
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: L.card,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ACCENT COLOR',
                              style: TextStyle(
                                  fontFamily: ff,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: L.sub,
                                  letterSpacing: 0.5)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: L.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4)),
                            child: Text('PREMIUM',
                                style: TextStyle(
                                    fontFamily: ff,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: L.green)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            'A3E635', // Lime
                            '3B82F6', // Blue
                            '8B5CF6', // Purple
                            'EC4899', // Pink
                            'EF4444', // Red
                            'F59E0B', // Amber
                            '10B981', // Emerald
                            '06B6D4', // Cyan
                          ].map((hex) {
                            final isSel =
                                state.profile?.accentColor == hex;
                            return GestureDetector(
                              onTap: () => state.updateAccentColor(hex),
                              child: Container(
                                width: 44,
                                height: 44,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                    color: hexToColor(hex),
                                    shape: BoxShape.circle,
                                    border: isSel
                                        ? Border.all(
                                            color: L.text, width: 2.5)
                                        : null,
                                    boxShadow: isSel
                                        ? [
                                            BoxShadow(
                                                color: hexToColor(hex)
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4))
                                          ]
                                        : null),
                                child: isSel
                                    ? Center(
                                        child: Icon(Icons.check_rounded,
                                            color: hex == 'A3E635'
                                                ? Colors.black
                                                : Colors.white,
                                            size: 20))
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ]),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                color: L.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('APP ICON',
                        style: TextStyle(
                            fontFamily: ff,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: L.sub,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          {'id': 'default', 'label': 'Default', 'path': 'assets/images/app_icon.png'},
                          {'id': 'gold', 'label': 'Premium Gold', 'path': 'assets/images/app_icon_gold.png'},
                          {'id': 'blue', 'label': 'Deep Blue', 'path': 'assets/images/app_icon_blue.png'},
                          {'id': 'dark', 'label': 'Classic Dark', 'path': 'assets/images/app_icon_dark.png'},
                        ].map((icon) {
                          final isSel = (state.profile?.appIcon ?? 'default') == icon['id'];
                          return GestureDetector(
                            onTap: () => state.updateAppIcon(icon['id'] as String),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: isSel ? Border.all(color: L.green, width: 3) : null,
                                      image: DecorationImage(
                                        image: AssetImage(icon['path'] as String),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(icon['label'] as String,
                                      style: TextStyle(
                                          fontFamily: ff,
                                          fontSize: 10,
                                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                                          color: isSel ? L.green : L.sub)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              Container(
                padding: const EdgeInsets.all(16),
                color: L.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('REMINDER SOUND',
                        style: TextStyle(
                            fontFamily: ff,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: L.sub,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'Default', 'Chime', 'Pulse', 'Digital', 'Zen', 'Alert'
                        ].map((sound) {
                          final isSel = (state.profile?.reminderSound ?? 'Default') == sound;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              state.updateReminderSound(sound);
                            },
                            child: AnimatedContainer(
                              duration: 300.ms,
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF111111) : L.fill,
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(
                                  color: isSel ? L.green.withValues(alpha: 0.3) : Colors.transparent
                                )
                              ),
                              child: Text(sound,
                                  style: TextStyle(
                                      fontFamily: ff,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isSel ? L.green : L.text)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ])),
        Section(
            title: 'Security',
            child: SRow(
                icon: Icons.fingerprint_rounded,
                iconBg: const Color(0xFF111111),
                label: 'Biometric Lock',
                sub: 'Unlock with FaceID / Fingerprint',
                right: AppToggle(
                    value: state.profile?.biometricEnabled ?? false,
                    onChanged: (v) => state.toggleBiometricLock(v)),
                border: false)),
        Section(
            title: 'Support & Feedback',
            child: Container(
              padding: const EdgeInsets.all(16),
              color: L.card,
              child: Column(children: [
                Text('Enjoying Med AI?',
                    style: TextStyle(
                        fontFamily: ff,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: L.text)),
                const SizedBox(height: 4),
                Text('Your feedback helps us improve for everyone.',
                    style:
                        TextStyle(fontFamily: ff, fontSize: 12, color: L.sub)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      5,
                      (i) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.star_rounded,
                                    color: L.amber, size: 36)
                                .animate(
                                    onPlay: (controller) =>
                                        controller.repeat(reverse: true))
                                .shimmer(
                                    delay: (i * 200).ms,
                                    duration: 2.seconds,
                                    color: Colors.white.withValues(alpha: 0.3))
                                .scale(
                                    begin: const Offset(1, 1),
                                    end: const Offset(1.1, 1.1),
                                    duration: 2.seconds,
                                    curve: Curves.easeInOut),
                          )),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  // ignore: deprecated_member_use
                  onTap: () => Share.share(
                      'I\'m using Med AI to stay on top of my medications! 💊'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(24)),
                    child: const Text('Share with friends',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ]),
            )),
        Section(
            title: 'App Info',
            child: Column(children: [
              const SRow(
                  icon: '💊',
                  label: 'Med AI',
                  sub: 'Version 2.0 · Premium Enabled',
                  border: true),
              SRow(
                  icon: Icons.shield_outlined,
                  iconBg: const Color(0xFF22C55E),
                  label: 'Privacy',
                  sub: 'Your data stays on this device',
                  onClick: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen())),
                  border: true),
              SRow(
                  icon: Icons.info_outline_rounded,
                  iconBg: const Color(0xFF6366F1),
                  label: '${state.meds.length} medicines tracked',
                  sub: 'Smart reminders active',
                  border: false),
            ])),
      ]),
    );
  }
}

// ── Data Tab ──────────────────────────────────────────────────────────────

class _DataTab extends StatefulWidget {
  final AppState state;
  final AppThemeColors L;
  final String ff;
  final VoidCallback onClose;
  const _DataTab(
      {required this.state,
      required this.L,
      required this.ff,
      required this.onClose});
  @override
  State<_DataTab> createState() => _DataTabState();
}

class _DataTabState extends State<_DataTab> {
  bool _confirming = false;

  Future<void> _exportCSV() async {
    final state = widget.state;
    final sb = state.exportDataCSV();
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/med_ai_export.csv');
      await file.writeAsString(sb);
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: 'Med AI Export');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final L = widget.L;
    final ff = widget.ff;
    final totalTaken =
        state.history.values.expand((e) => e).where((e) => e.taken).length;
    final totalDoses = state.history.values.expand((e) => e).length;
    final daysTracked = state.history.keys.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      child: Column(children: [
        // Data Summary Hero
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(24)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('YOUR DATA SUMMARY',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: [
                _SummaryBox(l: 'Medicines', v: '${state.meds.length}', ff: ff),
                _SummaryBox(
                    l: 'Alarms set',
                    v: '${state.meds.length}',
                    ff: ff), // Mocked for now
                _SummaryBox(l: 'Days tracked', v: '$daysTracked', ff: ff),
                _SummaryBox(l: 'Doses logged', v: '$totalDoses', ff: ff),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 16),

        Section(
            title: 'Export & Backup',
            child: Column(children: [
              SRow(
                  icon: Icons.picture_as_pdf_rounded,
                  iconBg: const Color(0xFF6366F1),
                  label: 'Export PDF Report',
                  sub: 'For doctors and caregivers',
                  onClick: () => ExportService.exportAdherenceReport(state),
                  border: true),
              SRow(
                  icon: Icons.download_rounded,
                  iconBg: const Color(0xFF22C55E),
                  label: 'Export History as CSV',
                  sub: '$totalTaken dose records',
                  onClick: _exportCSV,
                  border: false),
            ])),

        Section(
            title: 'Reset',
            child: SRow(
                icon: Icons.delete_outline_rounded,
                iconBg: const Color(0xFFEF4444),
                label: 'Delete All Data',
                sub: 'Removes all medicines, history & settings',
                onClick: () => setState(() => _confirming = true),
                border: false)),

        if (_confirming) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: L.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: L.red.withValues(alpha: 0.2))),
            child: Column(children: [
              Text('Delete All Data?',
                  style: TextStyle(
                      fontFamily: ff,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: L.red)),
              const SizedBox(height: 6),
              const Text(
                  'This will permanently delete all your data. This cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: GestureDetector(
                        onTap: () => setState(() => _confirming = false),
                        child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                                color: L.fill,
                                borderRadius: BorderRadius.circular(24)),
                            child: Center(
                                child: Text('Cancel',
                                    style: TextStyle(
                                        fontFamily: ff,
                                        fontWeight: FontWeight.w700)))))),
                const SizedBox(width: 8),
                Expanded(
                    child: GestureDetector(
                        onTap: () {
                          state.deleteAllData();
                          widget.onClose();
                        },
                        child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                                color: L.red,
                                borderRadius: BorderRadius.circular(24)),
                            child: const Center(
                                child: Text('Delete Everything',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)))))),
              ]),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String l, v, ff;
  const _SummaryBox({required this.l, required this.v, required this.ff});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(v,
            style: TextStyle(
                fontFamily: ff,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.8)),
        Text(l,
            style: TextStyle(
                fontFamily: ff,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.45))),
      ]),
    );
  }
}
