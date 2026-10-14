import Flutter
import Foundation

/// For native hosts SDK facade（Swift）。Create a no-interface internally FlutterEngine implement cgm_sdk_module entrance，
/// All calls MethodChannel transfer to Dart Side facade; method name / Parameter name / Error code and《CGM SDK Interface document” consistent。
///
/// - The results `Result<T, SdkError>` callback，`SdkError.code` = Document error code。
/// - For events `onXxx { }` Register for monitoring (you can register multiple times and you will receive）。
/// - All callbacks / Events are all on the main thread; the time is the same UTC millisecond（Int64）。
public final class CgmSdk {
  public static let shared = CgmSdk()

  /// SDK mistake：`code` Consistent with the document ”error code”。
  public struct SdkError: Error {
    public let code: String
    public let message: String?
  }

  // ───────────────────────── data object ─────────────────────────

  /// Initial configuration (interface 1）。
  public struct Config {
    public var logLevel = "info"
    public var foregroundNotice = "Blood glucose monitoring"
    public var minBatteryMv = 2800
    public var warmupMinutes = 120
    public init() {}
    fileprivate var map: [String: Any?] {
      ["logLevel": logLevel, "foregroundNotice": foregroundNotice, "minBatteryMv": minBatteryMv, "warmupMinutes": warmupMinutes]
    }
  }

  /// Algorithm parameters (alignment algorithm library V1.2.7 interface）：tempCoef1 = Factory sensitivity k、tempCoef2 = Factory intercept b
  /// （QR code 4/5 part），bgmBase = Finger blood reference (not transmitted SDK use 6.8 cover); the rest are optional parameters，
  /// Not passed on = The algorithm library uses the built-in default, Kalman Q/R Must be passed in pairs。positiveSlope2Fixed = Mandatory use
  /// positiveSlope2、Not modified by the algorithm library。
  public struct AlgoParams {
    public var tempCoef1: Double, tempCoef2: Double
    public var bgmBase: Double?
    public var positiveSlope1: Double?, negativeSlope1: Double?
    public var positiveSlope2: Double?, positiveSlope2Fixed = false, negativeSlope2: Double?
    public var dayKalmanQ: Double?, dayKalmanR: Double?, nightKalmanQ: Double?, nightKalmanR: Double?
    public init(tempCoef1: Double, tempCoef2: Double, bgmBase: Double? = nil,
                positiveSlope1: Double? = nil, negativeSlope1: Double? = nil,
                positiveSlope2: Double? = nil, positiveSlope2Fixed: Bool = false, negativeSlope2: Double? = nil,
                dayKalmanQ: Double? = nil, dayKalmanR: Double? = nil, nightKalmanQ: Double? = nil, nightKalmanR: Double? = nil) {
      self.tempCoef1 = tempCoef1; self.tempCoef2 = tempCoef2; self.bgmBase = bgmBase
      self.positiveSlope1 = positiveSlope1; self.negativeSlope1 = negativeSlope1
      self.positiveSlope2 = positiveSlope2; self.positiveSlope2Fixed = positiveSlope2Fixed; self.negativeSlope2 = negativeSlope2
      self.dayKalmanQ = dayKalmanQ; self.dayKalmanR = dayKalmanR; self.nightKalmanQ = nightKalmanQ; self.nightKalmanR = nightKalmanR
    }
    fileprivate var map: [String: Any?] {
      ["tempCoef1": tempCoef1, "tempCoef2": tempCoef2, "bgmBase": bgmBase,
       "positiveSlope1": positiveSlope1, "negativeSlope1": negativeSlope1,
       "positiveSlope2": positiveSlope2, "positiveSlope2Fixed": positiveSlope2Fixed, "negativeSlope2": negativeSlope2,
       "dayKalmanQ": dayKalmanQ, "dayKalmanR": dayKalmanR, "nightKalmanQ": nightKalmanQ, "nightKalmanR": nightKalmanR]
    }
    fileprivate static func from(_ m: [String: Any]?) -> AlgoParams? {
      guard let m = m, let k = m.d("tempCoef1"), let b = m.d("tempCoef2") else { return nil }
      return AlgoParams(tempCoef1: k, tempCoef2: b, bgmBase: m.d("bgmBase"),
                        positiveSlope1: m.d("positiveSlope1"), negativeSlope1: m.d("negativeSlope1"),
                        positiveSlope2: m.d("positiveSlope2"), positiveSlope2Fixed: (m["positiveSlope2Fixed"] as? Bool) ?? false,
                        negativeSlope2: m.d("negativeSlope2"),
                        dayKalmanQ: m.d("dayKalmanQ"), dayKalmanR: m.d("dayKalmanR"),
                        nightKalmanQ: m.d("nightKalmanQ"), nightKalmanR: m.d("nightKalmanR"))
    }
  }

