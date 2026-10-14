import 'package:cgm_sdk/cgm_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Real machine ”restarts” App automatic recovery」：bind → receive blood sugar → dispose（when App killed）→ Again init →
/// currentWear still、SDK Automatically reconnect and continue to deliver blood sugar (including replenishment)）→ unbind。
/// `flutter test integration_test/sdk_restart_test.dart -d <equipment> --dart-define=CGM_DEVICE=<Device number>`
const String kTarget = String.fromEnvironment(
  'CGM_DEVICE',
  defaultValue: 'E278B831FDBF',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  void p(String s) {
    // ignore: avoid_print
    print('RESTART $s');
  }

  Future<List<GlucoseSample>> waitGlucose(
    Duration max,
    List<String> events,
  ) async {
    final got = <GlucoseSample>[];
    final subs = [
      CgmSdk.glucose.listen(got.add),
      CgmSdk.connectionState.listen((s) => events.add('conn:${s.name}')),
      CgmSdk.progress.listen(
        (x) => events.add('progress:${x.kind} ${x.done}/${x.total}'),
      ),
      CgmSdk.error.listen((e) => events.add('error:${e.code} ${e.message}')),
    ];
    final deadline = DateTime.now().add(max);
    while (got.isEmpty && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 5));
    }
    for (final s in subs) {
      await s.cancel();
    }
    return got;
  }

  testWidgets(
    'bind → dispose → init automatic recovery → Continue to produce blood sugar → unbind',
    (t) async {
      const cfg = SdkConfig(minBatteryMv: 500, warmupMinutes: 15);
      await CgmSdk.init(config: cfg);
      if (await CgmSdk.currentWear() != null) await CgmSdk.unbind();
      final sw = Stopwatch()..start();
      final wear = await CgmSdk.bind(
        deviceId: kTarget,
        form: 'full',
        calibration: const AlgoParams(
          tempCoef1: 2.8632,
          tempCoef2: -0.04,
          bgmBase: 6.8,
        ),
      );
      p('bind ${sw.elapsed.inSeconds}s wear=${wear.wearId}（locally generated）');
      final ev1 = <String>[];
      final first = await waitGlucose(const Duration(seconds: 200), ev1);
      p(
        'first stage ${sw.elapsed.inSeconds}s blood sugar ${first.length} strip events=$ev1',
      );
      expect(first, isNotEmpty);
      final countBefore = await CgmSdk.count();

      // when App Killed: release everything (broken chain, closed library）
      await CgmSdk.dispose();
      p('dispose Completed, simulated App reopen');
      await Future<void>.delayed(const Duration(seconds: 3));

      await CgmSdk.init(config: cfg);
      final cur = await CgmSdk.currentWear();
      p('Heavy init back currentWear=${cur?.toMap()}');
      expect(cur?.wearId, wear.wearId);
      final ev2 = <String>[];
      final second = await waitGlucose(const Duration(seconds: 200), ev2);
      final countAfter = await CgmSdk.count();
      p(
        'second stage ${sw.elapsed.inSeconds}s blood sugar ${second.length} strip count $countBefore→$countAfter events=$ev2',
      );
      p(
        'The first article of the second phase ${second.isEmpty ? '-' : second.first.toMap()}',
      );
      expect(
        second,
        isNotEmpty,
        reason:
            'Heavy init back SDK It should automatically reconnect and continue to send blood sugar',
      );
      expect(countAfter, greaterThan(countBefore));

      await CgmSdk.unbind();
      expect(await CgmSdk.currentWear(), isNull);
      await CgmSdk.dispose();
      p('DONE');
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
