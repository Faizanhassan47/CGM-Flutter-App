import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:cgm_sdk/src/algorithm/algorithm_gateway.dart';
import 'package:cgm_sdk/src/algorithm/glucose_value.dart';

/// True algorithm gateway, via MethodChannel Tune the original cgmAlgoV1（Android libdtProc.so / iOS libCgmAlgo.a）。
/// The algorithm is not thread-safe and must be called serially. GlucosePipelineRepository of SerialExecutor reveal all the details。
class JniAlgorithmGateway implements AlgorithmGateway {
  static const MethodChannel _channel = MethodChannel(
    'com.linkxin.cgm/algorithm',
  );

  /// .so There is an internal history window and filtering status. During cold start, the historical current must be replayed to reconstruct the baseline.。
  @override
  bool get isStateful => true;

  @override
  Future<String> version() async =>
      (await _channel.invokeMethod<String>('version')) ?? 'unknown';

  /// Each time a collection is started, a version number is printed.（V1.2.7_r2 same version string at both ends); the delivery package must also be viewable without adding kDebugMode Door。
  /// Optional tuning parameters vary init Send the original together, the original is here init Adjust the algorithm library item by item after success. setXxx。
  @override
  Future<bool> init(GluCalcParameter p) async {
    // The version number is just diagnostic information. If you cannot get it, you must continue. init：Android side .so When loading fails version Can throw
    // UnsatisfiedLinkError，Not holding it in place will make the whole init Throw it away and the algorithm can never be initialized.。
    try {
      debugPrint('[CGMAlgorithm library] Version=${await version()}');
    } catch (e) {
      debugPrint(
        '[CGMAlgorithm library] Can’t get version number(Does not affect the algorithm): $e',
      );
    }
    return (await _channel.invokeMethod<bool>('init', {
          'startTs': p.startTs,
          'paramBGMbase': p.paramBGMbase,
          'slope': p.slope, // native side tempcoef1
          'intercept': p.intercept, // native side tempcoef2
          ...p.tuning.toChannelMap(),
        })) ??
        false;
  }

  @override
  Future<GlucoseValue?> dataProc({
    required double srcData,
    required double temperature,
    required int ts,
  }) async {
    final m = await _channel.invokeMapMethod<String, dynamic>('dataProc', {
      'srcData': srcData,
      'temperature': temperature,
      'ts': ts,
    });
    return m == null ? null : GlucoseValue.fromMap(m);
  }

  @override
  Future<bool> uninit() async =>
      (await _channel.invokeMethod<bool>('uninit')) ?? false;
}
