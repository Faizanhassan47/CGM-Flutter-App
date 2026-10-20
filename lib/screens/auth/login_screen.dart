import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/app_theme.dart';
import '../../state/app_controller.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/pill_button.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;
  String? validationError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _onSignIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      setState(() => validationError = 'Please enter your email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => validationError = 'Please enter your password.');
      return;
    }

    setState(() => validationError = null);
    try {
      await widget.controller.login(email, password);
    } catch (_) {
      // widget.controller.error has message
    }
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
    } catch (e) {
      setState(() => validationError = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only display auth/validation errors on login screen, not background SDK/BLE errors
    final errorMessage = validationError;

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
                  const SizedBox(height: 38),

                  // Welcome back!
                  Row(
                    children: const [
                      Text(
                        'Welcome back!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkPurple,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('👋', style: TextStyle(fontSize: 22)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to continue to your dashboard.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Error banner matching screenshot
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
                    controller: emailController,
                    label: 'Email',
                    hintText: 'you@example.com',
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 22),
                  CustomUnderlineField(
                    controller: passwordController,
                    label: 'Password',
                    hintText: 'Enter your password',
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

                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () async {
                        setState(() => validationError = null);
                        final resetEmail = await Navigator.of(context)
                            .push<String>(
                              MaterialPageRoute(
                                builder: (_) => ForgotPasswordScreen(
                                  controller: widget.controller,
                                  initialEmail: emailController.text.trim(),
                                ),
                              ),
                            );
                        if (resetEmail != null &&
                            resetEmail.isNotEmpty &&
                            mounted) {
                          emailController.text = resetEmail;
                          passwordController.clear();
                        }
                      },
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: AppTheme.darkPurple,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  PillButton(
                    text: 'Sign In',
                    loading: widget.controller.loading,
                    onPressed: _onSignIn,
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
                          "Don't have an account? ",
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    SignupScreen(controller: widget.controller),
                              ),
                            );
                          },
                          child: const Text(
                            'Create Account',
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

                  const SizedBox(height: 40),
                  // Security footer matching screenshot 091529
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(
                        Icons.shield_outlined,
                        color: AppTheme.primaryPurple,
                        size: 24,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your health data is secure',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.darkPurple,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'We protect your privacy and keep your data safe at all times.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textMuted,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
