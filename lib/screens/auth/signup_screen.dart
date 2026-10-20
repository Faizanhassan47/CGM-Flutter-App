import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/app_theme.dart';
import '../../state/app_controller.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/pill_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final dateOfBirthController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String? selectedGender;

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool agreeTerms = false;
  String? validationError;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    dateOfBirthController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 30),
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

  void _onRegister() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;

    if (name.isEmpty) {
      setState(() => validationError = 'Please enter your full name.');
      return;
    }
    if (email.isEmpty) {
      setState(() => validationError = 'Please enter your email address.');
      return;
    }
    if (password.length < 6) {
      setState(
        () => validationError = 'Password must be at least 6 characters.',
      );
      return;
    }
    if (password != confirm) {
      setState(() => validationError = 'Passwords do not match.');
      return;
    }
    if (!agreeTerms) {
      setState(
        () => validationError =
            'Please agree to the Terms of Service and Privacy Policy.',
      );
      return;
    }

    setState(() => validationError = null);
    try {
      await widget.controller.register(
        name,
        email,
        password,
        phone: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        dob: dateOfBirthController.text.trim().isEmpty
            ? null
            : dateOfBirthController.text.trim(),
        selectedGender: selectedGender,
      );
      if (mounted && widget.controller.authenticated) {
        Navigator.of(context).pop();
      }
    } catch (_) {}
  }

  void _onGoogleSignIn() async {
    setState(() => validationError = null);
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId:
            '203000957883-r5lchnrp5e9mq03dt95fb0qg64io5hrg.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) return;
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        setState(() => validationError = 'Could not obtain Google ID token.');
        return;
      }
      await widget.controller.googleLogin(
        idToken: idToken,
        fullName: account.displayName,
        email: account.email,
        photoUrl: account.photoUrl,
      );
      if (mounted && widget.controller.authenticated) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() => validationError = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = validationError ?? widget.controller.error;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  const BrandHeader(),
                  const SizedBox(height: 32),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: AppInsets.all6,
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppTheme.primaryPurple,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.darkPurple,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Create your account to securely access your glucose insights.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  if (errorMessage != null && errorMessage.isNotEmpty)
                    ErrorBanner(
                      errorMessage,
                      onClose: () {
                        setState(() => validationError = null);
                        widget.controller.clearError();
                      },
                    ),

                  const SizedBox(height: 8),
                  CustomUnderlineField(
                    controller: nameController,
                    label: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 20),

                  CustomUnderlineField(
                    controller: emailController,
                    label: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  CustomUnderlineField(
                    controller: phoneController,
                    label: 'Phone Number (Optional)',
                    hintText: 'Enter phone number',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),

                  CustomUnderlineField(
                    controller: dateOfBirthController,
                    label: 'Date of Birth (Optional)',
                    hintText: 'YYYY-MM-DD',
                    prefixIcon: Icons.calendar_month_outlined,
                    readOnly: true,
                    onTap: _pickDateOfBirth,
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    initialValue: selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender (Optional)',
                      prefixIcon: Icon(Icons.person_search_outlined),
                    ),
                    items:
                        const ['Male', 'Female', 'Other', 'Prefer not to say']
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) =>
                        setState(() => selectedGender = value),
                  ),
                  const SizedBox(height: 20),

                  CustomUnderlineField(
                    controller: passwordController,
                    label: 'Password',
                    hintText: 'Create a password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppTheme.primaryPurple,
                        size: 22,
                      ),
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 20),

                  CustomUnderlineField(
                    controller: confirmPasswordController,
                    label: 'Confirm Password',
                    hintText: 'Confirm your password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppTheme.primaryPurple,
                        size: 22,
                      ),
                      onPressed: () => setState(
                        () => obscureConfirmPassword = !obscureConfirmPassword,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Terms checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: agreeTerms,
                          activeColor: AppTheme.primaryPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadii.r4,
                          ),
                          side: const BorderSide(
                            color: AppTheme.primaryPurple,
                            width: 1.8,
                          ),
                          onChanged: (val) =>
                              setState(() => agreeTerms = val ?? false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'I agree to the Terms of Service and Privacy Policy',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  PillButton(
                    text: 'Create Account',
                    loading: widget.controller.loading,
                    onPressed: _onRegister,
                  ),

                  const SizedBox(height: 18),
                  Row(
                    children: const [
                      Expanded(child: Divider(color: AppPalette.hexFFECEAF4)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'or',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppPalette.hexFFECEAF4)),
                    ],
                  ),

                  const SizedBox(height: 18),
                  PillButton(
                    variant: PillButtonVariant.outlineCyan,
                    text: 'Continue with Google',
                    icon: SvgPicture.asset(
                      'assets/images/google_g.svg',
                      width: 20,
                      height: 20,
                    ),
                    onPressed: _onGoogleSignIn,
                  ),

                  const SizedBox(height: 26),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: AppTheme.darkPurple,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
