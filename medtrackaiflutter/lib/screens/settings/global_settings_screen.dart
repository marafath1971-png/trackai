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
// GLOBAL SETTINGS SCREEN
// Adapts app behavior for: USA, UK, CA, AU, JP, KR, SG, IL, MY
// ══════════════════════════════════════════════════════════════════════

class GlobalSettingsScreen extends StatefulWidget {
  const GlobalSettingsScreen({super.key});

  @override
  State<GlobalSettingsScreen> createState() => _GlobalSettingsScreenState();
}

class _GlobalSettingsScreenState extends State<GlobalSettingsScreen> {
  late UserProfile _profile;

  // Language options per market
  static const List<Map<String, String>> _languages = [
    {'code': 'en', 'label': 'English', 'flag': '🇺🇸'},
    {'code': 'fr', 'label': 'Français (French)', 'flag': '🇫🇷'},
    {'code': 'ja', 'label': '日本語 (Japanese)', 'flag': '🇯🇵'},
    {'code': 'ko', 'label': '한국어 (Korean)', 'flag': '🇰🇷'},
    {'code': 'zh', 'label': '中文 (Chinese)', 'flag': '🇨🇳'},
    {'code': 'he', 'label': 'עברית (Hebrew)', 'flag': '🇮🇱'},
    {'code': 'ms', 'label': 'Bahasa Melayu', 'flag': '🇲🇾'},
  ];

  // Country reference
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
    setState(() => _profile = updated);
    await context.read<AppState>().saveProfile(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _profile.amoledMode && isDark
          ? AppColors.black
          : theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const UnifiedHeader(title: 'Global Settings', showBack: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Country & Language ──────────────────────────────
                  _SectionHeader(
                    icon: '🌍',
                    title: s.country,
                    subtitle: s.countrySelectionSubtitle,
                  ),
                  _CountryLanguageTile(
                    profile: _profile,
                    languages: _languages,
                    countries: _countries,
                    onCountryChanged: (code) =>
                        _save(_profile.copyWith(country: code)),
                    onLanguageChanged: (code) =>
                        _save(_profile.copyWith(preferredLanguage: code)),
                  ),
                  const SizedBox(height: 8),

                  // ── Name Conventions ─────────────────────────────────
                  _SectionHeader(
                    icon: '💊',
                    title: s.medicationDisplay,
                    subtitle: s.showGenericNamesSubtitle,
                  ),
                  _SettingsTile(
                    title: s.showGenericNames,
                    subtitle: s.showGenericNamesSubtitle,
                    icon: Icons.label_outline_rounded,
                    badge: '🇬🇧 🇮🇱 🇨🇦',
                    value: _profile.showGenericNames,
                    onChanged: (v) =>
                        _save(_profile.copyWith(showGenericNames: v)),
                  ),
                  const SizedBox(height: 8),

                  // ── Religious Observance ─────────────────────────────
                  _SectionHeader(
                    icon: '🕌',
                    title: s.religiousObservance,
                    subtitle: s.shabbatModeSubtitle,
                  ),
                  _SettingsTile(
                    title: s.shabbatMode,
                    subtitle: s.shabbatModeSubtitle,
                    icon: Icons.nights_stay_rounded,
                    badge: '🇮🇱',
                    value: _profile.shabbatMode,
                    onChanged: (v) => _save(_profile.copyWith(shabbatMode: v)),
                  ),
                  const SizedBox(height: 8),

                  // ── Australia PBS ────────────────────────────────────
                  _SectionHeader(
                    icon: '🇦🇺',
                    title: s.pbsSafetyNet,
                    subtitle: s.pbsSafetyNetSubtitle,
                  ),
                  _PBSTrackerTile(
                    spendThisYear: _profile.pbsSpendThisYear,
                    onChanged: (v) =>
                        _save(_profile.copyWith(pbsSpendThisYear: v)),
                  ),
                  const SizedBox(height: 8),

                  // ── Chronic Disease Modes ────────────────────────────
                  const _SectionHeader(
                    icon: '🩺',
                    title: 'Clinical Modes',
                    subtitle: 'USA · UK · UAE · Malaysia',
                  ),
                  _SettingsTile(
                    title: s.diabetesMode,
                    subtitle:
                        'Log blood glucose alongside insulin / diabetes medications',
                    icon: Icons.water_drop_rounded,
                    badge: '🇦🇪 🇲🇾 🇺🇸',
                    value: _profile.diabetesMode,
                    onChanged: (v) => _save(_profile.copyWith(diabetesMode: v)),
                  ),
                  const SizedBox(height: 4),
                  _SettingsTile(
                    title: s.hypertensionMode,
                    subtitle:
                        'Log blood pressure alongside antihypertensive medications',
                    icon: Icons.favorite_rounded,
                    badge: '🇦🇪 🇲🇾 🇺🇸',
                    value: _profile.hypertensionMode,
                    onChanged: (v) =>
                        _save(_profile.copyWith(hypertensionMode: v)),
                  ),
                  const SizedBox(height: 8),

                  // ── Display ──────────────────────────────────────────
                  _SectionHeader(
                    icon: '📱',
                    title: s.displaySettings,
                    subtitle: s.amoledModeSubtitle,
                  ),
                  _SettingsTile(
                    title: s.amoledMode,
                    subtitle: s.amoledModeSubtitle,
                    icon: Icons.dark_mode_rounded,
                    badge: '🇰🇷',
                    value: _profile.amoledMode,
                    onChanged: (v) => _save(_profile.copyWith(amoledMode: v)),
                  ),
                  const SizedBox(height: 24),

                  // ── Info Card ────────────────────────────────────────
                  _InfoCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  const _SectionHeader(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 24),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(),
                    style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: L.text,
                        letterSpacing: 1.5,
                        fontSize: 12)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTypography.labelSmall
                        .copyWith(color: L.sub, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String badge;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value
              ? L.secondary.withValues(alpha: 0.4)
              : L.border.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: value ? L.secondary.withValues(alpha: 0.15) : L.fill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: value ? L.secondary : L.sub),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: AppTypography.titleLarge.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: L.text)),
            ),
            if (badge.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: L.text.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(badge,
                    style: AppTypography.labelSmall
                        .copyWith(fontSize: 10, fontWeight: FontWeight.w900)),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle,
              style: AppTypography.labelSmall.copyWith(
                  color: L.sub, height: 1.4, fontWeight: FontWeight.w500)),
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

