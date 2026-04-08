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
import '../../../core/utils/haptic_engine.dart';

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
      {'id': 'profile', 'label': s.settingsProfile.toUpperCase(), 'icon': '👤'},
      {'id': 'stats', 'label': s.settingsStats.toUpperCase(), 'icon': '📈'},
      {'id': 'app', 'label': s.settingsApp.toUpperCase(), 'icon': '📱'},
      {'id': 'data', 'label': s.settingsData.toUpperCase(), 'icon': '💾'},
      {'id': 'global', 'label': s.settingsGlobal.toUpperCase(), 'icon': '🌐'},
    ];

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.4), // Softer backdrop
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              height: size.height * 0.9,
              width: size.width,
              constraints: const BoxConstraints(maxWidth: 430),
              decoration: BoxDecoration(
                  color: L.meshBg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: AppShadows.neumorphic),
              child: Column(children: [
                const SizedBox(height: 12),
                Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: L.text.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10))),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.settings.toUpperCase(),
                                style: AppTypography.labelSmall.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: L.sub.withValues(alpha: 0.5),
                                    letterSpacing: 2.0,
                                    fontSize: 10)),
                            const SizedBox(height: 4),
                            Text("Command Center",
                                style: AppTypography.displaySmall.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: L.text,
                                    fontSize: 24,
                                    letterSpacing: -1.0)),
                          ],
                        ),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: L.text.withValues(alpha: 0.05), shape: BoxShape.circle),
                            child: Center(
                                child: Icon(Icons.close_rounded,
                                    color: L.text, size: 20)),
                          ),
                        ),
                      ])
                      .animate()
                      .fade(duration: 400.ms)
                      .slideY(begin: -0.1, end: 0),
                ),
                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  height: 42,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                        children: tabs.map((t) {
                      final isAct = _activeTab == t['id'];
                      final idx = tabs.indexOf(t);
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            HapticEngine.selection();
                            setState(() => _activeTab = t['id'] as String);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutQuart,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: isAct ? L.text : L.card.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isAct ? L.text : L.border.withValues(alpha: 0.08),
                                    width: 0.5)),
                            child: Row(children: [
                              Text(t['icon'] as String, 
                                style: const TextStyle(fontSize: 14))
                                .animate(target: isAct ? 1 : 0)
                                .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.2, 1.2), duration: 200.ms),
                              const SizedBox(width: 8),
                              Text(t['label'] as String,
                                  style: AppTypography.labelSmall.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: isAct ? L.bg : L.text.withValues(alpha: 0.4),
                                      letterSpacing: 0.5,
                                      fontSize: 10)),
                            ]),
                          ),
                        )
                            .animate()
                            .fade(delay: (idx * 30).ms)
                            .scale(begin: const Offset(0.95, 0.95)),
                      );
                    }).toList()),
                  ),
                ),
                Divider(height: 1, color: L.border.withValues(alpha: 0.1)),
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
