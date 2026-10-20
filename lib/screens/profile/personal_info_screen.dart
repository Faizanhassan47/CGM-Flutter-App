import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
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
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickAndUploadAvatar,
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryPurple,
                            width: 2.5,
                          ),
                          image: widget.controller.profilePictureUrl != null &&
                                  widget.controller.profilePictureUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(
                                    widget.controller.profilePictureUrl!,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: widget.controller.profilePictureUrl == null ||
                                widget.controller.profilePictureUrl!.isEmpty
                            ? const Icon(
                                Icons.person_outline_rounded,
                                color: AppTheme.primaryPurple,
                                size: 48,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAndUploadAvatar,
                        child: Container(
                          padding: AppInsets.all6,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryPurple,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 14,
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                label: 'Phone number',
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

  Future<void> _pickAndUploadAvatar() async {
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
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading profile photo...'),
          duration: Duration(seconds: 2),
        ),
      );

      await widget.controller.uploadProfilePicture(bytes, picked.name);

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload photo: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
