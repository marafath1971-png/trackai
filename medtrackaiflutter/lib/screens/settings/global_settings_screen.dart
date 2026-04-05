import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../domain/entities/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/unified_header.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/shared/shared_widgets.dart';
import '../../core/utils/haptic_engine.dart';

// ══════════════════════════════════════════════════════════════════════
// GLOBAL SETTINGS SCREEN (Cal AI Industrial Authority Refined)
// ══════════════════════════════════════════════════════════════════════

class GlobalSettingsScreen extends StatefulWidget {
  const GlobalSettingsScreen({super.key});

  @override
  State<GlobalSettingsScreen> createState() => _GlobalSettingsScreenState();
}

class _GlobalSettingsScreenState extends State<GlobalSettingsScreen> {
  late UserProfile _profile;

  static const List<Map<String, String>> _languages = [
    {'code': 'en', 'label': 'English', 'flag': '🇺🇸'},
    {'code': 'fr', 'label': 'Français (French)', 'flag': '🇫🇷'},
    {'code': 'ja', 'label': '日本語 (Japanese)', 'flag': '🇯🇵'},
    {'code': 'ko', 'label': '한국어 (Korean)', 'flag': '🇰🇷'},
    {'code': 'zh', 'label': '中文 (Chinese)', 'flag': '🇨🇳'},
    {'code': 'he', 'label': 'עברית (Hebrew)', 'flag': '🇮🇱'},
    {'code': 'ms', 'label': 'Bahasa Melayu', 'flag': '🇲🇾'},
  ];

  static const List<Map<String, String>> _countries = [
    {'code': 'US', 'label': 'United States', 'flag': '🇺🇸'},
    {'code': 'GB', 'label': 'United Kingdom', 'flag': '🇬🇧'},
    {'code': 'CA', 'label': 'Canada', 'flag': '🇨🇦'},
    {'code': 'AU', 'label': 'Australia', 'flag': '🇦🇺'},
    {'code': 'JP', 'label': 'Japan', 'flag': '🇯🇵'},
    {'code': 'KR', 'label': 'South Korea', 'flag': '🇰🇷'},
    {'code': 'SG', 'label': 'Singapore', 'flag': '🇸🇬'},
    {'code': 'IL', 'label': 'Israel', 'flag': '🇮🇱'},
    {'code': 'MY', 'label': 'Malaysia', 'flag': '🇲🇾'},
    {'code': 'AE', 'label': 'United Arab Emirates', 'flag': '🇦🇪'},
  ];

  @override
  void initState() {
    super.initState();
    _profile = context.read<AppState>().profile ?? UserProfile();
  }

