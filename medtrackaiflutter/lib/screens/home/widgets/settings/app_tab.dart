import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../../../providers/app_state.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/shared/shared_widgets.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../domain/entities/entities.dart';
import '../../../settings/privacy_policy_screen.dart';
import '../../../../widgets/common/paywall_sheet.dart';
import '../../../../services/notification_service.dart';
import 'settings_shared.dart';

class AppTab extends StatefulWidget {
  final AppState state;
  final AppThemeColors L;
  final String ff;
  final VoidCallback onClose;

  const AppTab({
    super.key,
    required this.state,
    required this.L,
    required this.ff,
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
    final ff = widget.ff;
    final profile = context.select<AppState, UserProfile?>((s) => s.profile);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                          s.saveProfile(
                              s.profile!.copyWith(notifPerm: v));
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
                          s.saveProfile(
                              s.profile!.copyWith(notifSound: v));
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
                          s.saveProfile(
                              s.profile!.copyWith(notifRefill: v));
                        }
                      }),
                  last: false,
                  border: true),
              SettingsModalRow(
                  icon: Icons.notifications_none_rounded,
                  iconBg: L.sub,
                  label: 'Test Notifications',
                  sub: 'Send a test reminder now',
                  onClick: () {
                    HapticFeedback.lightImpact();
                    NotificationService.showTestNotification();
                  },
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
                  ff: ff,
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
                sub: context.select<AppState, bool>((s) => s.darkMode) ? 'Using dark theme' : 'Using light theme',
                right: AppToggle(
                    value: context.select<AppState, bool>((s) => s.darkMode),
                    onChanged: (_) => context.read<AppState>().toggleDarkMode()),
                border: false)),
        SettingsSection(
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
                                profile?.accentColor == hex;
                            return GestureDetector(
                              onTap: () => context.read<AppState>().updateAccentColor(hex),
                              child: Container(
                                width: 44,
                                height: 44,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                    color: hexToColor(hex),
                                    shape: BoxShape.circle,
                                    border: isSel
                                        ? Border.all(
                                            color: L.text, width: 2.0)
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
                  label: '${context.select<AppState, int>((s) => s.meds.length)} medicines tracked',
                  sub: 'Smart reminders active',
                  border: false),
            ])),
        const SizedBox(height: 120),
      ]),
    );
  }
}
