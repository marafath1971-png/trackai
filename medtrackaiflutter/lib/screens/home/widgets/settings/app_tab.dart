import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../providers/app_state.dart';
import '../../../../widgets/shared/shared_widgets.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/share_service.dart';
import '../../../../widgets/shared/shared_widgets.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../domain/entities/entities.dart';
import '../../../settings/privacy_policy_screen.dart';
import '../../../../widgets/common/paywall_sheet.dart';
import 'settings_shared.dart';

class AppTab extends StatefulWidget {
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onClose;

  const AppTab({
    super.key,
    required this.state,
    required this.L,
    required this.onClose,
  });

  @override
  State<AppTab> createState() => _AppTabState();
}

class _AppTabState extends State<AppTab> {
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
    final profile = context.select<AppState, UserProfile?>((s) => s.profile);

    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      child: Column(children: [
        SettingsSection(
            title: 'Notifications',
            child: Column(children: [
              SettingsModalRow(
                  icon: Icons.notifications_active_outlined,
                  iconBg: const Color(0xFFEF4444),
                  label: 'Dose Reminders',
                  sub: 'Get notified when it\'s time',
                  right: AppToggle(
                      value: profile?.notifPerm ?? true,
                      onChanged: (v) {
                        final s = context.read<AppState>();
                        if (s.profile != null) {
                          s.saveProfile(s.profile!.copyWith(notifPerm: v));
                        }
                      }),
                  first: true,
                  border: true),
              SettingsModalRow(
                  icon: Icons.flash_on_outlined,
                  iconBg: const Color(0xFFF59E0B),
                  label: 'Sound & Haptics',
                  sub: 'Vibrate and play sound',
                  right: AppToggle(
                      value: profile?.notifSound ?? true,
                      onChanged: (v) {
                        final s = context.read<AppState>();
                        if (s.profile != null) {
                          s.saveProfile(s.profile!.copyWith(notifSound: v));
                        }
                      }),
                  border: true),
              SettingsModalRow(
                  icon: Icons.access_time_outlined,
                  iconBg: const Color(0xFF6366F1),
                  label: 'Refill Alerts',
                  sub: 'Alert when meds run low',
                  right: AppToggle(
                      value: profile?.notifRefill ?? true,
                      onChanged: (v) {
                        final s = context.read<AppState>();
                        if (s.profile != null) {
                          s.saveProfile(s.profile!.copyWith(notifRefill: v));
                        }
                      }),
                  last: true,
                  border: false),
            ])),
        SettingsSection(
            title: 'Reminder Timing',
            child: Column(
                children: _leadOpts.asMap().entries.map((e) {
              final o = e.value;
              return SettingsSelectRow(
                  label: o['l'] as String,
                  isSel: _leadMins == o['v'],
                  onClick: () => setState(() => _leadMins = o['v'] as int),
                  L: L,
                  first: e.key == 0,
                  last: e.key == _leadOpts.length - 1,
                  border: e.key < _leadOpts.length - 1);
            }).toList())),
        SettingsSection(
            title: 'Appearance',
            child: SettingsModalRow(
                icon: context.select<AppState, bool>((s) => s.darkMode)
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                iconBg: context.select<AppState, bool>((s) => s.darkMode)
                    ? const Color(0xFF5856D6)
                    : const Color(0xFFF59E0B),
                label: 'Dark Mode',
                sub: context.select<AppState, bool>((s) => s.darkMode)
                    ? 'Using dark theme'
                    : 'Using light theme',
                right: AppToggle(
                    value: context.select<AppState, bool>((s) => s.darkMode),
                    onChanged: (_) =>
                        context.read<AppState>().toggleDarkMode()),
                border: false)),
        SettingsSection(
            title: 'Personalization',
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: L.text,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ACCENT COLOR',
                              style: AppTypography.labelLarge.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  color: L.bg.withValues(alpha: 0.4),
                                  letterSpacing: 2.0)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: L.bg.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4)),
                            child: Text('PREMIUM',
                                style: AppTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 8,
                                    color: L.bg.withValues(alpha: 0.8))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
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
                            final isSel = profile?.accentColor == hex;
                            return GestureDetector(
                              onTap: () => context
                                  .read<AppState>()
                                  .updateAccentColor(hex),
                              child: Container(
                                width: 44,
                                height: 44,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                    color: hexToColor(hex),
                                    shape: BoxShape.circle,
                                    border: isSel
                                        ? Border.all(color: L.text, width: 2.0)
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
            ])),
        SettingsSection(
            title: 'Security',
            child: SettingsModalRow(
                icon: Icons.fingerprint_rounded,
                iconBg: const Color(0xFF111111),
                label: 'Biometric Lock',
                sub: 'Unlock with FaceID / Fingerprint',
                right: AppToggle(
                    value: profile?.biometricEnabled ?? false,
                    onChanged: (v) {
                      final s = context.read<AppState>();
                      if (s.isPremium) {
                        s.toggleBiometricLock(v);
                      } else {
                        PaywallSheet.show(context);
                      }
                    }),
                border: false)),
        SettingsSection(
            title: 'Support & Feedback',
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: L.fill.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: L.border.withValues(alpha: 0.05)),
              ),
              child: Column(children: [
                Text('Enjoying Med AI?',
                    style: AppTypography.titleLarge
                        .copyWith(fontWeight: FontWeight.w900, color: L.text, fontSize: 18)),
                const SizedBox(height: 6),
                Text('Your feedback helps us improve for everyone.',
                    style: AppTypography.bodySmall.copyWith(color: L.sub, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      5,
                      (i) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(Icons.star_rounded,
                                    color: L.text, size: 32)
                                .animate(
                                    onPlay: (controller) =>
                                        controller.repeat(reverse: true))
                                .shimmer(
                                    delay: (i * 200).ms,
                                    duration: 2.seconds,
                                    color: L.bg.withValues(alpha: 0.5))
                                .scale(
                                    begin: const Offset(1, 1),
                                    end: const Offset(1.1, 1.1),
                                    duration: 2.seconds,
                                    curve: Curves.easeInOut),
                          )),
                ),
                const SizedBox(height: 24),
                BouncingButton(
                  onTap: () => ShareService.shareText(
                      'I\'m using Med AI to stay on top of my medications! 💊'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                        color: L.text,
                        borderRadius: BorderRadius.circular(16)),
                    child: Center(
                      child: Text('SHARE WITH FRIENDS',
                          style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0, color: L.bg)),
                    ),
                  ),
                ),
              ]),
            )),
        SettingsSection(
            title: 'App Info',
            child: Column(children: [
              const SettingsModalRow(
                  icon: '💊',
                  label: 'Med AI',
                  sub: 'Version 2.0 · Premium Enabled',
                  border: true),
              SettingsModalRow(
                  icon: Icons.shield_outlined,
                  iconBg: const Color(0xFF22C55E),
                  label: 'Privacy',
                  sub: 'Your data stays on this device',
                  onClick: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen())),
                  border: true),
              SettingsModalRow(
                  icon: Icons.info_outline_rounded,
                  iconBg: const Color(0xFF6366F1),
                  label:
                      '${context.select<AppState, int>((s) => s.meds.length)} medicines tracked',
                  sub: 'Smart reminders active',
                  border: false),
            ])),
        const SizedBox(height: 120),
      ]),
    );
  }
}
