import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../state/app_controller.dart';
import '../../widgets/pill_button.dart';

class SleepMonitoringScreen extends StatefulWidget {
  const SleepMonitoringScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<SleepMonitoringScreen> createState() => _SleepMonitoringScreenState();
}

class _SleepMonitoringScreenState extends State<SleepMonitoringScreen> {
  late TimeOfDay _bedTime;
  late TimeOfDay _wakeTime;
  late double _nightLow;
  late double _nightHigh;
  late bool _nightAlerts;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initValues();
    widget.controller.loadOvernightReport();
  }

  void _initValues() {
    final c = widget.controller;
    _bedTime = _parseTime(c.bedTime, const TimeOfDay(hour: 22, minute: 0));
    _wakeTime = _parseTime(c.wakeTime, const TimeOfDay(hour: 7, minute: 0));
    _nightLow = c.nightLowThreshold;
    _nightHigh = c.nightHighThreshold;
    _nightAlerts = c.nightAlertsEnabled;
  }

  TimeOfDay _parseTime(String timeStr, TimeOfDay fallback) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (_) {}
    return fallback;
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final min = t.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  Future<void> _selectTime({required bool isBedTime}) async {
    final initial = isBedTime ? _bedTime : _wakeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryPurple,
              onPrimary: AppColors.surface,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isBedTime) {
          _bedTime = picked;
        } else {
          _wakeTime = picked;
        }
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      await widget.controller.saveSleepSettings(
        bed: _formatTimeOfDay(_bedTime),
        wake: _formatTimeOfDay(_wakeTime),
        lowThreshold: _nightLow,
        highThreshold: _nightHigh,
        alertsEnabled: _nightAlerts,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppPalette.hexFF00B894,
            content: Text('Sleep monitoring settings saved successfully.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppPalette.hexFFD63031,
            content: Text('Failed to save settings: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final report = c.overnightReport;

    return Scaffold(
      backgroundColor: AppPalette.hexFFF8F9FE,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryPurple),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Sleep & Overnight Monitoring',
          style: TextStyle(
            color: AppTheme.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppInsets.all20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Clinical Overview Banner
            _buildInfoCard(),
            const SizedBox(height: 18),

            // Latest Overnight Analysis Card
            _buildOvernightAnalysisCard(report),
            const SizedBox(height: 24),

            // Sleep Schedule Configuration
            _buildSectionHeader(
              'Sleep Schedule & Window',
              Icons.bedtime_outlined,
            ),
            const SizedBox(height: 12),
            _buildScheduleCard(),
            const SizedBox(height: 24),

            // Night Thresholds
            _buildSectionHeader(
              'Nocturnal Alert Thresholds',
              Icons.security_rounded,
            ),
            const SizedBox(height: 12),
            _buildThresholdCard(),
            const SizedBox(height: 28),

            // Save Button
            PillButton(
              text: 'Save Sleep Preferences',
              loading: _saving,
              onPressed: _saveSettings,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryPurple),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppPalette.hexFF3B2A68,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: AppInsets.all16,
      decoration: BoxDecoration(
        color: AppPalette.hexFFEDE7F6,
        borderRadius: AppRadii.r16,
        border: Border.all(color: AppPalette.hexFFD1C4E9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: AppInsets.all8,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.nightlight_round,
              color: AppTheme.primaryPurple,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nocturnal Protection Guard',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.hexFF3B2A68,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Continuous night glucose tracking guards against asymptomatic nocturnal hypoglycemia, detects morning Dawn Phenomenon, and alerts caregivers immediately.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppPalette.hexFF5E35B1,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOvernightAnalysisCard(Map<String, dynamic>? data) {
    if (data == null || data['hasData'] != true) {
      return Container(
        padding: AppInsets.all20,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.r18,
          border: Border.all(color: AppPalette.hexFFECEAF4),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 36,
              color: AppPalette.hexFFA0AEC0,
            ),
            const SizedBox(height: 8),
            const Text(
              'No Overnight Sleep Readings Yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppPalette.hexFF3B2A68,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sleep data will populate automatically as your sensor streams readings between ${widget.controller.bedTime} and ${widget.controller.wakeTime}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppPalette.hexFF7E72A2,
              ),
            ),
          ],
        ),
      );
    }

    final mean = data['meanGlucose'] ?? 0;
    final tir = data['timeInRange'] ?? 0;
    final lowest = data['lowestGlucose'] ?? 0;
    final isHypo = data['nocturnalHypoDetected'] == true;
    final isDawn = data['dawnPhenomenonDetected'] == true;
    final isSomogyi = data['somogyiEffectDetected'] == true;
    final stability = data['stabilityScore']?.toString() ?? 'Stable';

    return Container(
      padding: AppInsets.all20,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.r18,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppPalette.hexFFECEAF4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bedtime, size: 18, color: AppTheme.primaryPurple),
                  SizedBox(width: 6),
                  Text(
                    'Last Night Analysis',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.hexFF3B2A68,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isHypo
                      ? AppPalette.hexFFFFEBEE
                      : (tir >= 80
                            ? AppPalette.hexFFE8F8F0
                            : AppPalette.hexFFFFF9E6),
                  borderRadius: AppRadii.r12,
                ),
                child: Text(
                  isHypo ? 'Nocturnal Dip Detected' : stability,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isHypo
                        ? AppPalette.hexFFD63031
                        : (tir >= 80
                              ? AppPalette.hexFF00B894
                              : AppPalette.hexFFE67E22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Key metrics row
          Row(
            children: [
              _buildMetricTile(
                'Avg Night Glucose',
                '$mean mg/dL',
                AppPalette.hexFF5E35B1,
              ),
              _buildMetricTile('Sleep TIR', '$tir%', AppPalette.hexFF00B894),
              _buildMetricTile(
                'Lowest Glucose',
                '$lowest mg/dL',
                lowest < 70 ? AppPalette.hexFFE74C3C : AppPalette.hexFF3498DB,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Clinical Detections
          if (isHypo || isDawn || isSomogyi) ...[
            const Divider(height: 1, color: AppPalette.hexFFECEAF4),
            const SizedBox(height: 12),
            if (isHypo)
              _buildClinicalBadge(
                'Nocturnal Hypoglycemia Alert',
                'Blood sugar dipped below ${data['nightLowThreshold']} mg/dL during sleep. Review evening insulin doses or snacks with your physician.',
                AppPalette.hexFFD63031,
                AppPalette.hexFFFFEBEE,
              ),
            if (isDawn)
              _buildClinicalBadge(
                ' Dawn Phenomenon Detected',
                'Morning glucose rose by ${data['dawnRiseMgDl']} mg/dL between 4 AM and wake time due to natural circadian hormones.',
                AppPalette.hexFFD35400,
                AppPalette.hexFFFDF2E9,
              ),
            if (isSomogyi)
              _buildClinicalBadge(
                'Somogyi Effect Indicated',
                'An overnight drop triggered a reactive morning spike. Avoid over-correcting with bedtime insulin.',
                AppPalette.hexFF8E44AD,
                AppPalette.hexFFF4ECF7,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppPalette.hexFFF7F5FC,
          borderRadius: AppRadii.r12,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppPalette.hexFF7E72A2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalBadge(
    String title,
    String body,
    Color primaryColor,
    Color bgColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: AppInsets.all12,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadii.r10,
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: primaryColor.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      padding: AppInsets.all18,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.r18,
        border: Border.all(color: AppPalette.hexFFECEAF4),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: AppInsets.all10,
                decoration: BoxDecoration(
                  color: AppPalette.hexFFEDE7F6,
                  borderRadius: AppRadii.r10,
                ),
                child: const Icon(
                  Icons.bedtime,
                  color: AppTheme.primaryPurple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Bedtime',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'When nighttime monitoring begins',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppPalette.hexFF7E72A2,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _selectTime(isBedTime: true),
                borderRadius: AppRadii.r8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.hexFFF5F3FB,
                    borderRadius: AppRadii.r8,
                    border: Border.all(color: AppPalette.hexFFD1C4E9),
                  ),
                  child: Text(
                    _formatTimeOfDay(_bedTime),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppPalette.hexFFECEAF4),
          Row(
            children: [
              Container(
                padding: AppInsets.all10,
                decoration: BoxDecoration(
                  color: AppPalette.hexFFFFF3E0,
                  borderRadius: AppRadii.r10,
                ),
                child: const Icon(
                  Icons.wb_sunny_rounded,
                  color: AppPalette.hexFFF39C12,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Wake Time',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'When morning evaluation concludes',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppPalette.hexFF7E72A2,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _selectTime(isBedTime: false),
                borderRadius: AppRadii.r8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.hexFFF5F3FB,
                    borderRadius: AppRadii.r8,
                    border: Border.all(color: AppPalette.hexFFD1C4E9),
                  ),
                  child: Text(
                    _formatTimeOfDay(_wakeTime),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdCard() {
    return Container(
      padding: AppInsets.all18,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.r18,
        border: Border.all(color: AppPalette.hexFFECEAF4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Night Low Glucose Alert',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Triggers loud warning during sleep',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppPalette.hexFF7E72A2,
                    ),
                  ),
                ],
              ),
              Text(
                '${_nightLow.toInt()} mg/dL',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.hexFFD63031,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppPalette.hexFFE74C3C,
              thumbColor: AppPalette.hexFFE74C3C,
              inactiveTrackColor: AppPalette.hexFFFADBD8,
            ),
            child: Slider(
              value: _nightLow,
              min: 55,
              max: 90,
              divisions: 35,
              onChanged: (v) => setState(() => _nightLow = v),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Night High Glucose Target',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Overnight upper boundary',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppPalette.hexFF7E72A2,
                    ),
                  ),
                ],
              ),
              Text(
                '${_nightHigh.toInt()} mg/dL',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.hexFFE67E22,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppPalette.hexFFE67E22,
              thumbColor: AppPalette.hexFFE67E22,
              inactiveTrackColor: AppPalette.hexFFFDEBD0,
            ),
            child: Slider(
              value: _nightHigh,
              min: 130,
              max: 220,
              divisions: 18,
              onChanged: (v) => setState(() => _nightHigh = v),
            ),
          ),
          const Divider(height: 24, color: AppPalette.hexFFECEAF4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Audible Nocturnal Alarms',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Plays emergency sound even in silent/DND mode for dangerous lows',
              style: TextStyle(fontSize: 12, color: AppPalette.hexFF7E72A2),
            ),
            activeThumbColor: AppTheme.primaryPurple,
            value: _nightAlerts,
            onChanged: (v) => setState(() => _nightAlerts = v),
          ),
        ],
      ),
    );
  }
}