  /// QR code parsing results (interface 5）。
  public struct QrInfo {
    public let deviceId: String, form: String, calibration: AlgoParams?, expireDate: Int64?, transmitterSn: String?, sensorSn: String?
    fileprivate static func from(_ m: [String: Any]) -> QrInfo {
      QrInfo(deviceId: m.s("deviceId"), form: m.s("form"), calibration: AlgoParams.from(m["calibration"] as? [String: Any]),
             expireDate: m.l("expireDate"), transmitterSn: m.sn("transmitterSn"), sensorSn: m.sn("sensorSn"))
    }
  }

  /// Scanned devices (interfaces 6）。
  public struct ScanDevice {
    public let deviceId: String, name: String, bleId: String, rssi: Int
    fileprivate static func from(_ m: [String: Any]) -> ScanDevice {
      ScanDevice(deviceId: m.s("deviceId"), name: m.s("name"), bleId: m.s("bleId"), rssi: m.i("rssi") ?? 0)
    }
  }

  /// Wearing record (interface 8 / 9 / 13）。
  public struct WearInfo {
    public var wearId: Int64, deviceId: String, bleId: String, form: String
    public var activatedAt: Int64, warmupEndAt: Int64, expiresAt: Int64
    public var calibration: AlgoParams?
    public var transmitterSn: String?, sensorSn: String?
    public init(wearId: Int64, deviceId: String, bleId: String, form: String, activatedAt: Int64, warmupEndAt: Int64, expiresAt: Int64,
                calibration: AlgoParams? = nil, transmitterSn: String? = nil, sensorSn: String? = nil) {
      self.wearId = wearId; self.deviceId = deviceId; self.bleId = bleId; self.form = form
      self.activatedAt = activatedAt; self.warmupEndAt = warmupEndAt; self.expiresAt = expiresAt
      self.calibration = calibration; self.transmitterSn = transmitterSn; self.sensorSn = sensorSn
    }
    fileprivate var map: [String: Any?] {
      ["wearId": wearId, "deviceId": deviceId, "bleId": bleId, "form": form, "activatedAt": activatedAt,
       "warmupEndAt": warmupEndAt, "expiresAt": expiresAt, "calibration": calibration?.map,
       "transmitterSn": transmitterSn, "sensorSn": sensorSn]
    }
    fileprivate static func from(_ m: [String: Any]) -> WearInfo {
      WearInfo(wearId: m.l("wearId") ?? 0, deviceId: m.s("deviceId"), bleId: m.s("bleId"), form: m.s("form"),
               activatedAt: m.l("activatedAt") ?? 0, warmupEndAt: m.l("warmupEndAt") ?? 0, expiresAt: m.l("expiresAt") ?? 0,
               calibration: AlgoParams.from(m["calibration"] as? [String: Any]), transmitterSn: m.sn("transmitterSn"), sensorSn: m.sn("sensorSn"))
    }
  }

