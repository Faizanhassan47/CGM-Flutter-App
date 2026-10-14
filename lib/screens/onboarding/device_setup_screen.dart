import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cgm_sdk/cgm_sdk.dart';
import '../../core/app_theme.dart';
import '../../state/app_controller.dart';
import '../../widgets/pill_button.dart';

class DeviceSetupScreen extends StatefulWidget {
  const DeviceSetupScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen> {
  int currentStep = 1; // 1: Choose, 2: Pairing/Scan, 3: Ready
  String selectedType = 'Disposable'; // 'Disposable' | 'Reusable'
  final qrController = TextEditingController();
  bool showCamera = false;
  bool barcodeHandled = false;

  @override
  void initState() {
    super.initState();
    selectedType = widget.controller.selectedDeviceType;
  }

  @override
  void dispose() {
    qrController.dispose();
    super.dispose();
  }

  void _onConnectDevice() {
    setState(() {
      currentStep = 2;
    });
    widget.controller.scan();
  }

  void _onBindQr() async {
    final code = qrController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan or enter sensor QR code.')),
      );
      return;
    }

    try {
      await widget.controller.bindQr(code);
      setState(() {
        currentStep = 3;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Binding error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final isStepTwo = currentStep == 2;
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                isStepTwo ? Icons.close : Icons.arrow_back,
                color: AppTheme.darkPurple,
              ),
              onPressed: () {
                if (currentStep > 1) {
                  setState(() => currentStep--);
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: Text(
              isStepTwo ? 'Device Pairing' : 'Device Setup',
              style: const TextStyle(
                color: AppTheme.darkPurple,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            actions: [
              if (isStepTwo)
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.bluetooth,
                        size: 16,
                        color: AppTheme.primaryPurple,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'BLE',
                        style: TextStyle(
                          color: AppTheme.primaryPurple,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Center(
                    child: Text(
                      '$currentStep of 3',
                      style: const TextStyle(
                        color: AppTheme.darkPurple,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: currentStep == 1
                        ? _buildStepOne()
                        : currentStep == 2
                        ? _buildStepTwo()
                        : _buildStepThree(),
                  ),
                ),
                if (currentStep == 1) _buildBottomStepper(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepOne() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Choose Your CGM',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkPurple,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select the type of CGM device you will be using. You can change this later in Settings.',
          style: TextStyle(
            fontSize: 13.5,
            color: AppTheme.textMuted,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 24),

        // Device Selection Cards
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildDeviceCard(
                title: 'Disposable CGM',
                description:
                    'Wear for up to 14 days. Small, all-in-one sensor.',
                imagePath: 'assets/images/device_disposable.png',
                isSelected: selectedType == 'Disposable',
                onTap: () {
                  setState(() => selectedType = 'Disposable');
                  widget.controller.setDeviceType('Disposable');
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildDeviceCard(
                title: 'Reusable CGM',
                description:
                    'Wear with replaceable sensors. Rechargeable transmitter.',
                imagePath: 'assets/images/device_reusable.png',
                isSelected: selectedType == 'Reusable',
                onTap: () {
                  setState(() => selectedType = 'Reusable');
                  widget.controller.setDeviceType('Reusable');
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 36),

        // Bluetooth Connection Info
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: AppInsets.all6,
              decoration: const BoxDecoration(
                color: AppTheme.lightPurpleBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bluetooth,
                color: AppTheme.primaryPurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Bluetooth Connection',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkPurple,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Use Bluetooth to connect to your CGM device.',
                    style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        _buildChecklistItem(Icons.access_time_rounded, 'Turn on Bluetooth'),
        const SizedBox(height: 12),
        _buildChecklistItem(Icons.smartphone_rounded, 'Keep device nearby'),
        const SizedBox(height: 12),
        _buildChecklistItem(
          Icons.lock_outline_rounded,
          'Allow location & nearby permissions',
        ),

        const SizedBox(height: 36),
        PillButton(
          text: 'Connect Device',
          loading: widget.controller.loading,
          onPressed: _onConnectDevice,
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text(''),
          ),
        ),
      ],
    );
  }

  Widget _buildStepTwo() {
    final results = widget.controller.scanResults;
    if (results.isNotEmpty) {
      return _buildDeviceDetectedView(results);
    }
    return _buildScanningView();
  }

  /// Screen 1: Searching / Scanning state
  Widget _buildScanningView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        // Blue circle with Bluetooth icon
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            color: AppPalette.hexFF00B0FF,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.bluetooth, color: AppColors.surface, size: 44),
          ),
        ),
        const SizedBox(height: 60),

        // Scanning pill
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadii.r24,
            onTap: widget.controller.loading ? null : () => widget.controller.scan(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: AppRadii.r24,
                border: Border.all(color: AppPalette.hexFF7E57C2, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.controller.loading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryPurple,
                      ),
                    )
                  else
                    const Icon(
                      Icons.refresh,
                      size: 14,
                      color: AppTheme.primaryPurple,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    widget.controller.loading
                        ? 'SCANNING BLE CHANNELS'
                        : 'TAP TO SCAN AGAIN',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.hexFF512DA8,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Searching for nearby CGM...',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkPurple,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Keep your CGM close to your phone and ensure it is activated.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textMuted,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),

        // Checklist
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'PAIRING CHECKLIST',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkPurple.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildPairingChecklistItem(
          'Keep phone within 1 meter (3 ft) of sensor',
        ),
        const SizedBox(height: 12),
        _buildPairingChecklistItem('Ensure Bluetooth and Location are ON'),
        const SizedBox(height: 12),
        _buildPairingChecklistItem(
          'Press applicator button if applying new sensor',
        ),

        const SizedBox(height: 36),
        TextButton(
          onPressed: () {
            setState(() => currentStep = 1);
          },
          child: const Text(
            'Cancel Pairing',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.darkPurple,
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _showQrSheet,
          child: const Text(
            'Or pair via QR code',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  /// Screen 2: CGM Device Detected state
  Widget _buildDeviceDetectedView(List<ScanDevice> devices) {
    final device = devices.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 50),
        // Rounded square with checkmark
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.r24,
            border: Border.all(color: AppTheme.primaryPurple, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.check, color: AppTheme.primaryPurple, size: 48),
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'CGM Device Detected',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkPurple,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'A compatible Continuous Glucose Monitor is ready to connect.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textMuted,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),

        // Detected device card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.r16,
            border: Border.all(color: AppPalette.hexFFE2D9F3, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: AppRadii.r14,
                  border: Border.all(color: AppPalette.hexFFE2D9F3, width: 1.2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.wifi_tethering,
                    color: AppTheme.primaryPurple,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CGM Continuous Sensor',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.darkPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatEnding(device),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkPurple,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryPurple,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Strong Signal (${device.rssi} dBm)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 50),

        PillButton(
          text: 'Connect to This CGM',
          loading: widget.controller.loading,
          onPressed: () => _connectToDevice(device),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: () {
              widget.controller.scan();
            },
            child: const Text(
              'Scan Again',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkPurple,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  String _formatEnding(ScanDevice device) {
    final name = device.name;
    if (name.toLowerCase().endsWith('ator')) {
      return 'Ending in ator';
    }
    if (name.length >= 4) {
      return 'Ending in ${name.substring(name.length - 4).toLowerCase()}';
    }
    final id = device.deviceId;
    if (id.length >= 4) {
      return 'Ending in ${id.substring(id.length - 4).toLowerCase()}';
    }
    return 'Ending in $id';
  }

  Widget _buildPairingChecklistItem(String text) {
    return Row(
      children: [
        const Icon(Icons.check, size: 16, color: AppPalette.hexFF00BCD4),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.darkPurple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _connectToDevice(ScanDevice device) async {
    final dev = device.deviceId
        .replaceAll(':', '')
        .replaceAll('-', '')
        .toUpperCase();
    final payload = '1,CGM-$dev,-5,2.8632,-0.04,4,4,6,6,9,9';
    try {
      await widget.controller.bindQr(payload);
      if (!mounted) return;
      setState(() {
        currentStep = 3;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to connect: $e')));
    }
  }

  void _showQrSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Scan or Enter QR Code',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkPurple,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (showCamera) ...[
                    ClipRRect(
                      borderRadius: AppRadii.r16,
                      child: SizedBox(
                        height: 200,
                        child: MobileScanner(
                          onDetect: (capture) {
                            if (barcodeHandled || capture.barcodes.isEmpty) {
                              return;
                            }
                            final val = capture.barcodes.first.rawValue;
                            if (val != null) {
                              barcodeHandled = true;
                              qrController.text = val;
                              setModalState(() => showCamera = false);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  PillButton(
                    variant: PillButtonVariant.outlineCyan,
                    text: showCamera ? 'Close camera' : 'Open camera scanner',
                    icon: const Icon(
                      Icons.qr_code_scanner,
                      color: AppTheme.darkPurple,
                    ),
                    onPressed: () => setModalState(() {
                      showCamera = !showCamera;
                      barcodeHandled = false;
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qrController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Sensor QR Payload',
                      hintText: 'Paste sensor QR code payload',
                      border: OutlineInputBorder(borderRadius: AppRadii.r12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PillButton(
                    text: 'Bind & Connect',
                    onPressed: () {
                      Navigator.pop(ctx);
                      _onBindQr();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStepThree() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            color: AppPalette.hexFFDCFCE7,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppTheme.successGreen,
            size: 54,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Sensor Connected!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.darkPurple,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your continuous glucose monitor is linked and telemetry streaming is ready.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 36),
        PillButton(
          text: 'Go to Dashboard',
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ],
    );
  }

  Widget _buildDeviceCard({
    required String title,
    required String description,
    required String imagePath,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 260,
        padding: AppInsets.all14,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.r22,
          border: Border.all(
            color: isSelected ? AppTheme.primaryPurple : AppPalette.hexFFECEAF4,
            width: isSelected ? 2.2 : 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppTheme.darkPurple
                      : AppColors.transparent,
                  border: isSelected
                      ? null
                      : Border.all(color: AppPalette.hexFFD6D1E8, width: 1.5),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: AppColors.surface,
                      )
                    : null,
              ),
            ),
            const Spacer(),
            Image.asset(
              imagePath,
              height: 88,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.memory,
                size: 70,
                color: AppTheme.primaryPurple,
              ),
            ),
            const Spacer(),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkPurple,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppTheme.textMuted,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.darkPurple),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
        ),
        const Icon(Icons.check, size: 18, color: AppTheme.darkPurple),
      ],
    );
  }

  Widget _buildBottomStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppPalette.hexFFF0ECF8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStepItem(Icons.smartphone_rounded, 'Device', currentStep >= 1),
          _buildStepItem(Icons.bluetooth, 'Pairing', currentStep >= 2),
          _buildStepItem(Icons.check, 'Ready', currentStep >= 3),
        ],
      ),
    );
  }

  Widget _buildStepItem(IconData icon, String title, bool active) {
    final color = active ? AppTheme.darkPurple : AppPalette.hexFFABA7BE;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
