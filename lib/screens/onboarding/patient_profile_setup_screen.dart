import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../state/app_controller.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pill_button.dart';
import 'device_setup_screen.dart';

class PatientProfileSetupScreen extends StatefulWidget {
  const PatientProfileSetupScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<PatientProfileSetupScreen> createState() =>
      _PatientProfileSetupScreenState();
}

class _PatientProfileSetupScreenState extends State<PatientProfileSetupScreen> {
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late String selectedUnit;
  late bool pushNotifications;
  late bool criticalAlerts;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.controller.fullName);
    phoneController = TextEditingController(
      text: widget.controller.phoneNumber,
    );
    selectedUnit = widget.controller.preferredGlucoseUnit;
    pushNotifications = widget.controller.pushNotifications;
    criticalAlerts = widget.controller.criticalAlerts;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _onSaveAndContinue() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name.')));
      return;
    }

    try {
      await widget.controller.saveProfile(
        name: name,
        phone: phoneController.text.trim(),
        unit: selectedUnit,
      );
      await widget.controller.setPreferences(
        push: pushNotifications,
        critical: criticalAlerts,
      );

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DeviceSetupScreen(controller: widget.controller),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Set Up Your Patient Profile',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkPurple,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Personalize your CGM experience and monitoring preferences.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 32),

              CustomUnderlineField(
                controller: nameController,
                label: 'Your Name',
                hintText: 'Enter your name',
              ),
              const SizedBox(height: 28),

              CustomUnderlineField(
                controller: phoneController,
                label: 'Phone Number (Optional)',
                hintText: 'e.g. +1 (555) 000-0000',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 28),

              const Text(
                'Preferred Glucose Unit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkPurple,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildUnitCard(
                      title: 'mg/dL',
                      subtitle: 'Standard US/Intl',
                      isSelected: selectedUnit == 'mg/dL',
                      onTap: () => setState(() => selectedUnit = 'mg/dL'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildUnitCard(
                      title: 'mmol/L',
                      subtitle: 'UK / Canada / EU',
                      isSelected: selectedUnit == 'mmol/L',
                      onTap: () => setState(() => selectedUnit = 'mmol/L'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),
              const Text(
                'Monitoring & Alert Preferences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkPurple,
                ),
              ),
              const SizedBox(height: 18),

              _buildPreferenceSwitch(
                title: 'Push Notifications',
                subtitle: 'Receive background glucose sync alerts',
                value: pushNotifications,
                onChanged: (val) => setState(() => pushNotifications = val),
              ),
              const SizedBox(height: 20),

              _buildPreferenceSwitch(
                title: 'Critical Glucose Alerts',
                subtitle: 'Urgent low and high threshold alerts',
                value: criticalAlerts,
                onChanged: (val) => setState(() => criticalAlerts = val),
              ),

              const SizedBox(height: 48),
              PillButton(
                text: 'Save & Continue to Device Setup',
                loading: widget.controller.loading,
                onPressed: _onSaveAndContinue,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : AppColors.surface,
          borderRadius: AppRadii.r16,
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : AppPalette.hexFFE5DCF4,
            width: isSelected ? 2 : 1.2,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? AppTheme.darkPurple
                        : AppTheme.textMuted,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.check,
                    size: 18,
                    color: AppTheme.primaryPurple,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppTheme.darkPurple : AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
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
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        Transform.scale(
          scale: 0.9,
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