  /// bind After passing the verification, it is handed over to the host site (interface 8 callback）。
  public struct BindCheck {
    public let transmitterId: Int64, transmitterSn: String, sensorId: Int64, sensorSn: String
    public let bluetoothAddr: String, batteryMv: Int, inUse: Bool, at: Int64
    fileprivate static func from(_ m: [String: Any]) -> BindCheck {
      BindCheck(transmitterId: m.l("transmitterId") ?? 0, transmitterSn: m.s("transmitterSn"), sensorId: m.l("sensorId") ?? 0,
                sensorSn: m.s("sensorSn"), bluetoothAddr: m.s("bluetoothAddr"), batteryMv: m.i("batteryMv") ?? 0,
                inUse: m["inUse"] as? Bool ?? false, at: m.l("at") ?? 0)
    }
  }

  /// The host is beforeActivate decision。
  public struct BindDecision {
    fileprivate let map: [String: Any?]
    /// Release; can be worn with rear-end distribution ID / Preheating end time（UTC millisecond）。
    public static func proceed(wearId: Int64? = nil, preheatEndAt: Int64? = nil) -> BindDecision {
      BindDecision(map: ["proceed": true, "wearId": wearId, "preheatEndAt": preheatEndAt])
    }
    /// abort，message Give it back as it is bind the caller（E_BIND_REJECTED）。
    public static func abort(_ message: String) -> BindDecision {
      BindDecision(map: ["proceed": false, "message": message])
    }
  }

  /// Device information (interface 14）。
  public struct DeviceInfo {
    public let deviceId: String, firmware: String, batteryMv: Int, latestSeq: Int, measuring: Bool, measuredSec: Int
    fileprivate static func from(_ m: [String: Any]) -> DeviceInfo {
      DeviceInfo(deviceId: m.s("deviceId"), firmware: m.s("firmware"), batteryMv: m.i("batteryMv") ?? 0,
                 latestSeq: m.i("latestSeq") ?? 0, measuring: m["measuring"] as? Bool ?? false, measuredSec: m.i("measuredSec") ?? 0)
    }
  }

  /// A blood glucose (interface 17 / 18 / 19、event 3）。
  public struct GlucoseSample {
    public var wearId: Int64, seq: Int, measuredAt: Int64, value: Double?
    public var warmup: Bool, abnormal: Bool, source: String
    public var rawCurrent: Double?, temperature: Double?, voltage: Double?
    public init(wearId: Int64, seq: Int, measuredAt: Int64, value: Double?, warmup: Bool = false, abnormal: Bool = false,
                source: String = "live", rawCurrent: Double? = nil, temperature: Double? = nil, voltage: Double? = nil) {
      self.wearId = wearId; self.seq = seq; self.measuredAt = measuredAt; self.value = value; self.warmup = warmup
      self.abnormal = abnormal; self.source = source; self.rawCurrent = rawCurrent; self.temperature = temperature; self.voltage = voltage
    }
    fileprivate static func from(_ m: [String: Any]) -> GlucoseSample {
      GlucoseSample(wearId: m.l("wearId") ?? 0, seq: m.i("seq") ?? 0, measuredAt: m.l("measuredAt") ?? 0, value: m.d("value"),
                    warmup: m["warmup"] as? Bool ?? false, abnormal: m["abnormal"] as? Bool ?? false, source: m.s("source"),
                    rawCurrent: m.d("rawCurrent"), temperature: m.d("temperature"), voltage: m.d("voltage"))
    }
  }

  /// Device raw data (interface 20）。
  public struct RawSample {
    public let wearId: Int64, seq: Int, measuredAt: Int64, current: Double?, temperature: Double?, voltage: Double?, lactate: Double?
    fileprivate static func from(_ m: [String: Any]) -> RawSample {
      RawSample(wearId: m.l("wearId") ?? 0, seq: m.i("seq") ?? 0, measuredAt: m.l("measuredAt") ?? 0, current: m.d("current"),
                temperature: m.d("temperature"), voltage: m.d("voltage"), lactate: m.d("lactate"))
    }
  }

