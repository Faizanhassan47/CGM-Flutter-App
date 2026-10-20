import 'package:cgm_sdk/cgm_sdk.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../state/app_controller.dart';
import '../../widgets/app_animations.dart';
import '../../widgets/glucose_trend_chart.dart';
import '../onboarding/device_setup_screen.dart';

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
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isConnected =
            controller.connection == CgmConnectionState.connected;
        // Never present a cached glucose value as current telemetry while the
        // sensor link is disconnected or reconnecting.
        final sample = isConnected ? controller.latest : null;
        final sampleVal = sample?.value;
        final double? rawMg = sampleVal != null
            ? (sampleVal > 30 ? sampleVal : sampleVal * 18.0182)
            : null;
        final int? mg = rawMg?.round();

        final isMmol = controller.preferredGlucoseUnit.toLowerCase().contains(
          'mmol',
        );
        final String unitStr = isMmol ? 'mmol/L' : 'mg/dL';
        final String displayGlucose = rawMg != null
            ? (isMmol
                  ? (rawMg / 18.0182).toStringAsFixed(1)
                  : '${rawMg.round()}')
            : '--';
        final double displayLow = isMmol
            ? (controller.targetLow / 18.0182)
            : controller.targetLow;
        final double displayHigh = isMmol
            ? (controller.targetHigh / 18.0182)
            : controller.targetHigh;
        final String targetStr = isMmol
            ? '${displayLow.toStringAsFixed(1)}-${displayHigh.toStringAsFixed(1)}'
            : '${controller.targetLow.round()}-${controller.targetHigh.round()}';

        final displayName = controller.fullName.trim().isNotEmpty
            ? controller.fullName.trim().split(' ').first
            : 'Visole';

        final lowT = controller.targetLow;
        final highT = controller.targetHigh;

        final isUrgentLow = mg != null && mg < 55;
        final inTarget = mg != null && mg >= lowT && mg <= highT;
        final statusText = mg == null
            ? 'No sensor readings'
            : isUrgentLow
            ? 'Urgent Low (< 55 mg/dL)'
            : inTarget
            ? 'In Target • Stable (±0.5 mg/dL/min)'
            : mg < lowT
            ? 'Below Target • Low'
            : 'Above Target • High';

        return SafeArea(
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
                // 1. Top Header (Good morning, Visole + Profile Avatar)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.darkPurple,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => onSwitchTab(4), // navigate to Profile tab
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.lightPurpleBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryPurple.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          image: controller.profilePictureUrl != null &&
                                  controller.profilePictureUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(
                                    controller.profilePictureUrl!,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: controller.profilePictureUrl == null ||
                                controller.profilePictureUrl!.isEmpty
                            ? const Icon(
                                Icons.person_rounded,
                                color: AppTheme.primaryPurple,
                                size: 26,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 2. Sensor status / Reconnecting card
                FadeSlideEntrance(
                  delay: const Duration(milliseconds: 50),
                  child: _buildSensorStatusCard(context, isConnected),
                ),
                const SizedBox(height: 14),

                // 3. Connect a CGM sensor purple banner (hidden once connected or bound)
                if (!isConnected && controller.wear == null) ...[
                  FadeSlideEntrance(
                    delay: const Duration(milliseconds: 80),
                    child: _buildConnectCgmBanner(context),
                  ),
                  const SizedBox(height: 16),
                ],

                // 4. Grace Period / Sensor Expiration Warning Banner
                Builder(
                  builder: (context) {
                    final wear = controller.wear;
                    if (wear != null) {
                      final now = DateTime.now();
                      if (now.isAfter(wear.expiresAt)) {
                        final hoursOver = now
                            .difference(wear.expiresAt)
                            .inHours;
                        final graceHoursLeft = (12 - hoursOver).clamp(0, 12);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
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
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // 5. Glucose Telemetry Cyan Card
                FadeSlideEntrance(
                  delay: const Duration(milliseconds: 100),
                  child: _buildTelemetryCyanCard(
                    context,
                    mg,
                    statusText,
                    lowT,
                    highT,
                    isConnected: isConnected,
                    unitStr: unitStr,
                    displayGlucose: displayGlucose,
                    targetStr: targetStr,
                    isUrgentLow: isUrgentLow,
                    isHigh: mg != null && mg > highT,
                  ),
                ),
                const SizedBox(height: 24),

                if (isConnected) ...[
                  // Sensor-derived summaries remain hidden while offline so
                  // stale readings cannot be mistaken for live values.
                  FadeSlideEntrance(
                    delay: const Duration(milliseconds: 150),
                    child: _buildTodayAtAGlance(true),
                  ),
                  const SizedBox(height: 24),
                  FadeSlideEntrance(
                    delay: const Duration(milliseconds: 200),
                    child: GlucoseTrendCard(
                      samples: controller.history,
                      lowTarget: lowT,
                      highTarget: highT,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeSlideEntrance(
                    delay: const Duration(milliseconds: 250),
                    child: _buildDietAssistantCard(
                      mg,
                      lowT,
                      highT,
                      controller.history,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 8. "Target range" Card (Screenshot 091624)
                FadeSlideEntrance(
                  delay: const Duration(milliseconds: 300),
                  child: _buildTargetRangeCard(lowT, highT),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
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
      title = 'Urgent Hypoglycemia • Fast-Acting Carbs';
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
      title = 'Below Target • Hypo Stabilization';
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
      title = 'High Glucose Load • Hydration & Low GI';
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
      title = 'Elevated Glucose • Fiber & Lean Protein';
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
      title = 'Optimal Glycemic Control • Balanced Diet';
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
