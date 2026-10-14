import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../state/app_controller.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  late bool criticalGlucoseAlerts;
  late bool sensorAlerts;
  late bool reportReminders;

  @override
  void initState() {
    super.initState();
    criticalGlucoseAlerts = widget.controller.criticalAlerts;
    sensorAlerts = widget.controller.sensorAlerts;
    reportReminders = widget.controller.reportReminders;
  }

  void _update() {
    widget.controller.setPreferences(
      critical: criticalGlucoseAlerts,
      sensor: sensorAlerts,
      reminders: reportReminders,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: AppTheme.darkPurple,
            size: 28,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notification Preferences',
          style: TextStyle(
            color: AppTheme.darkPurple,
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
          child: Column(
            children: [
              _buildPreferenceRow(
                'Critical glucose alerts',
                criticalGlucoseAlerts,
                (val) {
                  setState(() => criticalGlucoseAlerts = val);
                  _update();
                },
              ),
              const SizedBox(height: 36),
              _buildPreferenceRow(
                'Sensor and connection alerts',
                sensorAlerts,
                (val) {
                  setState(() => sensorAlerts = val);
                  _update();
                },
              ),
              const SizedBox(height: 36),
              _buildPreferenceRow('Report reminders', reportReminders, (val) {
                setState(() => reportReminders = val);
                _update();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkPurple,
            ),
          ),
        ),
        Transform.scale(
          scale: 0.95,
          child: Switch(
            value: value,
            activeThumbColor: AppColors.surface,
            activeTrackColor: AppTheme.primaryPurple,
            inactiveThumbColor: AppColors.surface,
            inactiveTrackColor: AppPalette.hexFFCCC8DC,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
