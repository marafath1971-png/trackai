import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../../../providers/app_state.dart';
import '../../../../services/export_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../domain/entities/entities.dart';
import 'settings_shared.dart';

class DataTab extends StatefulWidget {
  final AppState state;
  final AppThemeColors L;
  final String ff;
  final VoidCallback onClose;

  const DataTab({
    super.key,
    required this.state,
    required this.L,
    required this.ff,
    required this.onClose,
  });

  @override
  State<DataTab> createState() => _DataTabState();
}

class _DataTabState extends State<DataTab> {
  bool _confirming = false;

  Future<void> _exportCSV() async {
    final state = widget.state;
    final sb = state.exportDataCSV();
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/med_ai_export.csv');
      await file.writeAsString(sb);
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: 'Med AI Export');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final L = widget.L;
    final ff = widget.ff;
    
    // Select history and meds to react to changes
    final history = context.select<AppState, Map<String, List<DoseEntry>>>((s) => s.history);
    final medsCount = context.select<AppState, int>((s) => s.meds.length);

    final totalTaken =
        history.values.expand((e) => e).where((e) => e.taken).length;
    final totalDoses = history.values.expand((e) => e).length;
    final daysTracked = history.keys.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      child: Column(children: [
        // Data Summary Hero
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(24)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('YOUR DATA SUMMARY',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: [
                _SummaryBox(l: 'Medicines', v: '$medsCount', ff: ff),
                _SummaryBox(
                    l: 'Alarms set',
                    v: '$medsCount',
                    ff: ff), // Mocked for now
                _SummaryBox(l: 'Days tracked', v: '$daysTracked', ff: ff),
                _SummaryBox(l: 'Doses logged', v: '$totalDoses', ff: ff),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 16),

        SettingsSection(
            title: 'Export & Backup',
            child: Column(children: [
              SettingsModalRow(
                  icon: Icons.picture_as_pdf_rounded,
                  iconBg: const Color(0xFF6366F1),
                  label: 'Export PDF Report',
                  sub: 'For doctors and caregivers',
                  onClick: () => ExportService.exportAdherenceReport(context.read<AppState>()),
                  border: true),
              SettingsModalRow(
                  icon: Icons.download_rounded,
                  iconBg: const Color(0xFF22C55E),
                  label: 'Export History as CSV',
                  sub: '$totalTaken dose records',
                  onClick: _exportCSV,
                  border: false),
            ])),

        SettingsSection(
            title: 'Reset',
            child: SettingsModalRow(
                icon: Icons.delete_outline_rounded,
                iconBg: const Color(0xFFEF4444),
                label: 'Delete All Data',
                sub: 'Removes all medicines, history & settings',
                onClick: () => setState(() => _confirming = true),
                border: false)),

        if (_confirming) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: L.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: L.red.withValues(alpha: 0.2))),
            child: Column(children: [
              Text('Delete All Data?',
                  style: TextStyle(
                      fontFamily: ff,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: L.red)),
              const SizedBox(height: 6),
              const Text(
                  'This will permanently delete all your data. This cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: GestureDetector(
                        onTap: () => setState(() => _confirming = false),
                        child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                                color: L.fill,
                                borderRadius: BorderRadius.circular(24)),
                            child: Center(
                                child: Text('Cancel',
                                    style: TextStyle(
                                        fontFamily: ff,
                                        fontWeight: FontWeight.w700)))))),
                const SizedBox(width: 8),
                Expanded(
                    child: GestureDetector(
                        onTap: () {
                          context.read<AppState>().deleteAllData();
                          widget.onClose();
                        },
                        child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                                color: L.red,
                                borderRadius: BorderRadius.circular(24)),
                            child: const Center(
                                child: Text('Delete Everything',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)))))),
              ]),
            ]),
          ),
        ],
        const SizedBox(height: 120),
      ]),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String l, v, ff;
  const _SummaryBox({required this.l, required this.v, required this.ff});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(v,
            style: TextStyle(
                fontFamily: ff,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.8)),
        Text(l,
            style: TextStyle(
                fontFamily: ff,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.45))),
      ]),
    );
  }
}
