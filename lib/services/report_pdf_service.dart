import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

enum CircleReportType {
  /// Every reading in the period; out-of-range values shown in red.
  allData,

  /// One-hour interval averages across the period.
  hourlyInterval,

  /// Summary averages plus times when glucose was unstable.
  average,
}

/// Report-only target band (mg/dL). Does not change app alert settings.
class ReportRange {
  static const double low = 80;
  static const double high = 130;
  static const String label = '80-130 mg/dL';
  static const String lowLabel = '<80 mg/dL';
  static const String highLabel = '>130 mg/dL';
}

extension CircleReportTypeLabel on CircleReportType {
  String get title => switch (this) {
        CircleReportType.allData => 'All data report',
        CircleReportType.hourlyInterval => '1-hour interval report',
        CircleReportType.average => 'Average report',
      };

  String get subtitle => switch (this) {
        CircleReportType.allData =>
          'Every reading · out-of-range values marked in red',
        CircleReportType.hourlyInterval =>
          'Hour-by-hour averages for the selected period',
        CircleReportType.average =>
          'Period averages · unstable time windows listed',
      };

  String get fileTag => switch (this) {
        CircleReportType.allData => 'AllData',
        CircleReportType.hourlyInterval => 'Hourly',
        CircleReportType.average => 'Average',
      };
}

class ReportBreakdownItem {
  final String dateLabel;
  final int avgGlucose;
  final double inRangePct;
  final double below70Pct;
  final double highPct;
  final int readingsCount;

  const ReportBreakdownItem({
    required this.dateLabel,
    required this.avgGlucose,
    required this.inRangePct,
    required this.below70Pct,
    required this.highPct,
    required this.readingsCount,
  });
}

class ReportReadingRow {
  final DateTime time;
  final double mgDl;
  final String status;

  const ReportReadingRow({
    required this.time,
    required this.mgDl,
    required this.status,
  });

  bool get isUnstable => status != 'Normal';
}

class ReportHourlyInterval {
  final DateTime hourStart;
  final int avgGlucose;
  final int minGlucose;
  final int maxGlucose;
  final int readingsCount;
  final double inRangePct;
  final double lowPct;
  final double highPct;
  final bool unstable;

  const ReportHourlyInterval({
    required this.hourStart,
    required this.avgGlucose,
    required this.minGlucose,
    required this.maxGlucose,
    required this.readingsCount,
    required this.inRangePct,
    required this.lowPct,
    required this.highPct,
    required this.unstable,
  });
}

class ReportUnstablePeriod {
  final DateTime start;
  final DateTime end;
  final String reason;
  final int avgGlucose;
  final int readingCount;

  const ReportUnstablePeriod({
    required this.start,
    required this.end,
    required this.reason,
    required this.avgGlucose,
    required this.readingCount,
  });
}

class CircleReportMetrics {
  final String patientName;
  final String deviceName;
  final String patientEmail;
  final DateTime start;
  final DateTime end;
  final int totalDays;
  final int totalReadings;
  final String avgGlucose;
  final String timeInRange;
  final String lowGlucosePct;
  final String variability;
  final String highPct;
  final String veryHighPct;
  final String estimatedA1c;
  final String highestGlucose;
  final String lowestGlucose;
  final String standardDeviation;
  final List<double> trendValues;
  final List<ReportBreakdownItem> breakdown;
  final List<ReportReadingRow> readings;
  final List<ReportHourlyInterval> hourlyIntervals;
  final List<ReportUnstablePeriod> unstablePeriods;

  const CircleReportMetrics({
    required this.patientName,
    required this.deviceName,
    required this.patientEmail,
    required this.start,
    required this.end,
    required this.totalDays,
    required this.totalReadings,
    required this.avgGlucose,
    required this.timeInRange,
    required this.lowGlucosePct,
    required this.variability,
    required this.highPct,
    required this.veryHighPct,
    required this.estimatedA1c,
    required this.highestGlucose,
    required this.lowestGlucose,
    required this.standardDeviation,
    required this.trendValues,
    required this.breakdown,
    this.readings = const [],
    this.hourlyIntervals = const [],
    this.unstablePeriods = const [],
  });
}

class ReportPdfService {
  const ReportPdfService._();

  static const _navy = PdfColor.fromInt(0xFF1B2A4A);
  static const _muted = PdfColor.fromInt(0xFF8A93A6);
  static const _border = PdfColor.fromInt(0xFFDFE3EA);
  static const _softBg = PdfColor.fromInt(0xFFF4F6F8);
  static const _peach = PdfColor.fromInt(0xFFFFF8F5);
  static const _red = PdfColor.fromInt(0xFFFF554A);
  static const _green = PdfColor.fromInt(0xFF159669);
  static const _blue = PdfColor.fromInt(0xFF489CCD);
  static const _orange = PdfColor.fromInt(0xFFFF913D);
  static const _high = PdfColor.fromInt(0xFFFFA337);

