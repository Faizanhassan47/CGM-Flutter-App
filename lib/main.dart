import 'package:cgm_sdk/cgm_sdk.dart';
import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding/patient_profile_setup_screen.dart';
import 'services/api_service.dart';
import 'state/app_controller.dart';
import 'widgets/brand_header.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // In release APKs, Flutter defaults to a blank/white container on unhandled errors.
  // This custom ErrorWidget ensures any startup error is visibly readable instead of a white screen.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Application Startup Error',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    details.exceptionAsString(),
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    details.stack?.toString() ?? '',
                    style: const TextStyle(color: Colors.black54, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  };

  runApp(const AimaApp());
}

class AimaApp extends StatefulWidget {
  const AimaApp({super.key});

  @override
  State<AimaApp> createState() => _AimaAppState();
}

class _AimaAppState extends State<AimaApp> {
  late final AppController controller = AppController(ApiService());

  @override
  void initState() {
    super.initState();
    controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aima',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.loading && !controller.sdkReady) {
            return const SplashView();
          }
          if (!controller.authenticated) {
            return LoginScreen(controller: controller);
          }
          if (!controller.profileCompleted && controller.wear == null) {
            return PatientProfileSetupScreen(controller: controller);
          }
          return MainShell(controller: controller);
        },
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    CgmSdk.dispose();
    super.dispose();
  }
}

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandHeader(),
            SizedBox(height: 36),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
