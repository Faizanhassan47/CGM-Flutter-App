import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../core/app_theme.dart';
import '../../core/device_time.dart';
import '../../core/ui_perf.dart';
import '../../services/report_pdf_service.dart';
import '../../state/app_controller.dart';
import '../../widgets/page_top_bar.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _presets = ['7D', '14D', '30D', '90D', 'Custom'];

  /// Report-only target band (does not change app alert targets).
  static const double _reportLow = 80;
  static const double _reportHigh = 130;

  String _selectedFilter = '7D';
  CircleReportType _reportType = CircleReportType.average;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _loading = false;
  bool _exporting = false;
  String? _loadError;

  /// Live metrics built from Glucose/summary + history (same source as History).
  CircleReportMetrics? _metrics;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _endDate = today;
    _startDate = today.subtract(const Duration(days: 6));
    _loadReport();
  }

  String _apiDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<void> _onFilterSelected(String filter) async {
    final today = DateUtils.dateOnly(DateTime.now());
    if (filter == 'Custom') {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: today.add(const Duration(days: 365)),
        initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
        helpText: 'Select report dates',
        saveText: 'Apply',
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.surface,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.surface,
            ),
          ),
          child: child!,
        ),
      );
      if (range == null || !mounted) return;
      setState(() {
        _selectedFilter = 'Custom';
        _startDate = DateUtils.dateOnly(range.start);
        _endDate = DateUtils.dateOnly(range.end);
      });
      await _loadReport();
      return;
    }

    final days = switch (filter) {
      '14D' => 14,
      '30D' => 30,
      '90D' => 90,
      _ => 7,
    };
      setState(() {
      _selectedFilter = filter;
        _endDate = today;
        _startDate = today.subtract(Duration(days: days - 1));
      });
      await _loadReport();
    }

  // ---------------------------------------------------------------------------
  // Data loading — Glucose/summary + history (proven path from History screen)
  // ---------------------------------------------------------------------------

  double _pickMg(Map row) {
    final raw = row['glucoseValue'] ??
        row['GlucoseValue'] ??
        row['value'] ??
        row['Value'];
    if (raw is! num) return double.nan;
    final v = raw.toDouble();
    // Server stores mg/dL; SDK/local samples may be mmol/L (< 30).
    return v > 30 ? v : v * 18.0182;
  }

  DateTime? _pickTime(Map row) {
    final raw = row['measurementTime'] ??
        row['MeasurementTime'] ??
        row['time'] ??
        row['Time'] ??
        row['measuredAt'];
    return DeviceTime.parseApi(raw);
  }

  String _fmt(num? n, {int decimals = 0}) {
    if (n == null || n.isNaN) return '--';
    if (decimals == 0) return n.round().toString();
    return n.toStringAsFixed(decimals);
  }

  String _pct(num? n) {
    if (n == null || n.isNaN) return '--';
    final v = n.toDouble();
    return v == v.roundToDouble()
        ? v.round().toString()
        : v.toStringAsFixed(1);
  }

  String _deviceLabel() {
    final sensor = widget.controller.activeSensor;
    final device = widget.controller.activeDevice;
    final serial =
        '${sensor?['sensorIdentifier'] ?? device?['serialNumber'] ?? ''}'
            .trim();
    if (serial.isNotEmpty) return 'Circle CGM · $serial';
    final type = widget.controller.selectedDeviceType.trim();
    if (type.isNotEmpty) return 'Circle CGM · $type';
    return 'Circle CGM sensor';
  }

  String _patientName(Map<String, dynamic> report) {
    final fromDb = '${report['patientName'] ?? report['PatientName'] ?? ''}'
        .trim();
    if (fromDb.isNotEmpty) return fromDb;
    final local = widget.controller.fullName.trim();
    return local.isEmpty ? 'Circle Patient' : local;
  }

  Future<List<Map<String, dynamic>>> _fetchAllHistoryRows(
    DateTime start,
    DateTime end,
  ) async {
    final rows = <Map<String, dynamic>>[];
    var page = 1;
    final lowEnd = mounted && UiPerf.isLowEndLayout(context);
    final pageSize = lowEnd ? 80 : 200;
    final maxPages = lowEnd ? 10 : 25;
    while (page <= maxPages) {
      final res = await widget.controller.fetchGlucoseHistoryPage(
        startUtc: start,
        endUtc: end,
        page: page,
        pageSize: pageSize,
      );
      final items = res['items'];
      if (items is! List || items.isEmpty) break;
      for (final item in items) {
        if (item is Map) {
          rows.add(Map<String, dynamic>.from(item));
        }
      }
      if (res['hasMore'] != true) break;
      page += 1;
    }
    return rows;
  }

  List<double> _localMgValues(DateTime start, DateTime end) {
    return widget.controller.history
        .where(
          (s) =>
              s.value != null &&
              !s.warmup &&
              !s.abnormal &&
              !s.measuredAt.isBefore(start) &&
              s.measuredAt.isBefore(end),
        )
        .map((s) {
          final v = s.value!;
          return v > 30 ? v : v * 18.0182;
        })
        .toList();
  }

  CircleReportMetrics _computeMetrics({
    required Map<String, dynamic> summary,
    required Map<String, dynamic> report,
    required List<Map<String, dynamic>> historyRows,
    required List<double> localMg,
  }) {
    final totalDays = _endDate.difference(_startDate).inDays + 1;
    const lowTarget = _reportLow;
    const highTarget = _reportHigh;

    // Prefer mg values from history rows; fall back to local BLE buffer.
    final timed = <MapEntry<DateTime, double>>[];
    final byDay = <String, List<double>>{};
    for (final row in historyRows) {
      final mg = _pickMg(row);
      final time = _pickTime(row);
      if (mg.isNaN || time == null) continue;
      timed.add(MapEntry(time, mg));
      final key = DateFormat('yyyy-MM-dd').format(time);
      byDay.putIfAbsent(key, () => []).add(mg);
    }

    if (timed.isEmpty && localMg.isNotEmpty) {
      final start = _startDate;
      final endExclusive = _endDate.add(const Duration(days: 1));
      for (final s in widget.controller.history) {
        if (s.value == null || s.warmup || s.abnormal) continue;
        if (s.measuredAt.isBefore(start) ||
            !s.measuredAt.isBefore(endExclusive)) {
          continue;
        }
        final v = s.value!;
        final mg = v > 30 ? v : v * 18.0182;
        timed.add(MapEntry(s.measuredAt, mg));
        final key = DateFormat('yyyy-MM-dd').format(s.measuredAt);
        byDay.putIfAbsent(key, () => []).add(mg);
      }
    }

    timed.sort((a, b) => a.key.compareTo(b.key));
    final values = timed.map((e) => e.value).toList();

    String statusFor(double mg) {
      if (mg < 54) return 'Very Low';
      if (mg < lowTarget) return 'Low';
      if (mg > 250) return 'Very High';
      if (mg > highTarget) return 'High';
      return 'Normal';
    }

    final readings = timed
        .map(
          (e) => ReportReadingRow(
            time: e.key,
            mgDl: e.value,
            status: statusFor(e.value),
          ),
        )
        .toList();

    // One-hour interval buckets
    final byHour = <String, List<double>>{};
    final hourKeys = <String, DateTime>{};
    for (final e in timed) {
      final hour = DateTime(
        e.key.year,
        e.key.month,
        e.key.day,
        e.key.hour,
      );
      final key = hour.toIso8601String();
      byHour.putIfAbsent(key, () => []).add(e.value);
      hourKeys[key] = hour;
    }
    final hourlyIntervals = <ReportHourlyInterval>[];
    final hourSorted = hourKeys.keys.toList()..sort();
    for (final key in hourSorted) {
      final vals = byHour[key]!;
      final avg = (vals.reduce((a, b) => a + b) / vals.length).round();
      final inRange = vals
              .where((v) => v >= lowTarget && v <= highTarget)
              .length /
          vals.length *
          100;
      final low = vals.where((v) => v < lowTarget).length / vals.length * 100;
      final high =
          vals.where((v) => v > highTarget).length / vals.length * 100;
      hourlyIntervals.add(
        ReportHourlyInterval(
          hourStart: hourKeys[key]!,
            avgGlucose: avg,
          minGlucose: vals.reduce(math.min).round(),
          maxGlucose: vals.reduce(math.max).round(),
          readingsCount: vals.length,
          inRangePct: inRange,
          lowPct: low,
          highPct: high,
          unstable: inRange < 70 ||
              low > 0 ||
              high > 15 ||
              avg < lowTarget ||
              avg > highTarget,
          ),
        );
      }

    // Group consecutive out-of-range readings into unstable periods
    final unstablePeriods = <ReportUnstablePeriod>[];
    DateTime? runStart;
    DateTime? runEnd;
    final runVals = <double>[];
    String? runReason;

    void flushRun() {
      if (runStart == null || runVals.isEmpty) return;
      unstablePeriods.add(
        ReportUnstablePeriod(
          start: runStart!,
          end: runEnd ?? runStart!,
          reason: runReason ?? 'Unstable',
          avgGlucose:
              (runVals.reduce((a, b) => a + b) / runVals.length).round(),
          readingCount: runVals.length,
        ),
      );
      runStart = null;
      runEnd = null;
      runVals.clear();
      runReason = null;
    }

    for (final e in timed) {
      final mg = e.value;
      final out = mg < lowTarget || mg > highTarget;
      if (!out) {
        flushRun();
        continue;
      }
      final reason = mg < lowTarget ? 'Low glucose' : 'High glucose';
      if (runStart == null) {
        runStart = e.key;
        runEnd = e.key;
        runReason = reason;
        runVals.add(mg);
      } else {
        final gap = e.key.difference(runEnd!).inMinutes;
        if (gap <= 20 && runReason == reason) {
          runEnd = e.key;
          runVals.add(mg);
        } else {
          flushRun();
          runStart = e.key;
          runEnd = e.key;
          runReason = reason;
          runVals.add(mg);
        }
      }
    }
    flushRun();

    // Also flag high-variability hours as unstable windows
    for (final h in hourlyIntervals) {
      if (!h.unstable || h.readingsCount < 3) continue;
      final already = unstablePeriods.any(
        (u) =>
            !h.hourStart.isBefore(u.start) &&
            !h.hourStart.isAfter(u.end.add(const Duration(hours: 1))),
      );
      if (already) continue;
      if (h.inRangePct >= 70 && h.lowPct == 0 && h.highPct <= 15) continue;
      if (h.avgGlucose >= lowTarget &&
          h.avgGlucose <= highTarget &&
          h.lowPct == 0) {
        continue;
      }
      // Variability-style unstable hour with mixed swings
      if (h.maxGlucose - h.minGlucose >= 60) {
        unstablePeriods.add(
          ReportUnstablePeriod(
            start: h.hourStart,
            end: h.hourStart.add(const Duration(hours: 1)),
            reason: 'High variability',
            avgGlucose: h.avgGlucose,
            readingCount: h.readingsCount,
          ),
        );
      }
    }
    unstablePeriods.sort((a, b) => a.start.compareTo(b.start));

    num? asNum(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      final cleaned = '$v'
          .replaceAll('%', '')
          .replaceAll('mg/dL', '')
          .replaceAll(' ', '')
          .trim();
      return num.tryParse(cleaned);
    }

    final readingCount = asNum(
          summary['readingCount'] ??
              summary['ReadingCount'] ??
              report['totalReadings'] ??
              report['TotalReadings'],
        )?.toInt() ??
        values.length;

    double? avg = asNum(
      summary['averageGlucose'] ??
          summary['AverageGlucose'] ??
          report['avgGlucose'] ??
          report['AvgGlucose'],
    )?.toDouble();
    if ((avg == null || avg.isNaN) && values.isNotEmpty) {
      avg = values.reduce((a, b) => a + b) / values.length;
    }
    // If avg looks like mmol, convert for display.
    if (avg != null && avg > 0 && avg < 30) avg = avg * 18.0182;

    double? highest = asNum(
      summary['highestGlucose'] ??
          summary['HighestGlucose'] ??
          report['highestGlucose'],
    )?.toDouble();
    if ((highest == null || highest.isNaN) && values.isNotEmpty) {
      highest = values.reduce(math.max);
    }
    if (highest != null && highest > 0 && highest < 30) {
      highest = highest * 18.0182;
    }

    double? lowest = asNum(
      summary['lowestGlucose'] ??
          summary['LowestGlucose'] ??
          report['lowestGlucose'],
    )?.toDouble();
    if ((lowest == null || lowest.isNaN) && values.isNotEmpty) {
      lowest = values.reduce(math.min);
    }
    if (lowest != null && lowest > 0 && lowest < 30) {
      lowest = lowest * 18.0182;
    }

    // Report TIR / low / high always use 80-130 (not app or server 70-180).
    double? tir;
    double? lowPct;
    double? highPct;
    if (values.isNotEmpty) {
      tir = values.where((v) => v >= lowTarget && v <= highTarget).length /
          values.length *
          100;
      lowPct =
          values.where((v) => v < lowTarget).length / values.length * 100;
      highPct =
          values.where((v) => v > highTarget).length / values.length * 100;
    }

    double? veryHighPct = asNum(
      report['veryHighPercentage'] ?? report['timeVeryHigh'],
    )?.toDouble();
    if ((veryHighPct == null || veryHighPct.isNaN) && values.isNotEmpty) {
      veryHighPct = values.where((v) => v > 250).length / values.length * 100;
    }

    double? cv = asNum(report['glucoseVariability'])?.toDouble();
    double? sd = asNum(report['standardDeviation'])?.toDouble();
    if (values.length >= 2) {
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance = values
              .map((v) => math.pow(v - mean, 2))
              .reduce((a, b) => a + b) /
          (values.length - 1);
      final computedSd = math.sqrt(variance);
      sd ??= computedSd;
      if (mean > 0) cv ??= (computedSd / mean) * 100;
    }

    String a1c = '${report['estimatedA1c'] ?? ''}'.trim();
    if (a1c.isEmpty || a1c == 'null') {
      if (avg != null) {
        a1c = '${(((avg + 46.7) / 28.7) * 10).round() / 10}%';
      } else {
        a1c = '--';
      }
    }

    // Daily breakdown
    final breakdown = <ReportBreakdownItem>[];
    final dayKeys = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final key in dayKeys) {
      final dayVals = byDay[key]!;
      if (dayVals.isEmpty) continue;
      final dayAvg =
          (dayVals.reduce((a, b) => a + b) / dayVals.length).round();
      final inRange = dayVals
              .where((v) => v >= lowTarget && v <= highTarget)
              .length /
          dayVals.length *
          100;
      final below =
          dayVals.where((v) => v < lowTarget).length / dayVals.length * 100;
      final high =
          dayVals.where((v) => v > highTarget).length / dayVals.length * 100;
      breakdown.add(
        ReportBreakdownItem(
          dateLabel: DateFormat('EEE, MMM d')
              .format(DateTime.tryParse(key) ?? DateTime.now()),
          avgGlucose: dayAvg,
          inRangePct: inRange,
          below70Pct: below,
          highPct: high,
          readingsCount: dayVals.length,
        ),
      );
    }

    // Trend: last 24h from history rows or local
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final trend = <MapEntry<DateTime, double>>[];
    for (final row in historyRows) {
      final mg = _pickMg(row);
      final time = _pickTime(row);
      if (mg.isNaN || time == null || time.isBefore(cutoff)) continue;
      trend.add(MapEntry(time, mg));
    }
    if (trend.isEmpty) {
      for (final s in widget.controller.history) {
        if (s.value == null || s.warmup || s.abnormal) continue;
        if (s.measuredAt.isBefore(cutoff)) continue;
        final v = s.value!;
        trend.add(MapEntry(s.measuredAt, v > 30 ? v : v * 18.0182));
      }
    }
    trend.sort((a, b) => a.key.compareTo(b.key));

    return CircleReportMetrics(
      patientName: _patientName(report),
      deviceName: _deviceLabel(),
      patientEmail:
          '${report['patientEmail'] ?? widget.controller.userEmail}'.trim(),
          start: _startDate,
          end: _endDate,
      totalDays: totalDays,
      totalReadings: readingCount > 0 ? readingCount : values.length,
      avgGlucose: _fmt(avg),
      timeInRange: _pct(tir),
      lowGlucosePct: _pct(lowPct),
      variability: _pct(cv),
      highPct: _pct(highPct),
      veryHighPct: _pct(veryHighPct),
      estimatedA1c: a1c,
      highestGlucose: _fmt(highest),
      lowestGlucose: _fmt(lowest),
      standardDeviation: _fmt(sd, decimals: 1),
      trendValues: trend.map((e) => e.value).toList(),
          breakdown: breakdown,
      readings: readings,
      hourlyIntervals: hourlyIntervals,
      unstablePeriods: unstablePeriods,
    );
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    final start = _startDate;
    final endExclusive = _endDate.add(
      const Duration(hours: 23, minutes: 59, seconds: 59),
    );

    try {
      Map<String, dynamic> summary = {};
      Map<String, dynamic> report = {};
      var historyRows = <Map<String, dynamic>>[];

      await Future.wait([
        () async {
          try {
            summary = await widget.controller.fetchGlucoseSummary(
              startUtc: start,
              endUtc: endExclusive,
            );
          } catch (_) {}
        }(),
        () async {
          try {
            await widget.controller.loadReports(
              startDate: _apiDate(_startDate),
              endDate: _apiDate(_endDate),
            );
            report = Map<String, dynamic>.from(
              widget.controller.detailedReport,
            );
          } catch (_) {}
        }(),
        () async {
          try {
            historyRows = await _fetchAllHistoryRows(start, endExclusive);
          } catch (_) {}
        }(),
      ]);

      final localMg = _localMgValues(
        start,
        endExclusive.add(const Duration(seconds: 1)),
      );

      final metrics = _computeMetrics(
        summary: summary,
        report: report,
        historyRows: historyRows,
        localMg: localMg,
      );

      if (!mounted) return;
      setState(() {
        _metrics = metrics;
        _loading = false;
        if (metrics.totalReadings == 0) {
          _loadError =
              'No glucose readings found for this period. Sync your sensor or pick another range.';
        }
      });
    } catch (e) {
      // Last-resort: local BLE buffer only.
      final localMg = _localMgValues(
        start,
        endExclusive.add(const Duration(seconds: 1)),
      );
      final metrics = _computeMetrics(
        summary: const {},
        report: widget.controller.detailedReport,
        historyRows: const [],
        localMg: localMg,
      );
      if (!mounted) return;
      setState(() {
        _metrics = metrics;
        _loading = false;
        _loadError = metrics.totalReadings == 0
            ? 'Could not load report data. Pull to refresh.'
            : null;
      });
    }
  }

  Future<void> _exportPdf() async {
    final metrics = _metrics;
    if (_exporting || metrics == null) return;
    setState(() => _exporting = true);
    try {
      await ReportPdfService.share(metrics: metrics, type: _reportType);
      if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Text('${_reportType.title} ready to share.'),
          backgroundColor: AppColors.primary,
          ),
        );
    } catch (error) {
      if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Text('Could not export: $error'),
          backgroundColor: AppColors.danger,
          ),
        );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportCsv() async {
    final metrics = _metrics;
    if (_exporting || metrics == null) return;
    setState(() => _exporting = true);
    try {
      final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
      final csv = StringBuffer()
        ..writeln('Patient,${metrics.patientName}')
        ..writeln('Email,${metrics.patientEmail}')
        ..writeln('Device,${metrics.deviceName}')
        ..writeln(
          'Period,${DateFormat('yyyy-MM-dd').format(metrics.start)} to ${DateFormat('yyyy-MM-dd').format(metrics.end)}',
        )
        ..writeln('Total Readings,${metrics.totalReadings}')
        ..writeln('Mean Glucose,${metrics.avgGlucose}')
        ..writeln('Time in Range %,${metrics.timeInRange}')
        ..writeln('Low %,${metrics.lowGlucosePct}')
        ..writeln('High %,${metrics.highPct}')
        ..writeln('Very High %,${metrics.veryHighPct}')
        ..writeln('Variability %,${metrics.variability}')
        ..writeln('Estimated A1C,${metrics.estimatedA1c}')
        ..writeln('Highest,${metrics.highestGlucose}')
        ..writeln('Lowest,${metrics.lowestGlucose}')
        ..writeln('Std Dev,${metrics.standardDeviation}')
        ..writeln()
        ..writeln('Date,Mean,In Range %,Below 80 %,High %,Readings');
      for (final row in metrics.breakdown) {
        csv.writeln(
          '${row.dateLabel},${row.avgGlucose},${row.inRangePct.toStringAsFixed(1)},${row.below70Pct.toStringAsFixed(1)},${row.highPct.toStringAsFixed(1)},${row.readingsCount}',
        );
      }
      await Printing.sharePdf(
        bytes: Uint8List.fromList(csv.toString().codeUnits),
        filename: 'Circle_CGM_Report_$stamp.csv',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not export CSV: $error'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _metrics;
    final rangeLabel =
        '${DateFormat('MMM d').format(_startDate)} – ${DateFormat('MMM d, yyyy').format(_endDate)}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadReport,
          child: ListView(
            cacheExtent: UiPerf.listCacheExtent(context),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            children: [
              PageTopBar(
                title: 'Reports',
                subtitle: 'CGM summary for your care team',
                leading: PageTopAction(
                  icon: Icons.chevron_left_rounded,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                trailing: PageTopAction(
                  icon: Icons.calendar_month_outlined,
                  tooltip: 'Custom range',
                  onPressed: () => _onFilterSelected('Custom'),
                ),
              ),
              const SizedBox(height: 18),
              _filterChips(),
              const SizedBox(height: 16),
              if (_loading && m == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              else if (m != null) ...[
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: AppColors.primary,
                      backgroundColor: AppColors.primarySoft,
                    ),
                  ),
                _periodCard(m, rangeLabel),
                if (_loadError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _loadError!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              const SizedBox(height: 20),
                _sectionTitle('Summary', '${m.totalDays}-day period'),
                const SizedBox(height: 12),
                _summaryRow(m),
                const SizedBox(height: 10),
                _secondaryStats(m),
                const SizedBox(height: 22),
                _sectionTitle('Time in range', '80–130 mg/dL'),
                const SizedBox(height: 12),
                _rangeCard(m),
                const SizedBox(height: 22),
                _sectionTitle(
                  'Daily breakdown',
                  '${m.breakdown.length} days',
                ),
                const SizedBox(height: 12),
                _dailyList(m.breakdown),
                const SizedBox(height: 22),
                _exportCard(),
                const SizedBox(height: 28),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  Widget _filterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _presets.map((f) {
          final selected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: _loading ? null : () => _onFilterSelected(f),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: AppRadii.r20,
                  border: Border.all(
                    color:
                        selected ? AppColors.primary : AppColors.surfaceBorder,
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color:
                        selected ? AppColors.surface : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _periodCard(CircleReportMetrics m, String rangeLabel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.r18,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                      m.patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                        fontSize: 16,
                    fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                      m.deviceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.surfaceBorder),
          const SizedBox(height: 12),
          Row(
                children: [
              _miniStat('Period', rangeLabel),
              _miniStat('Days', '${m.totalDays}'),
              _miniStat(
                'Readings',
                NumberFormat('#,###').format(m.totalReadings),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );

  Widget _sectionTitle(String title, String trailing) {
    return Row(
        children: [
          Expanded(
            child: Text(
              title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              ),
            ),
          ),
        Text(
          trailing,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(CircleReportMetrics m) {
    return Row(
        children: [
        Expanded(
          child: _pill(
            Icons.water_drop_outlined,
            AppPalette.hexFF0284C7,
            'Average',
            m.avgGlucose,
            'mg/dL',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _pill(
            Icons.adjust_rounded,
            AppPalette.hexFF16A34A,
            'In Range',
            m.timeInRange == '--' ? '--' : '${m.timeInRange}%',
            'TIR',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _pill(
            Icons.arrow_upward_rounded,
            AppColors.dangerDark,
            'Highest',
            m.highestGlucose,
            'mg/dL',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _pill(
            Icons.arrow_downward_rounded,
            AppPalette.hexFF0284C7,
            'Lowest',
            m.lowestGlucose,
            'mg/dL',
          ),
        ),
      ],
    );
  }

  Widget _pill(
    IconData icon,
    Color iconColor,
    String title,
    String value,
    String sub,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.r16,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
            value,
              style: const TextStyle(
                fontSize: 16,
              fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _secondaryStats(CircleReportMetrics m) {
    Widget tile(String label, String value, IconData icon, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
            borderRadius: AppRadii.r14,
            border: Border.all(color: AppColors.surfaceBorder),
          ),
            child: Row(
              children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            tile(
              'Low <80',
              m.lowGlucosePct == '--' ? '--' : '${m.lowGlucosePct}%',
              Icons.trending_down_rounded,
              AppPalette.hexFF489CCD,
            ),
            const SizedBox(width: 8),
            tile(
              'High >130',
              m.highPct == '--' ? '--' : '${m.highPct}%',
              Icons.trending_up_rounded,
              AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            tile(
              'Variability',
              m.variability == '--' ? '--' : '${m.variability}%',
              Icons.show_chart_rounded,
              AppColors.accent,
            ),
            const SizedBox(width: 8),
            tile(
              'Est. A1C',
              m.estimatedA1c,
              Icons.analytics_outlined,
              AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _rangeCard(CircleReportMetrics m) {
    double parse(String v) => double.tryParse(v) ?? 0;
    final veryHigh = parse(m.veryHighPct);
    final highAll = parse(m.highPct);
    final high = math.max(0.0, highAll - veryHigh);
    final inRange = parse(m.timeInRange);
    final low = parse(m.lowGlucosePct);
    final total = math.max(0.1, veryHigh + high + inRange + low);

    Widget seg(double portion, Color color) {
      if (portion <= 0) return const SizedBox.shrink();
      return Expanded(
        flex: math.max(1, (portion / total * 1000).round()),
        child: ColoredBox(color: color),
      );
    }

    Widget row(String label, String value, Color color) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
                      Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.r18,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  seg(veryHigh, AppPalette.hexFFD95A61),
                  seg(high, AppColors.warning),
                  seg(inRange, AppPalette.hexFF16A34A),
                  seg(low, AppPalette.hexFF489CCD),
              ],
            ),
          ),
          ),
          const SizedBox(height: 14),
          row(
            'Very high >250',
            m.veryHighPct == '--' ? '--' : '${m.veryHighPct}%',
            AppPalette.hexFFD95A61,
          ),
          row(
            'High >130',
            m.highPct == '--' ? '--' : '${m.highPct}%',
            AppColors.warning,
          ),
          row(
            'In range 80–130',
            m.timeInRange == '--' ? '--' : '${m.timeInRange}%',
            AppPalette.hexFF16A34A,
          ),
          row(
            'Low <80',
            m.lowGlucosePct == '--' ? '--' : '${m.lowGlucosePct}%',
            AppPalette.hexFF489CCD,
          ),
        ],
      ),
    );
  }

  Widget _dailyList(List<ReportBreakdownItem> items) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.r18,
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: const Column(
          children: [
                    Icon(
                      Icons.analytics_outlined,
              size: 36,
              color: AppColors.textDisabled,
                    ),
                    SizedBox(height: 10),
                    Text(
              'No daily readings yet',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
              'Sync your sensor or choose another date range.',
                      textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.r18,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'DATE',
                      style: TextStyle(
                      fontSize: 10,
                        fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'MEAN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                      fontSize: 10,
                        fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'IN RANGE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                      fontSize: 10,
                        fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'LOW/HIGH',
                    textAlign: TextAlign.right,
                      style: TextStyle(
                      fontSize: 10,
                        fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceBorder),
          ...() {
            final maxRows =
                UiPerf.isLowEndLayout(context) ? 30 : items.length;
            final visible = items.length > maxRows
                ? items.sublist(0, maxRows)
                : items;
            return [
              for (var i = 0; i < visible.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: AppColors.surfaceBorder),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                          visible[i].dateLabel,
                              style: const TextStyle(
                            fontSize: 13,
                                fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                          '${visible[i].readingsCount} readings',
                              style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  Expanded(
                    flex: 2,
                          child: Text(
                      '${visible[i].avgGlucose}',
                      textAlign: TextAlign.center,
                            style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                  Expanded(
                    flex: 2,
                          child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                        color: AppColors.successSoft,
                              borderRadius: AppRadii.r12,
                            ),
                            child: Text(
                        '${visible[i].inRangePct.toStringAsFixed(0)}%',
                        textAlign: TextAlign.center,
                              style: const TextStyle(
                          fontSize: 12,
                                fontWeight: FontWeight.w800,
                          color: AppColors.successDark,
                              ),
                            ),
                          ),
                        ),
                  Expanded(
                    flex: 2,
                          child: Text(
                      '${visible[i].below70Pct.toStringAsFixed(0)}% / ${visible[i].highPct.toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                            style: const TextStyle(
                        fontSize: 11,
                                fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                    ],
              ),
            ),
              ],
              if (items.length > visible.length)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  child: Text(
                    'Showing ${visible.length} of ${items.length} days',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ];
          }(),
        ],
      ),
    );
  }

  Widget _exportCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.r18,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
            'Create report',
                  style: TextStyle(
              fontSize: 16,
            fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
          ),
        ),
          const SizedBox(height: 4),
        const Text(
            'Choose the report type, then download a PDF.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          for (final type in CircleReportType.values) ...[
            _reportTypeTile(type),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          SizedBox(
      width: double.infinity,
            height: 50,
      child: ElevatedButton(
              onPressed: (_exporting || _metrics == null) ? null : _exportPdf,
        style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.r16),
        ),
        child: _exporting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.surface,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                        const Icon(Icons.picture_as_pdf_rounded, size: 20),
                  const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Download ${_reportType.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                              fontSize: 14,
                      fontWeight: FontWeight.w800,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: (_exporting || _metrics == null) ? null : _exportCsv,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primaryBorder),
                shape: RoundedRectangleBorder(borderRadius: AppRadii.r16),
              ),
              child: const Text(
                'Export CSV',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportTypeTile(CircleReportType type) {
    final selected = _reportType == type;
    return GestureDetector(
      onTap: () => setState(() => _reportType = type),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.background,
          borderRadius: AppRadii.r14,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surfaceBorder,
            width: selected ? 1.6 : 1,
          ),
        ),
    child: Row(
      children: [
            Icon(
              switch (type) {
                CircleReportType.allData => Icons.list_alt_rounded,
                CircleReportType.hourlyInterval => Icons.schedule_rounded,
                CircleReportType.average => Icons.insights_rounded,
              },
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.subtitle,
            style: const TextStyle(
              fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.textDisabled,
              size: 20,
        ),
      ],
    ),
        ),
      );
    }
}
