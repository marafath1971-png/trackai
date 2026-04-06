import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../providers/app_state.dart';
import '../../../../services/export_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import 'settings_shared.dart';

class DataTab extends StatefulWidget {
  final AppState state;
  final AppThemeColors L;
  final VoidCallback onClose;

  const DataTab({
    super.key,
    required this.state,
    required this.L,
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final L = widget.L;
    final s = AppLocalizations.of(context)!;

    final history = context
        .select<AppState, Map<String, List<DoseEntry>>>((s) => s.history);
    final medsCount = context.select<AppState, int>((s) => s.meds.length);

    final totalTaken =
        history.values.expand((e) => e).where((e) => e.taken).length;
    final totalDoses = history.values.expand((e) => e).length;
    final daysTracked = history.keys.length;
    final symptomsCount = context.select<AppState, int>((s) => s.symptoms.length);

    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      child: Column(children: [
        // ── Data Summary Hero ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: L.text,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: L.text.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                )
              ]),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('DATA INFRASTRUCTURE',
                    style: AppTypography.labelLarge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: L.bg.withValues(alpha: 0.4),
                        letterSpacing: 2.0)),
                Icon(Icons.storage_rounded, color: L.bg.withValues(alpha: 0.3), size: 16),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.8,
              children: [
                _SummaryBox(l: "MEDICINES", v: '$medsCount', L: L),
                _SummaryBox(l: 'SYMPTOMS', v: '$symptomsCount', L: L),
                _SummaryBox(l: "DAYS TRACKED", v: '$daysTracked', L: L),
                _SummaryBox(l: "DOSES LOGGED", v: '$totalDoses', L: L),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Export & Backup ───────────────────────────────────────────
        SettingsSection(
            title: s.exportAndBackup,
            child: Column(children: [
              SettingsModalRow(
                  icon: Icons.picture_as_pdf_rounded,
                  iconBg: const Color(0xFF6366F1),
                  label: s.exportPdfReport,
                  sub: s.exportPdfSubtitle,
                  onClick: () => ExportService.exportAdherenceReport(
                      context.read<AppState>()),
                  border: true),
              SettingsModalRow(
                  icon: Icons.download_rounded,
                  iconBg: const Color(0xFF22C55E),
                  label: s.exportCsv,
                  sub: s.exportCsvSubtitle(totalTaken),
                  onClick: _exportCSV,
                  border: false),
            ])),

        // ── Reset ─────────────────────────────────────────────────────
        SettingsSection(
            title: s.resetSection,
            child: SettingsModalRow(
                icon: Icons.delete_outline_rounded,
                iconBg: const Color(0xFFEF4444),
                label: s.deleteAllData,
                sub: s.deleteAllDataSubtitle,
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
              Text(s.deleteConfirmTitle,
                  style: AppTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.w800, color: L.red)),
              const SizedBox(height: 6),
              Text(s.deleteConfirmBody,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(color: L.sub)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: GestureDetector(
                        onTap: () => setState(() => _confirming = false),
                        child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                                color: L.fill,
                                borderRadius: BorderRadius.circular(24),
                                border:
                                    Border.all(color: L.border, width: 1.5)),
                            child: Center(
                                child: Text(s.cancel,
                                    style: AppTypography.labelLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: L.text)))))),
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
                            child: Center(
                                child: Text(s.deleteButton,
                                    style: AppTypography.labelLarge.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)))))),
              ]),
            ]),
          ),
        ],

        const SizedBox(height: 16),

        // ── Legal (App Store Mandatory) ───────────────────────────────
        SettingsSection(
            title: s.legalSection,
            child: Column(children: [
              SettingsModalRow(
                  icon: Icons.shield_outlined,
                  iconBg: const Color(0xFF0EA5E9),
                  label: s.privacyPolicy,
                  sub: s.privacyPolicySubtitle,
                  onClick: () =>
                      _launchUrl('https://medai.app/privacy'),
                  border: true),
              SettingsModalRow(
                  icon: Icons.gavel_rounded,
                  iconBg: const Color(0xFF8B5CF6),
                  label: s.termsOfService,
                  sub: s.termsOfServiceSubtitle,
                  onClick: () =>
                      _launchUrl('https://medai.app/terms'),
                  border: false),
            ])),

        const SizedBox(height: 16),

        // ── App Version ───────────────────────────────────────────────
        Center(
          child: Text('${s.appVersionLabel}: ${s.appVersionValue}',
              style: AppTypography.labelSmall
                  .copyWith(color: L.sub, letterSpacing: 0.5)),
        ),
        const SizedBox(height: 80),
      ]),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String l, v;
  final AppThemeColors L;
  const _SummaryBox({required this.l, required this.v, required this.L});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: L.bg.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: L.bg.withValues(alpha: 0.1), width: 1.0)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(v,
                style: AppTypography.displaySmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: L.bg,
                    fontSize: 24,
                    letterSpacing: -1.0)),
            const SizedBox(height: 2),
            Text(l.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: L.bg.withValues(alpha: 0.4),
                    fontSize: 10,
                    letterSpacing: 0.5)),
          ]),
    );
  }
}
