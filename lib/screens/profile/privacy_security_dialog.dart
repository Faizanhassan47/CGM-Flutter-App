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
  String? currentPasswordError;
  String? newPasswordError;
  String? confirmPasswordError;

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

    final currentError = requiresCurrentPassword && current.isEmpty
        ? 'Enter your current password.'
        : null;
    final newError = next.isEmpty
        ? 'Enter a new password.'
        : next.length < 6
        ? 'Password must contain at least 6 characters.'
        : null;
    final confirmError = confirm.isEmpty
        ? 'Confirm your new password.'
        : next != confirm
        ? 'Passwords do not match.'
        : null;

    setState(() {
      currentPasswordError = currentError;
      newPasswordError = newError;
      confirmPasswordError = confirmError;
    });

    if (currentError != null || newError != null || confirmError != null) {
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
      final message = e.toString();
      if (requiresCurrentPassword &&
          message.toLowerCase().contains('current password')) {
        setState(() => currentPasswordError = message);
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $message')));
    }
  }

  void _onDisableAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable Account?'),
        content: const Text(
          'Your account will be disabled and active sensors will stop. Your data will be retained. Register again with this email and complete your details to reactivate it.',
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
              'Disable',
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
        ).showSnackBar(SnackBar(content: Text('Disable failed: $e')));
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
                      errorText: currentPasswordError,
                      onChanged: (_) {
                        if (currentPasswordError != null) {
                          setState(() => currentPasswordError = null);
                        }
                      },
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
                    errorText: newPasswordError,
                    onChanged: (_) {
                      if (newPasswordError != null ||
                          confirmPasswordError != null) {
                        setState(() {
                          newPasswordError = null;
                          confirmPasswordError = null;
                        });
                      }
                    },
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
                    errorText: confirmPasswordError,
                    onChanged: (_) {
                      if (confirmPasswordError != null) {
                        setState(() => confirmPasswordError = null);
                      }
                    },
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

            // "Disable account" Card
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
                    'Disable account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.hexFFE11D48,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Temporarily disable your account. Your health data is retained and can be restored by completing registration again with this email.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textMuted,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 18),

                  PillButton(
                    variant: PillButtonVariant.danger,
                    text: 'Disable Account',
                    loading: widget.controller.loading,
                    onPressed: _onDisableAccount,
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
