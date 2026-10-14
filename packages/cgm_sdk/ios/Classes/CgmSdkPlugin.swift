import Flutter
import Foundation

/// Lianxin CGM Algorithm library (V1.2.7) bridge, with Android same set MethodChannel contract。
/// The bottom layer is ObjC static library cgmAlgo (libCgmAlgo.a)，The header file comes with pod Public and directly available within the same module。
/// Original App Inside CgmAlgorithmPlugin Import the plug-in as it is, and GeneratedPluginRegistrant Automatic registration。
public final class CgmSdkPlugin: NSObject, FlutterPlugin {

  private static let channelName = "com.linkxin.cgm/algorithm"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let instance = CgmSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "version":
      result(cgmAlgo.algoVersion())

    case "init":
      guard let args = call.arguments as? [String: Any],
            let startTs = (args["startTs"] as? NSNumber)?.int32Value,
            let paramBGMbase = (args["paramBGMbase"] as? NSNumber)?.doubleValue,
            let slope = (args["slope"] as? NSNumber)?.doubleValue,
            let intercept = (args["intercept"] as? NSNumber)?.doubleValue else {
        result(FlutterError(code: "bad_args",
                            message: "init need startTs, paramBGMbase, slope, intercept",
                            details: nil))
        return
      }
      // tempcoef1 = slope、tempcoef2 = intercept
      let ok = cgmAlgo.algoInit(startTs,
                                paramBGMbase: paramBGMbase,
                                tempcoef1: slope,
                                tempcoef2: intercept)
      if ok { applyTuning(args) }
      result(ok)

    case "dataProc":
      guard let args = call.arguments as? [String: Any],
            let srcData = (args["srcData"] as? NSNumber)?.doubleValue,
            let temperature = (args["temperature"] as? NSNumber)?.doubleValue,
            let ts = (args["ts"] as? NSNumber)?.uint32Value else {
        result(FlutterError(code: "bad_args",
                            message: "dataProc need srcData, temperature, ts",
                            details: nil))
        return
      }
      let ret = cgmAlgo.algoDataProc(srcData, dTemp: temperature, uiTs: ts)
      // Key name alignment Dart side contract
      let map: [String: Any] = [
        "value": ret.value,
        "idx": Int(ret.idx),
        "current": ret.current,
        "current_iir_filter": ret.current_iir_filter,
        "current_median_filter": ret.current_median_filter,
        "current_remove_squeeze1": ret.current_remove_squeeze1,
        "current_remove_squeeze2": ret.current_remove_squeeze2,
        "current_base": ret.current_base,
        "sensitivity_used": ret.sensitivity_used,
        "day_kalman_paramQ": ret.day_kalman_paramQ,
        "day_kalman_paramR": ret.day_kalman_paramR,
        "night_kalman_paramQ": ret.night_kalman_paramQ,
        "night_kalman_paramR": ret.night_kalman_paramR,
        "glucosePre": ret.glucosePre,
      ]
      result(map)

    case "uninit":
      cgmAlgo.algoUninit()
      result(true)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// init After success, apply the optional tuning parameters (algorithm library’s algoSetXxx，In-factory testing/For background distribution）：Dart Keys that are not transmitted on the side
  /// No correspondence setter，The algorithm library uses built-in default。setter return false Only logs and does not block（init Successfully）。
  private func applyTuning(_ args: [String: Any]) {
    func d(_ k: String) -> Double? { (args[k] as? NSNumber)?.doubleValue }
    func check(_ name: String, _ ok: Bool) {
      if !ok { NSLog("[CgmSdkPlugin] %@ return false，The value is not accepted by the algorithm library", name) }
    }
    if let v = d("positiveSlope1") { check("algoSetPositiveSlope1", cgmAlgo.algoSetPositiveSlope1(v)) }
    if let v = d("negativeSlope1") { check("algoSetNegativesSlope1", cgmAlgo.algoSetNegativesSlope1(v)) }
    if let v = d("positiveSlope2") {
      let fixed = (args["positiveSlope2Fixed"] as? Bool) ?? false
      check("algoSetPositiveSlope2", cgmAlgo.algoSetPositiveSlope2(v, bgSw: fixed))
    }
    if let v = d("negativeSlope2") { check("algoSetNegativesSlope2", cgmAlgo.algoSetNegativesSlope2(v)) }
    if let q = d("dayKalmanQ"), let r = d("dayKalmanR") { check("algoSetDayKalman", cgmAlgo.algoSetDayKalman(q, dR: r)) }
    if let q = d("nightKalmanQ"), let r = d("nightKalmanR") { check("algoSetNightKalman", cgmAlgo.algoSetNightKalman(q, dR: r)) }
  }
}
