import 'package:cgm_sdk/cgm_sdk.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_theme.dart';
import '../../state/app_controller.dart';
import '../../widgets/app_animations.dart';
import 'family_circle_screen.dart';
import 'linked_device_screen.dart';
import 'notification_preferences_screen.dart';
import 'personal_info_screen.dart';
import 'privacy_security_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final isConnected = controller.connection == CgmConnectionState.connected;
    final statusText = isConnected ? 'Connected' : 'Disconnected';

    // Dynamic Sensor & Device info
    final deviceModel =
        controller.activeDevice?['deviceModel']?.toString() ??
        (controller.wear?.form == 'half' ? 'G-B' : 'G-AA');
    final deviceName =
        controller.activeDevice?['deviceName']?.toString() ??
        (controller.activeDevice?['bleDeviceName']?.toString().isNotEmpty ==
                true
            ? controller.activeDevice!['bleDeviceName']
            : (controller.wear?.deviceId != null
                  ? 'CxM ${controller.wear!.deviceId}'
                  : 'Circle CGM'));
    final serialNumber =
        controller.activeDevice?['serialNumber']?.toString() ??
        controller.wear?.transmitterSn ??
        controller.wear?.sensorSn ??
        controller.wear?.deviceId ??
        controller.activeSensor?['sensorIdentifier']?.toString() ??
        '--';
    final firmware =
        controller.activeDevice?['firmwareVersion']?.toString() ?? 'A100';

    // Sensor days calculations
    int remainingDays = 14;
    int dayPassed = 1;
    if (controller.deviceStatus?.remainingDays != null &&
        controller.deviceStatus!.remainingDays > 0) {
      remainingDays = controller.deviceStatus!.remainingDays;
      dayPassed = (14 - remainingDays).clamp(1, 14);
    } else if (controller.wear?.activatedAt != null) {
      final daysDiff = DateTime.now()
          .difference(controller.wear!.activatedAt)
          .inDays;
      dayPassed = (daysDiff + 1).clamp(1, 14);
      remainingDays = (14 - dayPassed).clamp(0, 14);
    } else if (controller.activeSensor?['startedAt'] != null) {
      final started = DateTime.tryParse(
        controller.activeSensor!['startedAt'].toString(),
      );
      if (started != null) {
        final daysDiff = DateTime.now().difference(started).inDays;
        dayPassed = (daysDiff + 1).clamp(1, 14);
        remainingDays = (14 - dayPassed).clamp(0, 14);
      }
    }
    final wearRatio = (dayPassed / 14).clamp(0.0, 1.0);

    // Battery calculations
    final batteryMv =
        controller.deviceStatus?.batteryMv ??
        (controller.activeDevice?['batteryVoltageMv'] != null
            ? int.tryParse(
                controller.activeDevice!['batteryVoltageMv'].toString(),
              )
            : 3000);
    final batteryPct = controller.activeDevice?['batteryPercentage'] != null
        ? (controller.activeDevice!['batteryPercentage'] as num).toInt()
        : (batteryMv != null
              ? (((batteryMv - 2600) / (3000 - 2600)) * 100)
                    .clamp(0, 100)
                    .round()
              : 95);
    final batteryDisplay = batteryMv != null
        ? '$batteryMv mV ($batteryPct%)'
        : '$batteryPct%';
    final batteryRatio = (batteryPct / 100.0).clamp(0.0, 1.0);

    // Temperature calculations
    final tempVal = controller.deviceStatus?.temperature ?? 32.5;
    final tempDisplay = '${tempVal.toStringAsFixed(1)}°C (Normal)';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Header
            const Text(
              'Profile & Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkPurple,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage your profile, device and app preferences.',
              style: TextStyle(fontSize: 13.5, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),

            // 1. User Card (Screenshot 091707)
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  SmoothPageRoute(
                    page: PersonalInfoScreen(controller: controller),
                  ),
                );
              },
              child: Container(
                padding: AppInsets.all18,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.r22,
                  border: Border.all(color: AppPalette.hexFFEFEBF6, width: 1.2),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _pickAndUploadAvatar(context),
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryPurple,
                                width: 2,
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
                                    Icons.person_outline_rounded,
                                    color: AppTheme.primaryPurple,
                                    size: 34,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _pickAndUploadAvatar(context),
                            child: Container(
                              padding: AppInsets.all3,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryPurple,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 12,
                                color: AppColors.surface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.darkPurple,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            controller.userEmail,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                isConnected
                                    ? Icons.sensors_rounded
                                    : Icons.sensors_off_rounded,
                                size: 14,
                                color: isConnected
                                    ? AppTheme.successGreen
                                    : AppTheme.darkPurple,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isConnected
                                      ? AppTheme.successGreen
                                      : AppTheme.darkPurple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.darkPurple,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. CGM Hardware Sensor Card
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LinkedDeviceScreen(controller: controller),
                  ),
                );
              },
              child: Container(
                padding: AppInsets.all18,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.r22,
                  border: Border.all(color: AppPalette.hexFFEFEBF6, width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryPurple,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryPurple,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CGM Hardware Sensor',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            deviceName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.darkPurple,
                            ),
                          ),
                          if (isConnected) ...[
                            const SizedBox(height: 2),
                            Text(
                              '$remainingDays days left',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      statusText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isConnected) ...[
              const SizedBox(height: 16),

              // 3. Sensor Hardware Telemetry Card
              Container(
                padding: AppInsets.all18,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.r22,
                  border: Border.all(color: AppPalette.hexFFEFEBF6, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: AppInsets.all6,
                          child: const Icon(
                            Icons.memory_rounded,
                            color: AppTheme.primaryPurple,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Sensor Hardware Telemetry',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.darkPurple,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Live BLE diagnostics from on-skin sensor',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.hexFFE6F9EE,
                            borderRadius: AppRadii.r10,
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppPalette.hexFF10B981,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 2x2 Telemetry Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildTelemetryCell(
                            icon: Icons.battery_charging_full_rounded,
                            iconColor: AppPalette.hexFF10B981,
                            label: 'Battery Voltage',
                            value: batteryDisplay,
                            hasProgressBar: true,
                            progressRatio: batteryRatio,
                            progressColor: AppPalette.hexFF10B981,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTelemetryCell(
                            icon: Icons.thermostat_rounded,
                            iconColor: AppPalette.hexFFF97316,
                            label: 'Probe Temp',
                            value: tempDisplay,
                            caption: 'Skin Surface Norm',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTelemetryCell(
                            icon: Icons.access_time_filled_rounded,
                            iconColor: AppTheme.primaryPurple,
                            label: 'Sensor Wear',
                            value:
                                'Day $dayPassed of 14 • $remainingDays days left',
                            hasProgressBar: true,
                            progressRatio: wearRatio,
                            progressColor: AppTheme.primaryPurple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTelemetryCell(
                            icon: Icons.wifi,
                            iconColor: AppPalette.hexFF00B2E2,
                            label: 'Signal (RSSI)',
                            value: '-58 dBm (Strong BLE)',
                            caption: 'GATT Connected',
                            captionColor: AppPalette.hexFF10B981,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppPalette.hexFFF2EEF8),
                    const SizedBox(height: 8),
                    Text(
                      'Model:  $deviceModel   •   Firmware: $firmware   •   SN: $serialNumber',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // 4. Settings List (Screenshot 091711)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.r22,
                border: Border.all(color: AppPalette.hexFFEFEBF6, width: 1.2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: AppColors.transparent,
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Personal Info',
                      subtitle: 'Update your personal details',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PersonalInfoScreen(controller: controller),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.groups_outlined,
                      title: 'Family Monitoring',
                      subtitle: 'Share alerts with trusted family',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                FamilyCircleScreen(controller: controller),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.link_rounded,
                      title: 'Linked CGM Device',
                      subtitle: 'View device details and settings',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                LinkedDeviceScreen(controller: controller),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.access_time_rounded,
                      title: 'Glucose Unit',
                      subtitle: 'Choose your preferred unit',
                      trailingText: controller.preferredGlucoseUnit,
                      onTap: () {
                        _showUnitDialog(context);
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.track_changes_rounded,
                      title: 'Target Glucose Range',
                      subtitle:
                          'Day target: ${controller.targetLow.round()} ${controller.targetHigh.round()} ${controller.preferredGlucoseUnit}',
                      trailingText:
                          '${controller.targetLow.round()} - ${controller.targetHigh.round()}',
                      onTap: () {
                        _showTargetRangeDialog(context);
                      },
                    ),

                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notification Preferences',
                      subtitle: 'Manage alerts and reminders',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NotificationPreferencesScreen(
                              controller: controller,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Privacy & Security',
                      subtitle: 'Manage your data and privacy',
                      onTap: () {
                        PrivacySecurityModal.show(context, controller);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sign Out Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.r22,
                border: Border.all(color: AppPalette.hexFFEFEBF6, width: 1.2),
              ),
              child: _buildSettingsTile(
                icon: Icons.meeting_room_outlined,
                title: 'Sign Out',
                subtitle: 'Sign out of your account',
                onTap: controller.logout,
              ),
            ),
            const SizedBox(height: 24),

            const Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryCell({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? caption,
    Color? captionColor,
    bool hasProgressBar = false,
    double progressRatio = 0.5,
    Color? progressColor,
  }) {
    return Container(
      padding: AppInsets.all12,
      decoration: BoxDecoration(
        color: AppPalette.hexFFF9F9FC,
        borderRadius: AppRadii.r16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkPurple,
            ),
          ),
          if (hasProgressBar) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: AppRadii.r2,
              child: LinearProgressIndicator(
                value: progressRatio,
                minHeight: 3.5,
                backgroundColor: AppPalette.hexFFE5DCF4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressColor ?? AppTheme.primaryPurple,
                ),
              ),
            ),
          ],
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: captionColor ?? AppPalette.hexFFF97316,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? trailingText,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.r16,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: AppInsets.all8,
              decoration: const BoxDecoration(
                color: AppTheme.lightPurpleBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryPurple, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkPurple,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkPurple,
                ),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(
              Icons.chevron_right,
              color: AppTheme.darkPurple,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 64,
      endIndent: 20,
      color: AppPalette.hexFFF4EFF8,
    );
  }

  void _showUnitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Glucose Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('mg/dL (Standard US/Intl)'),
              trailing: controller.preferredGlucoseUnit == 'mg/dL'
                  ? const Icon(Icons.check, color: AppTheme.primaryPurple)
                  : null,
              onTap: () {
                controller.saveProfile(
                  name: controller.fullName,
                  unit: 'mg/dL',
                );
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              title: const Text('mmol/L (UK / Canada / EU)'),
              trailing: controller.preferredGlucoseUnit == 'mmol/L'
                  ? const Icon(Icons.check, color: AppTheme.primaryPurple)
                  : null,
              onTap: () {
                controller.saveProfile(
                  name: controller.fullName,
                  unit: 'mmol/L',
                );
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

 

  void _showTargetRangeDialog(BuildContext context) {
    double localLow = controller.targetLow;
    double localHigh = controller.targetHigh;
    double localUrgentLow = controller.urgentLowThreshold;
    double localUrgentHigh = controller.urgentHighThreshold;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppPalette.hexFFDDD8EC,
                        borderRadius: AppRadii.r2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: AppInsets.all8,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: AppTheme.primaryPurple,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Glucose Targets & Critical Alerts',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.darkPurple,
                              ),
                            ),
                            Text(
                              'Configure clinical ranges and emergency alarms',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Target Low (Hypo Threshold)
                  _buildThresholdSlider(
                    label: 'Target Low (Hypoglycemia warning)',
                    value: localLow,
                    min: 65,
                    max: 100,
                    divisions: 35,
                    unit: 'mg/dL',
                    color: AppPalette.hexFFF97316,
                    onChanged: (v) {
                      setModalState(() {
                        localLow = v;
                        if (localLow >= localHigh) {
                          localHigh = localLow + 10;
                        }
                        if (localUrgentLow >= localLow) {
                          localUrgentLow = localLow - 10;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  // Target High (Hyper Threshold)
                  _buildThresholdSlider(
                    label: 'Target High (Hyperglycemia warning)',
                    value: localHigh,
                    min: 120,
                    max: 200,
                    divisions: 80,
                    unit: 'mg/dL',
                    color: AppPalette.hexFF8B5CF6,
                    onChanged: (v) {
                      setModalState(() {
                        localHigh = v;
                        if (localHigh <= localLow) {
                          localLow = localHigh - 10;
                        }
                        if (localUrgentHigh <= localHigh) {
                          localUrgentHigh = localHigh + 20;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  // Urgent Critical Low
                  _buildThresholdSlider(
                    label: '🚨 Urgent Critical Low (Emergency Alarm)',
                    value: localUrgentLow,
                    min: 45,
                    max: 70,
                    divisions: 25,
                    unit: 'mg/dL',
                    color: AppPalette.hexFFEF4444,
                    onChanged: (v) {
                      setModalState(() {
                        localUrgentLow = v;
                        if (localUrgentLow >= localLow) {
                          localLow = localUrgentLow + 10;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  // Urgent Critical High
                  _buildThresholdSlider(
                    label: '🚨 Urgent Critical High (Emergency Alarm)',
                    value: localUrgentHigh,
                    min: 200,
                    max: 350,
                    divisions: 15,
                    unit: 'mg/dL',
                    color: AppPalette.hexFF5B21B6,
                    onChanged: (v) {
                      setModalState(() {
                        localUrgentHigh = v;
                        if (localUrgentHigh <= localHigh) {
                          localHigh = localUrgentHigh - 20;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            setModalState(() => saving = true);
                            try {
                              await controller.saveGlucoseTargetRange(
                                low: localLow,
                                high: localHigh,
                                urgentLow: localUrgentLow,
                                urgentHigh: localUrgentHigh,
                              );
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Target range updated: ${localLow.round()} - ${localHigh.round()} mg/dL',
                                    ),
                                    backgroundColor: AppTheme.primaryPurple,
                                  ),
                                );
                              }
                            } catch (e) {
                              setModalState(() => saving = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to save: $e'),
                                    backgroundColor: AppColors.materialRed,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      foregroundColor: AppColors.surface,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: AppRadii.r16),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.surface,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Target Ranges & Alerts',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildThresholdSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalette.hexFFFBFBFE,
        borderRadius: AppRadii.r16,
        border: Border.all(color: AppPalette.hexFFECEAF4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkPurple,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadii.r8,
                ),
                child: Text(
                  '${value.round()} $unit',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              thumbColor: color,
              trackHeight: 3,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryPurple),
                title: const Text('Take a photo'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryPurple),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 92,
      );
      if (picked == null) return;

      // Crop with passport size presets and manual adjustment
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust Profile Photo',
            toolbarColor: AppTheme.primaryPurple,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppTheme.primaryPurple,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
            ],
          ),
          IOSUiSettings(
            title: 'Adjust Profile Photo',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
            ],
          ),
        ],
      );

      if (croppedFile == null) return;

      final bytes = await croppedFile.readAsBytes();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading profile photo...'),
          duration: Duration(seconds: 2),
        ),
      );

      await controller.uploadProfilePicture(bytes, picked.name);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload photo: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
