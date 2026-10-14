import 'package:cgm_sdk/src/algorithm/glucose_value.dart';

/// Calibration parameters fed to the algorithm library。V1.2.4+ of init Just eat slope(tempcoef1)/intercept(tempcoef2)/
/// startTs/paramBGMbase four items；paramA~D、L3~G5 It’s an old version setGluCalcParameter legacy fields，
/// Only log in now。[tuning] Is the algorithm library optional setXxx Adjustment items，init After success, the gateway will apply it item by item.。
class GluCalcParameter {
  final double slope;
  final double intercept;
  final int startTs;
  final double paramA;
  final double paramB;
  final double paramC;
  final double paramD;
  final double paramL3;
  final double paramG3;
  final double paramL4;
  final double paramG4;
  final double paramL5;
  final double paramG5;
  final double paramBGMbase;
  final double tempcoef1;
  final double tempcoef2;
  final AlgoTuning tuning;

  const GluCalcParameter({
    required this.slope,
    required this.intercept,
    required this.startTs,
    this.paramA = 1.63189,
    this.paramB = -8.25417,
    this.paramC = 12.43634,
    this.paramD = 2.5,
    required this.paramL3,
    required this.paramG3,
    required this.paramL4,
    required this.paramG4,
    required this.paramL5,
    required this.paramG5,
    required this.paramBGMbase,
    this.tempcoef1 = 0.0,
    this.tempcoef2 = 0.0,
    this.tuning = const AlgoTuning(),
  });
}

/// Algorithm library optional tuning parameters（V1.2.4+ of setPositiveslope1/2、setNegativeslope1/2、setDayKalman、
/// setNightKalman）。null = No correspondence setter，The algorithm library uses the built-in default; Kalman Q/R Must be in pairs。
class AlgoTuning {
  const AlgoTuning({
    this.positiveSlope1,
    this.negativeSlope1,
    this.positiveSlope2,
    this.positiveSlope2Fixed = false,
    this.negativeSlope2,
    this.dayKalmanQ,
    this.dayKalmanR,
    this.nightKalmanQ,
    this.nightKalmanR,
  });

  final double? positiveSlope1;
  final double? negativeSlope1;
  final double? positiveSlope2;

  /// setPositiveslope2 of bUseBgSet：true = Mandatory use [positiveSlope2]、Not modified by the algorithm library。
  final bool positiveSlope2Fixed;
  final double? negativeSlope2;
  final double? dayKalmanQ;
  final double? dayKalmanR;
  final double? nightKalmanQ;
  final double? nightKalmanR;

  bool get isEmpty =>
      positiveSlope1 == null &&
      negativeSlope1 == null &&
      positiveSlope2 == null &&
      negativeSlope2 == null &&
      dayKalmanQ == null &&
      dayKalmanR == null &&
      nightKalmanQ == null &&
      nightKalmanR == null;

  /// Native channel key name (with CgmSdkPlugin.kt / .swift of applyTuning consistent），null Item is not included。
  Map<String, Object> toChannelMap() => {
    if (positiveSlope1 != null) 'positiveSlope1': positiveSlope1!,
    if (negativeSlope1 != null) 'negativeSlope1': negativeSlope1!,
    if (positiveSlope2 != null) 'positiveSlope2': positiveSlope2!,
    if (positiveSlope2 != null) 'positiveSlope2Fixed': positiveSlope2Fixed,
    if (negativeSlope2 != null) 'negativeSlope2': negativeSlope2!,
    if (dayKalmanQ != null) 'dayKalmanQ': dayKalmanQ!,
    if (dayKalmanR != null) 'dayKalmanR': dayKalmanR!,
    if (nightKalmanQ != null) 'nightKalmanQ': nightKalmanQ!,
    if (nightKalmanR != null) 'nightKalmanR': nightKalmanR!,
  };

  @override
  String toString() => isEmpty ? 'none' : toChannelMap().toString();
}

abstract class AlgorithmGateway {
  /// Whether there is internal state; stateless cold start can avoid full historical replay。
  bool get isStateful;

  Future<String> version();

  /// Initialize the algorithm library and write calibration, the first call。V1.2.4 Start calibration and advance init，no separate
  /// setGluCalcParameter；[params] use slope/intercept/startTs/paramBGMbase four items，
  /// another [GluCalcParameter.tuning] The non-empty items are in init After success, apply it to the algorithm library。
  Future<bool> init(GluCalcParameter params);

  /// Calculate a single blood glucose value and adjust it every time a piece of device data is received.。[srcData] is the original current，[ts] Unit second。
  /// Return on failure null，Not thrown, it is up to the caller to decide whether to leave the frame and try again。
  Future<GlucoseValue?> dataProc({
    required double srcData,
    required double temperature,
    required int ts,
  });

  /// Stop measuring and change sensor、Called on exit。
  Future<bool> uninit();
}
