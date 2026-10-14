import 'dart:io';

import 'package:cgm_sdk/cgm_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Real machine smoking（Mac superior `flutter test integration_test -d <equipment>`）：Does not rely on sensors to verify
/// engine→Dart→JNI/.a Algorithm library, encryption library opening, local data interface, export, analysis, scanning permission path。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'SDK Real machine smoking：init → algorithmVersion → local data interface → Export → analyze',
    (t) async {
      await CgmSdk.init(
        config: const SdkConfig(minBatteryMv: 500, warmupMinutes: 15),
      );
      final v = await CgmSdk.algorithmVersion();
      // ignore: avoid_print
      print('SMOKE algorithmVersion=$v');
      expect(v, startsWith('V1.2.7'));
      expect(await CgmSdk.version(), cgmSdkVersion);

      final n = await CgmSdk.count();
      final rows = await CgmSdk.query(limit: 10);
      // ignore: avoid_print
      print(
        'SMOKE count=$n query=${rows.length} latest=${(await CgmSdk.latest())?.toMap()}',
      );
      expect(rows.length, lessThanOrEqualTo(10));

      final q = CgmSdk.parseQrCode(
        '1,CGM-E278CF00FD3B,-5,2.8632,-0.04,4,4,6,6,9,9',
      );
      expect(q.deviceId, 'E278CF00FD3B');
      await CgmSdk.setAlgoParams(q.calibration!);
      expect((await CgmSdk.getAlgoParams())?.tempCoef1, 2.8632);

      final csv = await CgmSdk.export();
      expect(File(csv).existsSync(), isTrue);
      final zip = await CgmSdk.exportDiagnostics();
      expect(File(zip).existsSync(), isTrue);
      // ignore: avoid_print
      print('SMOKE csv=$csv zip=$zip');

      expect(await CgmSdk.currentWear(), isNull);
      await expectLater(
        CgmSdk.connect(),
        throwsA(
          isA<CgmSdkException>().having(
            (e) => e.code,
            'code',
            CgmErrorCode.notBound,
          ),
        ),
      );

      // Scanning: Report when there is no authorization E_PERMISSION_DENIED / E_BLE_OFF，Don’t collapse
      try {
        final devs = await CgmSdk.scan(timeoutSeconds: 5).toList();
        // ignore: avoid_print
        print('SMOKE scan devices=${devs.map((d) => d.toMap())}');
      } on CgmSdkException catch (e) {
        // ignore: avoid_print
        print('SMOKE scan error=${e.code.code} ${e.message}');
      }
      await CgmSdk.dispose();
    },
  );
}
