import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../providers/app_state.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/auth_service.dart';
import '../../../../widgets/common/paywall_sheet.dart';
import '../../../../widgets/shared/shared_widgets.dart';
import 'settings_shared.dart';
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

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.L.bg,
        title: Text('Delete Account?',
            style: AppTypography.titleLarge
                .copyWith(color: widget.L.text, fontWeight: FontWeight.w900)),
        content: Text(
          'This action is permanent and will delete all your medication history and account data from our servers.',
          style: AppTypography.bodyMedium.copyWith(color: widget.L.sub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL',
                style: AppTypography.labelLarge.copyWith(color: widget.L.sub)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.state.deleteAccount();
            },
            child: Text('DELETE',
                style: AppTypography.labelLarge.copyWith(
                    color: Colors.redAccent, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
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
      child: Column(
        children: [
          // Avatar + Name Hero
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: L.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: L.border.withValues(alpha: 0.07), width: 0.5),
              boxShadow: AppShadows.neumorphic,
            ),
            child: Row(children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                    color: L.fill.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: L.border.withValues(alpha: 0.1))),
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
                                      .copyWith(fontSize: 36))
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(1.0, 1.0),
                                end: const Offset(1.1, 1.1),
                                duration: 2000.ms,
                                curve: Curves.easeInOut,
                              )),
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
                                  color: L.text,
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
                                    fontSize: 10,
                                    color: Colors.black,
                                    letterSpacing: 0.5)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                        '${p?.age != null && p!.age.isNotEmpty ? "Age ${p.age}" : "Age not set"}${p?.gender != null && p!.gender.isNotEmpty ? " · ${p.gender}" : ""}',
                        style: AppTypography.bodySmall.copyWith(
                            color: L.sub.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w700)),
                  ])),
              if (!_editing)
                BouncingButton(
                  onTap: () {
                    HapticEngine.selection();
                    setState(() => _editing = true);
                  },
                  scaleFactor: 0.9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                        color: L.fill.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: L.border.withValues(alpha: 0.1))),
                    child: Text(s.edit.toUpperCase(),
                        style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 1.0,
                            color: L.text)),
                  ),
                ),
            ]),
          ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),

          // ── APP SETTINGS (GLOBAL AUTHORITY) ──────────
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
                last: true,
                border: false,
              ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(
                  duration: 3000.ms, color: L.primary.withValues(alpha: 0.05)),
            ]),
          ),
          const SizedBox(height: 24),

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
                            onClick: () =>
                                setState(() => _genderInput = e.value),
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
            // Removed redundant country selector from edit form to consolidate in Global Settings
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
                      HapticEngine.success();
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
            const SizedBox(height: 24),
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
                        color: L.border.withValues(alpha: 0.07), width: 0.5),
                    boxShadow: AppShadows.neumorphic,
                  ),
                  child: Row(children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: L.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                          child: const Text('🚀',
                                  style: TextStyle(fontSize: 24))
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(1.0, 1.0),
                                end: const Offset(1.2, 1.2),
                                duration: 1500.ms,
                                curve: Curves.easeInOut,
                              )),
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
                    Icon(Icons.chevron_right_rounded,
                        color: L.primary, size: 28),
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
            // Moved to top as primary section
            SettingsSection(
              title: 'Data & Reports',
              child: Column(children: [
                SettingsModalRow(
                  icon: Icons.assignment_rounded,
                  label: 'Clinical PDF Report',
                  sub: 'Generate a summary for your doctor',
                  onClick: () => widget.state.exportDataPDF(),
                  first: true,
                  border: true,
                ),
                SettingsModalRow(
                  icon: '📊',
                  label: 'Export CSV Data',
                  sub: 'Download raw history for backup',
                  onClick: () => widget.state.exportDataCSV(),
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
                      icon: '🚪',
                      label: 'Sign Out',
                      sub: AuthService.email,
                      onClick: () {
                        HapticEngine.selection();
                        widget.state.signOut();
                      },
                      first: true,
                      border: true,
                    ),
                    SettingsModalRow(
                      icon: '🗑️',
                      label: 'Delete Account',
                      sub: 'Permanently remove your data',
                      iconBg: L.red,
                      onClick: () => _confirmDeleteAccount(context),
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
            SettingsSection(
              title: 'Support & Feedback',
              child: Column(children: [
                SettingsModalRow(
                  icon: '💬',
                  label: 'Contact Support',
                  sub: 'Get help with your account',
                  onClick: () => widget.state.contactSupport(),
                  first: true,
                  border: true,
                ),
                SettingsModalRow(
                  icon: '⭐',
                  label: 'Rate MedAI',
                  sub: 'Help us improve for others',
                  onClick: () => widget.state.requestReview(),
                  last: true,
                  border: false,
                ),
              ]),
            ),
            SettingsSection(
              title: 'Legal & Privacy',
              child: Column(children: [
                SettingsModalRow(
                  icon: '🔐',
                  label: 'Privacy Policy',
                  sub: 'How we protect your data',
                  onClick: () => widget.state.openPrivacyPolicy(),
                  first: true,
                  border: true,
                ),
                SettingsModalRow(
                  icon: '📜',
                  label: 'Terms of Service',
                  sub: 'Your rights and responsibilities',
                  onClick: () => widget.state.openTermsOfService(),
                  border: true,
                ),
                SettingsModalRow(
                  icon: 'ℹ️',
                  label: 'Open Source Licenses',
                  sub: 'Software that makes MedAI possible',
                  onClick: () => showLicensePage(context: context),
                  last: true,
                  border: false,
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  Text(
                    'MedAI 1.0.0+1',
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MADE WITH ❤️ BY MEDAI TEAM',
                    style: AppTypography.labelSmall.copyWith(
                      color: L.sub.withValues(alpha: 0.2),
                      fontWeight: FontWeight.w900,
                      fontSize: 8,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 140),
          ],
        ],
      ),
    );
  }
}
