import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/entities/entities.dart';

class ReportService {
  static Future<void> generateAndShareReport({
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
            _buildHeader(userName),
            pw.SizedBox(height: 20),
            _buildSummarySection(adherence, meds.length),
            pw.SizedBox(height: 30),
            _buildMedicationTable(meds),
            pw.SizedBox(height: 30),
            _buildSymptomSection(symptoms),
            pw.SizedBox(height: 40),
            _buildFooter(),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'MedAI_Health_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _buildHeader(String name) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('MedAI Health Report',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text('Personal Medical Summary & Adherence Trends',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Patient: $name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummarySection(double adherence, int medCount) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatBox('Overall Adherence', '${(adherence * 100).round()}%'),
          _buildStatBox('Active Medications', '$medCount'),
          _buildStatBox('Report Period', 'Last 30 Days'),
        ],
      ),
    );
  }

  static pw.Widget _buildStatBox(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.Text(value,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildMedicationTable(List<Medicine> meds) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Current Medications',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Medicine', 'Dose', 'Frequency', 'Stock Remaining'],
          data: meds.map((m) => [
            m.name,
            m.dose,
            m.frequency,
            '${m.count} / ${m.totalCount}',
          ]).toList(),
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

  static pw.Widget _buildSymptomSection(List<Symptom> symptoms) {
    if (symptoms.isEmpty) {
      return pw.Text('No symptoms logged in this period.',
          style: pw.TextStyle(color: PdfColors.grey600, fontStyle: pw.FontStyle.italic));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Recent Symptoms & Well-being',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: ['Date', 'Symptom', 'Severity', 'Notes'],
          data: symptoms.take(20).map((s) => [
            s.timestamp.toString().split(' ')[0],
            s.name,
            '${s.severity}/10',
            s.notes ?? '-',
          ]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellHeight: 25,
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey),
        pw.SizedBox(height: 10),
        pw.Text(
          'Generated by MedAI Pro. This report is for informational purposes only and should be reviewed by a qualified healthcare professional.',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ],
    );
  }
}
