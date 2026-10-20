import 'package:cgm_sdk/cgm_sdk.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding/patient_profile_setup_screen.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'state/app_controller.dart';
import 'widgets/brand_header.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[Firebase] Startup initialization note: $e');
  }

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

  runApp(const CircleApp());
}

class CircleApp extends StatefulWidget {
  const CircleApp({super.key});

  @override
  State<CircleApp> createState() => _CircleAppState();
}

class _CircleAppState extends State<CircleApp> {
  late final AppController controller = AppController(ApiService());

  @override
  void initState() {
    super.initState();
    controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Circle',
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

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandHeader(),
                SizedBox(height: 36),
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                    strokeWidth: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
