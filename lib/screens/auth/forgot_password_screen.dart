import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_theme.dart';
import '../../state/app_controller.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/pill_button.dart';

enum ForgotStep { enterEmail, enterCode, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.controller,
    this.initialEmail,
  });

  final AppController controller;
  final String? initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  ForgotStep _currentStep = ForgotStep.enterEmail;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // 6-digit OTP controllers and focus nodes
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String? _verifiedToken;

  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.trim().isNotEmpty) {
      _emailController.text = widget.initialEmail!.trim();
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = 45);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown > 1) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      }
    });
  }

  String get _otpCode => _otpControllers.map((c) => c.text.trim()).join();

  Future<void> _sendResetCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.controller.forgotPassword(email);
      if (!mounted) return;
      _startCooldown();
      setState(() {
        _currentStep = ForgotStep.enterCode;
        _errorMessage = null;
        _successMessage = 'A 6-digit code has been sent to your email.';
      });
      // Focus first OTP field
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _otpFocusNodes.isNotEmpty) {
          _otpFocusNodes[0].requestFocus();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _otpCode;
    final email = _emailController.text.trim();

    if (code.length < 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await widget.controller.verifyResetCode(email, code);
      if (!mounted) return;
      setState(() {
        _verifiedToken = token ?? code;
        _currentStep = ForgotStep.newPassword;
        _errorMessage = null;
        _successMessage = 'Code verified! Now choose your new password.';
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final newPassword = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final token = _verifiedToken ?? _otpCode;

    if (newPassword.length < 6) {
      setState(
        () => _errorMessage = 'Password must be at least 6 characters long.',
      );
      return;
    }
    if (newPassword != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.controller.resetPassword(
        email: email,
        token: token,
        newPassword: newPassword,
      );
      if (!mounted) return;

      // Show success dialog
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadii.r20),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.hexFFE8F8F0,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppPalette.hexFF00B894,
                  size: 44,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Password Reset!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your password has been successfully updated. You can now sign in with your new credentials.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.hexFF5E35B1,
                    shape: RoundedRectangleBorder(borderRadius: AppRadii.r28),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop(_emailController.text.trim());
                  },
                  child: const Text(
                    'Sign In Now',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(_emailController.text.trim());
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onBackTapped() {
    if (_currentStep == ForgotStep.newPassword) {
      setState(() => _currentStep = ForgotStep.enterCode);
    } else if (_currentStep == ForgotStep.enterCode) {
      setState(() => _currentStep = ForgotStep.enterEmail);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppPalette.hexFF5E35B1),
          onPressed: _onBackTapped,
        ),
        centerTitle: true,
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            color: AppPalette.hexFF5E35B1,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Step Icon
              _buildStepIcon(),

              const SizedBox(height: 24),

              // Title & Subtitle
              _buildHeaders(),

              const SizedBox(height: 28),

              // Error or Success Banner
              if (_errorMessage != null) ...[
                ErrorBanner(
                  _errorMessage!,
                  onClose: () => setState(() => _errorMessage = null),
                ),
                const SizedBox(height: 16),
              ],
              if (_successMessage != null && _errorMessage == null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.hexFFE8F8F0,
                    borderRadius: AppRadii.r10,
                    border: Border.all(
                      color: AppPalette.hexFF00B894.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppPalette.hexFF00B894,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(
                            color: AppPalette.hexFF007A5A,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Step specific form content
              if (_currentStep == ForgotStep.enterEmail)
                _buildEmailStep()
              else if (_currentStep == ForgotStep.enterCode)
                _buildCodeStep()
              else
                _buildPasswordStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIcon() {
    IconData icon;
    if (_currentStep == ForgotStep.enterEmail) {
      icon = Icons.lock;
    } else if (_currentStep == ForgotStep.enterCode) {
      icon = Icons.mark_email_read_outlined;
    } else {
      icon = Icons.lock_reset_rounded;
    }

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppPalette.hexFF5E35B1, width: 2.2),
      ),
      child: Center(child: Icon(icon, size: 42, color: AppPalette.hexFF5E35B1)),
    );
  }

  Widget _buildHeaders() {
    String title;
    String subtitle;

    switch (_currentStep) {
      case ForgotStep.enterEmail:
        title = 'Reset your password';
        subtitle =
            "No worries! Enter your email or phone number and we'll send you a reset code to get back into your account.";
        break;
      case ForgotStep.enterCode:
        title = 'Enter Verification Code';
        subtitle =
            "We've sent a 6-digit numeric verification code to:\n${_emailController.text.trim()}";
        break;
      case ForgotStep.newPassword:
        title = 'Create New Password';
        subtitle =
            'Your identity has been verified! Choose a strong password with at least 6 characters.';
        break;
    }

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppPalette.hexFF3B2A68,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppPalette.hexFF7E72A2,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  // --- Step 1: Enter Email ---
  Widget _buildEmailStep() {
    return Column(
      children: [
        CustomUnderlineField(
          controller: _emailController,
          label: 'Email Address',
          hintText: 'Enter your registered email',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) {
            if (_errorMessage != null) setState(() => _errorMessage = null);
          },
        ),
        const SizedBox(height: 36),
        PillButton(
          text: 'Send Reset Code',
          loading: _isLoading,
          onPressed: _sendResetCode,
        ),
        const SizedBox(height: 22),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Back to Sign In',
              style: TextStyle(
                color: AppPalette.hexFF5E35B1,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Step 2: 6-Digit Code Input ---
  Widget _buildCodeStep() {
    return Column(
      children: [
        // 6-digit PIN boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 46,
              height: 54,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.hexFF3B2A68,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppPalette.hexFFF7F6FB,
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadii.r12,
                    borderSide: const BorderSide(
                      color: AppPalette.hexFFD3CCE8,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadii.r12,
                    borderSide: const BorderSide(
                      color: AppPalette.hexFF5E35B1,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                  if (value.isNotEmpty) {
                    if (index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    } else {
                      _otpFocusNodes[index].unfocus();
                      if (_otpCode.length == 6) {
                        _verifyCode();
                      }
                    }
                  } else {
                    if (index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                  }
                },
              ),
            );
          }),
        ),

        const SizedBox(height: 32),
        PillButton(
          text: 'Verify Code',
          loading: _isLoading,
          onPressed: _verifyCode,
        ),
        const SizedBox(height: 20),

        // Resend countdown or button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Didn't get the code? ",
              style: TextStyle(color: AppPalette.hexFF7E72A2, fontSize: 13.5),
            ),
            GestureDetector(
              onTap: (_resendCooldown > 0 || _isLoading)
                  ? null
                  : _sendResetCode,
              child: Text(
                _resendCooldown > 0
                    ? 'Resend in ${_resendCooldown}s'
                    : 'Resend Code',
                style: TextStyle(
                  color: _resendCooldown > 0
                      ? AppPalette.hexFFA0AEC0
                      : AppPalette.hexFF5E35B1,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            setState(() {
              _currentStep = ForgotStep.enterEmail;
              _errorMessage = null;
            });
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Change Email Address',
              style: TextStyle(
                color: AppPalette.hexFF7E72A2,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Step 3: Set New Password ---
  Widget _buildPasswordStep() {
    return Column(
      children: [
        CustomUnderlineField(
          controller: _passwordController,
          label: 'New Password',
          hintText: 'Enter new password (min. 6 chars)',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppTheme.primaryPurple,
              size: 22,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          onChanged: (_) {
            if (_errorMessage != null) setState(() => _errorMessage = null);
          },
        ),
        const SizedBox(height: 22),
        CustomUnderlineField(
          controller: _confirmPasswordController,
          label: 'Confirm New Password',
          hintText: 'Re-enter your new password',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppTheme.primaryPurple,
              size: 22,
            ),
            onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
          onChanged: (_) {
            if (_errorMessage != null) setState(() => _errorMessage = null);
          },
        ),
        const SizedBox(height: 36),
        PillButton(
          text: 'Reset Password',
          loading: _isLoading,
          onPressed: _resetPassword,
        ),
      ],
    );
  }
}
