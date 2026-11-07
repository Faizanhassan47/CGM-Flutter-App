import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/app_config.dart';
import '../../core/app_theme.dart';

class PhoneReadiness {
  const PhoneReadiness({
    required this.bluetoothOn,
    required this.bluetoothAllowed,
    required this.networkOn,
    required this.notificationsOn,
    required this.compatible,
  });

  final bool bluetoothOn;
  final bool bluetoothAllowed;
  final bool networkOn;
  final bool notificationsOn;
  final bool compatible;

  bool get ready =>
      bluetoothOn &&
      bluetoothAllowed &&
      networkOn &&
      notificationsOn &&
      compatible;

  String get blockedReason {
    if (!compatible) return 'This phone cannot use Bluetooth sensors.';
    if (!bluetoothOn) return 'Turn Bluetooth on to continue.';
    if (!bluetoothAllowed) return 'Allow Bluetooth permission to continue.';
    if (!networkOn) return 'Connect to the internet to continue.';
    if (!notificationsOn) return 'Allow notifications to continue.';
    return '';
  }
}

Future<PhoneReadiness> readPhoneReadiness() async {
  var btOn = false;
  var btOk = false;
  var net = false;
  var notes = false;
  var compat = false;
  try {
    final adapter = await FlutterBluePlus.adapterState.first
        .timeout(const Duration(seconds: 2));
    btOn = adapter == BluetoothAdapterState.on;
    compat = await FlutterBluePlus.isSupported;
  } catch (_) {}
  try {
    if (Platform.isAndroid) {
      final scan = await Permission.bluetoothScan.status;
      final connect = await Permission.bluetoothConnect.status;
      btOk = scan.isGranted && connect.isGranted;
    } else {
      btOk = (await Permission.bluetooth.status).isGranted;
    }
    notes = (await Permission.notification.status).isGranted;
  } catch (_) {}
  try {
    final host = Uri.parse(AppConfig.apiBaseUrl).host;
    final result = await InternetAddress.lookup(host)
        .timeout(const Duration(seconds: 3));
    net = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } catch (_) {}
  return PhoneReadiness(
    bluetoothOn: btOn,
    bluetoothAllowed: btOk,
    networkOn: net,
    notificationsOn: notes,
    compatible: compat,
  );
}

class SystemSelfCheck extends StatefulWidget {
  const SystemSelfCheck({super.key, required this.onContinue});
  final VoidCallback onContinue;

  @override
  State<SystemSelfCheck> createState() => _SystemSelfCheckState();
}

class _Check {
  _Check({
    required this.title,
    required this.detail,
    required this.ok,
    required this.required,
    required this.onTap,
  });
  final String title;
  final String detail;
  final bool ok;
  final bool required;
  final VoidCallback onTap;
}

class _SystemSelfCheckState extends State<SystemSelfCheck>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool bluetoothOn = false;
  bool bluetoothAllowed = false;
  bool networkOn = false;
  bool notificationsOn = false;
  bool compatible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final result = await readPhoneReadiness();
    if (!mounted) return;
    setState(() {
      bluetoothOn = result.bluetoothOn;
      bluetoothAllowed = result.bluetoothAllowed;
      networkOn = result.networkOn;
      notificationsOn = result.notificationsOn;
      compatible = result.compatible;
    });
  }

  Future<void> _ask(Permission permission) async {
    final status = await permission.status;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      final next = await permission.request();
      if (next.isPermanentlyDenied) await openAppSettings();
    }
    await _refresh();
  }

  bool get _ready =>
      bluetoothOn &&
      bluetoothAllowed &&
      networkOn &&
      notificationsOn &&
      compatible;

  @override
  Widget build(BuildContext context) {
    final checks = <_Check>[
      _Check(
        title: 'Enable bluetooth',
        detail: bluetoothOn
            ? 'Bluetooth is on and nearby-device access is granted.'
            : 'Turn on Bluetooth and allow nearby devices so the sensor can connect.',
        ok: bluetoothOn && bluetoothAllowed,
        required: true,
        onTap: () async {
          if (!bluetoothAllowed) {
            if (Platform.isAndroid) {
              await _ask(Permission.bluetoothScan);
              await _ask(Permission.bluetoothConnect);
            } else {
              await _ask(Permission.bluetooth);
            }
          } else {
            try {
              await FlutterBluePlus.turnOn();
            } catch (_) {}
          }
        },
      ),
      _Check(
        title: 'Enable network',
        detail: 'Needed to sign in and link a CGM sensor.',
        ok: networkOn,
        required: true,
        onTap: _refresh,
      ),
      _Check(
        title: 'Enable notifications',
        detail: 'Needed for glucose alerts and sensor messages.',
        ok: notificationsOn,
        required: true,
        onTap: () => _ask(Permission.notification),
      ),
      _Check(
        title: 'Compatibility',
        detail: compatible
            ? 'This phone can use Bluetooth Low Energy.'
            : 'This phone does not support Bluetooth Low Energy.',
        ok: compatible,
        required: true,
        onTap: _refresh,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Please complete these checks so the phone can connect to your CGM sensor.',
          style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            children: [
              for (var i = 0; i < 4; i++) ...[
                _row(checks[i]),
                if (i < 3) const Divider(height: 1),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () async {
            final result = await readPhoneReadiness();
            if (!mounted) return;
            setState(() {
              bluetoothOn = result.bluetoothOn;
              bluetoothAllowed = result.bluetoothAllowed;
              networkOn = result.networkOn;
              notificationsOn = result.notificationsOn;
              compatible = result.compatible;
            });
            if (!result.ready) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result.blockedReason)),
              );
              return;
            }
            widget.onContinue();
          },
          style: FilledButton.styleFrom(
            backgroundColor: _ready ? AppColors.primary : AppColors.surfaceBorder,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _row(_Check check) {
    final icon = check.ok
        ? Icons.check_circle
        : (check.required ? Icons.error : Icons.circle_outlined);
    final color = check.ok
        ? AppColors.success
        : (check.required ? AppColors.danger : AppColors.textSecondary);
    return InkWell(
      onTap: check.onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(check.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(check.detail, style: const TextStyle(fontSize: 12.5, height: 1.3, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
