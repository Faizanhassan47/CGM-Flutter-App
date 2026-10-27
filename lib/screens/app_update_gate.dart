import 'package:flutter/material.dart';
import '../services/app_update_service.dart';

class AppUpdateGate extends StatelessWidget {
  const AppUpdateGate({super.key, required this.policy});
  final AppUpdatePolicy policy;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.system_update_outlined,
                    size: 64,
                    color: Color(0xFFFF3B3B),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Update Required',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10203A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    policy.message.isEmpty
                        ? 'A newer version of Circle CGM is required. Please update your app to continue.'
                        : policy.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Installed ${policy.installedVersion}  •  Latest ${policy.latestVersion}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B3B),
                        padding: const EdgeInsets.all(16),
                      ),
                      onPressed: () => AppUpdateService.instance.launchUpdate(
                        policy,
                        mandatory: true,
                      ),
                      child: const Text('Update Now'),
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