  static Future<void> share({
    required CircleReportMetrics metrics,
    CircleReportType type = CircleReportType.average,
  }) async {
    final bytes = await build(metrics: metrics, type: type);
    final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Circle_CGM_${type.fileTag}_$stamp.pdf',
    );
  }

  static Future<Uint8List> build({
    required CircleReportMetrics metrics,
    CircleReportType type = CircleReportType.average,
  }) async {
    final document = pw.Document(
      title: 'Circle CGM ${type.title}',
      author: 'Circle Health',
      subject: type.subtitle,
    );

    switch (type) {
      case CircleReportType.allData:
        _buildAllDataPages(document, metrics);
      case CircleReportType.hourlyInterval:
        _buildHourlyPages(document, metrics);
      case CircleReportType.average:
        _buildAveragePages(document, metrics);
    }

    return document.save();
  }

  // ---------------------------------------------------------------------------
  // Shared chrome
  // ---------------------------------------------------------------------------

  static pw.Widget _header({required String subtitle, required String badge}) {
    const circleSvg = '''
<svg width="60" height="60" viewBox="0 0 512 512">
  <path d="M256 56a200 200 0 1 0 0 400V276h180V236H276V56z" fill="#FF554A" />
  <path d="M256 56a200 200 0 0 1 180 180H256z" fill="#FFA337" />
</svg>''';
    return pw.Column(
      children: [
        pw.Row(
          children: [
            pw.SvgImage(svg: circleSvg, width: 26, height: 26),
            pw.SizedBox(width: 8),
            pw.Text(
              'circle',
              style: pw.TextStyle(
                fontSize: 20,
                color: _navy,
                letterSpacing: -0.8,
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Text(
              'CGM REPORT',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _muted,
                letterSpacing: 0.4,
              ),
            ),
            pw.Spacer(),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  badge.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: _muted,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  subtitle,
                  style: const pw.TextStyle(fontSize: 9, color: _muted),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: _border, thickness: 1),
      ],
    );
  }

  static pw.Widget _patientBar(CircleReportMetrics m) {
    pw.Widget cell(String label, String value) => pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _muted,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                value,
                maxLines: 2,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _navy,
                ),
              ),
            ],
          ),
        );

    final range =
        '${DateFormat('dd MMM').format(m.start)} – ${DateFormat('dd MMM yyyy').format(m.end)}';
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: _softBg,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        children: [
          cell('PATIENT', m.patientName),
          cell('DEVICE', m.deviceName),
          cell('PERIOD', range),
          cell('READINGS', NumberFormat('#,###').format(m.totalReadings)),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context context, String label) {
    return pw.Column(
      children: [
        pw.Divider(color: _border, thickness: 1),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Circle  |  $label  |  ${DateFormat('MMM d, yyyy h:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 7, color: _muted),
            ),
            pw.Text(
              'Page ${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 7, color: _muted),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _metricStrip(CircleReportMetrics m) {
    pw.Widget card(String title, String value, String foot, PdfColor accent) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _border),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 22,
                height: 3,
                color: accent,
              ),
              pw.SizedBox(height: 8),
              pw.Text(title, style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
              pw.SizedBox(height: 2),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _navy,
                ),
              ),
              pw.Text(foot, style: const pw.TextStyle(fontSize: 6.5, color: _muted)),
            ],
          ),
        ),
      );
    }

    return pw.Row(
      children: [
        card(
          'Mean',
          m.avgGlucose == '--' ? '--' : '${m.avgGlucose} mg/dL',
          '${m.totalDays}-day avg',
          _red,
        ),
        pw.SizedBox(width: 6),
        card(
          'In range',
          m.timeInRange == '--' ? '--' : '${m.timeInRange}%',
          ReportRange.label,
          _green,
        ),
        pw.SizedBox(width: 6),
        card(
          'Low',
          m.lowGlucosePct == '--' ? '--' : '${m.lowGlucosePct}%',
          ReportRange.lowLabel,
          _blue,
        ),
        pw.SizedBox(width: 6),
        card(
          'High',
          m.highPct == '--' ? '--' : '${m.highPct}%',
          ReportRange.highLabel,
          _high,
        ),
        pw.SizedBox(width: 6),
        card(
          'CV',
          m.variability == '--' ? '--' : '${m.variability}%',
          'Variability',
          _orange,
        ),
      ],
    );
  }

  static pw.Widget _legendRed() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _peach,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        'Values in red are out of range (<${ReportRange.low.toInt()} or >${ReportRange.high.toInt()} mg/dL) or otherwise unstable.',
        style: pw.TextStyle(
          fontSize: 8,
          color: _red,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.TableRow _tableHeader(List<String> cols) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: _softBg),
      children: [
        for (final c in cols)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
            child: pw.Text(
              c,
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: _muted,
              ),
            ),
          ),
      ],
    );
  }

  static pw.Widget _cell(
    String text, {
    bool alert = false,
    pw.FontWeight? weight,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: weight ?? (alert ? pw.FontWeight.bold : pw.FontWeight.normal),
          color: alert ? _red : _navy,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1) ALL DATA — every reading, red if unstable
  // ---------------------------------------------------------------------------

  static void _buildAllDataPages(
    pw.Document document,
    CircleReportMetrics m,
  ) {
    final readings = List<ReportReadingRow>.from(m.readings)
      ..sort((a, b) => a.time.compareTo(b.time));

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 26, 32, 26),
        header: (c) => _header(
          badge: 'ALL DATA REPORT',
          subtitle: '${m.totalDays}-DAY READINGS',
        ),
        footer: (c) => _footer(c, 'All data report'),
        build: (context) => [
          pw.SizedBox(height: 10),
          pw.Text(
            'All glucose readings',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: _navy,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Complete reading list for the selected period. Unstable values are highlighted in red.',
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
          pw.SizedBox(height: 10),
          _patientBar(m),
          pw.SizedBox(height: 10),
          _metricStrip(m),
          pw.SizedBox(height: 10),
          _legendRed(),
          pw.SizedBox(height: 12),
          if (readings.isEmpty)
            pw.Text(
              'No readings available for this period.',
              style: const pw.TextStyle(fontSize: 10, color: _muted),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: _border, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.4),
                1: const pw.FlexColumnWidth(1.4),
                2: const pw.FlexColumnWidth(1.6),
                3: const pw.FlexColumnWidth(1.4),
              },
              children: [
                _tableHeader(const ['TIME', 'mg/dL', 'STATUS', 'FLAG']),
                ...readings.map((r) {
                  final alert = r.isUnstable;
                  return pw.TableRow(
                    children: [
                      _cell(DateFormat('dd MMM yyyy  HH:mm').format(r.time)),
                      _cell('${r.mgDl.round()}', alert: alert, weight: pw.FontWeight.bold),
                      _cell(r.status, alert: alert),
                      _cell(alert ? 'Not well' : 'OK', alert: alert),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2) HOURLY INTERVAL — one-hour buckets
  // ---------------------------------------------------------------------------

  static void _buildHourlyPages(
    pw.Document document,
    CircleReportMetrics m,
  ) {
    final hours = List<ReportHourlyInterval>.from(m.hourlyIntervals)
      ..sort((a, b) => a.hourStart.compareTo(b.hourStart));

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 26, 32, 26),
        header: (c) => _header(
          badge: '1-HOUR INTERVAL REPORT',
          subtitle: '${m.totalDays}-DAY HOURLY',
        ),
        footer: (c) => _footer(c, '1-hour interval report'),
        build: (context) => [
          pw.SizedBox(height: 10),
          pw.Text(
            'One-hour interval report',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: _navy,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Each row summarizes readings inside a single one-hour window.',
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
          pw.SizedBox(height: 10),
          _patientBar(m),
          pw.SizedBox(height: 10),
          _metricStrip(m),
          pw.SizedBox(height: 10),
          _legendRed(),
          pw.SizedBox(height: 12),
          if (hours.isEmpty)
            pw.Text(
              'No hourly intervals available for this period.',
              style: const pw.TextStyle(fontSize: 10, color: _muted),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: _border, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.6),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(1.1),
                3: const pw.FlexColumnWidth(1.1),
                4: const pw.FlexColumnWidth(1.2),
                5: const pw.FlexColumnWidth(1.1),
                6: const pw.FlexColumnWidth(1.3),
              },
              children: [
                _tableHeader(const [
                  'HOUR',
                  'AVG',
                  'MIN',
                  'MAX',
                  'IN RANGE',
                  'N',
                  'STATUS',
                ]),
                ...hours.map((h) {
                  final alert = h.unstable;
                  final label =
                      '${DateFormat('dd MMM').format(h.hourStart)}  ${DateFormat('HH:mm').format(h.hourStart)}–${DateFormat('HH:mm').format(h.hourStart.add(const Duration(hours: 1)))}';
                  return pw.TableRow(
                    children: [
                      _cell(label, alert: alert),
                      _cell('${h.avgGlucose}', alert: alert, weight: pw.FontWeight.bold),
                      _cell('${h.minGlucose}', alert: alert),
                      _cell('${h.maxGlucose}', alert: alert),
                      _cell('${h.inRangePct.toStringAsFixed(0)}%', alert: alert),
                      _cell('${h.readingsCount}'),
                      _cell(alert ? 'Unstable' : 'Stable', alert: alert),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3) AVERAGE — summary + unstable times
  // ---------------------------------------------------------------------------

  static void _buildAveragePages(
    pw.Document document,
    CircleReportMetrics m,
  ) {
    final unstable = List<ReportUnstablePeriod>.from(m.unstablePeriods)
      ..sort((a, b) => a.start.compareTo(b.start));

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 26, 32, 26),
        header: (c) => _header(
          badge: 'AVERAGE REPORT',
          subtitle: '${m.totalDays}-DAY SUMMARY',
        ),
        footer: (c) => _footer(c, 'Average report'),
        build: (context) => [
          pw.SizedBox(height: 10),
          pw.Text(
            'Average report',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: _navy,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Period averages only, plus times when glucose was unstable.',
            style: const pw.TextStyle(fontSize: 9, color: _muted),
          ),
          pw.SizedBox(height: 10),
          _patientBar(m),
          pw.SizedBox(height: 12),
          pw.Text(
            'Period averages',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: _navy,
            ),
          ),
          pw.SizedBox(height: 8),
          _metricStrip(m),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _miniStat('Highest', m.highestGlucose == '--' ? '--' : '${m.highestGlucose} mg/dL'),
              pw.SizedBox(width: 6),
              _miniStat('Lowest', m.lowestGlucose == '--' ? '--' : '${m.lowestGlucose} mg/dL'),
              pw.SizedBox(width: 6),
              _miniStat('Est. A1C', m.estimatedA1c),
              pw.SizedBox(width: 6),
              _miniStat('Std Dev', m.standardDeviation == '--' ? '--' : '${m.standardDeviation} mg/dL'),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Unstable times',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: _navy,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Windows where glucose was low, high, or highly variable. These times need attention.',
            style: const pw.TextStyle(fontSize: 8.5, color: _muted),
          ),
          pw.SizedBox(height: 8),
          _legendRed(),
          pw.SizedBox(height: 10),
          if (unstable.isEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFECFDF5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'No unstable periods detected in this range. Glucose stayed mostly stable.',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: _green,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: _border, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.8),
                1: const pw.FlexColumnWidth(2.2),
                2: const pw.FlexColumnWidth(1.3),
                3: const pw.FlexColumnWidth(1.2),
              },
              children: [
                _tableHeader(const ['WHEN', 'REASON', 'AVG', 'READINGS']),
                ...unstable.map((u) {
                  final when =
                      '${DateFormat('dd MMM yyyy HH:mm').format(u.start)} – ${DateFormat('HH:mm').format(u.end)}';
                  return pw.TableRow(
                    children: [
                      _cell(when, alert: true),
                      _cell(u.reason, alert: true, weight: pw.FontWeight.bold),
                      _cell('${u.avgGlucose} mg/dL', alert: true),
                      _cell('${u.readingCount}', alert: true),
                    ],
                  );
                }),
              ],
            ),
          if (m.breakdown.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              'Daily averages',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: _navy,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: _border, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.2),
                1: const pw.FlexColumnWidth(1.4),
                2: const pw.FlexColumnWidth(1.4),
                3: const pw.FlexColumnWidth(1.3),
                4: const pw.FlexColumnWidth(1.3),
              },
              children: [
                _tableHeader(const ['DATE', 'MEAN', 'IN RANGE', 'LOW', 'HIGH']),
                ...m.breakdown.map((d) {
                  final alert = d.inRangePct < 70 || d.below70Pct > 5 || d.highPct > 10;
                  return pw.TableRow(
                    children: [
                      _cell(d.dateLabel, alert: alert),
                      _cell('${d.avgGlucose} mg/dL', alert: alert),
                      _cell(
                        '${d.inRangePct.toStringAsFixed(0)}%',
                        alert: alert,
                        weight: pw.FontWeight.bold,
                      ),
                      _cell('${d.below70Pct.toStringAsFixed(0)}%', alert: d.below70Pct > 0),
                      _cell('${d.highPct.toStringAsFixed(0)}%', alert: d.highPct > 0),
                    ],
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _miniStat(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: pw.BoxDecoration(
          color: _softBg,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 6.5,
                fontWeight: pw.FontWeight.bold,
                color: _muted,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
