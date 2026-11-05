import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../widgets/page_top_bar.dart';
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              PageTopBar(
                title: 'Notifications',
                subtitle: 'Choose which alerts you receive',
                leading: PageTopAction(icon: Icons.chevron_left, onPressed: () => Navigator.pop(context)),
              ),
              const SizedBox(height: 20),
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
