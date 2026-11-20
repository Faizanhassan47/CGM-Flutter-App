import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cgm_sdk/cgm_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../core/ui_perf.dart';
import '../../state/app_controller.dart';
import '../../widgets/page_top_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.controller,
    this.isActive = true,
    this.activeTabListenable,
    this.tabIndex = 1,
  });
  final AppController controller;
  final bool isActive;
  final ValueListenable<int>? activeTabListenable;
  final int tabIndex;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime selectedDate = DateTime.now();
  String selectedFilter = 'Today'; // 'Today', '7D', '14D', '30D', '300D'
  late DateTime _weekStartMonday;
  bool _showAllReadings = false;
  Timer? _telemetryDebounce;

  List<GlucoseSample> _serverSamples = [];
  Map<String, dynamic>? _serverSummary;
  bool _loading = false;
  bool _loadingMore = false;
  int _page = 1;
  bool _hasMore = false;
  String? _loadError;

  static const _pageSize = 80;
  final GlobalKey<_ZoomableTrendChartState> _trendChartKey =
      GlobalKey<_ZoomableTrendChartState>();

  @override
  void initState() {
    super.initState();
    _initWeekForDate(DateTime.now());
    // Live SDK ticks only matter for "Today"; longer ranges stay on server pages.
    widget.controller.telemetryRevision.addListener(_onTelemetry);
    unawaited(_loadFromServer());
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.telemetryRevision.removeListener(_onTelemetry);
      widget.controller.telemetryRevision.addListener(_onTelemetry);
    }
  }

  @override
  void dispose() {
    widget.controller.telemetryRevision.removeListener(_onTelemetry);
    _telemetryDebounce?.cancel();
    super.dispose();
  }

  bool get _tabActive {
    final listenable = widget.activeTabListenable;
    if (listenable == null) return widget.isActive;
    return listenable.value == widget.tabIndex;
  }

  void _onTelemetry() {
    if (!_tabActive || selectedFilter != 'Today') return;
    _telemetryDebounce?.cancel();
    _telemetryDebounce = Timer(const Duration(milliseconds: 1800), () {
      if (mounted && _tabActive) setState(() {});
    });
  }

  (DateTime, DateTime) _rangeForFilter() {
    final now = DateTime.now();
    if (selectedFilter == 'Today') {
      final start = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      final end = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        23,
        59,
        59,
        999,
      );
      return (start, end);
    }
    int days = 7;
    if (selectedFilter == '14D') days = 14;
    if (selectedFilter == '30D') days = 30;
    if (selectedFilter == '300D') days = 300;
    return (now.subtract(Duration(days: days)), now);
  }

  Future<void> _loadFromServer({bool append = false}) async {
    if (append) {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _loadError = null;
        _page = 1;
        _hasMore = false;
      });
    }

    final range = _rangeForFilter();
    final page = append ? _page + 1 : 1;
    try {
      final historyPage = await widget.controller.fetchGlucoseHistoryPage(
        startUtc: range.$1,
        endUtc: range.$2,
        page: page,
        pageSize: _pageSize,
      );
      final rawItems = historyPage['items'];
      final mapped = <GlucoseSample>[];
      if (rawItems is List) {
        for (final row in rawItems) {
          if (row is! Map) continue;
          final sample = AppController.sampleFromServerRow(
            Map<String, dynamic>.from(row),
          );
          if (sample != null) mapped.add(sample);
        }
      }

      Map<String, dynamic>? summary = _serverSummary;
      if (!append) {
        try {
          summary = await widget.controller.fetchGlucoseSummary(
            startUtc: range.$1,
            endUtc: range.$2,
          );
        } catch (_) {
          summary = null;
        }
      }

      if (!mounted) return;
      setState(() {
        if (append) {
          // Server returns newest-first; keep that order when appending pages.
          final existing = {
            for (final s in _serverSamples)
              '${s.wearId}:${s.seq}:${s.measuredAt.millisecondsSinceEpoch}',
          };
          for (final s in mapped) {
            final key =
                '${s.wearId}:${s.seq}:${s.measuredAt.millisecondsSinceEpoch}';
            if (existing.add(key)) _serverSamples.add(s);
          }
        } else {
          _serverSamples = mapped;
        }
        _serverSummary = summary;
        _page = page;
        _hasMore = historyPage['hasMore'] == true;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _loadError = 'Could not load history. Pull to refresh.';
      });
    }
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
      selectedFilter = 'Today';
      _showAllReadings = false;
    });
    _trendChartKey.currentState?.reset(animate: false);
    unawaited(_loadFromServer());
  }

  void _onNextWeek() {
    setState(() {
      _weekStartMonday = _weekStartMonday.add(const Duration(days: 7));
      selectedDate = _weekStartMonday;
      selectedFilter = 'Today';
      _showAllReadings = false;
    });
    _trendChartKey.currentState?.reset(animate: false);
    unawaited(_loadFromServer());
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
        selectedFilter = 'Today';
        _initWeekForDate(picked);
        _showAllReadings = false;
      });
      _trendChartKey.currentState?.reset(animate: false);
      unawaited(_loadFromServer());
    }
  }

  // ignore: unused_element
  void _onSelectFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      if (filter == 'Today') {
        selectedDate = DateTime.now();
        _initWeekForDate(selectedDate);
      }
    });
    _trendChartKey.currentState?.reset(animate: false);
    unawaited(_loadFromServer());
  }

  @override
  Widget build(BuildContext context) {
    final lowTarget = widget.controller.targetLow.toDouble();
    final highTarget = widget.controller.targetHigh.toDouble();
    final range = _rangeForFilter();
    final rangeStart = range.$1;
    final rangeEnd = range.$2;

    // Server page (newest-first) + optional unsynced local points for Today.
    final samplesNewestFirst = List<GlucoseSample>.from(_serverSamples);
    if (selectedFilter == 'Today') {
      final keys = {
        for (final s in samplesNewestFirst)
          '${s.wearId}:${s.seq}:${s.measuredAt.millisecondsSinceEpoch}',
      };
      for (var i = widget.controller.history.length - 1; i >= 0; i--) {
        final s = widget.controller.history[i];
        if (s.value == null) continue;
        if (s.measuredAt.isBefore(rangeStart) ||
            s.measuredAt.isAfter(rangeEnd)) {
          continue;
        }
        final key =
            '${s.wearId}:${s.seq}:${s.measuredAt.millisecondsSinceEpoch}';
        if (keys.add(key)) samplesNewestFirst.insert(0, s);
      }
    }

    // Server pages and the live SDK buffer can arrive in different orders.
    // Normalize the merged collection before building the list and chart.
    samplesNewestFirst.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));

    // Chronological for the chart painter.
    final samplesForView = samplesNewestFirst.reversed.toList();
    final hasRealData = samplesForView.isNotEmpty;
    final readings = _showAllReadings
        ? samplesNewestFirst
        : samplesNewestFirst.take(9).toList();
    // Keep denser points so pinch-zoom stays smooth and detailed.
    final chartSamples = hasRealData
        ? UiPerf.downsample(
            samplesForView,
            maxPoints: UiPerf.isLowEndLayout(context) ? 160 : 360,
          )
        : const <GlucoseSample>[];

    final summary = _serverSummary;
    final avg = summary?['averageGlucose'] is num
        ? (summary!['averageGlucose'] as num).round()
        : (hasRealData
              ? (samplesForView
                            .map((r) => (r.value! * 18.0182).round())
                            .reduce((a, b) => a + b) /
                        samplesForView.length)
                    .round()
              : 119);
    final highest = summary?['highestGlucose'] is num
        ? (summary!['highestGlucose'] as num).round()
        : (hasRealData
              ? samplesForView
                    .map((r) => (r.value! * 18.0182).round())
                    .reduce((a, b) => a > b ? a : b)
              : 110);
    final lowest = summary?['lowestGlucose'] is num
        ? (summary!['lowestGlucose'] as num).round()
        : (hasRealData
              ? samplesForView
                    .map((r) => (r.value! * 18.0182).round())
                    .reduce((a, b) => a < b ? a : b)
              : 100);
    final tir = summary?['timeInRangePercentage'] is num
        ? (summary!['timeInRangePercentage'] as num).round()
        : (hasRealData
              ? ((samplesForView.where((r) {
                              final mg = (r.value! * 18.0182);
                              return mg >= lowTarget && mg <= highTarget;
                            }).length /
                            samplesForView.length) *
                        100)
                    .round()
              : 0);

    DateTime? highAt;
    DateTime? lowAt;
    for (final r in samplesForView) {
      if (r.value == null) continue;
      final mg = (r.value! * 18.0182).round();
      if (mg == highest) highAt = r.measuredAt;
      if (mg == lowest) lowAt = r.measuredAt;
    }
    final highestTimeStr = highAt == null
        ? '--'
        : DateFormat('h:mm a').format(highAt).toLowerCase();
    final lowestTimeStr = lowAt == null
        ? '--'
        : DateFormat('h:mm a').format(lowAt).toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryPurple,
          onRefresh: () async {
            await widget.controller.refreshHistory();
            await _loadFromServer();
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            children: [
              _buildTopHeader(),
              const SizedBox(height: 18),
              _buildWeekSelectorStrip(),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                )
              else ...[
                if (_loadError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _loadError!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                _buildGlucoseTrendCard(
                  samples: chartSamples,
                  lowTarget: lowTarget,
                  highTarget: highTarget,
                  startTime: rangeStart,
                  endTime: rangeEnd,
                ),
                const SizedBox(height: 20),
                _buildGlucoseReadingsCard(
                  readings,
                  lowTarget,
                  highTarget,
                  hasRealData: hasRealData,
                ),
                if (_hasMore) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: _loadingMore
                          ? null
                          : () => unawaited(_loadFromServer(append: true)),
                      child: _loadingMore
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Load more readings'),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (hasRealData || (summary?['hasData'] == true))
                  _buildDailySummarySection(
                    avg: avg,
                    tir: tir,
                    highest: highest,
                    highestTime: highestTimeStr,
                    lowest: lowest,
                    lowestTime: lowestTimeStr,
                  ),
              ],
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
    return PageTopBar(
      title: 'History',
      subtitle: 'View your glucose data and past readings.',
      trailing: PageTopAction(
        tooltip: 'Calendar',
        icon: Icons.calendar_month_outlined,
        onPressed: _openCalendarPicker,
      ),
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
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.primary,
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
                        _showAllReadings = false;
                      });
                      _trendChartKey.currentState?.reset(animate: false);
                      unawaited(_loadFromServer());
                    },
                    borderRadius: AppRadii.r16,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(18),
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
                                  ? Colors.white70
                                  : AppColors.textSecondary,
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
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.surface
                                  : AppColors.primary,
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
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ),
      ],
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
        border: Border.all(color: AppColors.surfaceBorder),
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
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Glucose Trend',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.hexFF2E1A47,
                  ),
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
            'Pinch to zoom · drag to pan · double-tap to reset',
            style: TextStyle(fontSize: 12, color: AppPalette.hexFF8A7D9D),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 188,
            child: samples.length < 2
                ? const Center(
                    child: Text(
                      'No readings for this period',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : _ZoomableTrendChart(
                    key: _trendChartKey,
                    samples: samples,
                    fullStart: startTime,
                    fullEnd: endTime,
                    lowTarget: lowTarget,
                    highTarget: highTarget,
                  ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
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
    double highTarget, {
    required bool hasRealData,
  }) {
    final dateDisplay = DateFormat('EEEE, MMM d, yyyy').format(selectedDate);
    final displayed = _showAllReadings ? readings : readings.take(9).toList();

    return Container(
      padding: AppInsets.all18,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.r22,
        border: Border.all(color: AppColors.surfaceBorder),
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

          // Items or Empty State
          if (!hasRealData || readings.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      size: 36,
                      color: AppPalette.hexFF7E6E91,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No stored readings for this date',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.hexFF7E6E91,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
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
            if (_showAllReadings || _hasMore || _serverSamples.length > 9) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _loadingMore ? null : _toggleAllReadings,
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
          ],
        ],
      ),
    );
  }

  Future<void> _toggleAllReadings() async {
    if (_showAllReadings) {
      setState(() => _showAllReadings = false);
      return;
    }

    setState(() => _showAllReadings = true);
    while (mounted && _hasMore) {
      final previousPage = _page;
      await _loadFromServer(append: true);
      if (_page == previousPage) break;
    }
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
        border: Border.all(color: AppColors.surfaceBorder),
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
  // ignore: unused_element
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

  // ignore: unused_element
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
// Smooth pinch-zoom / pan glucose trend
// =============================================================================
class _ZoomableTrendChart extends StatefulWidget {
  const _ZoomableTrendChart({
    super.key,
    required this.samples,
    required this.fullStart,
    required this.fullEnd,
    required this.lowTarget,
    required this.highTarget,
  });

  final List<GlucoseSample> samples;
  final DateTime fullStart;
  final DateTime fullEnd;
  final double lowTarget;
  final double highTarget;

  @override
  State<_ZoomableTrendChart> createState() => _ZoomableTrendChartState();
}

class _ZoomableTrendChartState extends State<_ZoomableTrendChart>
    with SingleTickerProviderStateMixin {
  static const _minScale = 1.0;
  static const _maxScale = 20.0;

  /// scale, focus (0–1)
  final ValueNotifier<Offset> _view = ValueNotifier(const Offset(1, 0.5));

  double _gestureBaseScale = 1.0;
  double _gestureBaseFocus = 0.5;
  double _gestureAccumPanPx = 0.0;
  double _gestureStartFocalFrac = 0.5;
  bool _zoomedChrome = false;

  late final AnimationController _resetCtrl;
  Animation<Offset>? _resetAnim;

  @override
  void initState() {
    super.initState();
    _resetCtrl =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 280),
        )..addListener(() {
          final anim = _resetAnim;
          if (anim != null) _view.value = anim.value;
        });
  }

  @override
  void didUpdateWidget(covariant _ZoomableTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fullStart != widget.fullStart ||
        oldWidget.fullEnd != widget.fullEnd) {
      reset(animate: false);
    }
  }

  @override
  void dispose() {
    _resetCtrl.dispose();
    _view.dispose();
    super.dispose();
  }

  void reset({bool animate = true}) {
    _resetCtrl.stop();
    if (!animate || (_view.value.dx == 1.0 && _view.value.dy == 0.5)) {
      _view.value = const Offset(1, 0.5);
      if (_zoomedChrome) setState(() => _zoomedChrome = false);
      return;
    }
    _resetAnim = Tween<Offset>(
      begin: _view.value,
      end: const Offset(1, 0.5),
    ).animate(CurvedAnimation(parent: _resetCtrl, curve: Curves.easeOutCubic));
    _resetCtrl.forward(from: 0).whenComplete(() {
      if (mounted && _zoomedChrome) setState(() => _zoomedChrome = false);
    });
  }

  (DateTime, DateTime) _window(double scale, double focus) {
    final fullMs = math.max(
      1,
      widget.fullEnd.difference(widget.fullStart).inMilliseconds,
    );
    final visibleMs = math.max(1.0, fullMs / scale);
    var startMs = focus * fullMs - visibleMs / 2;
    startMs = startMs.clamp(0.0, fullMs - visibleMs);
    final viewStart = widget.fullStart.add(
      Duration(milliseconds: startMs.round()),
    );
    final viewEnd = viewStart.add(Duration(milliseconds: visibleMs.round()));
    return (viewStart, viewEnd);
  }

  void _onScaleStart(ScaleStartDetails details, double width) {
    _resetCtrl.stop();
    _gestureBaseScale = _view.value.dx;
    _gestureBaseFocus = _view.value.dy;
    _gestureAccumPanPx = 0.0;
    _gestureStartFocalFrac = (details.localFocalPoint.dx / width).clamp(
      0.0,
      1.0,
    );
  }

  void _onScaleUpdate(ScaleUpdateDetails details, double width) {
    if (width <= 0) return;
    final fullMs = math.max(
      1,
      widget.fullEnd.difference(widget.fullStart).inMilliseconds,
    );

    final nextScale = (_gestureBaseScale * details.scale).clamp(
      _minScale,
      _maxScale,
    );

    // Keep the time under the starting focal point stable while pinching.
    final visibleBefore = fullMs / _gestureBaseScale;
    var startBefore = _gestureBaseFocus * fullMs - visibleBefore / 2;
    startBefore = startBefore.clamp(0.0, fullMs - visibleBefore);
    final focalTimeMs = startBefore + _gestureStartFocalFrac * visibleBefore;

    final visibleAfter = fullMs / nextScale;
    var nextFocus =
        (focalTimeMs - (_gestureStartFocalFrac - 0.5) * visibleAfter) / fullMs;

    // Smooth pan: accumulate total drag since gesture start (not per-frame only).
    _gestureAccumPanPx += details.focalPointDelta.dx;
    if (nextScale > 1.01) {
      nextFocus -= (_gestureAccumPanPx / width) / nextScale;
    }

    // Keep viewport inside full range.
    final half = (1 / nextScale) / 2;
    nextFocus = nextFocus.clamp(half, 1.0 - half);

    _view.value = Offset(nextScale, nextFocus);

    final nowZoomed = nextScale > 1.04;
    if (nowZoomed != _zoomedChrome) {
      setState(() => _zoomedChrome = nowZoomed);
    }
  }

  List<String> _axisLabels(DateTime viewStart, DateTime viewEnd) {
    final span = viewEnd.difference(viewStart);
    final format = span.inHours <= 6
        ? DateFormat('h:mm a')
        : span.inHours <= 36
        ? DateFormat('h a')
        : DateFormat('MMM d');
    const ticks = 5;
    final ms = math.max(1, span.inMilliseconds);
    return List.generate(ticks, (i) {
      final t = viewStart.add(
        Duration(milliseconds: (ms * i / (ticks - 1)).round()),
      );
      return format.format(t);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_zoomedChrome)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Spacer(),
                GestureDetector(
                  onTap: () => reset(animate: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: AppRadii.r12,
                    ),
                    child: ValueListenableBuilder<Offset>(
                      valueListenable: _view,
                      builder: (_, v, __) => Text(
                        'Reset ${v.dx.toStringAsFixed(1)}x',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: () => reset(animate: true),
                onScaleStart: (d) => _onScaleStart(d, constraints.maxWidth),
                onScaleUpdate: (d) => _onScaleUpdate(d, constraints.maxWidth),
                child: ValueListenableBuilder<Offset>(
                  valueListenable: _view,
                  builder: (context, view, _) {
                    final window = _window(view.dx, view.dy);
                    final labels = _axisLabels(window.$1, window.$2);
                    return Column(
                      children: [
                        Expanded(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: _HistoryTrendPainter(
                                samples: widget.samples,
                                startTime: window.$1,
                                endTime: window.$2,
                                lowTarget: widget.lowTarget,
                                highTarget: widget.highTarget,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (final label in labels)
                              Flexible(
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppPalette.hexFF8A7D9D,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
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
      if (s.measuredAt.isBefore(startTime) || s.measuredAt.isAfter(endTime)) {
        continue;
      }
      final ms = s.measuredAt.difference(startTime).inMilliseconds;
      final x = (ms / totalSpanMs).clamp(0.0, 1.0) * w;
      final mg = s.value! * 18.0182;
      final y = yForMg(mg);
      points.add(Offset(x, y));
    }

    if (points.length < 2) {
      if (points.isNotEmpty) {
        canvas.drawCircle(points.first, 5, Paint()..color = AppColors.primary);
      }
      return;
    }

    final curvePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    // Dense zoomed views look smoother with straight segments; sparse
    // overview still uses soft mid-point curves.
    if (points.length >= 40) {
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    } else {
      for (var i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final midX = (p0.dx + p1.dx) / 2;
        path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
      }
    }
    canvas.drawPath(path, curvePaint);

    // Latest dot
    final last = points.last;
    canvas.drawCircle(last, 4.5, Paint()..color = AppColors.primary);
    canvas.drawCircle(
      last,
      8,
      Paint()..color = AppColors.primary.withValues(alpha: 0.25),
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
  bool shouldRepaint(covariant _HistoryTrendPainter oldDelegate) {
    return !identical(oldDelegate.samples, samples) ||
        oldDelegate.startTime != startTime ||
        oldDelegate.endTime != endTime ||
        oldDelegate.lowTarget != lowTarget ||
        oldDelegate.highTarget != highTarget;
  }
}
