import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/app_state.dart';
import '../core/utils/date_formatter.dart';

class ExportService {
  static Future<void> exportAdherenceReport(AppState state) async {
    final pdf = pw.Document();

    final profile = state.profile;
    final userName = profile?.name ?? 'User';
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('MedAI Report',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Generated: $todayStr',
                      style: const pw.TextStyle(
                          fontSize: 12, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Patient Name: $userName',
                style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 4),
            pw.Text('Report Summary',
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, child: pw.Text('Active Medications')),
            if (state.activeMeds.isEmpty)
              pw.Text('No active medications.')
            else
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Medicine', 'Dose', 'Schedule'],
                  ...state.activeMeds.map((m) {
                    final scheds = m.schedule
                        .where((s) => s.enabled)
                        .map((s) => '${fmtTime(s.h, s.m)} (${s.label})')
                        .join(', ');
                    return [
                      m.name,
                      m.dose.isNotEmpty ? m.dose : '-',
                      scheds.isNotEmpty ? scheds : 'No schedule',
                    ];
                  }),
                ],
              ),
            pw.SizedBox(height: 20),
            pw.Header(
                level: 1, child: pw.Text('Recent Adherence (Last 7 Days)')),
            _buildAdherenceLog(state),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/med_report_$todayStr.pdf');
    await file.writeAsBytes(await pdf.save());

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(file.path)], text: 'MedAI Export Data');
  }

  static pw.Widget _buildAdherenceLog(AppState state) {
    List<List<String>> rows = [
      ['Date', 'Medicine', 'Time', 'Status']
    ];

    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final doses = state.history[dateStr] ?? [];

      for (var dose in doses) {
        final medName =
            state.meds.where((m) => m.id == dose.medId).firstOrNull?.name ??
                'Unknown Medicine';
        rows.add([
          dateStr,
          medName,
          dose.time,
          dose.taken ? 'Taken' : (dose.skipped ? 'Skipped' : 'Missed')
        ]);
      }
    }

    if (rows.length == 1) {
      return pw.Text('No history found for the last 7 days.');
    }

    return pw.TableHelper.fromTextArray(
      data: rows,
    );
  }
}
