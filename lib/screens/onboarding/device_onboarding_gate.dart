import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/ui_perf.dart';
import '../../state/app_controller.dart';
import '../../widgets/pill_button.dart';
import 'pairing_guide_screen.dart';

/// Root gate for authenticated users who have not paired a CGM yet.
/// Offers pairing guide → device setup, or skip to Home for later setup.
class DeviceOnboardingGate extends StatefulWidget {
  const DeviceOnboardingGate({super.key, required this.controller});
  final AppController controller;

  @override
  State<DeviceOnboardingGate> createState() => _DeviceOnboardingGateState();
}

class _DeviceOnboardingGateState extends State<DeviceOnboardingGate> {
  bool _starting = false;
  bool _skipping = false;

  Future<void> _startSetup() async {
    if (_starting || _skipping || !mounted) return;
    setState(() => _starting = true);
    try {
      await openDeviceSetup(context, widget.controller);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _skipForLater() async {
    if (_starting || _skipping) return;
    setState(() => _skipping = true);
    try {
      await widget.controller.skipDeviceSetup();
    } finally {
      if (mounted) setState(() => _skipping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _starting || _skipping;
    final compact = UiPerf.isLowEndLayout(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, compact ? 20 : 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Set up your sensor',
                style: TextStyle(
                  fontSize: compact ? 24 : 26,
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
                onPressed: busy ? null : _startSetup,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: busy ? null : _skipForLater,
                child: Text(
                  _skipping ? 'Opening home…' : 'Skip this, I will set up later',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
