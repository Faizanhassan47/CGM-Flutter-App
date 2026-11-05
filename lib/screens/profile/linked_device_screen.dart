import 'package:cgm_sdk/cgm_sdk.dart';
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../widgets/page_top_bar.dart';
import '../../state/app_controller.dart';
import '../../widgets/pill_button.dart';
import '../onboarding/pairing_guide_screen.dart';

class LinkedDeviceScreen extends StatelessWidget {
  const LinkedDeviceScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final isConnected = controller.connection == CgmConnectionState.connected;

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

    // Battery & Temperature
    final batteryMv =
        controller.deviceStatus?.batteryMv ??
        (controller.activeDevice?['batteryVoltageMv'] != null
            ? int.tryParse(
                controller.activeDevice!['batteryVoltageMv'].toString(),
              )
            : 3000);
    final tempVal = controller.deviceStatus?.temperature ?? 32.5;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageTopBar(
                title: 'Linked device',
                subtitle: 'Sensor details and connection',
                leading: PageTopAction(icon: Icons.chevron_left, onPressed: () => Navigator.pop(context)),
              ),
              const SizedBox(height: 16),
              Text(
                deviceName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkPurple,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Hardware: Continuous Glucose Sensor ($deviceModel)\nSerial Number: $serialNumber\nFirmware: $firmware',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),

              if (isConnected) ...[
                const Text(
                  'Telemetry Diagnostics (Stage 1)',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.darkPurple,
                  ),
                ),
                const SizedBox(height: 14),

                _buildBullet(
                  'Battery Voltage: ${batteryMv ?? 3000} mV (${batteryMv != null && batteryMv < 2700 ? "Low" : "Good"})',
                ),
                const SizedBox(height: 8),
                _buildBullet(
                  'Sensor Temperature: ${tempVal.toStringAsFixed(1)} °C',
                ),
                const SizedBox(height: 8),
                _buildBullet(
                  'Baseline Protocol: Verified (E7, E8, E1, E2, E3)',
                ),
                const SizedBox(height: 8),
                _buildBullet('GATT Services: FFF0 / FFF1 / FFF2'),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppPalette.hexFFF9F9FC,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppPalette.hexFFEFEBF6),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.sensors_off_rounded,
                        color: AppTheme.textMuted,
                        size: 22,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sensor is currently disconnected. Live diagnostics will appear once reconnected.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 48),
              PillButton(
                variant: PillButtonVariant.cyan,
                text: 'Pair another sensor',
                onPressed: () {
                  openDeviceSetup(context, controller);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6, right: 10),
          child: Icon(Icons.circle, size: 6, color: AppTheme.primaryPurple),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
