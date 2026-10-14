import 'package:cgm_sdk/cgm_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Full chain of real devices (need to be nearby CGM Transmitter, Bluetooth permission has been granted）：
/// `flutter test integration_test/sdk_device_test.dart -d <equipment> --dart-define=CGM_DEVICE=<12bit device number>`
/// scan → bind（beforeActivate release）→ deviceInfo → wait glucose / deviceStatus event → query → unbind。
/// Current when the device is not close to the body≈0，The blood sugar value itself does not count, what is tested is the link: connection, activation, frame collection, algorithm, drop-in, and event。
const String kTarget = String.fromEnvironment(
  'CGM_DEVICE',
  defaultValue: 'E278B831FDBF',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  void p(String s) {
    // ignore: avoid_print
    print('DEVICE $s');
  }

  testWidgets('scan → bind → event → unbind', (t) async {
    await CgmSdk.init(
      config: const SdkConfig(minBatteryMv: 500, warmupMinutes: 15),
    );
    p('algorithmVersion=${await CgmSdk.algorithmVersion()}');
    final glucose = <GlucoseSample>[];
    final events = <String>[];
    final subs = [
      CgmSdk.connectionState.listen((s) => events.add('conn:${s.name}')),
      CgmSdk.deviceStatus.listen(
        (s) => events.add(
          'status:even=${s.connected} ${s.batteryMv}mV seq=${s.latestSeq} Preheat leftover${s.warmupRemainingMin} abnormal=${s.abnormal}',
        ),
      ),
      CgmSdk.glucose.listen((s) {
        glucose.add(s);
        events.add(
          'glucose:${s.value} seq=${s.seq} ${s.source} I=${s.rawCurrent} V=${s.voltage}',
        );
      }),
      CgmSdk.algoResult.listen(
        (a) => events.add('algo:seq=${a.seq} k=${a.sensitivityUsed}'),
      ),
      CgmSdk.progress.listen(
        (x) => events.add('progress:${x.kind} ${x.done}/${x.total}'),
      ),
      CgmSdk.error.listen((e) => events.add('error:${e.code} ${e.message}')),
    ];

    // If there are any old ones on site, clear them out first to ensure that they never bind walk through
    if (await CgmSdk.currentWear() != null) {
      await CgmSdk.unbind();
      p('Cleared out old wear');
    }

    final found = <ScanDevice>[];
    try {
      await for (final d in CgmSdk.scan(timeoutSeconds: 15)) {
        found.add(d);
        p('scan Discover ${d.name} ${d.bleId} ${d.rssi}dBm');
      }
    } on CgmSdkException catch (e) {
      p('scan Report an error ${e.code.code} ${e.message}');
    }
    p(
      'scan common ${found.length} platform, target $kTarget ${found.any((d) => d.deviceId == kTarget) ? "exist" : "Not here"}list',
    );

    BindCheck? check;
    final sw = Stopwatch()..start();
    final wear = await CgmSdk.bind(
      deviceId: kTarget,
      form: 'full',
      calibration: const AlgoParams(
        tempCoef1: 2.8632,
        tempCoef2: -0.04,
        bgmBase: 6.8,
      ),
      beforeActivate: (c) async {
        check = c;
        p(
          'beforeActivate Voltage=${c.batteryMv}mV In use=${c.inUse} addr=${c.bluetoothAddr}',
        );
        return const BeforeActivateResult.proceed(wearId: 20260915);
      },
    );
    p(
      'bind time ${sw.elapsed.inSeconds}s → wear=${wear.wearId} ${wear.deviceId} ${wear.form} activation ${wear.activatedAt} preheat to ${wear.warmupEndAt}',
    );
    expect(check, isNotNull);
    expect(wear.wearId, 20260915);
    expect((await CgmSdk.currentWear())?.wearId, 20260915);

    try {
      final info = await CgmSdk.deviceInfo();
      p(
        'deviceInfo fw=${info.firmware} ${info.batteryMv}mV seq=${info.latestSeq} Under test=${info.measuring} Tested${info.measuredSec}s',
      );
    } on CgmSdkException catch (e) {
      p('deviceInfo Report an error ${e.code.code} ${e.message}');
    }

    // Device one frame per minute, wait up to 200 See the first blood sugar event in seconds
    final deadline = DateTime.now().add(const Duration(seconds: 200));
    while (glucose.isEmpty && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 5));
    }
    p(
      'wait ${sw.elapsed.inSeconds}s back glucose event ${glucose.length} strip',
    );
    for (final e in events) {
      p('  event $e');
    }
    p(
      'count=${await CgmSdk.count()} latest=${(await CgmSdk.latest())?.toMap()}',
    );
    expect(
      glucose,
      isNotEmpty,
      reason:
          'After binding 200 At least one blood glucose reading should be calculated within seconds (the device has one frame per minute）',
    );

    await CgmSdk.unbind();
    expect(await CgmSdk.currentWear(), isNull);
    p('unbind Finish');
    for (final s in subs) {
      await s.cancel();
    }
    await CgmSdk.dispose();
  }, timeout: const Timeout(Duration(minutes: 8)));
}