  /// device status (event 2）。
  public struct DeviceStatus {
    public let connected: Bool, batteryMv: Int?, temperature: Double?, latestSeq: Int?
    public let measuring: Bool, flashFull: Bool, warmupRemainingMin: Int, remainingDays: Int, abnormal: String?
    fileprivate static func from(_ m: [String: Any]) -> DeviceStatus {
      DeviceStatus(connected: m["connected"] as? Bool ?? false, batteryMv: m.i("batteryMv"), temperature: m.d("temperature"),
                   latestSeq: m.i("latestSeq"), measuring: m["measuring"] as? Bool ?? false, flashFull: m["flashFull"] as? Bool ?? false,
                   warmupRemainingMin: m.i("warmupRemainingMin") ?? 0, remainingDays: m.i("remainingDays") ?? 0, abnormal: m.sn("abnormal"))
    }
  }

  /// Algorithm complete output (event 4）。
  public struct AlgoResult {
    public let seq: Int, value: Double, current: Double, currentIirFilter: Double, currentMedianFilter: Double
    public let currentBase: Double, sensitivityUsed: Double, dayKalmanQ: Double, dayKalmanR: Double, nightKalmanQ: Double, nightKalmanR: Double
    /// Algorithm library V1.2.7 New: Current value after squeeze noise removal 1 / 2、Predict blood sugar levels。
    public let currentRemoveSqueeze1: Double, currentRemoveSqueeze2: Double, glucosePre: Double
    fileprivate static func from(_ m: [String: Any]) -> AlgoResult {
      AlgoResult(seq: m.i("seq") ?? 0, value: m.d("value") ?? 0, current: m.d("current") ?? 0, currentIirFilter: m.d("currentIirFilter") ?? 0,
                 currentMedianFilter: m.d("currentMedianFilter") ?? 0, currentBase: m.d("currentBase") ?? 0, sensitivityUsed: m.d("sensitivityUsed") ?? 0,
                 dayKalmanQ: m.d("dayKalmanQ") ?? 0, dayKalmanR: m.d("dayKalmanR") ?? 0, nightKalmanQ: m.d("nightKalmanQ") ?? 0, nightKalmanR: m.d("nightKalmanR") ?? 0,
                 currentRemoveSqueeze1: m.d("currentRemoveSqueeze1") ?? 0, currentRemoveSqueeze2: m.d("currentRemoveSqueeze2") ?? 0, glucosePre: m.d("glucosePre") ?? 0)
    }
  }

  /// progress(event 5）：kind = warmup / backfill / replay。
  public struct Progress {
    public let kind: String, done: Int, total: Int
    fileprivate static func from(_ m: [String: Any]) -> Progress { Progress(kind: m.s("kind"), done: m.i("done") ?? 0, total: m.i("total") ?? 0) }
  }

  /// Errors and warnings (events 6）。
  public struct SdkErrorEvent {
    public let code: String, severity: String, message: String
    fileprivate static func from(_ m: [String: Any]) -> SdkErrorEvent { SdkErrorEvent(code: m.s("code"), severity: m.s("severity"), message: m.s("message")) }
  }

  /// SDK log(event 7）。
  public struct LogEntry {
    public let at: Int64, level: String, tag: String, message: String
    fileprivate static func from(_ m: [String: Any]) -> LogEntry { LogEntry(at: m.l("at") ?? 0, level: m.s("level"), tag: m.s("tag"), message: m.s("message")) }
  }

  // ───────────────────────── engine ─────────────────────────

  private static let apiChannelName = "com.linkxin.cgm_sdk/api"
  private static let eventChannelName = "com.linkxin.cgm_sdk/events"
  /// internal engine（initialize after is not empty). Host needs to register SDK Used when relying on plug-ins, see [initialize] of registerPlugins。
  public private(set) var engine: FlutterEngine?
  private var api: FlutterMethodChannel?
  private var events: FlutterMethodChannel?

  private init() {}

  // ───────────────────────── 1~4 life cycle ─────────────────────────

