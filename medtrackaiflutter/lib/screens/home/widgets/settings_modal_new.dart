import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../providers/app_state.dart';
import '../../../theme/app_theme.dart';
import 'settings/profile_tab.dart';
import 'settings/stats_tab.dart';
import 'settings/app_tab.dart';
import 'settings/data_tab.dart';

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
    final state = context.read<AppState>();
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
                  border: Border.all(color: L.border, width: 1.0)),
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
        return ProfileTab(state: state, L: L, ff: ff);
      case 'stats':
        return StatsTab(state: state, L: L, ff: ff);
      case 'app':
        return AppTab(state: state, L: L, ff: ff, onClose: widget.onClose);
      case 'data':
        return DataTab(state: state, L: L, ff: ff, onClose: widget.onClose);
      default:
        return const SizedBox();
    }
  }
}
