import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cgm_sdk/cgm_sdk.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../state/app_controller.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime selectedDate = DateTime.now();
  String selectedFilter = 'Today'; // 'Today', '7D', '14D', '30D', '300D'
  late DateTime _weekStartMonday;
  bool _showAllReadings = false;

  @override
  void initState() {
    super.initState();
    _initWeekForDate(DateTime.now());
  }

  void _initWeekForDate(DateTime date) {
    // In DateTime: Monday = 1, Sunday = 7
    final weekday = date.weekday;
    _weekStartMonday = DateUtils.dateOnly(
      date.subtract(Duration(days: weekday - 1)),
    );
  }

  void _onPrevWeek() {
    setState(() {
      _weekStartMonday = _weekStartMonday.subtract(const Duration(days: 7));
      selectedDate = _weekStartMonday.add(const Duration(days: 6));
    });
  }

  void _onNextWeek() {
    setState(() {
      _weekStartMonday = _weekStartMonday.add(const Duration(days: 7));
      selectedDate = _weekStartMonday;
    });
  }

  Future<void> _openCalendarPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryPurple,
              onPrimary: AppColors.surface,
              onSurface: AppTheme.darkPurple,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _initWeekForDate(picked);
      });
    }
  }

  void _onSelectFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      if (filter == 'Today') {
        selectedDate = DateTime.now();
        _initWeekForDate(selectedDate);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lowTarget = widget.controller.targetLow.toDouble();
    final highTarget = widget.controller.targetHigh.toDouble();

    // 1. Filter samples according to filter or selectedDate
    List<GlucoseSample> samplesForView = [];
    DateTime rangeStart;
    DateTime rangeEnd;

    final now = DateTime.now();
    if (selectedFilter == 'Today') {
      rangeStart = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        0,
        0,
        0,
      );
      rangeEnd = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        23,
        59,
        59,
      );
      samplesForView = widget.controller.history.where((s) {
        return s.value != null &&
            DateUtils.isSameDay(s.measuredAt, selectedDate);
      }).toList();
    } else {
      int days = 7;
      if (selectedFilter == '14D') days = 14;
      if (selectedFilter == '30D') days = 30;
      if (selectedFilter == '300D') days = 300;

      rangeStart = now.subtract(Duration(days: days));
      rangeEnd = now;
      samplesForView = widget.controller.history.where((s) {
        return s.value != null && s.measuredAt.isAfter(rangeStart);
      }).toList();
    }

    // Sort chronologically
    samplesForView.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    // Fallback demo readings if currently empty
    final hasRealData = samplesForView.isNotEmpty;
    final readings = hasRealData
        ? samplesForView.reversed.toList()
        : _generateFallbackReadings();

    // Calculate metrics
    final values = readings.map((r) => (r.value! * 18.0182).round()).toList();
    final avg = values.isNotEmpty
        ? (values.reduce((a, b) => a + b) / values.length).round()
        : 113;
    final highest = values.isNotEmpty
        ? values.reduce((a, b) => a > b ? a : b)
        : 119;
    final lowest = values.isNotEmpty
        ? values.reduce((a, b) => a < b ? a : b)
        : 110;

    // Highest and lowest reading timestamps
    String highestTimeStr = '3:41 pm';
    String lowestTimeStr = '3:09 pm';
    if (hasRealData && readings.isNotEmpty) {
      final highSample = readings.firstWhere(
        (r) => (r.value! * 18.0182).round() == highest,
        orElse: () => readings.first,
      );
      final lowSample = readings.firstWhere(
        (r) => (r.value! * 18.0182).round() == lowest,
        orElse: () => readings.first,
      );
      highestTimeStr = DateFormat(
        'h:mm a',
      ).format(highSample.measuredAt).toLowerCase();
      lowestTimeStr = DateFormat(
        'h:mm a',
      ).format(lowSample.measuredAt).toLowerCase();
    }

    final inTargetCount = values
        .where((v) => v >= lowTarget && v <= highTarget)
        .length;
    final tir = values.isNotEmpty
        ? ((inTargetCount / values.length) * 100).round()
        : 100;

    return Scaffold(
      backgroundColor: AppPalette.hexFFFBF9FD,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryPurple,
          onRefresh: widget.controller.refreshHistory,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            children: [
              // Header: "History" and Calendar Icon Button
              _buildTopHeader(),
              const SizedBox(height: 18),

              // Calendar Strip with Prev/Next buttons
              _buildWeekSelectorStrip(),
              const SizedBox(height: 18),

              // Filter Buttons Pill Row: Today, 7D, 14D, 30D, 300D
              _buildPeriodFilterPills(),
              const SizedBox(height: 20),

              // Glucose Trend Chart Card
              _buildGlucoseTrendCard(
                samples: hasRealData
                    ? samplesForView
                    : _generateFallbackSamplesForChart(),
                lowTarget: lowTarget,
                highTarget: highTarget,
                startTime: selectedFilter == 'Today'
                    ? DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        0,
                        0,
                      )
                    : rangeStart,
                endTime: selectedFilter == 'Today'
                    ? DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        23,
                        59,
                      )
                    : rangeEnd,
              ),
              const SizedBox(height: 20),

              // Glucose Readings List Card
              _buildGlucoseReadingsCard(readings, lowTarget, highTarget),
              const SizedBox(height: 24),

              // Daily Summary Metrics Card
              _buildDailySummarySection(
                avg: avg,
                tir: tir,
                highest: highest,
                highestTime: highestTimeStr,
                lowest: lowest,
                lowestTime: lowestTimeStr,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. Top Header
  // ===========================================================================
  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'History',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppPalette.hexFF5E2B97,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'View your glucose data and past readings.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppPalette.hexFF7E6E91,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: _openCalendarPicker,
          borderRadius: AppRadii.r14,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.r14,
              border: Border.all(color: AppPalette.hexFFECE6F5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: AppPalette.hexFF5E2B97,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. Week Selector Strip (with < and > arrows)
  // ===========================================================================
  Widget _buildWeekSelectorStrip() {
    final daysOfWeek = List.generate(
      7,
      (i) => _weekStartMonday.add(Duration(days: i)),
    );

    return Row(
      children: [
        // Left Arrow
        InkWell(
          onTap: _onPrevWeek,
          borderRadius: AppRadii.r20,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppPalette.hexFFF3EDF9,
              shape: BoxShape.circle,
              border: Border.all(color: AppPalette.hexFFEADBFA),
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: AppPalette.hexFF5E2B97,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 6),

        // 7 Days
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: daysOfWeek.map((day) {
              final isSelected = DateUtils.isSameDay(day, selectedDate);
              final dayName = DateFormat('E').format(day).toUpperCase();
              final dayNum = day.day;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedDate = day;
                        selectedFilter = 'Today';
                      });
                    },
                    borderRadius: AppRadii.r16,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppPalette.hexFF5E2B97
                            : AppColors.surface,
                        borderRadius: AppRadii.r16,
                        border: Border.all(
                          color: isSelected
                              ? AppPalette.hexFF5E2B97
                              : AppPalette.hexFFECE6F5,
                          width: 1.2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.white70
                                  : AppPalette.hexFF7E6E91,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$dayNum',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? AppColors.surface
                                  : AppPalette.hexFF2E1A47,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.surface
                                  : AppPalette.hexFF5E2B97,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 6),

        // Right Arrow
        InkWell(
          onTap: _onNextWeek,
          borderRadius: AppRadii.r20,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppPalette.hexFFF3EDF9,
              shape: BoxShape.circle,
              border: Border.all(color: AppPalette.hexFFEADBFA),
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: AppPalette.hexFF5E2B97,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. Period Filter Pills (Today, 7D, 14D, 30D, 300D)
  // ===========================================================================
  Widget _buildPeriodFilterPills() {
    final filters = ['Today', '7D', '14D', '30D', '300D'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => _onSelectFilter(filter),
              borderRadius: AppRadii.r22,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppPalette.hexFF00B4D8
                      : AppColors.surface,
                  borderRadius: AppRadii.r22,
                  border: Border.all(
                    color: isSelected
                        ? AppPalette.hexFF00B4D8
                        : AppPalette.hexFFECE6F5,
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppColors.surface
                        : AppPalette.hexFF4A3E5C,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // 4. Glucose Trend Chart Card
  // ===========================================================================
  Widget _buildGlucoseTrendCard({
    required List<GlucoseSample> samples,
    required double lowTarget,
    required double highTarget,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    return Container(
      padding: AppInsets.all18,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.r22,
        border: Border.all(color: AppPalette.hexFFECE6F5),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Glucose Trend',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.hexFF2E1A47,
                ),
              ),
              Text(
                'mg/dL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.hexFF8A7D9D,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Your glucose readings over selected period',
            style: TextStyle(fontSize: 12, color: AppPalette.hexFF8A7D9D),
          ),
          const SizedBox(height: 16),

          // Custom Painted Trend Chart with Target Corridor
          SizedBox(
            height: 160,
            child: CustomPaint(
              painter: _HistoryTrendPainter(
                samples: samples,
                startTime: startTime,
                endTime: endTime,
                lowTarget: lowTarget,
                highTarget: highTarget,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 10),

          // X-Axis Timeline Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '12 AM',
                style: TextStyle(fontSize: 10, color: AppPalette.hexFF8A7D9D),
              ),
              Text(
                '4 AM',
                style: TextStyle(fontSize: 10, color: AppPalette.hexFF8A7D9D),
              ),
              Text(
                '8 AM',
                style: TextStyle(fontSize: 10, color: AppPalette.hexFF8A7D9D),
              ),
              Text(
                '12 PM',
                style: TextStyle(fontSize: 10, color: AppPalette.hexFF8A7D9D),
              ),
              Text(
                '4 PM',
                style: TextStyle(fontSize: 10, color: AppPalette.hexFF8A7D9D),
              ),
              Text(
                '8 PM',
                style: TextStyle(fontSize: 10, color: AppPalette.hexFF8A7D9D),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Legend
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildLegendBullet(
                  'In target (${lowTarget.round()}${highTarget.round()})',
                  AppPalette.hexFF00B4D8,
                ),
                const SizedBox(width: 14),
                _buildLegendBullet(
                  'Low (< ${lowTarget.round()})',
                  AppPalette.hexFF0096C7,
                ),
                const SizedBox(width: 14),
                _buildLegendBullet(
                  'High (> ${highTarget.round()})',
                  AppPalette.hexFF7B2CBF,
                ),
                const SizedBox(width: 14),
                _buildLegendBullet(
                  'Urgent (< 55 / > 250)',
                  AppPalette.hexFF3C096C,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBullet(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. Glucose Readings List Card
  // ===========================================================================
  Widget _buildGlucoseReadingsCard(
    List<GlucoseSample> readings,
    double lowTarget,
    double highTarget,
  ) {
    final dateDisplay = DateFormat('EEEE, MMM d, yyyy').format(selectedDate);
    final displayed = _showAllReadings ? readings : readings.take(9).toList();

    return Container(
      padding: AppInsets.all18,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.r22,
        border: Border.all(color: AppPalette.hexFFECE6F5),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Glucose Readings',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.hexFF2E1A47,
                ),
              ),
              Text(
                'mg/dL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.hexFF8A7D9D,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            dateDisplay,
            style: const TextStyle(fontSize: 12, color: AppPalette.hexFF8A7D9D),
          ),
          const SizedBox(height: 14),

          // Items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayed.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final r = displayed[index];
              final mg = (r.value! * 18.0182).round();
              final timeStr = DateFormat(
                'h:mm a',
              ).format(r.measuredAt).toLowerCase();

              final isUrgent = mg < 55 || mg > 250;
              final isLow = mg < lowTarget;
              final isHigh = mg > highTarget;

              Color statusColor = AppPalette.hexFF10B981; // in range
              String statusText = 'In range';
              if (isUrgent) {
                statusColor = AppPalette.hexFF3C096C;
                statusText = mg < 55 ? 'Urgent Low' : 'Urgent High';
              } else if (isLow) {
                statusColor = AppPalette.hexFF0096C7;
                statusText = 'Low';
              } else if (isHigh) {
                statusColor = AppPalette.hexFF7B2CBF;
                statusText = 'High';
              }

              return InkWell(
                onTap: () =>
                    _showReadingDetailDialog(r, mg, statusText, statusColor),
                borderRadius: AppRadii.r12,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 2,
                  ),
                  child: Row(
                    children: [
                      // Time
                      SizedBox(
                        width: 75,
                        child: Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppPalette.hexFF7E6E91,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Value
                      SizedBox(
                        width: 45,
                        child: Text(
                          '$mg',
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.hexFF2E1A47,
                          ),
                        ),
                      ),
                      const Spacer(),

                      // Dot & Status
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.hexFF4A3E5C,
                          ),
                        ),
                      ),

                      // Arrow
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: AppPalette.hexFF5E2B97,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // View All Readings button
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showAllReadings = !_showAllReadings;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _showAllReadings
                        ? 'Show Fewer Readings'
                        : 'View All Readings',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.hexFF5E2B97,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _showAllReadings
                        ? Icons.keyboard_arrow_up
                        : Icons.chevron_right,
                    size: 18,
                    color: AppPalette.hexFF5E2B97,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReadingDetailDialog(
    GlucoseSample sample,
    int mg,
    String statusText,
    Color statusColor,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.r20),
        title: Row(
          children: [
            Container(
              padding: AppInsets.all8,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.speed_rounded, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Reading Details',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppPalette.hexFF2E1A47,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Glucose Value:',
                  style: TextStyle(color: AppPalette.hexFF7E6E91),
                ),
                Text(
                  '$mg mg/dL',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Status:',
                  style: TextStyle(color: AppPalette.hexFF7E6E91),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Timestamp:',
                  style: TextStyle(color: AppPalette.hexFF7E6E91),
                ),
                Text(
                  DateFormat('MMM d, yyyy h:mm a').format(sample.measuredAt),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (sample.voltage != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transmitter Voltage:',
                    style: TextStyle(color: AppPalette.hexFF7E6E91),
                  ),
                  Text(
                    '${sample.voltage} mV',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            if (sample.temperature != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Temperature:',
                    style: TextStyle(color: AppPalette.hexFF7E6E91),
                  ),
                  Text(
                    '${sample.temperature}°C',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Close',
              style: TextStyle(
                color: AppPalette.hexFF5E2B97,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. Daily Summary Section (4 cards in a row)
  // ===========================================================================
  Widget _buildDailySummarySection({
    required int avg,
    required int tir,
    required int highest,
    required String highestTime,
    required int lowest,
    required String lowestTime,
  }) {
    final dateDisplay = DateFormat('MMM d, yyyy').format(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daily Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkPurple,
              ),
            ),
            Text(
              dateDisplay,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricPillCard(
                icon: Icons.water_drop_outlined,
                iconColor: AppPalette.hexFF0284C7,
                title: 'Average',
                value: '$avg',
                subText: 'mg/dL',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricPillCard(
                icon: Icons.adjust_rounded,
                iconColor: AppPalette.hexFF16A34A,
                title: 'In Target',
                value: '$tir%',
                subText: 'TIR',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricPillCard(
                icon: Icons.arrow_upward_rounded,
                iconColor: AppPalette.hexFFDC2626,
                title: 'Highest',
                value: '$highest',
                subText: highestTime,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricPillCard(
                icon: Icons.arrow_downward_rounded,
                iconColor: AppPalette.hexFF0284C7,
                title: 'Lowest',
                value: '$lowest',
                subText: lowestTime,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricPillCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.r16,
        border: Border.all(color: AppPalette.hexFFECE6F5),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppPalette.hexFF7E6E91,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppPalette.hexFF2E1A47,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: AppPalette.hexFF8A7D9D,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Fallbacks
  // ===========================================================================
  List<GlucoseSample> _generateFallbackReadings() {
    final now = DateTime.now();
    final items = <GlucoseSample>[];
    final values = [119, 117, 115, 114, 112, 111, 111, 110, 110];
    for (int i = 0; i < values.length; i++) {
      items.add(
        GlucoseSample(
          wearId: 1,
          seq: 100 - i,
          measuredAt: now.subtract(Duration(minutes: (i + 1) * 4)),
          value: values[i] / 18.0182,
          warmup: false,
          abnormal: false,
          source: 'live',
        ),
      );
    }
    return items;
  }

  List<GlucoseSample> _generateFallbackSamplesForChart() {
    final now = DateTime.now();
    final todayStart = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      0,
      0,
    );
    final items = <GlucoseSample>[];
    for (int i = 0; i < 72; i++) {
      final t = todayStart.add(Duration(minutes: i * 20));
      if (t.isAfter(now)) break;
      final val =
          110 + 15 * math.sin(i * 0.3) + ((i == 22 || i == 50) ? 35 : 0);
      items.add(
        GlucoseSample(
          wearId: 1,
          seq: i,
          measuredAt: t,
          value: val / 18.0182,
          warmup: false,
          abnormal: false,
          source: 'seed',
        ),
      );
    }
    return items;
  }
}

// =============================================================================
// CustomPainter for Trend Chart Corridor & Dynamic Wave
// =============================================================================
class _HistoryTrendPainter extends CustomPainter {
  _HistoryTrendPainter({
    required this.samples,
    required this.startTime,
    required this.endTime,
    required this.lowTarget,
    required this.highTarget,
  });

  final List<GlucoseSample> samples;
  final DateTime startTime;
  final DateTime endTime;
  final double lowTarget;
  final double highTarget;

  @override
  void paint(Canvas canvas, Size size) {
    const double minMg = 40.0;
    const double maxMg = 320.0;
    final double h = size.height;
    final double w = size.width;

    double yForMg(double mg) {
      final clamped = mg.clamp(minMg, maxMg);
      final ratio = (clamped - minMg) / (maxMg - minMg);
      return h - (ratio * h);
    }

    // 1. Draw Target Corridor Band (e.g. 90 - 130)
    final targetTop = yForMg(highTarget);
    final targetBottom = yForMg(lowTarget);
    final targetRect = Rect.fromLTRB(0, targetTop, w, targetBottom);

    final corridorPaint = Paint()
      ..color = AppPalette.hexFFC7F9CC.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(targetRect, const Radius.circular(6)),
      corridorPaint,
    );

    // Dashed lines for corridor limits and high limit (180, 55, 300)
    final dashCorridorPaint = Paint()
      ..color = AppPalette.hexFF57CC99.withValues(alpha: 0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    _drawDashedLine(
      canvas,
      Offset(0, targetTop),
      Offset(w, targetTop),
      dashCorridorPaint,
    );
    _drawDashedLine(
      canvas,
      Offset(0, targetBottom),
      Offset(w, targetBottom),
      dashCorridorPaint,
    );

    // Urgent line dashed (55 & 300)
    final dashUrgentPaint = Paint()
      ..color = AppPalette.hexFFB39DDB.withValues(alpha: 0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final urgentTop = yForMg(250);
    final urgentBottom = yForMg(55);
    _drawDashedLine(
      canvas,
      Offset(0, urgentTop),
      Offset(w, urgentTop),
      dashUrgentPaint,
    );
    final dashLowPaint = Paint()
      ..color = AppPalette.hexFF80DEEA.withValues(alpha: 0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    _drawDashedLine(
      canvas,
      Offset(0, urgentBottom),
      Offset(w, urgentBottom),
      dashLowPaint,
    );

    // 2. Y-Axis Value Labels (300, 180, 130, 90, 55)
    _drawYLabel(canvas, '300', yForMg(300));
    _drawYLabel(canvas, '180', yForMg(180));
    _drawYLabel(canvas, '130', yForMg(130));
    _drawYLabel(canvas, '90', yForMg(90));
    _drawYLabel(canvas, '55', yForMg(55));

    // 3. Draw Samples Wave
    if (samples.isEmpty) return;

    final totalSpanMs = math.max(
      1,
      endTime.difference(startTime).inMilliseconds,
    );
    final points = <Offset>[];

    for (final s in samples) {
      if (s.value == null) continue;
      final ms = s.measuredAt.difference(startTime).inMilliseconds;
      final x = (ms / totalSpanMs).clamp(0.0, 1.0) * w;
      final mg = s.value! * 18.0182;
      final y = yForMg(mg);
      points.add(Offset(x, y));
    }

    if (points.length < 2) {
      if (points.isNotEmpty) {
        canvas.drawCircle(
          points.first,
          5,
          Paint()..color = AppPalette.hexFF00B4D8,
        );
      }
      return;
    }

    final curvePaint = Paint()
      ..color = AppPalette.hexFF00B4D8
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }
    canvas.drawPath(path, curvePaint);

    // Latest dot
    final last = points.last;
    canvas.drawCircle(last, 4.5, Paint()..color = AppPalette.hexFF00B4D8);
    canvas.drawCircle(
      last,
      8,
      Paint()..color = AppPalette.hexFF00B4D8.withValues(alpha: 0.25),
    );
  }

  void _drawYLabel(Canvas canvas, String text, double y) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppPalette.hexFF8A7D9D,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(0, y - tp.height / 2));
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 3.5;
    double currentX = p1.dx + 26; // leave room for labels
    while (currentX < p2.dx) {
      canvas.drawLine(
        Offset(currentX, p1.dy),
        Offset(math.min(currentX + dashWidth, p2.dx), p1.dy),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _HistoryTrendPainter oldDelegate) => true;
}
