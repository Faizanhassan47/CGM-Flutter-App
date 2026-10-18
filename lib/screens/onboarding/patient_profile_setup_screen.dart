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
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController dateOfBirthController;
  String? selectedGender;
  late String selectedUnit;
  late bool pushNotifications;
  late bool criticalAlerts;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.controller.fullName);
    emailController = TextEditingController(text: widget.controller.userEmail);
    phoneController = TextEditingController(
      text: widget.controller.phoneNumber,
    );
    dateOfBirthController = TextEditingController(
      text: widget.controller.dateOfBirth,
    );
    selectedGender = widget.controller.gender.trim().isEmpty
        ? null
        : widget.controller.gender;
    selectedUnit = widget.controller.preferredGlucoseUnit;
    pushNotifications = widget.controller.pushNotifications;
    criticalAlerts = widget.controller.criticalAlerts;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final existingDate = DateTime.tryParse(dateOfBirthController.text);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: existingDate ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (pickedDate == null) return;

    dateOfBirthController.text =
        '${pickedDate.year.toString().padLeft(4, '0')}-'
        '${pickedDate.month.toString().padLeft(2, '0')}-'
        '${pickedDate.day.toString().padLeft(2, '0')}';
  }

  void _onSaveAndContinue() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name.')));
      return;
    }
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your Google email is required.')),
      );
      return;
    }
    if (dateOfBirthController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth.')),
      );
      return;
    }
    if (selectedGender == null || selectedGender!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender.')),
      );
      return;
    }

    try {
      await widget.controller.saveProfile(
        name: name,
        phone: phoneController.text.trim(),
        dob: dateOfBirthController.text.trim(),
        selectedGender: selectedGender,
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

  Future<void> _onCancelAccountCreation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel account creation?'),
        content: const Text(
          'Your incomplete account will be permanently deleted and you will return to the sign-in screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep setting up'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.surface,
              elevation: 0,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await widget.controller.deleteAccount();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not cancel account creation: $error')),
      );
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
                label: 'Full Name',
                hintText: 'Enter your name',
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 20),

              CustomUnderlineField(
                controller: emailController,
                label: 'Google Account Email',
                hintText: 'Google account email',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                readOnly: true,
              ),
              const SizedBox(height: 20),

              CustomUnderlineField(
                controller: phoneController,
                label: 'Phone Number (Optional)',
                hintText: 'e.g. +1 (555) 000-0000',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              CustomUnderlineField(
                controller: dateOfBirthController,
                label: 'Date of Birth',
                hintText: 'YYYY-MM-DD',
                prefixIcon: Icons.calendar_month_outlined,
                readOnly: true,
                onTap: _pickDateOfBirth,
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                initialValue: selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.person_search_outlined),
                ),
                items: const ['Male', 'Female', 'Other', 'Prefer not to say']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => selectedGender = value),
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
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: widget.controller.loading
                    ? null
                    : _onCancelAccountCreation,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Cancel account creation'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.dangerDark,
                  minimumSize: const Size.fromHeight(44),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
