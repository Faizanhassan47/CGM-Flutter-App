import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../state/app_controller.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/pill_button.dart';

/// 6-digit email verification after signup (same UX as forgot-password code step).
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.controller,
    required this.email,
  });

  final AppController controller;
  final String email;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _otpFocusNodes.isNotEmpty) {
        _otpFocusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text.trim()).join();

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = 300);
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

  Future<void> _verifyCode() async {
    final code = _otpCode;
    if (code.length < 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit code.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.controller.verifyEmailCode(widget.email, code);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await widget.controller.resendEmailVerificationCode(widget.email);
      if (!mounted) return;
      _startCooldown();
      setState(() {
        _successMessage = 'A new 6-digit code has been sent to your email.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppPalette.hexFF5E35B1,
                        width: 2.2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.mark_email_read_outlined,
                        size: 42,
                        color: AppPalette.hexFF5E35B1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Enter Verification Code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.hexFF3B2A68,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "We've sent a 6-digit numeric verification code to:\n${widget.email}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppPalette.hexFF7E72A2,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_errorMessage != null && _errorMessage!.isNotEmpty)
                    ErrorBanner(
                      _errorMessage!,
                      onClose: () => setState(() => _errorMessage = null),
                    ),
                  if (_successMessage != null && _successMessage!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _successMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF166534),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
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
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
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
                            } else if (index > 0) {
                              _otpFocusNodes[index - 1].requestFocus();
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
                    onPressed: _isLoading ? null : _verifyCode,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Didn't get the code? ",
                        style: TextStyle(
                          color: AppPalette.hexFF7E72A2,
                          fontSize: 13.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: (_resendCooldown > 0 || _isLoading)
                            ? null
                            : _resendCode,
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
                  const SizedBox(height: 22),
                  GestureDetector(
                    onTap: () => widget.controller.cancelEmailVerification(),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
