import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../state/app_controller.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/pill_button.dart';

class PrivacySecurityModal extends StatefulWidget {
  const PrivacySecurityModal({super.key, required this.controller});
  final AppController controller;

  static void show(BuildContext context, AppController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => PrivacySecurityModal(controller: controller),
    );
  }

  @override
  State<PrivacySecurityModal> createState() => _PrivacySecurityModalState();
}

class _PrivacySecurityModalState extends State<PrivacySecurityModal> {
  final currentPwController = TextEditingController();
  final newPwController = TextEditingController();
  final confirmPwController = TextEditingController();

  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  bool get requiresCurrentPassword => widget.controller.hasPassword;

  @override
  void dispose() {
    currentPwController.dispose();
    newPwController.dispose();
    confirmPwController.dispose();
    super.dispose();
  }

  void _onChangePassword() async {
    final isSettingFirstPassword = !requiresCurrentPassword;
    final current = currentPwController.text;
    final next = newPwController.text;
    final confirm = confirmPwController.text;

    if ((requiresCurrentPassword && current.isEmpty) || next.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out password fields.')),
      );
      return;
    }
    if (next.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 6 characters.'),
        ),
      );
      return;
    }
    if (next != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match.')),
      );
      return;
    }

    try {
      await widget.controller.changePassword(
        requiresCurrentPassword ? current : null,
        next,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSettingFirstPassword
                  ? 'Password set successfully!'
                  : 'Password changed successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  void _onDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action is irreversible. All your glucose and health data will be deleted permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.surface),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.controller.deleteAccount();
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Privacy & Security',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      requiresCurrentPassword
                          ? 'Change your password or manage your\naccount.'
                          : 'Set a password or manage your\naccount.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppTheme.darkPurple,
                    size: 24,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // "Change password" Card
            Container(
              padding: AppInsets.all20,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.r22,
                border: Border.all(color: AppPalette.hexFFEFEBF6, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    requiresCurrentPassword
                        ? 'Change password'
                        : 'Set password',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkPurple,
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (requiresCurrentPassword) ...[
                    CustomUnderlineField(
                      controller: currentPwController,
                      label: 'Current password',
                      hintText: 'Enter current password',
                      obscureText: obscureCurrent,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureCurrent
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.primaryPurple,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  CustomUnderlineField(
                    controller: newPwController,
                    label: 'New password',
                    hintText: 'At least 6 characters',
                    obscureText: obscureNew,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppTheme.primaryPurple,
                        size: 20,
                      ),
                      onPressed: () => setState(() => obscureNew = !obscureNew),
                    ),
                  ),
                  const SizedBox(height: 18),

                  CustomUnderlineField(
                    controller: confirmPwController,
                    label: 'Confirm new password',
                    hintText: 'Enter new password again',
                    obscureText: obscureConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppTheme.primaryPurple,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                  const SizedBox(height: 24),

                  PillButton(
                    text: requiresCurrentPassword
                        ? 'Change Password'
                        : 'Set Password',
                    loading: widget.controller.loading,
                    onPressed: _onChangePassword,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // "Delete account" Card
            Container(
              padding: AppInsets.all20,
              decoration: BoxDecoration(
                color: AppPalette.hexFFFFF1F2,
                borderRadius: AppRadii.r22,
                border: Border.all(color: AppPalette.hexFFFFE4E6, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Delete account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.hexFFE11D48,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Permanently remove your account and all associated health data.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textMuted,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 18),

                  PillButton(
                    variant: PillButtonVariant.danger,
                    text: 'Delete Account',
                    loading: widget.controller.loading,
                    onPressed: _onDeleteAccount,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
