import 'package:cgm_sdk/src/algorithm/algorithm_gateway.dart';
import 'package:cgm_sdk/src/algorithm/glucose_value.dart';

/// Conversion gateway during debugging period, after the hardware is in place DI True .so。Only do linear mapping `blood sugar = current × a + b`，
/// a/b Depend on init calibrated thermal adjustment, stateless。
class LinearAlgorithmGateway implements AlgorithmGateway {
  @override
  bool get isStateful => false;

  /// It is no longer used internally and remains compatible with existing callers.。
  final int warmupSeconds;

  /// according to `(ts-startTs)/cycle` Push the serial number to get the neighborhood fitting a/b：Sensitivity drifts with wearing，
  /// There is a large deviation in the middle and late stages of a single full-range linearity. return null return fixed a/b。
  final ({double a, double b})? Function(int seq)? localFit;

  /// Serial number calculation period (seconds), consistent with the collection period。
  final int localFitPeriodSec;

  double _a;
  double _b;

  LinearAlgorithmGateway({
    double a = 0.79,
    double b = -0.24,
    // and kWearWarmupMinutes sync; no import This constant is to avoid reverse dependence of the algorithm layer features/home
    this.warmupSeconds = 15 * 60,
    this.localFit,
    this.localFitPeriodSec = 60,
  }) : _a = a,
       _b = b;

  double get a => _a;
  double get b => _b;

  bool _inited = false;
  int _startTs = 0;
  int _idx = 0;

  @override
  Future<String> version() async => 'linear-debug-1';

  @override
  Future<bool> init(GluCalcParameter params) async {
    _inited = true;
    _idx = 0;
    _startTs = params.startTs;
    if (params.slope != 0) _a = params.slope;
    if (params.intercept != 0) _b = params.intercept;
    return true;
  }

  @override
  Future<GlucoseValue?> dataProc({
    required double srcData,
    required double temperature,
    required int ts,
  }) async {
    if (!_inited) return null;
    _idx++;
    // The local fitting coefficient is given priority and cannot be unfixed. a/b
    var a = _a, b = _b;
    if (localFit != null && _startTs != 0 && ts >= _startTs) {
      final seq = (ts - _startTs) ~/ localFitPeriodSec + 1;
      final fit = localFit!(seq);
      if (fit != null) {
        a = fit.a;
        b = fit.b;
      }
    }
    final value = double.parse((srcData * a + b).toStringAsFixed(4));
    return GlucoseValue(
      value: value,
      idx: _idx,
      current: srcData,
      currentIirFilter: srcData,
      currentMedianFilter: srcData,
      currentBase: 0.0,
      sensitivityUsed: a,
      dayKalmanParamQ: 0.0,
      dayKalmanParamR: 0.0,
      nightKalmanParamQ: 0.0,
      nightKalmanParamR: 0.0,
    );
  }

  @override
  Future<bool> uninit() async {
    _inited = false;
    _idx = 0;
    return true;
  }
}