  /// App Call once at startup; repeated calls have no side effects. Immediately after starting the engine init Give Dart side，completion If successful, you can adjust other interfaces。
  ///
  /// `registerPlugins` **Must pass**（native host）：SDK Dependent on Bluetooth / keychain / Crypto library / The front-end plug-in needs to be registered on the engine once，
  /// Host transmission `{ GeneratedPluginRegistrant.register(with: $0) }`（from FlutterPluginRegistrant.xcframework）。
  /// If you don’t register init newspaper E_STORAGE_FAILED（Keychain cannot retrieve key）。
  public func initialize(config: Config = Config(),
                         registerPlugins: ((FlutterEngine) -> Void)? = nil,
                         _ completion: ((Result<Void, SdkError>) -> Void)? = nil) {
    if engine == nil {
      let e = FlutterEngine(name: "cgm_sdk", project: nil, allowHeadlessExecution: true)
      e.run()
      // same pod The algorithm bridge inside is directly registered; other plug-ins are processed by the host. registerPlugins Register (see Integration Guide）
      if let registrar = e.registrar(forPlugin: "CgmSdkPlugin") {
        CgmSdkPlugin.register(with: registrar)
      }
      registerPlugins?(e)
      api = FlutterMethodChannel(name: CgmSdk.apiChannelName, binaryMessenger: e.binaryMessenger)
      let ev = FlutterMethodChannel(name: CgmSdk.eventChannelName, binaryMessenger: e.binaryMessenger)
      ev.setMethodCallHandler { [weak self] call, result in self?.onDartCall(call, result) }
      events = ev
      engine = e
    }
    invokeVoid("init", ["config": config.map]) { completion?($0) }
  }

  /// Release the engine. Generally only in the host App Exit time tune。
  public func dispose() {
    invokeVoid("dispose", nil) { [weak self] _ in
      self?.events?.setMethodCallHandler(nil)
      self?.engine?.destroyContext()
      self?.engine = nil
      self?.api = nil
      self?.events = nil
    }
  }

  /// SDK Version。
  public func version(_ completion: @escaping (Result<String, SdkError>) -> Void) { invoke("version", nil, completion) }

  /// Algorithm library version (from .a）。Adjust this first after integration. If the version number can be returned, it means the link is connected.。
  public func algorithmVersion(_ completion: @escaping (Result<String, SdkError>) -> Void) { invoke("algorithmVersion", nil, completion) }

  // ───────────────────────── 5~7 QR code / scanning ─────────────────────────

  public func parseQrCode(_ qr: String, _ completion: @escaping (Result<QrInfo, SdkError>) -> Void) {
    invokeMap("parseQrCode", ["qr": qr], QrInfo.from, completion)
  }

  /// Scan for nearby devices: callback every time one is found onDevice Once; scan ends (timeout / stopScan）callback onDone。
  public func scan(timeoutSeconds: Int = 10, onDevice: @escaping (ScanDevice) -> Void, onDone: @escaping (Result<Void, SdkError>) -> Void) {
    scanListener = onDevice
    invokeVoid("scan", ["timeoutSeconds": timeoutSeconds]) { [weak self] r in
      self?.scanListener = nil
      onDone(r)
    }
  }

  public func stopScan(_ completion: ((Result<Void, SdkError>) -> Void)? = nil) { invokeVoid("stopScan", nil) { completion?($0) } }

  // ───────────────────────── 8~14 binding / connect ─────────────────────────

  /// Bind and activate。beforeActivate Adjust after passing the verification and before activation: The host adjusts its own backend binding interface，
  /// Adjust after completion `done(.proceed(...))` or `done(.abort("reason"))`（Can be called in any thread）。
  public func bind(deviceId: String, form: String, calibration: AlgoParams, expireDate: Int64? = nil,
                   transmitterSn: String? = nil, sensorSn: String? = nil,
                   beforeActivate: ((BindCheck, @escaping (BindDecision) -> Void) -> Void)? = nil,
                   _ completion: @escaping (Result<WearInfo, SdkError>) -> Void) {
    bindHook = beforeActivate
    invokeMap("bind", ["deviceId": deviceId, "form": form, "calibration": calibration.map, "expireDate": expireDate,
                       "transmitterSn": transmitterSn, "sensorSn": sensorSn, "hasBeforeActivate": beforeActivate != nil],
              WearInfo.from) { [weak self] r in
      self?.bindHook = nil
      completion(r)
    }
  }