  Future<void> _save(UserProfile updated) async {
    HapticEngine.selection();
    setState(() => _profile = updated);
    await context.read<AppState>().saveProfile(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = AppLocalizations.of(context)!;
    final L = context.L;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _profile.amoledMode && isDark ? Colors.black : L.bg,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(20, topPad + 110, 20, 120),
            physics: const BouncingScrollPhysics(),
            children: [
                  
                  // ── LOCALIZATION BLOCK ───────────────────────
                  _IndustrialSection(
                    label: 'LOCALIZATION',
                    icon: Icons.public_rounded,
                    L: L,
                    children: [
                      _PickerTile(
                        label: 'Country',
                        value: _countries.firstWhere((c) => c['code'] == _profile.country, orElse: () => _countries[0])['label']!,
                        flag: _countries.firstWhere((c) => c['code'] == _profile.country, orElse: () => _countries[0])['flag']!,
                        onTap: () async {
                          final res = await showModalBottomSheet<String>(
                            context: context,
                            builder: (_) => _PickerSheet(title: 'Select Country', items: _countries, selectedCode: _profile.country),
                          );
                          if (res != null) _save(_profile.copyWith(country: res));
                        },
                        L: L,
                      ),
                      _PickerTile(
                        label: 'Language',
                        value: _languages.firstWhere((l) => l['code'] == _profile.preferredLanguage, orElse: () => _languages[0])['label']!,
                        flag: _languages.firstWhere((l) => l['code'] == _profile.preferredLanguage, orElse: () => _languages[0])['flag']!,
                        onTap: () async {
                          final res = await showModalBottomSheet<String>(
                            context: context,
                            builder: (_) => _PickerSheet(title: 'Select Language', items: _languages, selectedCode: _profile.preferredLanguage),
                          );
                          if (res != null) _save(_profile.copyWith(preferredLanguage: res));
                        },
                        L: L,
                        isLast: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── CLINICAL MODES BLOCK ─────────────────────
                  _IndustrialSection(
                    label: 'CLINICAL MODES',
                    icon: Icons.science_rounded,
                    L: L,
                    children: [
                      _ToggleTile(
                        title: s.showGenericNames,
                        subtitle: s.showGenericNamesSubtitle,
                        value: _profile.showGenericNames,
                        onChanged: (v) => _save(_profile.copyWith(showGenericNames: v)),
                        L: L,
                      ),
                      _ToggleTile(
                        title: s.shabbatMode,
                        subtitle: s.shabbatModeSubtitle,
                        value: _profile.shabbatMode,
                        onChanged: (v) => _save(_profile.copyWith(shabbatMode: v)),
                        L: L,
                      ),
                      _ToggleTile(
                        title: 'Diabetes Metrics',
                        subtitle: 'Synchronize blood glucose logs',
                        value: _profile.diabetesMode,
                        onChanged: (v) => _save(_profile.copyWith(diabetesMode: v)),
                        L: L,
                      ),
                      _ToggleTile(
                        title: 'Hypertension Tracking',
                        subtitle: 'Synchronize systolic/diastolic logs',
                        value: _profile.hypertensionMode,
                        onChanged: (v) => _save(_profile.copyWith(hypertensionMode: v)),
                        L: L,
                        isLast: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── DISPLAY ARCHITECTURE BLOCK ───────────────
                  _IndustrialSection(
                    label: 'DISPLAY ARCHITECTURE',
                    icon: Icons.palette_rounded,
                    L: L,
                    children: [
                      _ToggleTile(
                        title: 'Amoled Optimization',
                        subtitle: 'Pure Black interface for power efficiency',
                        value: _profile.amoledMode,
                        onChanged: (v) => _save(_profile.copyWith(amoledMode: v)),
                        L: L,
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 120),
                ],
              ),

          // ── PREMIUM GLASS HEADER ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: EdgeInsets.fromLTRB(24, topPad + 12, 20, 16),
                  decoration: BoxDecoration(
                    color: L.bg.withValues(alpha: 0.8),
                    border: Border(bottom: BorderSide(color: L.border.withValues(alpha: 0.08), width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      BouncingButton(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back_ios_new_rounded, color: L.text, size: 22),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'PREFERENCES',
                              style: AppTypography.labelSmall.copyWith(
                                color: L.sub.withValues(alpha: 0.4),
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              'Settings',
                              style: AppTypography.headlineMedium.copyWith(
                                color: L.text,
                                fontWeight: FontWeight.w900,
                                fontSize: 26,
                                height: 1.1,
                                letterSpacing: -1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndustrialSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Widget> children;
  final AppThemeColors L;
  const _IndustrialSection({required this.label, required this.icon, required this.children, required this.L});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 12),
          child: Row(children: [
            Icon(icon, size: 14, color: L.text.withValues(alpha: 0.4)),
            const SizedBox(width: 10),
            Text(label, style: AppTypography.labelSmall.copyWith(
              color: L.text.withValues(alpha: 0.4), 
              fontWeight: FontWeight.w900, 
              letterSpacing: 2.0, 
              fontSize: 9)),
          ]),
        ),
        SquircleCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppThemeColors L;
  final bool isLast;
  const _ToggleTile({required this.title, required this.subtitle, required this.value, required this.onChanged, required this.L, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: L.border.withValues(alpha: 0.05), width: 0.5))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        title: Text(title, style: AppTypography.labelLarge.copyWith(
          color: L.text, 
          fontWeight: FontWeight.w900, 
          fontSize: 16,
          letterSpacing: -0.3,
        )),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: AppTypography.bodySmall.copyWith(
            color: L.text.withValues(alpha: 0.5), 
            fontWeight: FontWeight.w500, 
            height: 1.4, 
            fontSize: 12)),
        ),
        trailing: AppToggle(
          value: value,
          onChanged: (v) {
            HapticEngine.selection();
            onChanged(v);
          },
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String label, value, flag;
  final VoidCallback onTap;
  final AppThemeColors L;
  final bool isLast;
  const _PickerTile({required this.label, required this.value, required this.flag, required this.onTap, required this.L, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: L.border.withValues(alpha: 0.05), width: 0.5))),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(label, style: AppTypography.labelLarge.copyWith(color: L.text, fontWeight: FontWeight.w900, fontSize: 15)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$flag $value', style: AppTypography.bodySmall.copyWith(color: L.text.withValues(alpha: 0.8), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: -0.2)),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right_rounded, size: 20, color: L.sub.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<Map<String, String>> items;
  final String selectedCode;
  const _PickerSheet({required this.title, required this.items, required this.selectedCode});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      decoration: BoxDecoration(color: L.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: L.border.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Text(title, style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900, color: L.text, fontSize: 18)),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = item['code'] == selectedCode;
              return ListTile(
                onTap: () {
                  HapticEngine.selection();
                  Navigator.pop(context, item['code']);
                },
                title: Text(item['label']!, style: AppTypography.bodyMedium.copyWith(fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700, color: L.text)),
                trailing: isSelected ? Icon(Icons.check_rounded, color: L.text) : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
