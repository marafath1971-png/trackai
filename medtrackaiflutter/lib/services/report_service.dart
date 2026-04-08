import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/entities/entities.dart';
import '../l10n/app_localizations.dart';

class ReportService {
  static Future<void> generateAndShareReport({
    required AppLocalizations s,
    required String userName,
    required double adherence,
    required List<Medicine> meds,
    required List<Symptom> symptoms,
    required Map<String, List<DoseEntry>> history,
    double? avgHeartRate,
    double? avgSteps,
    int? currentStreak,
    List<Map<String, dynamic>>? trendData,
  }) async {
    final pdf = pw.Document();

    final fontInter = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontInter,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return [
            _buildHeader(s, userName),
            pw.SizedBox(height: 24),
            _buildVitalsSummary(s, avgHeartRate, avgSteps, currentStreak),
            pw.SizedBox(height: 24),
            _buildStabilityMatrix(s, trendData ?? []),
            pw.SizedBox(height: 24),
            _buildMedicationTable(s, meds),
            pw.SizedBox(height: 24),
            _buildSymptomSection(s, symptoms),
            pw.SizedBox(height: 40),
            _buildFooter(s),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'MedAI_Health_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _buildVitalsSummary(
      AppLocalizations s, double? hr, double? steps, int? streak) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('AVG HEART RATE', '${hr?.toInt() ?? "--"} BPM',
              PdfColors.red400),
          _buildStatItem(
              'DAILY STEPS', '${steps?.toInt() ?? "--"}', PdfColors.blue400),
          _buildStatItem('STREAK', '${streak ?? 0} DAYS', PdfColors.orange400),
        ],
      ),
    );
  }

  static pw.Widget _buildStatItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  static pw.Widget _buildStabilityMatrix(
      AppLocalizations s, List<Map<String, dynamic>> trendData) {
    // Render a 30-day stability grid
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('30-DAY STABILITY MATRIX',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        pw.Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(30, (index) {
            final data = index < trendData.length ? trendData[index] : null;
            final ad = (data?['adherence'] as double?) ?? 0.0;
            PdfColor color = PdfColors.grey200;
            if (ad >= 0.95) {
              color = PdfColors.green300;
            } else if (ad > 0) color = PdfColors.yellow300;

            return pw.Container(
              width: 28,
              height: 28,
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Center(
                child: pw.Text('${index + 1}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.white)),
              ),
            );
          }),
        ),
      ],
    );
  }

  static pw.Widget _buildHeader(AppLocalizations s, String name) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('MEDAI CLINICAL REPORT',
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text('Comprehensive medication & biometric summary',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(name.toUpperCase(),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('ID: ${DateTime.now().millisecondsSinceEpoch}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          ],
        ),
      ],
    );
  }



  static pw.Widget _buildMedicationTable(
      AppLocalizations s, List<Medicine> meds) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(s.currentMedications,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: [
            s.medicineCol,
            s.doseCol,
            s.frequencyCol,
            s.stockRemainingCol
          ],
          data: meds
              .map((m) => [
                    m.name,
                    m.dose,
                    m.frequency,
                    '${m.count} / ${m.totalCount}',
                  ])
              .toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellHeight: 30,
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
          },
        ),
      ],
    );
  }

  static pw.Widget _buildSymptomSection(
      AppLocalizations s, List<Symptom> symptoms) {
    if (symptoms.isEmpty) {
      return pw.Text(s.noSymptomsLogged,
          style: pw.TextStyle(
              color: PdfColors.grey600, fontStyle: pw.FontStyle.italic));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(s.recentSymptoms,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: [
            s.symptomDateCol,
            s.symptomNameCol,
            s.severityCol,
            s.notesCol
          ],
          data: symptoms
              .take(20)
              .map((sy) => [
                    sy.timestamp.toString().split(' ')[0],
                    sy.name,
                    '${sy.severity}/10',
                    sy.notes ?? '-',
                  ])
              .toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellHeight: 25,
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(AppLocalizations s) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey200),
        pw.SizedBox(height: 10),
        pw.Text(
          'This report was generated by MedAI. It is intended for clinical reference only and does not constitute medical advice.',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    );
  }

  /// Task 4: CSV Export Implementation
  static Future<void> generateAndShareCSV({
    required List<Medicine> meds,
    required Map<String, List<DoseEntry>> history,
  }) async {
    final buffer = StringBuffer();
    // Headers
    buffer.writeln('Date,Medicine,Dose,Status,Timestamp');

    final sortedDates = history.keys.toList()..sort((a, b) => b.compareTo(a));

    for (var date in sortedDates) {
      final entries = history[date] ?? [];
      for (var entry in entries) {
        final med = meds.firstWhere((m) => m.id == entry.medId,
            orElse: () => Medicine(
                id: 0,
                name: 'Unknown',
                dose: '',
                form: '',
                category: '',
                count: 0,
                totalCount: 0,
                courseStartDate: ''));
        buffer.writeln(
            '$date,${med.name},${med.dose},${entry.taken ? 'Taken' : 'Missed'},${entry.takenAt ?? ''}');
      }
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/MedAI_Health_Data_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles([XFile(file.path)], subject: 'My MedAI Health Data (CSV)');
  }
}