  /// Restore the bound device (change the device / Reinstall / cold start）。
  public func resume(_ wear: WearInfo, _ completion: @escaping (Result<Void, SdkError>) -> Void) { invokeVoid("resume", ["wear": wear.map], completion) }
  public func connect(_ completion: @escaping (Result<Void, SdkError>) -> Void) { invokeVoid("connect", nil, completion) }
  public func disconnect(_ completion: @escaping (Result<Void, SdkError>) -> Void) { invokeVoid("disconnect", nil, completion) }
  public func unbind(_ completion: @escaping (Result<Void, SdkError>) -> Void) { invokeVoid("unbind", nil, completion) }
  /// Current wearing record; not bound to nil。
  public func currentWear(_ completion: @escaping (Result<WearInfo?, SdkError>) -> Void) { invokeMapOrNil("currentWear", nil, WearInfo.from, completion) }
  public func deviceInfo(_ completion: @escaping (Result<DeviceInfo, SdkError>) -> Void) { invokeMap("deviceInfo", nil, DeviceInfo.from, completion) }

  // ───────────────────────── 15~16 Algorithm parameters ─────────────────────────

  public func setAlgoParams(_ p: AlgoParams, _ completion: @escaping (Result<Void, SdkError>) -> Void) { invokeVoid("setAlgoParams", ["params": p.map], completion) }
  public func getAlgoParams(_ completion: @escaping (Result<AlgoParams?, SdkError>) -> Void) {
    invokeMapOrNil("getAlgoParams", nil, { AlgoParams.from($0)! }, completion)
  }

  // ───────────────────────── 17~23 local data ─────────────────────────

  public func query(from: Int64? = nil, to: Int64? = nil, wearId: Int64? = nil, limit: Int = 5000,
                    _ completion: @escaping (Result<[GlucoseSample], SdkError>) -> Void) {
    invokeList("query", ["from": from, "to": to, "wearId": wearId, "limit": limit], GlucoseSample.from, completion)
  }
  public func latest(_ completion: @escaping (Result<GlucoseSample?, SdkError>) -> Void) { invokeMapOrNil("latest", nil, GlucoseSample.from, completion) }

  /// Subscribe to new blood sugar: push a batch first from If there are existing ones after that, they will be pushed once for each new batch.；unwatch stop。
  public func watch(from: Int64? = nil, _ listener: @escaping ([GlucoseSample]) -> Void) {
    watchListener = listener
    invokeVoid("watch", ["from": from]) { _ in }
  }
  public func unwatch() {
    watchListener = nil
    invokeVoid("unwatch", nil) { _ in }
  }

  public func queryRaw(from: Int64? = nil, to: Int64? = nil, _ completion: @escaping (Result<[RawSample], SdkError>) -> Void) {
    invokeList("queryRaw", ["from": from, "to": to], RawSample.from, completion)
  }
  /// Export csv / json，Returns the absolute path of the file。
  public func export(from: Int64? = nil, to: Int64? = nil, format: String = "csv", _ completion: @escaping (Result<String, SdkError>) -> Void) {
    invoke("export", ["from": from, "to": to, "format": format], completion)
  }
  /// Delete local data and return the number of deleted items; neither is transmitted = all。
  public func deleteData(from: Int64? = nil, to: Int64? = nil, wearId: Int64? = nil, _ completion: @escaping (Result<Int, SdkError>) -> Void) {
    invoke("deleteData", ["from": from, "to": to, "wearId": wearId], completion)
  }
  public func count(wearId: Int64? = nil, _ completion: @escaping (Result<Int, SdkError>) -> Void) { invoke("count", ["wearId": wearId], completion) }

  // ───────────────────────── 24~25 log / diagnosis ─────────────────────────

