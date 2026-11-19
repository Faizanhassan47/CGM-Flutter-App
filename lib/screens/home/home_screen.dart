import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cgm_sdk/cgm_sdk.dart';
import 'package:flutter/material.dart';
import '../alerts/alerts_screen.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../core/ui_perf.dart';
import '../../state/app_controller.dart';
import '../../widgets/app_animations.dart';
import '../../widgets/page_top_bar.dart';
import '../onboarding/device_setup_screen.dart';
import '../wellness/daily_activities_screen.dart';
import '../wellness/meal_reminders_screen.dart';
import '../wellness/water_reminders_screen.dart';
import '../wellness/wellness_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.onSwitchTab,
  });

  final AppController controller;
  final ValueChanged<int> onSwitchTab;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    // Reminder cards stay outside the glucose listener so API-backed widgets
    // are not rebuilt on every telemetry tick.
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppTheme.primaryPurple,
          onRefresh: () async {
            await controller.refreshHistory();
            await controller.loadReports();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final displayName = controller.fullName.trim().isNotEmpty
                      ? controller.fullName.trim().split(' ').first
                      : 'Visole';
                  return PageTopBar(
                    title: displayName,
                    subtitle: controller.wear == null
                        ? _greeting
                        : () {
                            final days = controller.wear!.expiresAt
                                .difference(DateTime.now())
                                .inDays;
                            final life = days > 0
                                ? '$days days left on this sensor'
                                : 'Replace this sensor';
                            return '$_greeting · $life';
                          }(),
                    trailing: PageTopAction(
                      tooltip: 'Alerts',
                      icon: Icons.notifications_none_rounded,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                AlertsScreen(controller: controller),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final isConnected =
                      controller.connection == CgmConnectionState.connected;
                  final sample = isConnected ? controller.latest : null;
                  final sampleVal = sample?.value;
                  final double? rawMg = sampleVal != null
                      ? (sampleVal > 30 ? sampleVal : sampleVal * 18.0182)
                      : null;
                  final int? mg = rawMg?.round();
                  final isMmol = controller.preferredGlucoseUnit
                      .toLowerCase()
                      .contains('mmol');
                  final unitStr = isMmol ? 'mmol/L' : 'mg/dL';
                  final displayGlucose = rawMg != null
                      ? (isMmol
                            ? (rawMg / 18.0182).toStringAsFixed(1)
                            : '${rawMg.round()}')
                      : '--';
                  final lowT = controller.targetLow;
                  final highT = controller.targetHigh;
                  final isUrgentLow = mg != null && mg < 55;
                  final inTarget = mg != null && mg >= lowT && mg <= highT;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _graceBanner(),
                      _readingCard(
                        context,
                        mg: mg,
                        displayGlucose: displayGlucose,
                        unitStr: unitStr,
                        isConnected: isConnected,
                        inTarget: inTarget,
                        isUrgentLow: isUrgentLow,
                        isHigh: mg != null && mg > highT,
                        scannedAt: sample?.measuredAt,
                      ),
                      const SizedBox(height: 14),
                      _todayChart(context, lowT, highT, isConnected, isMmol),
                      const SizedBox(height: 14),
                      _statGrid(isConnected, lowT, highT),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              _ReminderHomeCards(api: controller.api),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _graceBanner() {
    final wear = controller.wear;
    if (wear == null) return const SizedBox.shrink();
    final now = DateTime.now();
    if (!now.isAfter(wear.expiresAt)) return const SizedBox.shrink();
    final hoursOver = now.difference(wear.expiresAt).inHours;
    final graceHoursLeft = (12 - hoursOver).clamp(0, 12);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalette.hexFFFEF3C7,
        borderRadius: AppRadii.r16,
        border: Border.all(color: AppPalette.hexFFF59E0B),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppPalette.hexFFD97706,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sensor Grace Period Active',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: AppPalette.hexFF92400E,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '14-day lifespan reached. $graceHoursLeft hours grace remaining before replacement required.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppPalette.hexFFB45309,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _readingCard(
    BuildContext context, {
    required int? mg,
    required String displayGlucose,
    required String unitStr,
    required bool isConnected,
    required bool inTarget,
    required bool isUrgentLow,
    required bool isHigh,
    required DateTime? scannedAt,
  }) {
    GlucoseSample? lastSample = controller.latest;
    if (lastSample?.value == null) {
      for (var i = controller.history.length - 1; i >= 0; i--) {
        if (controller.history[i].value != null) {
          lastSample = controller.history[i];
          break;
        }
      }
    }
    final wear = controller.wear;
    final warming = isConnected && wear != null && DateTime.now().isBefore(wear.warmupEndAt);
    final warmupLeft = warming ? wear.warmupEndAt.difference(DateTime.now()).inMinutes.clamp(1, 999) : 0;
    final label = !isConnected
        ? 'No sensor'
        : warming
        ? 'Warming up'
        : mg == null
        ? 'Waiting'
        : isUrgentLow
        ? 'Urgent low'
        : isHigh
        ? 'Above range'
        : inTarget
        ? 'In range'
        : 'Below range';
    final chipColor = isUrgentLow || isHigh || (mg != null && !inTarget)
        ? AppColors.danger
        : AppColors.success;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your glucose', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.4)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: !isConnected
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DeviceSetupScreen(controller: controller)),
                  )
              : null,
          child: Text(
            !isConnected
                ? (lastSample == null
                    ? 'Device is not connected'
                    : 'Device is not connected · last reading ${DateFormat.jm().format(lastSample.measuredAt)}')
                : warming
                ? '$warmupLeft min left in warmup'
                : scannedAt == null
                ? 'No reading yet'
                : 'Scanned at ${DateFormat.jm().format(scannedAt)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: !isConnected ? AppColors.danger : AppColors.textSecondary, fontWeight: !isConnected ? FontWeight.w700 : FontWeight.w500),
          ),
        ),
        if (isConnected && mg != null) ...[
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: chipColor, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
        if (!isConnected && controller.wear == null) ...[
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DeviceSetupScreen(controller: controller)),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Connect sensor'),
          ),
        ],
      ],
    );
  }

  Widget _todayChart(BuildContext context, double lowT, double highT, bool isConnected, bool mmol) {
    return RepaintBoundary(
      child: _HomeChart(
        samples: controller.history,
        low: lowT,
        high: highT,
        mmol: mmol,
        connected: isConnected,
        api: controller.api,
        onConnect: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DeviceSetupScreen(controller: controller)),
        ),
      ),
    );
  }

  Widget _statGrid(bool isConnected, double lowT, double highT) {
    final cutoff = DateTime.now().subtract(const Duration(hours: 12));
    final values = <double>[];
    if (isConnected) {
      // History is sorted ascending — walk from the end and stop early.
      for (var i = controller.history.length - 1; i >= 0; i--) {
        final s = controller.history[i];
        if (!s.measuredAt.isAfter(cutoff)) break;
        if (s.value == null) continue;
        values.add(s.value! > 30 ? s.value! : s.value! * 18.0182);
      }
    }
    final avg = values.isEmpty ? null : (values.reduce((a, b) => a + b) / values.length).round();
    final tir = values.isEmpty
        ? null
        : (values.where((v) => v >= lowT && v <= highT).length / values.length * 100).round();
    final mv = controller.deviceStatus?.batteryMv;
    final battery = mv == null ? null : (((mv - 2600) / 400) * 100).clamp(0, 100).round();
    final wear = controller.wear;
    String life = '--';
    String lifeNote = '';
    var status = isConnected ? 'Ready' : 'Offline';
    var statusNote = battery == null ? '' : 'Battery $battery%';
    if (wear != null) {
      final days = wear.expiresAt.difference(DateTime.now()).inDays;
      life = days > 0 ? '${days}d' : '0d';
      lifeNote = 'until expiry';
      if (isConnected && DateTime.now().isBefore(wear.warmupEndAt)) {
        final mins = wear.warmupEndAt.difference(DateTime.now()).inMinutes.clamp(1, 999);
        status = 'Warming up';
        statusNote = '$mins min left';
      }
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _stat(Icons.medication_outlined, AppColors.primarySoft, AppColors.primary, 'Average', avg == null ? '--' : '$avg', 'mg/dL', false),
        _stat(Icons.restaurant_outlined, AppColors.primary, Colors.white, 'Time in range', tir == null ? '--' : '$tir%', 'last 12 hours', true),
        _stat(Icons.touch_app_outlined, AppColors.primarySoft, AppColors.primary, 'Sensor life', life, lifeNote, false),
        _stat(Icons.bolt, AppColors.primarySoft, AppColors.success, 'Status', status, statusNote, false),
      ],
    );
  }

  Widget _stat(IconData icon, Color bg, Color fg, String title, String value, String note, bool filled) {
    final titleColor = filled ? Colors.white70 : AppColors.textSecondary;
    final valueColor = filled ? Colors.white : AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: TextStyle(fontSize: 13, color: titleColor, fontWeight: FontWeight.w600))),
              Icon(icon, size: 18, color: fg),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: value.length > 6 ? 18 : 26, fontWeight: FontWeight.w800, color: valueColor, height: 1),
          ),
          if (note.isNotEmpty)
            Text(note, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: titleColor)),
        ],
      ),
    );
  }

  Widget _buildSensorStatusCard(BuildContext context, bool isConnected) {
    return InkWell(
      borderRadius: AppRadii.r20,
      onTap: () {
        if (!isConnected) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DeviceSetupScreen(controller: controller),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'CGM Sensor is connected and streaming telemetry normally.',
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.r20,
          border: Border.all(color: AppPalette.hexFFEFEBF6, width: 1.2),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (isConnected)
                  const SubtlePulseIndicator(
                    color: AppTheme.successGreen,
                    size: 26,
                  ),
                Icon(
                  isConnected
                      ? Icons.sensors_rounded
                      : Icons.sensors_off_rounded,
                  color: isConnected
                      ? AppTheme.successGreen
                      : AppTheme.primaryPurple,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sensor status',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isConnected ? 'Connected' : 'Reconnecting...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isConnected
                          ? AppTheme.successGreen
                          : AppTheme.darkPurple,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectCgmBanner(BuildContext context) {
    return Container(
      padding: AppInsets.all18,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalette.hexFF512DA8, AppPalette.hexFF673AB7],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadii.r22,
      ),
      child: Row(
        children: [
          Container(
            padding: AppInsets.all10,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.18),
              borderRadius: AppRadii.r14,
            ),
            child: const Icon(Icons.wifi, color: AppColors.surface, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Connect a CGM sensor',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'See live glucose data on your dashboard',
                  style: TextStyle(color: AppColors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppTheme.primaryPurple,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: AppRadii.r20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(80, 36),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DeviceSetupScreen(controller: controller),
                ),
              );
            },
            child: const Text(
              'Connect',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCyanCard(
    BuildContext context,
    int? mg,
    String statusText,
    double lowT,
    double highT, {
    required bool isConnected,
    String unitStr = 'mg/dL',
    String displayGlucose = '--',
    String targetStr = '90-130',
    bool isUrgentLow = false,
    bool isHigh = false,
  }) {
    if (!isConnected) {
      return Container(
        padding: AppInsets.all22,
        decoration: BoxDecoration(
          color: AppPalette.hexFF00B2E2,
          borderRadius: AppRadii.r26,
          boxShadow: [
            BoxShadow(
              color: AppPalette.hexFF00B2E2.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Glucose Telemetry',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.22),
                    borderRadius: AppRadii.r12,
                  ),
                  child: const Text(
                    'OFFLINE',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Icon(
              Icons.sensors_off_rounded,
              color: AppColors.surface,
              size: 38,
            ),
            const SizedBox(height: 12),
            const Text(
              'Connect your CGM sensor to view live glucose telemetry.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.surface,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DeviceSetupScreen(controller: controller),
                  ),
                );
              },
              icon: const Icon(Icons.add_link_rounded, size: 18),
              label: const Text('Connect sensor'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.white70),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Range bar dot calculation (40 - 300)
    final double? clamped = mg?.clamp(40, 300).toDouble();
    final double? ratio = clamped != null ? (clamped - 40) / (300 - 40) : null;

    // Color logic:
    // When reading goes high (> targetHigh) -> changes color to purple (AppTheme.primaryPurple / #5E2B97)
    // When normal (in target) -> cyan/blue (#00B2E2)
    // When urgent low -> red (#DC2626)
    final Color cardBgColor = isUrgentLow
        ? AppPalette.hexFFDC2626
        : (isHigh ? AppPalette.hexFF5E2B97 : AppPalette.hexFF00B2E2);

    return Container(
      padding: AppInsets.all22,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: AppRadii.r26,
        boxShadow: [
          BoxShadow(
            color: cardBgColor.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Glucose Telemetry',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LIVE / OFFLINE Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.22),
                      borderRadius: AppRadii.r12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isConnected
                                ? AppPalette.hexFF4ADE80
                                : AppColors.white70,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isConnected ? 'LIVE' : 'CACHED',
                          style: const TextStyle(
                            color: AppColors.surface,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Trend Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.22),
                      borderRadius: AppRadii.r12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isHigh ? 'High ' : (isUrgentLow ? 'Low ' : 'Stable '),
                          style: const TextStyle(
                            color: AppColors.surface,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Glucose Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                displayGlucose,
                style: const TextStyle(
                  color: AppColors.surface,
                  fontSize: 66,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unitStr,
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Target: $targetStr',
                    style: const TextStyle(
                      color: AppColors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => onSwitchTab(1), // go to history
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.surface,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // In target tag banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.25),
              borderRadius: AppRadii.r16,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.remove_red_eye_outlined,
                  color: AppColors.surface,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    statusText,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Range slider bar: 40 ... Target Range (90-130 mg/dL) ... 300
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 5,
                    width: barWidth,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.3),
                      borderRadius: AppRadii.r3,
                    ),
                  ),
                  // Target corridor highlight segment
                  Positioned(
                    left: barWidth * ((90 - 40) / (300 - 40)),
                    width: barWidth * ((130 - 90) / (300 - 40)),
                    child: Container(
                      height: 5,
                      color: AppColors.surface.withValues(alpha: 0.8),
                    ),
                  ),
                  // Current reading dot
                  if (ratio != null)
                    Positioned(
                      left: (ratio * barWidth - 6).clamp(0.0, barWidth - 12),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // Bottom line: "Updated just now", "View History >"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: AppColors.white70,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Updated just now',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => onSwitchTab(1),
                child: const Text(
                  'View History >',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayAtAGlance(bool isConnected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Today at a glance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkPurple,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your current sensor summary',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppPalette.hexFFDCFCE7,
                borderRadius: AppRadii.r12,
              ),
              child: const Text(
                '100%',
                style: TextStyle(
                  color: AppPalette.hexFF15803D,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Builder(
          builder: (context) {
            final wear = controller.wear;
            String lifeText = '14 days left';
            if (wear != null) {
              final now = DateTime.now();
              if (now.isBefore(wear.warmupEndAt)) {
                final mins = wear.warmupEndAt.difference(now).inMinutes;
                lifeText = 'Warmup: ${mins}m';
              } else {
                final daysLeft = wear.expiresAt.difference(now).inDays;
                lifeText = daysLeft > 0
                    ? '$daysLeft days left'
                    : 'Expires today';
              }
            }
            return Row(
              children: [
                Expanded(
                  child: _buildMetricMiniCard(
                    icon: Icons.memory_rounded,
                    iconColor: AppPalette.hexFF00B2E2,
                    iconBg: AppPalette.hexFFE0F7FD,
                    title: 'Sensor',
                    subtitle: isConnected
                        ? 'Connected'
                        : (wear != null ? 'Reconnecting' : 'Standby'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricMiniCard(
                    icon: Icons.access_time_filled_rounded,
                    iconColor: AppTheme.primaryPurple,
                    iconBg: AppTheme.lightPurpleBg,
                    title: 'Life left',
                    subtitle: lifeText,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricMiniCard(
                    icon: Icons.sync_rounded,
                    iconColor: AppPalette.hexFF10B981,
                    iconBg: AppPalette.hexFFD1FAE5,
                    title: 'Last sync',
                    subtitle: DateFormat.jm().format(DateTime.now()),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricMiniCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.r18,
        border: Border.all(color: AppPalette.hexFFEFEBF6, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: AppInsets.all7,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: AppRadii.r10,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietAssistantCard(
    int? currentMg,
    double lowTarget,
    double highTarget,
    List<dynamic> historySamples,
  ) {
    final now = DateTime.now();
    final twelveHoursAgo = now.subtract(const Duration(hours: 12));

    // Filter samples within the last 12 hours
    final recentSamples = historySamples.where((s) {
      if (s.value == null || s.warmup == true || s.abnormal == true) {
        return false;
      }
      return s.measuredAt.isAfter(twelveHoursAgo) &&
          s.measuredAt.isBefore(now.add(const Duration(minutes: 5)));
    }).toList();

    int? avg12h;
    int tir12h = 0;
    int lowCount12h = 0;
    int highCount12h = 0;
    double? trendDiff12h;

    if (recentSamples.isNotEmpty) {
      final values = recentSamples
          .map<double>((s) => s.value! * 18.0182)
          .toList();
      final sum = values.reduce((a, b) => a + b);
      avg12h = (sum / values.length).round();

      final inTargetCount = values
          .where((v) => v >= lowTarget && v <= highTarget)
          .length;
      tir12h = ((inTargetCount / values.length) * 100).round();

      lowCount12h = values.where((v) => v < lowTarget).length;
      highCount12h = values.where((v) => v > highTarget).length;

      if (values.length >= 2) {
        trendDiff12h = values.last - values.first;
      }
    }

    final effectiveMg = currentMg ?? avg12h;

    if (effectiveMg == null) {
      return Container(
        padding: AppInsets.all18,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.r22,
          border: Border.all(color: AppPalette.hexFFEFEBF6, width: 1.2),
        ),
        child: Row(
          children: const [
            Icon(
              Icons.info_outline_rounded,
              color: AppTheme.textMuted,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Connect sensor to view personalized diet recommendations based on your 12-hour report.',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final String title;
    final String advice;
    final List<String> foods;
    final Color badgeColor;
    final IconData icon;

    // Decision based on 12-hour report context and current status
    if (effectiveMg < 55) {
      title = 'Urgent Hypoglycemia â€¢ Fast-Acting Carbs';
      advice =
          'Your glucose dropped critically. Take 15g of fast-acting carbohydrates immediately and re-test in 15 minutes (Rule of 15).';
      foods = [
        '1/2 cup fruit juice',
        '3-4 glucose tablets',
        '1 tbsp honey / syrup',
        '1/2 can regular soda',
      ];
      badgeColor = AppPalette.hexFFEF4444;
      icon = Icons.warning_amber_rounded;
    } else if (effectiveMg < lowTarget || lowCount12h >= 3) {
      title = 'Below Target â€¢ Hypo Stabilization';
      advice =
          'Your 12-hour history reflects dips below ${lowTarget.round()} mg/dL. Prioritize complex carbs paired with healthy fats and protein to prevent hypoglycemia.';
      foods = [
        'Apple slices with peanut butter',
        'Whole grain toast with avocado',
        'Greek yogurt with walnuts',
        'Handful of mixed nuts & dried fruit',
      ];
      badgeColor = AppPalette.hexFFF97316;
      icon = Icons.cookie_outlined;
    } else if (effectiveMg > 220 || highCount12h >= 8) {
      title = 'High Glucose Load â€¢ Hydration & Low GI';
      advice =
          'Over the last 12 hours, readings trended above ${highTarget.round()} mg/dL ($highCount12h times). Avoid refined sugars and simple carbs; hydrate generously.';
      foods = [
        'Pure mineral water (16-20 oz)',
        'Steamed broccoli & grilled salmon',
        'Leafy greens with olive oil',
        'Celery sticks & unsalted almonds',
      ];
      badgeColor = AppPalette.hexFF8B5CF6;
      icon = Icons.water_drop_outlined;
    } else if (effectiveMg > highTarget) {
      title = 'Elevated Glucose â€¢ Fiber & Lean Protein';
      advice =
          'Recent levels are slightly above target. Choose high-fiber foods to slow absorption and take a light 15-minute walk.';
      foods = [
        'Spinach & kale salad',
        'Grilled chicken or tofu bowl',
        'Chia seed pudding (unsweetened)',
        'Cucumber slices with hummus',
      ];
      badgeColor = AppPalette.hexFF8B5CF6;
      icon = Icons.eco_rounded;
    } else {
      title = 'Optimal Glycemic Control â€¢ Balanced Diet';
      advice =
          'Excellent stability over the past 12 hours ($tir12h% Time in Range). Maintain your metabolic state with whole grains, lean proteins, and unsaturated fats.';
      foods = [
        'Quinoa bowl with avocado & chicken',
        'Steel-cut oats with flaxseeds',
        'Steamed asparagus & tofu',
        'Raw blueberries with cottage cheese',
      ];
      badgeColor = AppPalette.hexFF10B981;
      icon = Icons.restaurant_rounded;
    }

    return Container(
      padding: AppInsets.all18,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.r22,
        border: Border.all(color: AppPalette.hexFFEFEBF6, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: AppInsets.all6,
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      color: badgeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Diet Assistant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkPurple,
                        ),
                      ),
                      Text(
                        'Based on last 12 hours report',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: AppRadii.r12,
                ),
                child: Text(
                  currentMg != null
                      ? '$currentMg mg/dL'
                      : (avg12h != null ? 'Avg $avg12h' : '--'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 12-Hour Summary Stat Pills
          if (recentSamples.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppRadii.r14,
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _build12hStatItem(
                    label: '12h Avg',
                    value: avg12h != null ? '$avg12h' : '--',
                    unit: 'mg/dL',
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: AppPalette.hexFFE5DCF4,
                  ),
                  _build12hStatItem(
                    label: '12h TIR',
                    value: '$tir12h%',
                    unit: 'in target',
                    valueColor: tir12h >= 70
                        ? AppPalette.hexFF15803D
                        : AppPalette.hexFFD97706,
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: AppPalette.hexFFE5DCF4,
                  ),
                  _build12hStatItem(
                    label: '12h Trend',
                    value: trendDiff12h == null
                        ? 'Stable'
                        : (trendDiff12h > 15
                              ? '+${trendDiff12h.round()}'
                              : (trendDiff12h < -15
                                    ? '${trendDiff12h.round()}'
                                    : 'Stable')),
                    unit: trendDiff12h != null && trendDiff12h.abs() > 15
                        ? 'mg/dL'
                        : 'flat',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Guidance Box
          Container(
            padding: AppInsets.all14,
            decoration: BoxDecoration(
              color: AppPalette.hexFFF9F9FC,
              borderRadius: AppRadii.r16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: AppInsets.all8,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: AppColors.surface, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            advice,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textMuted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppPalette.hexFFECEAF4),
                const SizedBox(height: 10),
                const Text(
                  'Recommended Options for Your 12h Profile:',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: foods.map((f) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadii.r12,
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 13,
                            color: badgeColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            f,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '* Medical Note: Dynamic suggestions automatically adapt according to your 12-hour continuous glucose pattern.',
            style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _build12hStatItem({
    required String label,
    required String value,
    required String unit,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: valueColor ?? AppTheme.darkPurple,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildTargetRangeCard(double lowT, double highT) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.r20,
        border: Border.all(color: AppPalette.hexFFEFEBF6, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: AppInsets.all6,
            decoration: const BoxDecoration(
              color: AppPalette.hexFFDCFCE7,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: AppPalette.hexFF15803D,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Target range',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Recommended glucose corridor',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Text(
            '${lowT.round()} ${highT.round()} mg/dL',
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppPalette.hexFF15803D,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderHomeCards extends StatefulWidget {
  const _ReminderHomeCards({required this.api});
  final dynamic api;
  @override
  State<_ReminderHomeCards> createState() => _ReminderHomeCardsState();
}

class _ReminderHomeCardsState extends State<_ReminderHomeCards> {
  Map<String, dynamic>? summary;
  String mealNext = '';
  String waterNext = '';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await widget.api.getWellnessToday();
      final reminders = await widget.api.getWellnessReminders();
      if (!mounted) return;
      setState(() {
        summary = value;
        mealNext = _nextMeal(reminders['schedules']);
        waterNext = _nextWater(reminders['settings']);
      });
    } catch (_) {}
  }

  String _nextMeal(dynamic raw) {
    final now = TimeOfDay.now();
    final minutesNow = now.hour * 60 + now.minute;
    var best = 24 * 60 + 1;
    String label = '';
    for (final item in (raw as List?) ?? const []) {
      final map = item is Map ? item : null;
      if (map == null) continue;
      final parts = '${map['reminderTime'] ?? ''}'.split(':');
      if (parts.length < 2) continue;
      final mins = (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
      final delta = mins >= minutesNow ? mins - minutesNow : mins + 24 * 60 - minutesNow;
      if (delta < best) {
        best = delta;
        label = '${map['customName'] ?? map['mealType'] ?? 'Meal'} · ${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      }
    }
    return label;
  }

  String _nextWater(dynamic raw) {
    if (raw is! Map) return '';
    if (raw['waterEnabled'] == false) return '';
    final interval = int.tryParse('${raw['waterIntervalMinutes'] ?? 120}') ?? 120;
    if (raw['quietHoursEnabled'] != false && _inQuiet('${raw['quietStart'] ?? '22:00'}', '${raw['quietEnd'] ?? '07:00'}')) {
      return 'Quiet until ${raw['quietEnd'] ?? '07:00'}';
    }
    if (interval <= 0) return '';
    return 'Every $interval min';
  }

  bool _inQuiet(String start, String end) {
    int minutes(String value) {
      final parts = value.split(':');
      if (parts.length < 2) return 0;
      return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    }
    final now = DateTime.now().hour * 60 + DateTime.now().minute;
    final from = minutes(start);
    final to = minutes(end);
    if (from == to) return false;
    if (from < to) return now >= from && now < to;
    return now >= from || now < to;
  }

  @override
  Widget build(BuildContext context) {
    final meals = (summary?['meals'] as List?)?.length ?? 0;
    final water = (summary?['waterMl'] as num?)?.toInt() ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        _glanceRow(context, Icons.restaurant_outlined, AppColors.primary, 'Meals', '$meals logged', mealNext, MealRemindersScreen(api: widget.api)),
        const SizedBox(height: 8),
        _glanceRow(context, Icons.water_drop_outlined, AppColors.primary, 'Water', '$water mL', waterNext, WaterRemindersScreen(api: widget.api)),
      ],
    );
  }

  Widget _glanceRow(BuildContext context, IconData icon, Color color, String title, String value, String next, Widget page) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(radius: 18, backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color, size: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    if (next.isNotEmpty) Text(next, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text(value, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context,
    IconData icon,
    Color color,
    String title,
    String value,
    String action,
    Widget page,
  ) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.12),
              foregroundColor: color,
              child: Icon(icon, size: 21),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              action,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _WellnessHomeCard extends StatefulWidget {
  const _WellnessHomeCard({required this.api});
  final dynamic api;
  @override
  State<_WellnessHomeCard> createState() => _WellnessHomeCardState();
}

class _WellnessHomeCardState extends State<_WellnessHomeCard> {
  Map<String, dynamic>? summary;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await widget.api.getWellnessToday();
      if (mounted) setState(() => summary = value);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final meals = (summary?['meals'] as List?)?.length ?? 0;
    final water = (summary?['waterMl'] as num?)?.toInt() ?? 0;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.health_and_safety_outlined),
        title: const Text('Daily Wellness'),
        subtitle: Text('$meals meals logged  â€¢  $water mL water'),
        trailing: TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WellnessScreen(api: widget.api)),
          ),
          child: const Text('Open'),
        ),
      ),
    );
  }
}

class _HomeChart extends StatefulWidget {
  const _HomeChart({required this.samples, required this.low, required this.high, required this.mmol, required this.connected, required this.onConnect, required this.api});
  final List<GlucoseSample> samples;
  final double low;
  final double high;
  final bool mmol;
  final bool connected;
  final VoidCallback onConnect;
  final dynamic api;

  @override
  State<_HomeChart> createState() => _HomeChartState();
}

class _HomeChartState extends State<_HomeChart> with SingleTickerProviderStateMixin {
  int range = 0;
  int? picked;
  List<DateTime> marks = [];
  static const _labels = ['Live', '1h', '6h', '12h', '24h'];
  String? _pointsCacheKey;
  List<GlucoseSample> _cachedPoints = const [];

  Duration get _span => switch (range) {
    1 => const Duration(hours: 1),
    2 => const Duration(hours: 6),
    3 => const Duration(hours: 12),
    4 => const Duration(hours: 24),
    _ => const Duration(minutes: 15),
  };
  late final AnimationController _draw;

  @override
  void initState() {
    super.initState();
    final reduceMotion = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _draw = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: reduceMotion ? 0 : 450),
    )..forward();
    _loadMarks();
  }

  List<GlucoseSample> _pointsForRange(BuildContext context) {
    final last = widget.samples.isEmpty ? null : widget.samples.last;
    final key =
        '$range|${widget.samples.length}|${last?.seq}|${last?.wearId}|${widget.connected}';
    if (_pointsCacheKey == key) return _cachedPoints;
    final cutoff = DateTime.now().subtract(_span);
    final raw = <GlucoseSample>[];
    for (var i = widget.samples.length - 1; i >= 0; i--) {
      final s = widget.samples[i];
      if (!s.measuredAt.isAfter(cutoff)) break;
      if (s.value != null) raw.add(s);
    }
    _cachedPoints = UiPerf.downsample(
      raw.reversed.toList(),
      maxPoints: UiPerf.isLowEndLayout(context) ? 80 : 160,
    );
    _pointsCacheKey = key;
    return _cachedPoints;
  }

  Future<void> _loadMarks() async {
    final from = DateTime.now().toUtc().subtract(const Duration(hours: 24)).toIso8601String();
    final found = <DateTime>[];
    try {
      final today = await widget.api.getWellnessToday(startUtc: from);
      for (final item in (today['meals'] as List?) ?? const []) {
        final at = DateTime.tryParse('${item['occurredAtUtc'] ?? ''}')?.toLocal();
        if (at != null) found.add(at);
      }
    } catch (_) {}
    try {
      final activities = await widget.api.getActivities(from: from);
      for (final item in activities) {
        if (item is! Map) continue;
        final at = DateTime.tryParse('${item['occurredAtUtc'] ?? ''}')?.toLocal();
        if (at != null) found.add(at);
      }
    } catch (_) {}
    if (mounted) setState(() => marks = found);
  }

  Future<void> _noteSheet() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DailyActivitiesScreen(api: widget.api)),
    );
    if (mounted) _loadMarks();
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  void _select(int item) {
    setState(() {
      range = item;
      picked = null;
    });
    _draw.forward(from: 0);
  }

  void _pick(double dx, double width, int count) {
    if (count < 2 || width <= 8) return;
    final t = ((dx - 4) / (width - 8)).clamp(0.0, 1.0);
    setState(() => picked = (t * (count - 1)).round());
  }

  @override
  Widget build(BuildContext context) {
    final points = _pointsForRange(context);
    final values = points.map((s) => s.value! > 30 ? s.value! : s.value! * 18.0182).toList();
    final times = points.map((s) => s.measuredAt).toList();
    String shown(double mg) => widget.mmol ? (mg / 18.0182).toStringAsFixed(1) : mg.round().toString();
    final focus = values.isEmpty ? 0 : (picked ?? values.length - 1).clamp(0, values.length - 1);
    final focusLabel = values.isEmpty ? '' : '${shown(values[focus])}\n${DateFormat('h:mm a').format(times[focus])}';
    final delta = values.length < 2 ? 0.0 : values.last - values.first;
    final trend = delta.abs() < 8 ? 0 : delta.sign.toInt();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
            children: [
              for (var item = 0; item < _labels.length; item++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _select(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: range == item ? AppColors.primary : AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _labels[item],
                        style: TextStyle(
                          color: range == item ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: range == 0 && widget.connected && values.isNotEmpty ? 250 : 190,
            child: range == 0 && !widget.connected
                ? GestureDetector(
                    onTap: widget.onConnect,
                    child: const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Device is not connected. Open 1h, 6h, 12h, or 24h for earlier readings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, height: 1.35),
                      ),
                    ),
                  ),
                  )
                : range == 0 && values.isNotEmpty
                ? GestureDetector(
                    onTap: _noteSheet,
                    child: _LiveGauge(
                    mg: values.last,
                    text: shown(values.last),
                    unit: widget.mmol ? 'mmol/L' : 'mg/dL',
                    low: widget.low,
                    high: widget.high,
                    trend: trend,
                  ),
                  )
                : values.length < 2
                ? Center(child: Text(range == 0 ? 'Collecting the last 15 minutes' : 'No readings in this range yet.', style: const TextStyle(color: AppColors.textSecondary)))
                : LayoutBuilder(
                    builder: (context, constraints) => GestureDetector(
                      onTapDown: (details) => _pick(details.localPosition.dx, constraints.maxWidth, values.length),
                      child: AnimatedBuilder(
                        animation: _draw,
                        builder: (context, _) => CustomPaint(
                          painter: _SparkPainter(
                            values: values,
                            times: times,
                            label: focusLabel,
                            index: focus,
                            low: widget.low,
                            high: widget.high,
                            marks: marks,
                            progress: Curves.easeOutCubic.transform(_draw.value),
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LiveGauge extends StatelessWidget {
  const _LiveGauge({required this.mg, required this.text, required this.unit, required this.low, required this.high, required this.trend});
  final double mg;
  final String text;
  final String unit;
  final double low;
  final double high;
  final int trend;

  @override
  Widget build(BuildContext context) {
    final color = mg < low || mg > high ? AppColors.danger : AppColors.success;
    final arrow = trend > 0 ? Icons.trending_up_rounded : trend < 0 ? Icons.trending_down_rounded : Icons.trending_flat_rounded;
    return CustomPaint(
      painter: _GaugePainter(mg: mg),
      child: Center(
        child: Container(
          width: 118,
          height: 118,
          decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(arrow, color: color, size: 22),
              Text(text, style: TextStyle(fontSize: 40, height: 1, fontWeight: FontWeight.w800, color: color)),
              Text(unit, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.mg});
  final double mg;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 8);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const start = math.pi * 0.85;
    const sweep = math.pi * 1.3;
    final track = Paint()
      ..color = AppColors.primarySoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, start, sweep, false, track);
    final t = ((mg - 40) / 260).clamp(0.0, 1.0);
    canvas.drawArc(rect, start, sweep * t, false, arc);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.mg != mg;
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.values, required this.times, required this.label, required this.index, required this.progress, required this.low, required this.high, required this.marks});
  final List<double> values;
  final List<DateTime> times;
  final String label;
  final int index;
  final double progress;
  final double low;
  final double high;
  final List<DateTime> marks;
  static const line = AppColors.primary;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width < 40 || size.height < 40) return;
    const bottomGutter = 22.0;
    final plot = Rect.fromLTWH(4, 28, size.width - 8, size.height - 28 - bottomGutter);
    final minV = values.reduce((a, b) => a < b ? a : b) - 12;
    final maxV = values.reduce((a, b) => a > b ? a : b) + 18;
    final span = (maxV - minV).abs() < 1 ? 1.0 : (maxV - minV);
    double yOf(double v) => plot.bottom - ((v - minV) / span) * plot.height;
    double xOf(int i) => plot.left + plot.width * i / (values.length - 1);
    final bandTop = yOf(high).clamp(plot.top, plot.bottom);
    final bandBottom = yOf(low).clamp(plot.top, plot.bottom);
    canvas.drawRect(
      Rect.fromLTRB(plot.left, bandTop, plot.right, bandBottom),
      Paint()..color = AppColors.success.withValues(alpha: 0.14),
    );

    final path = Path();
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final p = Offset(xOf(i), yOf(values[i]));
      points.add(p);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    final metrics = path.computeMetrics().toList();
    final drawn = metrics.isEmpty ? path : metrics.first.extractPath(0, metrics.first.length * progress.clamp(0, 1));
    canvas.drawPath(
      drawn,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final last = points[index.clamp(0, points.length - 1)];
    canvas.drawLine(Offset(last.dx, last.dy), Offset(last.dx, plot.bottom), Paint()..color = AppColors.surfaceBorder..strokeWidth = 1);
    canvas.drawCircle(last, 5, Paint()..color = AppColors.primary);
    canvas.drawCircle(last, 2.2, Paint()..color = AppColors.surface);
    for (final mark in marks) {
      var nearest = 0;
      var best = 1 << 30;
      for (var i = 0; i < times.length; i++) {
        final gap = times[i].difference(mark).inMinutes.abs();
        if (gap < best) {
          best = gap;
          nearest = i;
        }
      }
      if (best > 30) continue;
      canvas.drawCircle(points[nearest].translate(0, -12), 5, Paint()..color = AppColors.primary);
    }

    final badge = TextPainter(
      text: TextSpan(
        children: [
          for (final line in label.split('\n'))
            TextSpan(
              text: line == label.split('\n').first ? '$line\n' : line,
              style: line == label.split('\n').first
                  ? const TextStyle(fontSize: 15, height: 1.1, fontWeight: FontWeight.w800, color: AppColors.textPrimary)
                  : const TextStyle(fontSize: 11, height: 1.2, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final maxX = size.width - badge.width;
    final maxY = (last.dy - badge.height - 8).clamp(0.0, size.height);
    badge.paint(
      canvas,
      Offset(
        maxX <= 0 ? 0 : (last.dx - badge.width / 2).clamp(0.0, maxX),
        maxY,
      ),
    );

    for (var i = 0; i < 5; i++) {
      final index = ((values.length - 1) * i / 4).round();
      final tp = TextPainter(
        text: TextSpan(text: DateFormat('h:mm').format(times[index]), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      final limit = size.width - tp.width;
      final x = limit <= 0 ? 0.0 : (xOf(index) - tp.width / 2).clamp(0.0, limit);
      tp.paint(canvas, Offset(x, size.height - tp.height));
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.label != label || oldDelegate.index != index || oldDelegate.marks.length != marks.length || oldDelegate.progress != progress;
}
