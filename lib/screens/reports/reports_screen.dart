import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../core/app_theme.dart';
import '../../services/report_pdf_service.dart';
import '../../state/app_controller.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Preset options: 'Last 7 days', 'Last 30 days', 'Last 90 days', 'Last 300 days', 'Custom Range'
  String _selectedRangePreset = 'Last 7 days';
  String _selectedFormat = 'PDF'; // 'PDF', 'CSV', 'Share'
  late DateTime _startDate;
  late DateTime _endDate;
  bool _loadingReport = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    // Default to 300 days as in mockup
    _startDate = today.subtract(const Duration(days: 7));
    _endDate = today;
    widget.controller.addListener(_onControllerChanged);
    _loadReport();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  String _apiDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<void> _loadReport() async {
    if (mounted) setState(() => _loadingReport = true);
    await widget.controller.loadReports(
      startDate: _apiDate(_startDate),
      endDate: _apiDate(_endDate),
    );
    if (mounted) setState(() => _loadingReport = false);
  }

  Future<void> _onPresetSelected(String preset) async {
    final today = DateUtils.dateOnly(DateTime.now());
    if (preset == 'Custom Range') {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: today.add(const Duration(days: 365)),
        initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
        helpText: 'Select custom report dates',
        saveText: 'Apply',
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryPurple,
              onPrimary: AppColors.surface,
              surface: AppColors.surface,
              onSurface: AppTheme.darkPurple,
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
        _selectedRangePreset = 'Custom Range';
        _startDate = DateUtils.dateOnly(range.start);
        _endDate = DateUtils.dateOnly(range.end);
      });
      await _loadReport();
    } else {
      final days = switch (preset) {
        'Last 7 days' => 7,
        'Last 30 days' => 30,
        'Last 90 days' => 90,
        _ => 300,
      };

      setState(() {
        _selectedRangePreset = preset;
        _endDate = today;
        _startDate = today.subtract(Duration(days: days - 1));
      });
      await _loadReport();
    }
  }

  // Generate breakdown table rows matching the mockup structure
  List<ReportBreakdownItem> _getBreakdownItems() {
    final breakdown = <ReportBreakdownItem>[];

    // Check if report has real daily summaries
    final rawSummaries = widget.controller.detailedReport['dailySummaries'];
    final dailyList = rawSummaries is List
        ? rawSummaries.whereType<Map>().toList()
        : <Map>[];

    if (dailyList.isNotEmpty) {
      // Use real daily summaries
      for (final d in dailyList.reversed) {
        final dateParsed =
            DateTime.tryParse('${d['dateFormatted'] ?? ''}') ?? DateTime.now();
        final avg = int.tryParse(
          '${d['avgGlucose'] ?? ''}'.replaceAll(' mg/dL', ''),
        );
        final tir = int.tryParse(
          '${d['timeInRange'] ?? ''}'.replaceAll('%', ''),
        );
        if (avg == null || tir == null) continue;

        final low = (d['lowEvents'] as num?)?.toInt() ?? (avg < 90 ? 1 : 0);
        final high = (d['highEvents'] as num?)?.toInt() ?? (avg > 130 ? 1 : 0);
        final usage =
            (d['readingsCount'] as num?) != null &&
                (d['readingsCount'] as num) > 0
            ? 100
            : 0;

        breakdown.add(
          ReportBreakdownItem(
            period: DateFormat('EEE, MMM d').format(dateParsed),
            subPeriod: DateFormat('yyyy').format(dateParsed),
            avgGlucose: avg,
            tir: tir,
            lowEvents: low,
            highEvents: high,
            sensorUsage: usage,
            note: tir >= 70 ? 'In Target' : (avg > 130 ? 'High' : 'Low'),
            noteStatus: tir >= 70 ? 'stable' : (avg > 130 ? 'high' : 'warning'),
          ),
        );
      }
    } else if (widget.controller.history.isNotEmpty) {
      // Build breakdown dynamically from local history
      final rangeStart = _startDate;
      final rangeEnd = _endDate.add(const Duration(days: 1));
      final dailyMap = <String, List<double>>{};
      for (final s in widget.controller.history) {
        if (s.value == null || s.warmup || s.abnormal) continue;
        if (s.measuredAt.isBefore(rangeStart) || s.measuredAt.isAfter(rangeEnd)) continue;
        final dateKey = DateFormat('yyyy-MM-dd').format(s.measuredAt);
        dailyMap.putIfAbsent(dateKey, () => []).add(s.value! * 18.0182);
      }
      final sortedDates = dailyMap.keys.toList()..sort((a, b) => b.compareTo(a));
      for (final dStr in sortedDates) {
        final dateParsed = DateTime.tryParse(dStr) ?? DateTime.now();
        final vals = dailyMap[dStr]!;
        if (vals.isEmpty) continue;
        final avg = (vals.reduce((a, b) => a + b) / vals.length).round();
        final inTir = vals.where((v) => v >= widget.controller.targetLow && v <= widget.controller.targetHigh).length;
        final tir = ((inTir / vals.length) * 100).round();
        final low = vals.where((v) => v < widget.controller.targetLow).length;
        final high = vals.where((v) => v > widget.controller.targetHigh).length;
        breakdown.add(
          ReportBreakdownItem(
            period: DateFormat('EEE, MMM d').format(dateParsed),
            subPeriod: DateFormat('yyyy').format(dateParsed),
            avgGlucose: avg,
            tir: tir,
            lowEvents: low,
            highEvents: high,
            sensorUsage: 100,
            note: tir >= 70 ? 'In Target' : (avg > 130 ? 'High' : 'Low'),
            noteStatus: tir >= 70 ? 'stable' : (avg > 130 ? 'high' : 'warning'),
          ),
        );
      }
    }

    return breakdown;
  }

  Future<void> _exportReport() async {
    if (_exporting) return;
    setState(() => _exporting = true);

    try {
      final report = widget.controller.detailedReport;
      final breakdown = _getBreakdownItems();
      final patientName = widget.controller.fullName.trim().isNotEmpty
          ? widget.controller.fullName.trim()
          : 'Aima Patient';

      if (_selectedFormat == 'CSV') {
        // Build true CSV representation of patient report readings
        final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
        final csvBuffer = StringBuffer();
        csvBuffer.writeln('Time,Glucose (mg/dL),Status');

        final readings = report['recentReadings'] is List
            ? report['recentReadings'] as List
            : [];
        for (final r in readings) {
          if (r is Map) {
            final t = r['timeFormatted'] ?? r['time'] ?? '';
            final val = r['value'] ?? '';
            final st = r['status'] ?? '';
            csvBuffer.writeln('"$t",$val,"$st"');
          }
        }

        final bytes = Uint8List.fromList(csvBuffer.toString().codeUnits);
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'Aima_CGM_Report_$stamp.csv',
        );
      } else {
        // PDF or Share
        await ReportPdfService.share(
          report: report,
          start: _startDate,
          end: _endDate,
          breakdown: breakdown,
          patientName: patientName,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report successfully generated as $_selectedFormat.'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not export report: $error'),
            backgroundColor: AppColors.materialRedAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.controller.detailedReport;
    final totalDays = _endDate.difference(_startDate).inDays + 1;

    // Filter local history samples that fall in selected date range
    final rangeStart = _startDate;
    final rangeEnd = _endDate.add(const Duration(days: 1));
    final filteredHistory = widget.controller.history.where((s) {
      if (s.value == null || s.warmup || s.abnormal) return false;
      return s.measuredAt.isAfter(rangeStart) && s.measuredAt.isBefore(rangeEnd);
    }).toList();

    final backendReadings = (report['totalReadings'] as num? ?? 0);

    // Average Glucose
    String avgGlucose = '--';
    if (backendReadings > 0 && report['avgGlucose'] != null) {
      avgGlucose = report['avgGlucose'].toString().replaceAll(' mg/dL', '');
    } else if (filteredHistory.isNotEmpty) {
      final sum = filteredHistory.fold<double>(0.0, (acc, s) => acc + (s.value! * 18.0182));
      avgGlucose = (sum / filteredHistory.length).round().toString();
    }

    // Time in Range (TIR: 90 - 130 mg/dL)
    String tir = '--';
    if (backendReadings > 0 && report['timeInRange'] != null) {
      tir = report['timeInRange'].toString().replaceAll('%', '');
    } else if (filteredHistory.isNotEmpty) {
      final inTir = filteredHistory.where((s) {
        final mg = s.value! * 18.0182;
        return mg >= widget.controller.targetLow && mg <= widget.controller.targetHigh;
      }).length;
      tir = ((inTir / filteredHistory.length) * 100).round().toString();
    }

    // Estimated A1C (Formula: (avgGlucose + 46.7) / 28.7)
    String a1c = '--';
    if (backendReadings > 0 && report['estimatedA1c'] != null) {
      a1c = report['estimatedA1c'].toString();
    } else if (avgGlucose != '--') {
      final avgNum = double.tryParse(avgGlucose);
      if (avgNum != null) {
        a1c = (((avgNum + 46.7) / 28.7) * 10).round() / 10 > 0
            ? '${(((avgNum + 46.7) / 28.7) * 10).round() / 10}%'
            : '--';
      }
    }

    // Low Events (< 90 mg/dL) & High Events (> 130 mg/dL)
    String lowEvents = '0';
    String highEvents = '0';
    if (backendReadings > 0) {
      lowEvents = report['lowEvents']?.toString() ?? '0';
      highEvents = report['highEvents']?.toString() ?? '0';
    } else if (filteredHistory.isNotEmpty) {
      int lows = 0;
      int highs = 0;
      bool wasLow = false;
      bool wasHigh = false;
      for (final s in filteredHistory) {
        final mg = s.value! * 18.0182;
        if (mg < widget.controller.targetLow) {
          if (!wasLow) lows++;
          wasLow = true;
        } else {
          wasLow = false;
        }
        if (mg > widget.controller.targetHigh) {
          if (!wasHigh) highs++;
          wasHigh = true;
        } else {
          wasHigh = false;
        }
      }
      lowEvents = '$lows';
      highEvents = '$highs';
    } else {
      lowEvents = '--';
      highEvents = '--';
    }

    final breakdownItems = _getBreakdownItems();
    final dateRangeStr =
        '${DateFormat('MMM d, yyyy').format(_startDate)}  ${DateFormat('MMM d, yyyy').format(_endDate)}';

    return Scaffold(
      backgroundColor: AppPalette.hexFFF9F9FC,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryPurple,
          onRefresh: _loadReport,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            children: [
              // 1. Top Header: Logo + "Export Report" + Back Button
              _buildTopHeader(context),
              if (_loadingReport) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: AppTheme.accentCyan,
                  backgroundColor: AppTheme.lightCyanBg,
                ),
              ],
              const SizedBox(height: 18),

              // 2. Report Range Card with Dropdown Selector
              _buildRangeCard(totalDays, dateRangeStr),
              const SizedBox(height: 22),

              // 3. Summary Title & Subtitle
              const Text(
                'Summary',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkPurple,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Key metrics for the selected $totalDays-day period.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),

              // 4. Five Summary Cards (Horizontal Scroll or Flex Row)
              _buildSummaryCardsStrip(
                avgGlucose: avgGlucose,
                tir: tir,
                a1c: a1c,
                lowEvents: lowEvents,
                highEvents: highEvents,
              ),
              const SizedBox(height: 22),

              // 5. Periodic Breakdown Table Card
              _buildBreakdownTableCard(totalDays, breakdownItems),
              const SizedBox(height: 16),

              // 6. Blue Notice Banner
              _buildNoticeBanner(totalDays),
              const SizedBox(height: 24),

              // 7. Export Format Selector (PDF, CSV, Share)
              _buildExportFormatSection(),
              const SizedBox(height: 20),

              // 8. Main Export Button
              _buildExportButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Top Header
  // ===========================================================================
  Widget _buildTopHeader(BuildContext context) {
    return Row(
      children: [
        // Aima Logo Circle
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppPalette.hexFFEFEBF6, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPurple.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: AppInsets.all5,
          child: SvgPicture.asset(
            'assets/images/logo.svg',
            semanticsLabel: 'Aima Logo',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Export Report',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkPurple,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Download your CGM data and insights.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Back / Action Button
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppPalette.hexFFF2EEF9,
            borderRadius: AppRadii.r12,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: AppTheme.primaryPurple,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Range Card with Dropdown Filter
  // ===========================================================================
  Widget _buildRangeCard(int totalDays, String dateRangeStr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.r18,
        border: Border.all(color: AppPalette.hexFFEFEBF6, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppPalette.hexFFF6F3FB,
              borderRadius: AppRadii.r12,
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: AppTheme.primaryPurple,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$totalDays Days Report',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkPurple,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dateRangeStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Dropdown Pill
          PopupMenuButton<String>(
            initialValue: _selectedRangePreset,
            onSelected: _onPresetSelected,
            color: AppColors.surface,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: AppRadii.r16),
            itemBuilder: (context) => [
              _buildPopupMenuItem('Last 7 days'),
              _buildPopupMenuItem('Last 30 days'),
              _buildPopupMenuItem('Last 90 days'),
              const PopupMenuDivider(height: 1),
              _buildPopupMenuItem(
                'Custom Range',
                icon: Icons.date_range_rounded,
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppPalette.hexFFF9F7FC,
                borderRadius: AppRadii.r20,
                border: Border.all(color: AppPalette.hexFFE5DCF4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 14,
                    color: AppTheme.primaryPurple,
                  ),
                  const SizedBox(width: 5),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 85),
                    child: Text(
                      _selectedRangePreset,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkPurple,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppTheme.primaryPurple,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String title, {IconData? icon}) {
    final isSelected = _selectedRangePreset == title;
    return PopupMenuItem<String>(
      value: title,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppTheme.primaryPurple : AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected
                    ? AppTheme.primaryPurple
                    : AppTheme.darkPurple,
              ),
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_rounded,
              size: 16,
              color: AppTheme.primaryPurple,
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5 Summary Metric Cards
  // ===========================================================================
  Widget _buildSummaryCardsStrip({
    required String avgGlucose,
    required String tir,
    required String a1c,
    required String lowEvents,
    required String highEvents,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildMetricPill(
            icon: Icons.water_drop_outlined,
            iconBg: AppPalette.hexFFE0F2FE,
            iconColor: AppPalette.hexFF0284C7,
            title: 'Average\nGlucose',
            value: avgGlucose,
            subText: 'mg/dL',
            valueColor: AppTheme.darkPurple,
          ),
          const SizedBox(width: 10),
          _buildMetricPill(
            icon: Icons.adjust_rounded,
            iconBg: AppPalette.hexFFDCFCE7,
            iconColor: AppPalette.hexFF16A34A,
            title: 'Time in\nRange',
            value: tir == '--' ? '--' : '$tir%',
            subText: '90-130 mg/dL',
            valueColor: AppTheme.darkPurple,
          ),
          const SizedBox(width: 10),
          _buildMetricPill(
            icon: Icons.bar_chart_rounded,
            iconBg: AppPalette.hexFFF3E8FF,
            iconColor: AppTheme.primaryPurple,
            title: 'Estimated\nA1C',
            value: a1c,
            subText: '(eA1C)',
            valueColor: AppTheme.darkPurple,
          ),
          const SizedBox(width: 10),
          _buildMetricPill(
            icon: Icons.arrow_downward_rounded,
            iconBg: AppPalette.hexFFE0F2FE,
            iconColor: AppPalette.hexFF0284C7,
            title: 'Low\nEvents',
            value: lowEvents,
            subText: '< 90 mg/dL',
            valueColor: AppTheme.darkPurple,
          ),
          const SizedBox(width: 10),
          _buildMetricPill(
            icon: Icons.arrow_upward_rounded,
            iconBg: AppPalette.hexFFFEE2E2,
            iconColor: AppPalette.hexFFDC2626,
            title: 'High\nEvents',
            value: highEvents,
            subText: '> 130 mg/dL',
            valueColor: AppPalette.hexFFDC2626,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required String subText,
    required Color valueColor,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.r16,
        border: Border.all(color: AppPalette.hexFFEFEBF6, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: valueColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Periodic Breakdown Table Card
  // ===========================================================================
  Widget _buildBreakdownTableCard(
    int totalDays,
    List<ReportBreakdownItem> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.r18,
        border: Border.all(color: AppPalette.hexFFEFEBF6, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header inside table card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalDays-Day Report (Breakdown)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkPurple,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.hexFFF3E8FF,
                    borderRadius: AppRadii.r12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.info_outline,
                        size: 12,
                        color: AppTheme.primaryPurple,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Values are averages',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppPalette.hexFFF0ECF8),

          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.analytics_outlined,
                      size: 40,
                      color: AppPalette.hexFFCDC6E2,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No data available',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkPurple,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'No CGM readings were recorded during this period.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Scrollable Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 52,
                horizontalMargin: 16,
                columnSpacing: 18,
                headingRowColor: WidgetStateProperty.all(
                  AppPalette.hexFFFAF8FE,
                ),
                columns: const [
                  DataColumn(
                    label: Text(
                      'Period',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Avg Glucose\n(mg/dL)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryPurple,
                        height: 1.1,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Time in Range\n(90-130)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryPurple,
                        height: 1.1,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Low\n(< 90)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryPurple,
                        height: 1.1,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'High\n(> 130)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryPurple,
                        height: 1.1,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Sensor\nUsage',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryPurple,
                        height: 1.1,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  ),
                ],
                rows: items.map((item) {
                  final isStable = item.noteStatus == 'stable';
                  final isWarning = item.noteStatus == 'warning';
                  final dotColor = isStable
                      ? AppPalette.hexFF22C55E
                      : (isWarning
                            ? AppPalette.hexFFEAB308
                            : AppPalette.hexFFF97316);

                  return DataRow(
                    cells: [
                      // Period
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.period,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.darkPurple,
                              ),
                            ),
                            Text(
                              item.subPeriod,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Avg Glucose
                      DataCell(
                        Center(
                          child: Text(
                            '${item.avgGlucose}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkPurple,
                            ),
                          ),
                        ),
                      ),
                      // Time in Range pill
                      DataCell(
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.hexFFDCFCE7,
                              borderRadius: AppRadii.r12,
                            ),
                            child: Text(
                              '${item.tir}%',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppPalette.hexFF15803D,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Low (<90)
                      DataCell(
                        Center(
                          child: Text(
                            '${item.lowEvents}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppPalette.hexFF0284C7,
                            ),
                          ),
                        ),
                      ),
                      // High (>130)
                      DataCell(
                        Center(
                          child: Text(
                            '${item.highEvents}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppPalette.hexFFDC2626,
                            ),
                          ),
                        ),
                      ),
                      // Sensor usage
                      DataCell(
                        Center(
                          child: Text(
                            '${item.sensorUsage}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.darkPurple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      // Notes with status dot
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.note,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isStable
                                    ? AppTheme.darkPurple
                                    : dotColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Notice Banner
  // ===========================================================================
  Widget _buildNoticeBanner(int totalDays) {
    return Container(
      padding: AppInsets.all14,
      decoration: BoxDecoration(
        color: AppPalette.hexFFF0F9FF,
        borderRadius: AppRadii.r16,
        border: Border.all(color: AppPalette.hexFFBAE6FD, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppPalette.hexFFE0F2FE,
              borderRadius: AppRadii.r10,
            ),
            child: const Icon(
              Icons.assessment_outlined,
              color: AppPalette.hexFF0284C7,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This report includes $totalDays days of CGM data, organized systematically.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.hexFF0369A1,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Export to share with your healthcare provider or keep for your records.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppPalette.hexFF0284C7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Export Format Section
  // ===========================================================================
  Widget _buildExportFormatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Export Format',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkPurple,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Choose a format for your report.',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFormatOptionCard(
                title: 'PDF',
                subtitle: 'Best for sharing',
                icon: Icons.picture_as_pdf_rounded,
                iconColor: AppPalette.hexFFDC2626,
                formatKey: 'PDF',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormatOptionCard(
                title: 'Share',
                subtitle: 'Send or save',
                icon: Icons.share_rounded,
                iconColor: AppTheme.primaryPurple,
                formatKey: 'Share',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormatOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String formatKey,
  }) {
    final isSelected = _selectedFormat == formatKey;

    return GestureDetector(
      onTap: () => setState(() => _selectedFormat = formatKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.r16,
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : AppPalette.hexFFEFEBF6,
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkPurple,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.surface,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Main Export Button
  // ===========================================================================
  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _exporting ? null : _exportReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryPurple,
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
                  const Icon(
                    Icons.download_rounded,
                    size: 20,
                    color: AppColors.surface,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Export Report ($_selectedFormat)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.surface,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
