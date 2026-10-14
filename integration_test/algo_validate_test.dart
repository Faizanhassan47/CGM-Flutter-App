import 'package:cgm_sdk/cgm_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Real machine algorithm verification（Mac superior `flutter test integration_test/algo_validate_test.dart -d <equipment>`）：
/// put inside the bag Excel The playback sets the current from seq1 Continuous feeding .so / .a，item by item comparison Excel Blood sugar, tested
/// 「New algorithm package + init ”Four Ginseng” This JNI/The bridge contract is really counting blood sugar (rather than the reflection signature being wrong and the whole thing failing、
/// Or output the transparent current as it is). and App of lib/algo_validate_main.dart Same caliber：
/// k=2.8632 / b=-0.04 / CGMbase=6.8 It’s this Excel Calibration of meter head, front 120 The preheating space occupied by the bar is not comparable。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  void p(String s) {
    // ignore: avoid_print
    print('ALGO $s');
  }

  testWidgets(
    'Excel Current continuous feeding algorithm library → and Excel blood sugar ratio MAE',
    (t) async {
      const k = 2.8632, b = -0.04, cgmbase = 6.8;
      const feed = 1440, warmup = 120;
      // Excel First measurement time 2026-05-02 16:51:21（Beijing）→ UTC seconds, impact day/Night Kalman Batch
      final startTs =
          DateTime.utc(2026, 5, 2, 8, 51, 21).millisecondsSinceEpoch ~/ 1000;

      final ds = await CgmReplayDataset.load();
      expect(
        ds.length,
        greaterThan(feed),
        reason: 'In the bag cgm_replay.csv Not loaded',
      );

      final algo = JniAlgorithmGateway();
      expect(
        await algo.init(
          GluCalcParameter(
            slope: k,
            intercept: b,
            startTs: startTs,
            paramL3: 0,
            paramG3: 0,
            paramL4: 0,
            paramG4: 0,
            paramL5: 0,
            paramG5: 0,
            paramBGMbase: cgmbase,
          ),
        ),
        isTrue,
        reason: 'Algorithm library init fail',
      );
      p(
        'library version=${await algo.version()} sample=${ds.length} Hello=$feed',
      );

      var sumAbs = 0.0, counted = 0, broken = 0, nulls = 0, passThrough = 0;
      for (var i = 0; i < feed; i++) {
        final s = ds.samples[i];
        final gv = await algo.dataProc(
          srcData: s.current,
          temperature: s.temperature,
          ts: startTs + i * 60,
        );
        if (gv == null) {
          nulls++;
          continue;
        }
        if ((i + 1) % 240 == 0) {
          p(
            'seq=${i + 1} current=${s.current} .soblood sugar=${gv.value.toStringAsFixed(3)} '
            'Excel=${s.excelGlucose.toStringAsFixed(3)} Difference=${(gv.value - s.excelGlucose).toStringAsFixed(3)} '
            'k=${gv.sensitivityUsed.toStringAsFixed(4)} squeeze1=${gv.currentRemoveSqueeze1.toStringAsFixed(3)} '
            'pre=${gv.glucosePre.toStringAsFixed(3)}',
          );
        }
        if (i < warmup) continue;
        counted++;
        final v = gv.value;
        if (v.isNaN || v.isInfinite || v < 0 || v > 40) {
          broken++;
          sumAbs += 50;
        } else {
          sumAbs += (v - s.excelGlucose).abs();
        }
        if ((v - s.current).abs() < 1e-9) passThrough++;
      }
      await algo.uninit();

      final mae = counted == 0 ? -1.0 : sumAbs / counted;
      p(
        'Summary Hello=$feed Preheat skip=$warmup credited=$counted Calm down/Cross the line=$broken null=$nulls '
        'blood sugar==current(pass-through)=$passThrough MAE=${mae.toStringAsFixed(3)} mmol/L',
      );
      expect(
        nulls,
        0,
        reason:
            'dataProc return null = JNI reflection/The bridge contract is broken',
      );
      expect(broken, 0);
      expect(
        passThrough,
        lessThan(counted ~/ 10),
        reason:
            'Blood sugar is equal to current = The algorithm is not calculating',
      );
      expect(
        mae,
        lessThan(1.0),
        reason:
            'and Excel Deviation is too large（1.2.4 Actual measurement 0.089）',
      );
    },
  );
}
