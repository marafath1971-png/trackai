import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../providers/app_state.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/auth_service.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../widgets/common/paywall_sheet.dart';
import '../../../../widgets/shared/shared_widgets.dart';
import 'settings_shared.dart';
import '../../../../models/constants.dart';
import '../../../settings/global_settings_screen.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/haptic_engine.dart';

class ProfileTab extends StatefulWidget {
  final AppState state;
  final AppThemeColors L;

  const ProfileTab({
    super.key,
    required this.state,
    required this.L,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  String? _genderInput;
  String? _goalInput;
  String? _countryInput;
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
    _countryInput = p?.country;
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
    final s = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      child: Column(children: [
        // Avatar + Name Hero
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: L.text, // Premium Industrial Black
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: L.text.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: L.bg.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: L.bg.withValues(alpha: 0.2))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Center(
                    child: p?.photoUrl != null
                        ? Image.network(
                            p!.photoUrl!,
                            fit: BoxFit.cover,
                            width: 72,
                            height: 72,
                            errorBuilder: (_, __, ___) => Text(p.avatar,
                                style: AppTypography.displaySmall
                                    .copyWith(fontSize: 36)),
                          )
                        : Text(p?.avatar ?? '😊',
                            style: AppTypography.displaySmall
                                .copyWith(fontSize: 36))),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(p?.name ?? 'Your Name',
                            style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.w900,
                                color: L.bg,
                                fontSize: 22,
                                letterSpacing: -0.5)),
                      ),
                      if (widget.state.isPremium) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('PRO',
                              style: AppTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 8,
                                  color: Colors.black,
                                  letterSpacing: 0.5)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                      '${p?.age != null && p!.age.isNotEmpty ? "Age ${p.age}" : "Age not set"}${p?.gender != null && p!.gender.isNotEmpty ? " · ${p.gender}" : ""}',
                      style: AppTypography.bodySmall
                          .copyWith(color: L.bg.withValues(alpha: 0.5), fontWeight: FontWeight.w700)),
                ])),
            if (!_editing)
              BouncingButton(
                onTap: () {
                  HapticEngine.selection();
                  setState(() => _editing = true);
                },
                scaleFactor: 0.9,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                      color: L.bg.withValues(alpha: 0.1), 
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: L.bg.withValues(alpha: 0.15))),
                  child: Text(s.edit.toUpperCase(),
                      style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 1.0,
                          color: L.bg)),
                ),
              ),
          ]),
        ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 20),

        if (_editing) ...[
          SettingsSection(
              title: s.editProfile,
              child: Column(children: [
                SettingsEditField(
                    label: 'Name',
                    ctrl: _nameCtrl,
                    placeholder: 'Your name',
                    L: L),
                SettingsEditField(
                    label: 'Age',
                    ctrl: _ageCtrl,
                    placeholder: 'e.g. 35',
                    L: L,
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
                          first: e.key == 0,
                          last: e.key == goals.length - 1,
                          border: e.key < goals.length - 1))
                      .toList())),
          SettingsSection(
              title: 'Country',
              child: Column(
                  children: kCountries
                      .asMap()
                      .entries
                      .map((e) => SettingsSelectRow(
                          label: e.value['v']!,
                          isSel: _countryInput == e.value['v'],
                          onClick: () =>
                              setState(() => _countryInput = e.value['v']),
                          L: L,
                          first: e.key == 0,
                          last: e.key == kCountries.length - 1,
                          border: e.key < kCountries.length - 1))
                      .toList())),
          Row(children: [
            Expanded(
                child: BouncingButton(
              onTap: () {
                HapticEngine.selection();
                setState(() {
                  _editing = false;
                  _nameCtrl.text = p?.name ?? '';
                  _ageCtrl.text = p?.age ?? '';
                  _genderInput = p?.gender;
                  _goalInput = p?.goal;
                  _countryInput = p?.country;
                });
              },
              scaleFactor: 0.95,
              child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                      color: L.fill, borderRadius: BorderRadius.circular(24)),
                  child: Center(
                      child: Text(s.cancel,
                          style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700, color: L.text)))),
            )),
            const SizedBox(width: 8),
            Expanded(
                flex: 2,
                child: BouncingButton(
                  onTap: () {
                    HapticEngine.selection();
                    final newProfile = p?.copyWith(
                            name: _nameCtrl.text,
                            age: _ageCtrl.text,
                            gender: _genderInput,
                            goal: _goalInput,
                            country: _countryInput) ??
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
                  scaleFactor: 0.95,
                  child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                          color: L.text,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: L.text.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ]),
                      child: Center(
                          child: Text('SAVE CHANGES',
                              style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                  color: L.bg)))),
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
                    border: true),
                SettingsModalRow(
                    icon: '🌍',
                    label: 'Country',
                    sub: p?.country ?? 'Not set',
                    last: true,
                    border: false),
              ])),
          if (!widget.state.isPremium)
            BouncingButton(
              onTap: () {
                HapticEngine.selection();
                PaywallSheet.show(context);
              },
              scaleFactor: 0.97,
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: L.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: L.primary.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: AppShadows.soft,
                ),
                child: Row(children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: L.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                        child: Text('🚀', style: TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Upgrade to MedAI Pro',
                            style: AppTypography.titleLarge.copyWith(
                                color: L.text,
                                fontSize: 18,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('Unlock AI insights, Family Sharing & more',
                            style: AppTypography.labelSmall.copyWith(
                                color: L.sub,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1)),
                      ])),
                  Icon(Icons.chevron_right_rounded, color: L.primary, size: 28),
                ]),
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(
                delay: 3.seconds,
                duration: 2.seconds,
                color: L.primary.withValues(alpha: 0.1)),
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
            title: 'App Settings',
            child: Column(children: [
              SettingsModalRow(
                icon: '🌐',
                label: s.globalSettings,
                sub: s.globalSettingsSubtitle,
                onClick: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const GlobalSettingsScreen()),
                  );
                },
                first: true,
                border: true,
              ),
              SettingsModalRow(
                icon: widget.state.darkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                label: 'Appearance',
                sub: widget.state.darkMode ? 'Dark Mode' : 'Light Mode',
                onClick: () => widget.state.toggleDarkMode(),
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
