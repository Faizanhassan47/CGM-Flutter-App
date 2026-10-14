import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportBreakdownItem {
  final String period;
  final String subPeriod;
  final int avgGlucose;
  final int tir;
  final int lowEvents;
  final int highEvents;
  final int sensorUsage;
  final String note;
  final String noteStatus; // 'stable', 'warning', 'high'

  const ReportBreakdownItem({
    required this.period,
    required this.subPeriod,
    required this.avgGlucose,
    required this.tir,
    required this.lowEvents,
    required this.highEvents,
    required this.sensorUsage,
    required this.note,
    this.noteStatus = 'stable',
  });
}

class ReportPdfService {
  const ReportPdfService._();

  static Future<void> share({
    required Map<String, dynamic> report,
    required DateTime start,
    required DateTime end,
    required List<ReportBreakdownItem> breakdown,
    String? patientName,
  }) async {
    final bytes = await build(
      report: report,
      start: start,
      end: end,
      breakdown: breakdown,
      patientName: patientName,
    );
    final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Aima_CGM_Report_$stamp.pdf',
    );
  }

  static Future<void> printReport({
    required Map<String, dynamic> report,
    required DateTime start,
    required DateTime end,
    required List<ReportBreakdownItem> breakdown,
    String? patientName,
  }) async {
    final bytes = await build(
      report: report,
      start: start,
      end: end,
      breakdown: breakdown,
      patientName: patientName,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Aima_CGM_Report',
    );
  }

  static Future<Uint8List> build({
    required Map<String, dynamic> report,
    required DateTime start,
    required DateTime end,
    required List<ReportBreakdownItem> breakdown,
    String? patientName,
  }) async {
    final document = pw.Document(
      title: 'Aima Report',
      author: 'Aima Health',
      subject: 'Continuous Glucose Monitoring Report & Analytics',
    );

    const purple = PdfColor.fromInt(0xFF5E2B97);
    const darkPurple = PdfColor.fromInt(0xFF221A3B);
    const palePurple = PdfColor.fromInt(0xFFF7F5FC);
    const border = PdfColor.fromInt(0xFFEFEBF6);
    const textMuted = PdfColor.fromInt(0xFF6F6A88);
    const greenPill = PdfColor.fromInt(0xFFDCFCE7);
    const greenText = PdfColor.fromInt(0xFF15803D);

    final rangeText =
        '${DateFormat('MMM d, yyyy').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}';
    final daysCount = end.difference(start).inDays + 1;

    final avgGlucoseStr = (report['avgGlucose']?.toString() ?? '118')
        .replaceAll(' mg/dL', '');
    final tirStr = (report['timeInRange']?.toString() ?? '78%');
    final a1cStr = (report['estimatedA1c']?.toString() ?? '6.1%');
    final lowEventsStr = (report['lowEvents']?.toString() ?? '12');
    final highEventsStr = (report['highEvents']?.toString() ?? '28');

    // Official Aima SVG logo definition for vector PDF rendering
    const String aimaSvg = '''
<svg width="60" height="60" viewBox="0 0 512 512">
  <g transform="translate(256, 256)">
    <path d="M -100,150 L 0,-140 L 100,150" fill="none" stroke="#5E2B97" stroke-width="56" stroke-linecap="round" stroke-linejoin="round" />
    <path d="M -60,40 L -25,40 L 0,-15 L 30,100 L 55,40 L 80,40" fill="none" stroke="#00B2E2" stroke-width="26" stroke-linecap="round" stroke-linejoin="round" />
    <path d="M -190,0 A 190,190 0 1,1 190,0 A 190,190 0 0,1 -120,147" fill="none" stroke="#00B2E2" stroke-width="24" stroke-linecap="round" />
  </g>
</svg>''';

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: border, width: 1.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 38,
                    height: 38,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: border, width: 1.2),
                    ),
                    padding: const pw.EdgeInsets.all(3),
                    child: pw.SvgImage(svg: aimaSvg),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Aima Report',
                        style: pw.TextStyle(
                          color: darkPurple,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Continuous Glucose Monitoring Summary & Insights',
                        style: const pw.TextStyle(
                          color: textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: palePurple,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: purple, width: 0.8),
                ),
                child: pw.Text(
                  'CONFIDENTIAL MEDICAL REPORT',
                  style: pw.TextStyle(
                    color: purple,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: border, width: 1)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Aima Health Continuous Glucose Monitoring  Generated on ${DateFormat('MMM d, yyyy h:mm a').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 8, color: textMuted),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: textMuted),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 16),

          // Report Range Card
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: pw.BoxDecoration(
              color: palePurple,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: border),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '$daysCount Days Report',
                      style: pw.TextStyle(
                        color: darkPurple,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      rangeText,
                      style: const pw.TextStyle(color: textMuted, fontSize: 11),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Patient: ${patientName ?? 'Aima Patient'}',
                      style: pw.TextStyle(
                        color: darkPurple,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Total readings: ${report['totalReadings'] ?? (daysCount * 96)}',
                      style: const pw.TextStyle(color: textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),

          // Summary Section Header
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              color: darkPurple,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Key metrics for the selected $daysCount-day period.',
            style: const pw.TextStyle(fontSize: 10, color: textMuted),
          ),
          pw.SizedBox(height: 10),

          // 5 Summary Metric Cards
          pw.Row(
            children: [
              _buildSummaryCard(
                title: 'Average Glucose',
                value: avgGlucoseStr,
                subText: 'mg/dL',
                valueColor: darkPurple,
              ),
              pw.SizedBox(width: 8),
              _buildSummaryCard(
                title: 'Time in Range',
                value: tirStr,
                subText: '90-130 mg/dL',
                valueColor: darkPurple,
              ),
              pw.SizedBox(width: 8),
              _buildSummaryCard(
                title: 'Estimated A1C',
                value: a1cStr,
                subText: '(eA1C)',
                valueColor: darkPurple,
              ),
              pw.SizedBox(width: 8),
              _buildSummaryCard(
                title: 'Low Events',
                value: lowEventsStr,
                subText: '< 90 mg/dL',
                valueColor: const PdfColor.fromInt(0xFF0284C7),
              ),
              pw.SizedBox(width: 8),
              _buildSummaryCard(
                title: 'High Events',
                value: highEventsStr,
                subText: '> 130 mg/dL',
                valueColor: const PdfColor.fromInt(0xFFDC2626),
              ),
            ],
          ),
          pw.SizedBox(height: 22),

          // Breakdown Section Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '$daysCount-Day Report (Breakdown)',
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: darkPurple,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Detailed summary of your CGM data over the selected range.',
                    style: const pw.TextStyle(fontSize: 9.5, color: textMuted),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: pw.BoxDecoration(
                  color: palePurple,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'Values are averages',
                  style: const pw.TextStyle(fontSize: 8, color: purple),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),

          // Breakdown Table
          pw.Table(
            border: pw.TableBorder.all(color: border, width: 0.8),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.2),
              1: const pw.FlexColumnWidth(1.6),
              2: const pw.FlexColumnWidth(1.6),
              3: const pw.FlexColumnWidth(1.2),
              4: const pw.FlexColumnWidth(1.2),
              5: const pw.FlexColumnWidth(1.4),
              6: const pw.FlexColumnWidth(2.0),
            },
            children: [
              // Header Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: palePurple),
                children: [
                  _tableHeader('Period'),
                  _tableHeader('Avg Glucose\n(mg/dL)'),
                  _tableHeader('Time in Range\n(90-130)'),
                  _tableHeader('Low\n(< 90)'),
                  _tableHeader('High\n(> 130)'),
                  _tableHeader('Sensor\nUsage'),
                  _tableHeader('Notes'),
                ],
              ),
              // Data Rows
              ...breakdown.map((item) {
                final isWarning = item.noteStatus == 'warning';
                final isHigh = item.noteStatus == 'high';
                final noteColor = isWarning
                    ? const PdfColor.fromInt(0xFFD97706)
                    : isHigh
                    ? const PdfColor.fromInt(0xFFEA580C)
                    : greenText;

                return pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.white),
                  children: [
                    // Period Column
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            item.period,
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                              color: darkPurple,
                            ),
                          ),
                          pw.Text(
                            item.subPeriod,
                            style: const pw.TextStyle(
                              fontSize: 7,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Avg Glucose
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Center(
                        child: pw.Text(
                          '${item.avgGlucose}',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: darkPurple,
                          ),
                        ),
                      ),
                    ),
                    // Time in Range pill
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Center(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: pw.BoxDecoration(
                            color: greenPill,
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: pw.Text(
                            '${item.tir}%',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: greenText,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Low (<90)
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Center(
                        child: pw.Text(
                          '${item.lowEvents}',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF0284C7),
                          ),
                        ),
                      ),
                    ),
                    // High (>130)
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Center(
                        child: pw.Text(
                          '${item.highEvents}',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFFDC2626),
                          ),
                        ),
                      ),
                    ),
                    // Sensor Usage
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Center(
                        child: pw.Text(
                          '${item.sensorUsage}%',
                          style: const pw.TextStyle(
                            fontSize: 8.5,
                            color: darkPurple,
                          ),
                        ),
                      ),
                    ),
                    // Notes
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 5,
                            height: 5,
                            decoration: pw.BoxDecoration(
                              color: noteColor,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.SizedBox(width: 4),
                          pw.Expanded(
                            child: pw.Text(
                              item.note,
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: noteColor,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 14),

          // Blue Info Box
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFEFF6FF),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFBFDBFE)),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 24,
                  height: 24,
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFDBEAFE),
                    shape: pw.BoxShape.circle,
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'i',
                    style: pw.TextStyle(
                      color: const PdfColor.fromInt(0xFF1D4ED8),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'This report includes $daysCount days of CGM data, organized systematically.',
                        style: pw.TextStyle(
                          color: const PdfColor.fromInt(0xFF1E3A8A),
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Export to share with your healthcare provider or keep for your medical records.',
                        style: const pw.TextStyle(
                          color: PdfColor.fromInt(0xFF3B82F6),
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Medical Disclaimer
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: palePurple,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'Notice: This continuous glucose monitoring summary is intended for personal health tracking and informational support. Clinical interpretations and therapeutic adjustments must be evaluated alongside a certified physician.',
              style: const pw.TextStyle(fontSize: 7.5, color: textMuted),
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subText,
    required PdfColor valueColor,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(
            color: const PdfColor.fromInt(0xFFEFEBF6),
            width: 1,
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              title,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(
                fontSize: 7.5,
                color: PdfColor.fromInt(0xFF6F6A88),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: valueColor,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              subText,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(
                fontSize: 6.5,
                color: PdfColor.fromInt(0xFF9E9AA7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: const PdfColor.fromInt(0xFF5E2B97),
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }
}
