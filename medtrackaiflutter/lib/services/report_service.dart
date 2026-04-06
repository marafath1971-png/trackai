import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
  }) async {
    final pdf = pw.Document();

    // Load fonts if needed, otherwise use defaults
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return [
            _buildHeader(s, userName),
            pw.SizedBox(height: 20),
            _buildSummarySection(s, adherence, meds.length),
            pw.SizedBox(height: 30),
            _buildMedicationTable(s, meds),
            pw.SizedBox(height: 30),
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

  static pw.Widget _buildHeader(AppLocalizations s, String name) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(s.healthReportTitle,
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text(s.medicalSummarySubtitle,
                style:
                    const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(s.patientLabel(name),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(s.reportDate(DateTime.now().toString().split(' ')[0])),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummarySection(
      AppLocalizations s, double adherence, int medCount) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatBox(s.overallAdherence, '${(adherence * 100).round()}%'),
          _buildStatBox(s.activeMedications, '$medCount'),
          _buildStatBox(s.reportPeriod, s.last30Days),
        ],
      ),
    );
  }

  static pw.Widget _buildStatBox(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.Text(value,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
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
        pw.Divider(color: PdfColors.grey),
        pw.SizedBox(height: 10),
        pw.Text(
          s.reportFooter,
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }
}