class _CountryLanguageTile extends StatelessWidget {
  final UserProfile profile;
  final List<Map<String, String>> languages;
  final List<Map<String, String>> countries;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onLanguageChanged;

  const _CountryLanguageTile({
    required this.profile,
    required this.languages,
    required this.countries,
    required this.onCountryChanged,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final currentCountry = countries.firstWhere(
        (c) => c['code'] == profile.country,
        orElse: () => {'code': '', 'label': 'Select Country', 'flag': '🌍'});
    final currentLang = languages.firstWhere(
        (l) => l['code'] == profile.preferredLanguage,
        orElse: () => {'code': 'en', 'label': 'English', 'flag': '🇺🇸'});

    return Container(
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: L.border, width: 1.5),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              HapticEngine.selection();
              final selected = await showModalBottomSheet<String>(
                context: context,
                builder: (_) => _PickerSheet(
                  title: 'Select Country',
                  items: countries,
                  selectedCode: profile.country,
                ),
              );
              if (selected != null) onCountryChanged(selected);
            },
            child: ListTile(
              leading: Icon(Icons.location_on_outlined, color: L.sub),
              title: Text('Country',
                  style: AppTypography.titleLarge.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: L.text)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${currentCountry['flag']} ${currentCountry['label']}',
                      style: AppTypography.labelLarge
                          .copyWith(color: L.sub, fontWeight: FontWeight.w700)),
                  Icon(Icons.chevron_right_rounded,
                      size: 22, color: L.sub.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
          Divider(
              height: 1, indent: 56, color: L.border.withValues(alpha: 0.2)),
          InkWell(
            onTap: () async {
              HapticEngine.selection();
              final selected = await showModalBottomSheet<String>(
                context: context,
                builder: (_) => _PickerSheet(
                  title: 'Select Language',
                  items: languages,
                  selectedCode: profile.preferredLanguage,
                ),
              );
              if (selected != null) onLanguageChanged(selected);
            },
            child: ListTile(
              leading: Icon(Icons.language_rounded, color: L.sub),
              title: Text('Language',
                  style: AppTypography.titleLarge.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: L.text)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${currentLang['flag']} ${currentLang['label']}',
                      style: AppTypography.labelLarge
                          .copyWith(color: L.sub, fontWeight: FontWeight.w700)),
                  Icon(Icons.chevron_right_rounded,
                      size: 22, color: L.sub.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<Map<String, String>> items;
  final String selectedCode;
  const _PickerSheet(
      {required this.title, required this.items, required this.selectedCode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final L = context.L;
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.8,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: L.border.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item['code'] == selectedCode;
                return ListTile(
                  leading: Text(item['flag'] ?? '',
                      style: AppTypography.displaySmall.copyWith(fontSize: 22)),
                  title: Text(item['label'] ?? '',
                      style: AppTypography.bodyMedium),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded, color: L.secondary)
                      : null,
                  onTap: () => Navigator.pop(context, item['code']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PBSTrackerTile extends StatelessWidget {
  final double spendThisYear;
  final ValueChanged<double> onChanged;

  const _PBSTrackerTile({required this.spendThisYear, required this.onChanged});

  // 2024 PBS Safety Net threshold
  static const double _threshold = 1622.90;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final L = context.L;
    final progress = (spendThisYear / _threshold).clamp(0.0, 1.0);
    final remaining = (_threshold - spendThisYear).clamp(0.0, _threshold);
    final reached = spendThisYear >= _threshold;
    final s = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: reached ? Border.all(color: L.success, width: 2.0) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🇦🇺',
                  style: AppTypography.titleLarge.copyWith(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.pbsSafetyNet,
                        style: AppTypography.labelLarge
                            .copyWith(fontWeight: FontWeight.bold)),
                    Text(s.pbsThreshold,
                        style: AppTypography.labelSmall.copyWith(color: L.sub)),
                  ],
                ),
              ),
              if (reached)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: L.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('🎉 ${s.reached}',
                      style: AppTypography.labelSmall.copyWith(
                          color: L.success, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: L.fill,
              valueColor:
                  AlwaysStoppedAnimation(reached ? L.success : L.secondary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.pbsSpent(spendThisYear.toStringAsFixed(2)),
                  style: AppTypography.labelMedium.copyWith(color: L.sub)),
              Text(
                reached
                    ? s.medsSubsidised
                    : s.pbsRemaining(remaining.toStringAsFixed(2)),
                style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: reached ? L.success : L.sub),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Manual entry
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: spendThisYear.clamp(0, _threshold),
                  min: 0,
                  max: _threshold,
                  divisions: 100,
                  activeColor: theme.extension<AppThemeColors>()!.secondary,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
          Text(
            s.spentAmountSubtitle,
            style: AppTypography.labelSmall.copyWith(color: L.sub),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final L = context.L;
    final s = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: L.card,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: L.secondary.withValues(alpha: 0.2), width: 1.5),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: L.secondary, size: 18),
              const SizedBox(width: 8),
              Text(s.supportedMarkets.toUpperCase(),
                  style: AppTypography.labelLarge.copyWith(
                      color: L.secondary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '🇺🇸 USA  ·  🇬🇧 UK  ·  🇨🇦 Canada  ·  🇦🇺 Australia\n'
            '🇦🇪 UAE  ·  🇯🇵 Japan  ·  🇰🇷 Korea  ·  🇸🇬 Singapore\n'
            '🇮🇱 Israel  ·  🇲🇾 Malaysia',
            style: AppTypography.labelMedium.copyWith(
                color: L.text, fontWeight: FontWeight.w600, height: 1.5),
          ),
        ],
      ),
    );
  }
}
