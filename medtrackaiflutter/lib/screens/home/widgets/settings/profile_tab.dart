import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../providers/app_state.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/auth_service.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../widgets/common/paywall_sheet.dart';
import 'settings_shared.dart';

class ProfileTab extends StatefulWidget {
  final AppState state;
  final AppThemeColors L;
  final String ff;
  
  const ProfileTab({
    super.key,
    required this.state,
    required this.L,
    required this.ff,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
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
              border: Border.all(color: L.border, width: 1.0)),
          child: Row(children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(24)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Center(
                    child: p?.photoUrl != null
                        ? Image.network(
                            p!.photoUrl!,
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
                            errorBuilder: (_, __, ___) => Text(p.avatar,
                                style: const TextStyle(fontSize: 28)),
                          )
                        : Text(p?.avatar ?? '😊',
                            style: const TextStyle(fontSize: 28))),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                    children: [
                      Text(p?.name ?? 'Your Name',
                          style: TextStyle(
                              fontFamily: ff,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: L.text,
                              letterSpacing: -0.3)),
                      if (widget.state.isPremium) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: L.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: L.primary, width: 0.5),
                          ),
                          child: Text('PRO', style: TextStyle(
                            fontFamily: ff, fontSize: 9, fontWeight: FontWeight.w900, color: L.primary
                          )),
                        ),
                      ],
                    ],
                  ),
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
          SettingsSection(
              title: 'Edit Profile',
              child: Column(children: [
                SettingsEditField(
                    label: 'Name',
                    ctrl: _nameCtrl,
                    placeholder: 'Your name',
                    L: L,
                    ff: ff),
                SettingsEditField(
                    label: 'Age',
                    ctrl: _ageCtrl,
                    placeholder: 'e.g. 35',
                    L: L,
                    ff: ff,
                    keyboard: TextInputType.number,
                    border: false),
              ])),
          SettingsSection(
              title: 'Gender',
              child: Column(
                  children: genders
                      .asMap()
                      .entries
                      .map((e) => SettingsSelectRow(
                          label: e.value,
                          isSel: _genderInput == e.value,
                          onClick: () => setState(() => _genderInput = e.value),
                          L: L,
                          ff: ff,
                          first: e.key == 0,
                          last: e.key == genders.length - 1,
                          border: e.key < genders.length - 1))
                      .toList())),
          SettingsSection(
              title: 'Primary Goal',
              child: Column(
                  children: goals
                      .asMap()
                      .entries
                      .map((e) => SettingsSelectRow(
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
          SettingsSection(
              title: 'Your Info',
              child: Column(children: [
                SettingsModalRow(
                    icon: '🎯',
                    label: 'Health Goal',
                    sub: p?.goal ?? 'Not set',
                    first: true,
                    border: true),
                SettingsModalRow(
                    icon: '🩺',
                    label: 'Conditions',
                    sub: p?.conditions.isNotEmpty == true
                        ? p!.conditions.join(", ")
                        : 'Not set',
                    border: true),
                SettingsModalRow(
                    icon: '🎂',
                    label: 'Age',
                    sub: p?.age != null && p!.age.isNotEmpty
                        ? '${p.age} years old'
                        : 'Not set',
                    border: true),
                SettingsModalRow(
                    icon: '🧬',
                    label: 'Gender',
                    sub: p?.gender ?? 'Not set',
                    last: true,
                    border: false),
              ])),
          
          if (!widget.state.isPremium)
            GestureDetector(
              onTap: () => PaywallSheet.show(context),
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [L.primary, L.primary.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: L.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Row(children: [
                  const Text('🚀', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Upgrade to MedAI Pro', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
                    Text('Unlock AI insights, Family Sharing & more', style: TextStyle(color: Colors.black.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600)),
                  ])),
                  const Icon(Icons.chevron_right_rounded, color: Colors.black),
                ]),
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(delay: 2.seconds, duration: 1.5.seconds),

          SettingsSection(
            title: 'Subscription',
            child: Column(children: [
              if (widget.state.isPremium)
                SettingsModalRow(
                  icon: '💳',
                  label: 'Manage Subscription',
                  sub: 'View or cancel your plan',
                  onClick: () => widget.state.manageSubscription(),
                  first: true,
                  border: true,
                ),
              SettingsModalRow(
                icon: '🔄',
                label: 'Restore Purchases',
                sub: 'Already paid? Restore here',
                onClick: () => widget.state.restorePurchases(),
                first: !widget.state.isPremium,
                last: true,
                border: false,
              ),
            ]),
          ),
          SettingsSection(
            title: 'Account',
            child: Column(
              children: [
                if (AuthService.isLoggedIn) ...[
                  SettingsModalRow(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    sub: AuthService.email,
                    onClick: () => widget.state.signOut(),
                    first: true,
                    last: true,
                    border: false,
                  ),
                ] else ...[
                  SettingsModalRow(
                    icon: '🌐',
                    label: 'Sign in with Google',
                    onClick: () => widget.state.signInWithGoogle(),
                    first: true,
                    border: true,
                  ),
                  SettingsModalRow(
                    icon: Icons.apple_rounded,
                    label: 'Sign in with Apple',
                    onClick: () => widget.state.signInWithApple(),
                    last: true,
                    border: false,
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 120),
      ]),
    );
  }
}
