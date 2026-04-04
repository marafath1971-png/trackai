import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import 'settings/profile_tab.dart';
import 'settings/stats_tab.dart';
import 'settings/app_tab.dart';
import 'settings/data_tab.dart';
import '../../../screens/settings/global_settings_screen.dart';
import '../../../l10n/app_localizations.dart';

class SettingsModal extends StatefulWidget {
  final VoidCallback onClose;
  const SettingsModal({super.key, required this.onClose});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  String _activeTab = 'profile'; // profile | stats | app | data | global

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final L = context.L;
    final s = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    final tabs = [
      {'id': 'profile', 'label': s.settingsProfile, 'icon': Icons.person_rounded},
      {'id': 'stats', 'label': s.settingsStats, 'icon': Icons.bar_chart_rounded},
      {'id': 'app', 'label': s.settingsApp, 'icon': Icons.settings_rounded},
      {'id': 'data', 'label': s.settingsData, 'icon': Icons.storage_rounded},
      {'id': 'global', 'label': s.settingsGlobal, 'icon': Icons.public_rounded},
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
                  border: Border.all(color: L.border.withValues(alpha: 0.2), width: 1.5)),
              child: Column(children: [
                const SizedBox(height: 10),
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: L.border.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(99)))),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                        Text(s.settings,
                            style: AppTypography.displaySmall.copyWith(
                                fontWeight: FontWeight.w900,
                                color: L.text,
                                letterSpacing: -0.7)),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: L.fill.withValues(alpha: 0.3), shape: BoxShape.circle),
                            child: Center(
                                child: Icon(Icons.close_rounded,
                                    color: L.sub, size: 22)),
                          ),
                        ),
                      ])
                      .animate()
                      .fade(duration: 400.ms)
                      .slideY(begin: -0.1, end: 0),
                ),
                // Tab Bar
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
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
                        onTap: () {
                          HapticEngine.selection();
                          setState(() => _activeTab = t['id'] as String);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                              color: isAct
                                  ? L.card
                                  : L.bg,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                  color: isAct
                                      ? L.text
                                      : Colors.black12,
                                  width: 1.0)),
                          child: Row(children: [
                            Icon(t['icon'] as IconData, 
                              size: 16, 
                              color: isAct ? L.bg : Colors.black54),
                            const SizedBox(width: 8),
                            Text(t['label'] as String,
                                style: AppTypography.labelLarge.copyWith(
                                    fontWeight: isAct ? FontWeight.w900 : FontWeight.w500,
                                    color: isAct ? L.bg : Colors.black54,
                                    fontSize: 13)),
                          ]),
                        ),
                      )
                          .animate()
                          .fade(delay: (idx * 50).ms)
                          .scale(begin: const Offset(0.9, 0.9)),
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
        return ProfileTab(state: state, L: L);
      case 'stats':
        return StatsTab(state: state, L: L);
      case 'app':
        return AppTab(state: state, L: L, onClose: widget.onClose);
      case 'data':
        return DataTab(state: state, L: L, onClose: widget.onClose);
      case 'global':
        return const GlobalSettingsScreen();
      default:
        return const SizedBox();
    }
  }
}
