import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../state/app_controller.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pill_button.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController dateOfBirthController;
  String? selectedGender;

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
    selectedGender = widget.controller.gender.isEmpty
        ? null
        : widget.controller.gender;
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
    final existing = DateTime.tryParse(dateOfBirthController.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: existing ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) {
      dateOfBirthController.text =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    }
  }

  void _onSave() async {
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    try {
      await widget.controller.saveProfile(
        name: name,
        phone: phoneController.text.trim(),
        dob: dateOfBirthController.text.trim().isEmpty
            ? null
            : dateOfBirthController.text.trim(),
        selectedGender: selectedGender,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personal information updated!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
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
          'Personal Info',
          style: TextStyle(
            color: AppTheme.darkPurple,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              CustomUnderlineField(
                controller: nameController,
                label: 'Full name',
                hintText: 'Enter your full name',
              ),
              const SizedBox(height: 28),

              CustomUnderlineField(
                controller: emailController,
                label: 'Email',
                hintText: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                readOnly: true,
              ),
              const SizedBox(height: 28),

              CustomUnderlineField(
                controller: phoneController,
                label: 'Patient phone number',
                hintText: 'Enter phone number',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 28),

              CustomUnderlineField(
                controller: dateOfBirthController,
                label: 'Date of birth',
                hintText: 'YYYY-MM-DD',
                readOnly: true,
                onTap: _pickDateOfBirth,
              ),
              const SizedBox(height: 28),

              DropdownButtonFormField<String>(
                initialValue: selectedGender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const ['Male', 'Female', 'Other', 'Prefer not to say']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => selectedGender = value),
              ),
              const SizedBox(height: 40),

              PillButton(
                variant: PillButtonVariant.cyan,
                text: 'Save personal information',
                loading: widget.controller.loading,
                onPressed: _onSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
