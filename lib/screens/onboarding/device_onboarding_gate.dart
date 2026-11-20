import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../state/app_controller.dart';
import '../../widgets/pill_button.dart';
import 'pairing_guide_screen.dart';

/// Root gate for authenticated users who have not paired a CGM yet.
/// Starts the pairing guide → device setup flow instead of Home.
class DeviceOnboardingGate extends StatefulWidget {
  const DeviceOnboardingGate({super.key, required this.controller});
  final AppController controller;

  @override
  State<DeviceOnboardingGate> createState() => _DeviceOnboardingGateState();
}

class _DeviceOnboardingGateState extends State<DeviceOnboardingGate> {
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startSetup();
    });
  }

  Future<void> _startSetup() async {
    if (_starting || !mounted) return;
    setState(() => _starting = true);
    try {
      await openDeviceSetup(context, widget.controller);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Set up your sensor',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.darkPurple,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Before you can see live glucose, apply your CGM and connect it to this phone.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              PillButton(
                text: 'Start device setup',
                loading: _starting,
                onPressed: _starting ? null : _startSetup,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