  /// level：none / error / warn / info / debug。
  public func setLogLevel(_ level: String, _ completion: ((Result<Void, SdkError>) -> Void)? = nil) { invokeVoid("setLogLevel", ["level": level]) { completion?($0) } }
  /// Export diagnostic package zip，Return absolute path。
  public func exportDiagnostics(_ completion: @escaping (Result<String, SdkError>) -> Void) { invoke("exportDiagnostics", nil, completion) }

  // ───────────────────────── event ─────────────────────────

  private var connectionListeners: [(String) -> Void] = []
  private var deviceStatusListeners: [(DeviceStatus) -> Void] = []
  private var glucoseListeners: [(GlucoseSample) -> Void] = []
  private var algoListeners: [(AlgoResult) -> Void] = []
  private var progressListeners: [(Progress) -> Void] = []
  private var errorListeners: [(SdkErrorEvent) -> Void] = []
  private var logListeners: [(LogEntry) -> Void] = []
  private var scanListener: ((ScanDevice) -> Void)?
  private var watchListener: (([GlucoseSample]) -> Void)?
  private var bindHook: ((BindCheck, @escaping (BindDecision) -> Void) -> Void)?

  /// event 1：connection status disconnected / scanning / connecting / connected / reconnecting。
  public func onConnectionState(_ l: @escaping (String) -> Void) { connectionListeners.append(l) }
  /// event 2：Device status。
  public func onDeviceStatus(_ l: @escaping (DeviceStatus) -> Void) { deviceStatusListeners.append(l) }
  /// event 3：New blood sugar (when replenishing source == backfill Will push many posts in a short period of time）。
  public func onGlucose(_ l: @escaping (GlucoseSample) -> Void) { glucoseListeners.append(l) }
  /// event 4：Algorithm complete output。
  public func onAlgoResult(_ l: @escaping (AlgoResult) -> Void) { algoListeners.append(l) }
  /// event 5：schedule。
  public func onProgress(_ l: @escaping (Progress) -> Void) { progressListeners.append(l) }
  /// event 6：Errors and warnings。
  public func onError(_ l: @escaping (SdkErrorEvent) -> Void) { errorListeners.append(l) }
  /// event 7：SDK log。
  public func onLog(_ l: @escaping (LogEntry) -> Void) { logListeners.append(l) }
  /// Clear all event monitoring。
  public func removeAllListeners() {
    connectionListeners = []; deviceStatusListeners = []; glucoseListeners = []; algoListeners = []
    progressListeners = []; errorListeners = []; logListeners = []
  }

