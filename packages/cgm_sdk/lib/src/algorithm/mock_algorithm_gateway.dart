import 'package:cgm_sdk/src/algorithm/algorithm_gateway.dart';
import 'package:cgm_sdk/src/algorithm/glucose_value.dart';

/// [AlgorithmGateway] of mock，Keep the state and call order constraints, so that the pipeline can be .so able to run。
/// The calculation uses deterministic formulas, with the same input and output.；[callLog] For testing assertions seriality and order。
class MockAlgorithmGateway implements AlgorithmGateway {
  final String mockVersion;

  /// It is no longer used internally and remains compatible with existing callers.。
  final int warmupCount;

  /// Simulate stateful algorithms and measure cold start history replay time settings true。
  @override
  final bool isStateful;

  MockAlgorithmGateway({
    this.mockVersion = 'mock-V1.2.4_r2',
    this.warmupCount = 119,
    this.isStateful = false,
  });

  bool _inited = false;
  int _procCount = 0;

  /// Call the pipeline (method name) and test the verification sequence and seriality。
  final List<String> callLog = [];

  /// every time dataProc Raw current fed, test verification history replay/Whether the complement is re-fed in order。
  final List<double> procSrcLog = [];

  /// every time dataProc fed ts（Second). real .so Depend on ts-startTs Position inner windows，
  /// The test uses it to assert that the timeline is continuous, hole-free and monotonous。
  final List<int> procTsLog = [];

  /// dataProc Enter/Leave count difference, greater than 1 Indicates that concurrent reentrancy has occurred。
  int _inFlight = 0;
  int maxConcurrentInFlight = 0;

  @override
  Future<String> version() async {
    callLog.add('version');
    return mockVersion;
  }

  @override
  Future<bool> init(GluCalcParameter params) async {
    callLog.add('init');
    _inited = true;
    _procCount = 0;
    return true;
  }

  @override
  Future<GlucoseValue?> dataProc({
    required double srcData,
    required double temperature,
    required int ts,
  }) async {
    callLog.add('dataProc');
    procSrcLog.add(srcData);
    procTsLog.add(ts);
    _inFlight++;
    if (_inFlight > maxConcurrentInFlight) {
      maxConcurrentInFlight = _inFlight;
    }
    try {
      if (!_inited) {
        // If the real algorithm is adjusted like this, it will make an error and return null Let the upper layer keep the frame and try again
        return null;
      }
      // Give up the event loop to enlarge the concurrency window when serialization is destroyed _inFlight meeting >1
      await Future<void>.delayed(Duration.zero);

      _procCount++;

      // Deterministic mapping, temperature fine-tuning
      final base = 3.0 + srcData * 0.05;
      final tempAdj = (temperature - 25.0) * 0.01;
      final value = double.parse((base + tempAdj).toStringAsFixed(4));

      return GlucoseValue(
        value: value,
        idx: _procCount,
        current: srcData,
        currentIirFilter: srcData * 0.98,
        currentMedianFilter: srcData * 0.97,
        currentBase: srcData * 0.1,
        sensitivityUsed: 1.0,
        dayKalmanParamQ: 0.01,
        dayKalmanParamR: 0.1,
        nightKalmanParamQ: 0.005,
        nightKalmanParamR: 0.1,
      );
    } finally {
      _inFlight--;
    }
  }

  @override
  Future<bool> uninit() async {
    callLog.add('uninit');
    _inited = false;
    _procCount = 0;
    return true;
  }
}