  /// Dart → Host: Events and bind pre-callback。
  private func onDartCall(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch call.method {
    case "event":
      let m = call.arguments as? [String: Any] ?? [:]
      let data = m["data"] as? [String: Any] ?? [:]
      switch m["event"] as? String {
      case "connectionState": connectionListeners.forEach { $0(data.s("state")) }
      case "deviceStatus": let d = DeviceStatus.from(data); deviceStatusListeners.forEach { $0(d) }
      case "glucose": let d = GlucoseSample.from(data); glucoseListeners.forEach { $0(d) }
      case "algoResult": let d = AlgoResult.from(data); algoListeners.forEach { $0(d) }
      case "progress": let d = Progress.from(data); progressListeners.forEach { $0(d) }
      case "error": let d = SdkErrorEvent.from(data); errorListeners.forEach { $0(d) }
      case "log": let d = LogEntry.from(data); logListeners.forEach { $0(d) }
      case "scanResult": scanListener?(ScanDevice.from(data))
      case "watch": watchListener?((data["samples"] as? [[String: Any]] ?? []).map(GlucoseSample.from))
      default: break
      }
      result(nil)
    case "beforeActivate":
      let check = BindCheck.from(call.arguments as? [String: Any] ?? [:])
      guard let hook = bindHook else {
        result(CgmSdk.sanitize(BindDecision.proceed().map))
        return
      }
      hook(check) { decision in DispatchQueue.main.async { result(CgmSdk.sanitize(decision.map)) } }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // ───────────────────────── channel encapsulation ─────────────────────────

  private func invokeAny(_ method: String, _ args: [String: Any?]?, _ completion: @escaping (Result<Any?, SdkError>) -> Void) {
    guard let ch = api else {
      completion(.failure(SdkError(code: "E_NOT_INITIALIZED", message: "Adjust first CgmSdk.shared.initialize()")))
      return
    }
    DispatchQueue.main.async {
      ch.invokeMethod(method, arguments: args.map { CgmSdk.sanitize($0) }) { result in
        if let err = result as? FlutterError {
          completion(.failure(SdkError(code: err.code, message: err.message)))
        } else if let obj = result as? NSObject, obj === FlutterMethodNotImplemented {
          completion(.failure(SdkError(code: "E_NOT_IMPLEMENTED", message: method)))
        } else {
          completion(.success(result is NSNull ? nil : result))
        }
      }
    }
  }

  /// Remove nested dictionaries / in array nil（Flutter Channel codec not recognized Swift of Optional.none）。
  private static func sanitize(_ dict: [String: Any?]) -> [String: Any] {
    var out: [String: Any] = [:]
    for (k, v) in dict {
      if let cleaned = sanitizeValue(v) { out[k] = cleaned }
    }
    return out
  }

  private static func sanitizeValue(_ v: Any?) -> Any? {
    guard let v = v else { return nil }
    if let d = v as? [String: Any?] { return sanitize(d) }
    if let a = v as? [Any?] { return a.compactMap { sanitizeValue($0) } }
    return v
  }

  private func invoke<T>(_ method: String, _ args: [String: Any?]?, _ completion: @escaping (Result<T, SdkError>) -> Void) {
    invokeAny(method, args) { r in
      completion(r.flatMap { (v) -> Result<T, SdkError> in
        if let t = v as? T { return .success(t) }
        return .failure(SdkError(code: "E_BAD_RESULT", message: "\(method) return \(String(describing: v))"))
      })
    }
  }

  private func invokeVoid(_ method: String, _ args: [String: Any?]?, _ completion: @escaping (Result<Void, SdkError>) -> Void) {
    invokeAny(method, args) { completion($0.map { _ in () }) }
  }

  private func invokeMap<T>(_ method: String, _ args: [String: Any?]?, _ parse: @escaping ([String: Any]) -> T,
                            _ completion: @escaping (Result<T, SdkError>) -> Void) {
    invokeAny(method, args) { r in
      completion(r.flatMap { (v) -> Result<T, SdkError> in
        if let m = v as? [String: Any] { return .success(parse(m)) }
        return .failure(SdkError(code: "E_BAD_RESULT", message: "\(method) return \(String(describing: v))"))
      })
    }
  }

  private func invokeMapOrNil<T>(_ method: String, _ args: [String: Any?]?, _ parse: @escaping ([String: Any]) -> T,
                                 _ completion: @escaping (Result<T?, SdkError>) -> Void) {
    invokeAny(method, args) { r in completion(r.map { v in (v as? [String: Any]).map(parse) }) }
  }

  private func invokeList<T>(_ method: String, _ args: [String: Any?]?, _ parse: @escaping ([String: Any]) -> T,
                             _ completion: @escaping (Result<[T], SdkError>) -> Void) {
    invokeAny(method, args) { r in completion(r.map { v in (v as? [[String: Any]] ?? []).map(parse) }) }
  }
}

// Map Value widget：Dart The end-integer warp channel may be Int / Int64 / NSNumber。
fileprivate extension Dictionary where Key == String, Value == Any {
  func s(_ k: String) -> String {
    guard let v = self[k], !(v is NSNull) else { return "" }
    return (v as? String) ?? "\(v)"
  }
  func sn(_ k: String) -> String? { self[k] is NSNull ? nil : self[k] as? String }
  func d(_ k: String) -> Double? { (self[k] as? NSNumber)?.doubleValue }
  func i(_ k: String) -> Int? { (self[k] as? NSNumber)?.intValue }
  func l(_ k: String) -> Int64? { (self[k] as? NSNumber)?.int64Value }
}
