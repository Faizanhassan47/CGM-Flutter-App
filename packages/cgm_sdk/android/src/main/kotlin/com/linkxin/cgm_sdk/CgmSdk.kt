package com.linkxin.cgm_sdk

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * For native hosts SDK facade（Kotlin）。Create a no-interface internally FlutterEngine implement cgm_sdk_module entrance，
 * All calls MethodChannel transfer to Dart Side facade; method name / Parameter name / Error code and《CGM SDK Interface document” consistent。
 *
 * - The results `Result<T>` callback, on failure `exceptionOrNull()` yes [CgmSdkException]（`code` = Document error code）。
 * - For events `onXxx { }` Register for monitoring (you can register multiple times and you will receive）。
 * - All callbacks / Events are all on the main thread。
 */
object CgmSdk {
    private const val API_CHANNEL = "com.linkxin.cgm_sdk/api"
    private const val EVENT_CHANNEL = "com.linkxin.cgm_sdk/events"

    private var engine: FlutterEngine? = null
    private var api: MethodChannel? = null
    private var events: MethodChannel? = null
    private val main = Handler(Looper.getMainLooper())

    // ───────────────────────── data object ─────────────────────────

    /** Initial configuration (interface 1）。 */
    data class Config(
        val logLevel: String = "info",
        val foregroundNotice: String = "Blood glucose monitoring",
        val minBatteryMv: Int = 2800,
        val warmupMinutes: Int = 120,
    ) {
        internal fun toMap() = mapOf(
            "logLevel" to logLevel, "foregroundNotice" to foregroundNotice,
            "minBatteryMv" to minBatteryMv, "warmupMinutes" to warmupMinutes,
        )
    }

    /**
     * Algorithm parameters (alignment algorithm library V1.2.7 interface）：tempCoef1 = Factory sensitivity k、tempCoef2 = Factory intercept b
     * （QR code 4/5 part），bgmBase = Finger blood reference (not transmitted SDK use 6.8 cover); the rest are optional parameters，
     * Not passed on = The algorithm library uses the built-in default, Kalman Q/R Must be passed in pairs。positiveSlope2Fixed = Mandatory use
     * positiveSlope2、Not modified by the algorithm library。
     */
    data class AlgoParams(
        val tempCoef1: Double, val tempCoef2: Double,
        val bgmBase: Double? = null,
        val positiveSlope1: Double? = null, val negativeSlope1: Double? = null,
        val positiveSlope2: Double? = null, val positiveSlope2Fixed: Boolean = false,
        val negativeSlope2: Double? = null,
        val dayKalmanQ: Double? = null, val dayKalmanR: Double? = null,
        val nightKalmanQ: Double? = null, val nightKalmanR: Double? = null,
    ) {
        internal fun toMap() = mapOf(
            "tempCoef1" to tempCoef1, "tempCoef2" to tempCoef2, "bgmBase" to bgmBase,
            "positiveSlope1" to positiveSlope1, "negativeSlope1" to negativeSlope1,
            "positiveSlope2" to positiveSlope2, "positiveSlope2Fixed" to positiveSlope2Fixed,
            "negativeSlope2" to negativeSlope2,
            "dayKalmanQ" to dayKalmanQ, "dayKalmanR" to dayKalmanR,
            "nightKalmanQ" to nightKalmanQ, "nightKalmanR" to nightKalmanR,
        )

        companion object {
            internal fun from(m: Map<*, *>?): AlgoParams? {
                val k = m?.d("tempCoef1") ?: return null
                val b = m.d("tempCoef2") ?: return null
                return AlgoParams(
                    k, b, m.d("bgmBase"),
                    m.d("positiveSlope1"), m.d("negativeSlope1"),
                    m.d("positiveSlope2"), m["positiveSlope2Fixed"] == true,
                    m.d("negativeSlope2"),
                    m.d("dayKalmanQ"), m.d("dayKalmanR"),
                    m.d("nightKalmanQ"), m.d("nightKalmanR"),
                )
            }
        }
    }

    /** QR code parsing results (interface 5）。 */
    data class QrInfo(
        val deviceId: String, val form: String, val calibration: AlgoParams?,
        val expireDate: Long?, val transmitterSn: String?, val sensorSn: String?,
    ) {
        companion object {
            internal fun from(m: Map<*, *>) = QrInfo(
                m.s("deviceId"), m.s("form"), AlgoParams.from(m["calibration"] as? Map<*, *>),
                m.l("expireDate"), m.sn("transmitterSn"), m.sn("sensorSn"),
            )
        }
    }

    /** Scanned devices (interfaces 6）。 */
    data class ScanDevice(val deviceId: String, val name: String, val bleId: String, val rssi: Int) {
        companion object {
            internal fun from(m: Map<*, *>) = ScanDevice(m.s("deviceId"), m.s("name"), m.s("bleId"), m.i("rssi") ?: 0)
        }
    }

    /** Wearing record (interface 8 / 9 / 13）。The time is UTC millisecond。 */
    data class WearInfo(
        val wearId: Long, val deviceId: String, val bleId: String, val form: String,
        val activatedAt: Long, val warmupEndAt: Long, val expiresAt: Long,
        val calibration: AlgoParams? = null,
        val transmitterSn: String? = null, val sensorSn: String? = null,
    ) {
        internal fun toMap() = mapOf(
            "wearId" to wearId, "deviceId" to deviceId, "bleId" to bleId, "form" to form,
            "activatedAt" to activatedAt, "warmupEndAt" to warmupEndAt, "expiresAt" to expiresAt,
            "calibration" to calibration?.toMap(), "transmitterSn" to transmitterSn, "sensorSn" to sensorSn,
        )

        companion object {
            internal fun from(m: Map<*, *>) = WearInfo(
                m.l("wearId") ?: 0L, m.s("deviceId"), m.s("bleId"), m.s("form"),
                m.l("activatedAt") ?: 0L, m.l("warmupEndAt") ?: 0L, m.l("expiresAt") ?: 0L,
                AlgoParams.from(m["calibration"] as? Map<*, *>), m.sn("transmitterSn"), m.sn("sensorSn"),
            )
        }
    }

    /** bind After passing the verification, it is handed over to the host site (interface 8 callback）。 */
    data class BindCheck(
        val transmitterId: Long, val transmitterSn: String, val sensorId: Long, val sensorSn: String,
        val bluetoothAddr: String, val batteryMv: Int, val inUse: Boolean, val at: Long,
    ) {
        companion object {
            internal fun from(m: Map<*, *>) = BindCheck(
                m.l("transmitterId") ?: 0L, m.s("transmitterSn"), m.l("sensorId") ?: 0L, m.s("sensorSn"),
                m.s("bluetoothAddr"), m.i("batteryMv") ?: 0, m["inUse"] == true, m.l("at") ?: 0L,
            )
        }
    }

    /** The host is beforeActivate decision。 */
    class BindDecision private constructor(internal val map: Map<String, Any?>) {
        companion object {
            /** Release; can be worn with rear-end distribution ID / Preheating end time（UTC millisecond）。 */
            @JvmStatic
            fun proceed(wearId: Long? = null, preheatEndAt: Long? = null) =
                BindDecision(mapOf("proceed" to true, "wearId" to wearId, "preheatEndAt" to preheatEndAt))

            /** abort，message Give it back as it is bind the caller（E_BIND_REJECTED）。 */
            @JvmStatic
            fun abort(message: String) = BindDecision(mapOf("proceed" to false, "message" to message))
        }
    }

    /** Device information (interface 14）。 */
    data class DeviceInfo(
        val deviceId: String, val firmware: String, val batteryMv: Int,
        val latestSeq: Int, val measuring: Boolean, val measuredSec: Int,
    ) {
        companion object {
            internal fun from(m: Map<*, *>) = DeviceInfo(
                m.s("deviceId"), m.s("firmware"), m.i("batteryMv") ?: 0,
                m.i("latestSeq") ?: 0, m["measuring"] == true, m.i("measuredSec") ?: 0,
            )
        }
    }

    /** A blood glucose (interface 17 / 18 / 19、event 3）。 */
    data class GlucoseSample(
        val wearId: Long, val seq: Int, val measuredAt: Long, val value: Double?,
        val warmup: Boolean, val abnormal: Boolean, val source: String,
        val rawCurrent: Double?, val temperature: Double?, val voltage: Double?,
    ) {
        companion object {
            internal fun from(m: Map<*, *>) = GlucoseSample(
                m.l("wearId") ?: 0L, m.i("seq") ?: 0, m.l("measuredAt") ?: 0L, m.d("value"),
                m["warmup"] == true, m["abnormal"] == true, m.s("source"),
                m.d("rawCurrent"), m.d("temperature"), m.d("voltage"),
            )
        }
    }

    /** Device raw data (interface 20）。 */
    data class RawSample(
        val wearId: Long, val seq: Int, val measuredAt: Long,
        val current: Double?, val temperature: Double?, val voltage: Double?, val lactate: Double?,
    ) {
        companion object {
            internal fun from(m: Map<*, *>) = RawSample(
                m.l("wearId") ?: 0L, m.i("seq") ?: 0, m.l("measuredAt") ?: 0L,
                m.d("current"), m.d("temperature"), m.d("voltage"), m.d("lactate"),
            )
        }
    }

    /** device status (event 2）。 */
    data class DeviceStatus(
        val connected: Boolean, val batteryMv: Int?, val temperature: Double?, val latestSeq: Int?,
        val measuring: Boolean, val flashFull: Boolean, val warmupRemainingMin: Int, val remainingDays: Int,
        val abnormal: String?,
    ) {
        companion object {
            internal fun from(m: Map<*, *>) = DeviceStatus(
                m["connected"] == true, m.i("batteryMv"), m.d("temperature"), m.i("latestSeq"),
                m["measuring"] == true, m["flashFull"] == true, m.i("warmupRemainingMin") ?: 0,
                m.i("remainingDays") ?: 0, m.sn("abnormal"),
            )
        }
    }

    /** Algorithm complete output (event 4）。 */
    data class AlgoResult(
        val seq: Int, val value: Double, val current: Double, val currentIirFilter: Double,
        val currentMedianFilter: Double, val currentBase: Double, val sensitivityUsed: Double,
        val dayKalmanQ: Double, val dayKalmanR: Double, val nightKalmanQ: Double, val nightKalmanR: Double,
        val currentRemoveSqueeze1: Double = 0.0, val currentRemoveSqueeze2: Double = 0.0, val glucosePre: Double = 0.0,
    ) {
        companion object {
            internal fun from(m: Map<*, *>) = AlgoResult(
                m.i("seq") ?: 0, m.d("value") ?: 0.0, m.d("current") ?: 0.0, m.d("currentIirFilter") ?: 0.0,
                m.d("currentMedianFilter") ?: 0.0, m.d("currentBase") ?: 0.0, m.d("sensitivityUsed") ?: 0.0,
                m.d("dayKalmanQ") ?: 0.0, m.d("dayKalmanR") ?: 0.0, m.d("nightKalmanQ") ?: 0.0, m.d("nightKalmanR") ?: 0.0,
                m.d("currentRemoveSqueeze1") ?: 0.0, m.d("currentRemoveSqueeze2") ?: 0.0, m.d("glucosePre") ?: 0.0,
            )
        }
    }

    /** progress(event 5）：kind = warmup / backfill / replay。 */
    data class Progress(val kind: String, val done: Int, val total: Int) {
        companion object {
            internal fun from(m: Map<*, *>) = Progress(m.s("kind"), m.i("done") ?: 0, m.i("total") ?: 0)
        }
    }

    /** Errors and warnings (events 6）。 */
    data class SdkError(val code: String, val severity: String, val message: String) {
        companion object {
            internal fun from(m: Map<*, *>) = SdkError(m.s("code"), m.s("severity"), m.s("message"))
        }
    }

    /** SDK log(event 7）。 */
    data class LogEntry(val at: Long, val level: String, val tag: String, val message: String) {
        companion object {
            internal fun from(m: Map<*, *>) = LogEntry(m.l("at") ?: 0L, m.s("level"), m.s("tag"), m.s("message"))
        }
    }

    // ───────────────────────── 1~4 life cycle ─────────────────────────

    /**
     * App Call once at startup; repeated calls have no side effects. Immediately after starting the engine init Give Dart side (open the encryption library, assemble Bluetooth and capture），
     * [callback] After receiving successfully, you can adjust other interfaces。
     */
    @JvmStatic
    @JvmOverloads
    fun init(context: Context, config: Config = Config(), callback: ((Result<Unit>) -> Unit)? = null) {
        if (engine == null) {
            // FlutterEngine Will go through when constructing GeneratedPluginRegistrant All plug-ins in the automatic registration module (including algorithm bridge）
            val e = FlutterEngine(context.applicationContext)
            e.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
            api = MethodChannel(e.dartExecutor.binaryMessenger, API_CHANNEL)
            events = MethodChannel(e.dartExecutor.binaryMessenger, EVENT_CHANNEL).also {
                it.setMethodCallHandler { call, result -> onDartCall(call, result) }
            }
            engine = e
        }
        invoke<Unit>("init", mapOf("config" to config.toMap())) { r -> callback?.invoke(r) }
    }

    /** Release the engine. Generally only in the host App Exit time tune。 */
    @JvmStatic
    fun dispose() {
        invoke<Unit>("dispose") {
            events?.setMethodCallHandler(null)
            engine?.destroy()
            engine = null
            api = null
            events = null
        }
    }

    /** SDK Version。 */
    @JvmStatic
    fun version(callback: (Result<String>) -> Unit) = invoke("version", null, callback)

    /** Algorithm library version (from .so）。Adjust this first after integration. If the version number can be returned, it means the link is connected.。 */
    @JvmStatic
    fun algorithmVersion(callback: (Result<String>) -> Unit) = invoke("algorithmVersion", null, callback)

    // ───────────────────────── 5~7 QR code / scanning ─────────────────────────

    /** Parse device QR code。 */
    @JvmStatic
    fun parseQrCode(qr: String, callback: (Result<QrInfo>) -> Unit) =
        invokeMap("parseQrCode", mapOf("qr" to qr), callback) { QrInfo.from(it) }

    /**
     * Scan for nearby devices: callback every time one is found [onDevice] Once; scan ends (timeout / stopScan）callback [onDone]。
     */
    @JvmStatic
    @JvmOverloads
    fun scan(timeoutSeconds: Int = 10, onDevice: (ScanDevice) -> Unit, onDone: (Result<Unit>) -> Unit) {
        scanListener = onDevice
        invoke<Unit>("scan", mapOf("timeoutSeconds" to timeoutSeconds)) { r ->
            scanListener = null
            onDone(r)
        }
    }

    /** End scan early。 */
    @JvmStatic
    fun stopScan(callback: ((Result<Unit>) -> Unit)? = null) = invoke<Unit>("stopScan") { callback?.invoke(it) }

    // ───────────────────────── 8~14 binding / connect ─────────────────────────

    /**
     * Bind and activate。[beforeActivate] Adjust after passing the verification and before activation: The host adjusts its own backend binding interface，
     * Adjust after completion `done(BindDecision.proceed(...))` or `done(BindDecision.abort("reason"))`（Can be called in any thread）。
     */
    @JvmStatic
    @JvmOverloads
    fun bind(
        deviceId: String,
        form: String,
        calibration: AlgoParams,
        expireDate: Long? = null,
        transmitterSn: String? = null,
        sensorSn: String? = null,
        beforeActivate: ((check: BindCheck, done: (BindDecision) -> Unit) -> Unit)? = null,
        callback: (Result<WearInfo>) -> Unit,
    ) {
        bindHook = beforeActivate
        invokeMap(
            "bind",
            mapOf(
                "deviceId" to deviceId, "form" to form, "calibration" to calibration.toMap(),
                "expireDate" to expireDate, "transmitterSn" to transmitterSn, "sensorSn" to sensorSn,
                "hasBeforeActivate" to (beforeActivate != null),
            ),
            { r -> bindHook = null; callback(r) },
        ) { WearInfo.from(it) }
    }

    /** Restore the bound device (change the device / Reinstall / cold start）。 */
    @JvmStatic
    fun resume(wear: WearInfo, callback: (Result<Unit>) -> Unit) = invoke("resume", mapOf("wear" to wear.toMap()), callback)

    /** Manual connection。 */
    @JvmStatic
    fun connect(callback: (Result<Unit>) -> Unit) = invoke("connect", null, callback)

    /** Manual disconnect。 */
    @JvmStatic
    fun disconnect(callback: (Result<Unit>) -> Unit) = invoke("disconnect", null, callback)

    /** unbundle。 */
    @JvmStatic
    fun unbind(callback: (Result<Unit>) -> Unit) = invoke("unbind", null, callback)

    /** Current wearing record; not bound to null。 */
    @JvmStatic
    fun currentWear(callback: (Result<WearInfo?>) -> Unit) =
        invokeMapOrNull("currentWear", null, callback) { WearInfo.from(it) }

    /** Read the status once to the device。 */
    @JvmStatic
    fun deviceInfo(callback: (Result<DeviceInfo>) -> Unit) = invokeMap("deviceInfo", null, callback) { DeviceInfo.from(it) }

    // ───────────────────────── 15~16 Algorithm parameters ─────────────────────────

    @JvmStatic
    fun setAlgoParams(params: AlgoParams, callback: (Result<Unit>) -> Unit) =
        invoke("setAlgoParams", mapOf("params" to params.toMap()), callback)

    @JvmStatic
    fun getAlgoParams(callback: (Result<AlgoParams?>) -> Unit) =
        invokeMapOrNull("getAlgoParams", null, callback) { AlgoParams.from(it)!! }

    // ───────────────────────── 17~23 local data ─────────────────────────

    /** by time period（UTC milliseconds) to check blood sugar, ascending order。 */
    @JvmStatic
    @JvmOverloads
    fun query(from: Long? = null, to: Long? = null, wearId: Long? = null, limit: Int = 5000, callback: (Result<List<GlucoseSample>>) -> Unit) =
        invokeList("query", mapOf("from" to from, "to" to to, "wearId" to wearId, "limit" to limit), callback) { GlucoseSample.from(it) }

    @JvmStatic
    fun latest(callback: (Result<GlucoseSample?>) -> Unit) =
        invokeMapOrNull("latest", null, callback) { GlucoseSample.from(it) }

    /** Subscribe to new blood sugar: push a batch first [from] If there are existing ones after that, they will be pushed once for each new batch.；[unwatch] stop。 */
    @JvmStatic
    @JvmOverloads
    fun watch(from: Long? = null, listener: (List<GlucoseSample>) -> Unit) {
        watchListener = listener
        invoke<Unit>("watch", mapOf("from" to from)) {}
    }

    @JvmStatic
    fun unwatch() {
        watchListener = null
        invoke<Unit>("unwatch") {}
    }

    @JvmStatic
    @JvmOverloads
    fun queryRaw(from: Long? = null, to: Long? = null, callback: (Result<List<RawSample>>) -> Unit) =
        invokeList("queryRaw", mapOf("from" to from, "to" to to), callback) { RawSample.from(it) }

    /** Export csv / json，Returns the absolute path of the file。 */
    @JvmStatic
    @JvmOverloads
    fun export(from: Long? = null, to: Long? = null, format: String = "csv", callback: (Result<String>) -> Unit) =
        invoke("export", mapOf("from" to from, "to" to to, "format" to format), callback)

    /** Delete local data and return the number of deleted items; neither is transmitted = all。 */
    @JvmStatic
    @JvmOverloads
    fun deleteData(from: Long? = null, to: Long? = null, wearId: Long? = null, callback: (Result<Int>) -> Unit) =
        invoke("deleteData", mapOf("from" to from, "to" to to, "wearId" to wearId), callback)

    @JvmStatic
    @JvmOverloads
    fun count(wearId: Long? = null, callback: (Result<Int>) -> Unit) = invoke("count", mapOf("wearId" to wearId), callback)

    // ───────────────────────── 24~25 log / diagnosis ─────────────────────────

    /** level：none / error / warn / info / debug。 */
    @JvmStatic
    fun setLogLevel(level: String, callback: ((Result<Unit>) -> Unit)? = null) =
        invoke<Unit>("setLogLevel", mapOf("level" to level)) { callback?.invoke(it) }

    /** Export diagnostic package zip，Return absolute path。 */
    @JvmStatic
    fun exportDiagnostics(callback: (Result<String>) -> Unit) = invoke("exportDiagnostics", null, callback)

    // ───────────────────────── event ─────────────────────────

    private val connectionListeners = mutableListOf<(String) -> Unit>()
    private val deviceStatusListeners = mutableListOf<(DeviceStatus) -> Unit>()
    private val glucoseListeners = mutableListOf<(GlucoseSample) -> Unit>()
    private val algoListeners = mutableListOf<(AlgoResult) -> Unit>()
    private val progressListeners = mutableListOf<(Progress) -> Unit>()
    private val errorListeners = mutableListOf<(SdkError) -> Unit>()
    private val logListeners = mutableListOf<(LogEntry) -> Unit>()
    private var scanListener: ((ScanDevice) -> Unit)? = null
    private var watchListener: ((List<GlucoseSample>) -> Unit)? = null
    private var bindHook: ((BindCheck, (BindDecision) -> Unit) -> Unit)? = null

    /** event 1：connection status disconnected / scanning / connecting / connected / reconnecting。 */
    @JvmStatic fun onConnectionState(l: (String) -> Unit) { connectionListeners += l }
    /** event 2：Device status。 */
    @JvmStatic fun onDeviceStatus(l: (DeviceStatus) -> Unit) { deviceStatusListeners += l }
    /** event 3：New blood sugar (when replenishing source == backfill Will push many posts in a short period of time）。 */
    @JvmStatic fun onGlucose(l: (GlucoseSample) -> Unit) { glucoseListeners += l }
    /** event 4：Algorithm complete output。 */
    @JvmStatic fun onAlgoResult(l: (AlgoResult) -> Unit) { algoListeners += l }
    /** event 5：schedule。 */
    @JvmStatic fun onProgress(l: (Progress) -> Unit) { progressListeners += l }
    /** event 6：Errors and warnings。 */
    @JvmStatic fun onError(l: (SdkError) -> Unit) { errorListeners += l }
    /** event 7：SDK log。 */
    @JvmStatic fun onLog(l: (LogEntry) -> Unit) { logListeners += l }

    /** Clear all event monitoring。 */
    @JvmStatic
    fun removeAllListeners() {
        connectionListeners.clear(); deviceStatusListeners.clear(); glucoseListeners.clear(); algoListeners.clear()
        progressListeners.clear(); errorListeners.clear(); logListeners.clear()
    }

    /** Dart → Host: Events and bind pre-callback。 */
    private fun onDartCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "event" -> {
                val m = call.arguments as? Map<*, *>
                val data = m?.get("data") as? Map<*, *> ?: emptyMap<Any, Any>()
                when (m?.get("event")) {
                    "connectionState" -> connectionListeners.forEach { it(data.s("state")) }
                    "deviceStatus" -> DeviceStatus.from(data).let { d -> deviceStatusListeners.forEach { it(d) } }
                    "glucose" -> GlucoseSample.from(data).let { d -> glucoseListeners.forEach { it(d) } }
                    "algoResult" -> AlgoResult.from(data).let { d -> algoListeners.forEach { it(d) } }
                    "progress" -> Progress.from(data).let { d -> progressListeners.forEach { it(d) } }
                    "error" -> SdkError.from(data).let { d -> errorListeners.forEach { it(d) } }
                    "log" -> LogEntry.from(data).let { d -> logListeners.forEach { it(d) } }
                    "scanResult" -> scanListener?.invoke(ScanDevice.from(data))
                    "watch" -> watchListener?.let { l ->
                        l((data["samples"] as? List<*>)?.mapNotNull { (it as? Map<*, *>)?.let { m2 -> GlucoseSample.from(m2) } } ?: emptyList())
                    }
                }
                result.success(null)
            }
            "beforeActivate" -> {
                val hook = bindHook
                val check = BindCheck.from(call.arguments as? Map<*, *> ?: emptyMap<Any, Any>())
                if (hook == null) {
                    result.success(BindDecision.proceed().map)
                } else {
                    hook(check) { decision -> main.post { result.success(decision.map) } }
                }
            }
            else -> result.notImplemented()
        }
    }

    // ───────────────────────── channel encapsulation ─────────────────────────

    private fun <T> invoke(method: String, args: Map<String, Any?>? = null, callback: (Result<T>) -> Unit) {
        val ch = api
        if (ch == null) {
            callback(Result.failure(CgmSdkException("E_NOT_INITIALIZED", "Adjust first CgmSdk.init(context)")))
            return
        }
        main.post {
            ch.invokeMethod(method, args, object : MethodChannel.Result {
                @Suppress("UNCHECKED_CAST")
                override fun success(result: Any?) = callback(Result.success(result as T))

                override fun error(code: String, message: String?, details: Any?) =
                    callback(Result.failure(CgmSdkException(code, message)))

                override fun notImplemented() =
                    callback(Result.failure(CgmSdkException("E_NOT_IMPLEMENTED", method)))
            })
        }
    }

    private fun <T> invokeMap(method: String, args: Map<String, Any?>?, callback: (Result<T>) -> Unit, parse: (Map<*, *>) -> T) =
        invoke<Any?>(method, args) { r ->
            callback(r.mapCatching { v ->
                (v as? Map<*, *>)?.let(parse) ?: throw CgmSdkException("E_BAD_RESULT", "$method return $v")
            })
        }

    private fun <T> invokeMapOrNull(method: String, args: Map<String, Any?>?, callback: (Result<T?>) -> Unit, parse: (Map<*, *>) -> T) =
        invoke<Any?>(method, args) { r -> callback(r.mapCatching { v -> (v as? Map<*, *>)?.let(parse) }) }

    private fun <T> invokeList(method: String, args: Map<String, Any?>?, callback: (Result<List<T>>) -> Unit, parse: (Map<*, *>) -> T) =
        invoke<Any?>(method, args) { r ->
            callback(r.mapCatching { v -> (v as? List<*>)?.mapNotNull { (it as? Map<*, *>)?.let(parse) } ?: emptyList() })
        }

    private fun Map<*, *>.s(k: String) = this[k]?.toString() ?: ""
    private fun Map<*, *>.sn(k: String) = this[k]?.toString()
    private fun Map<*, *>.d(k: String) = (this[k] as? Number)?.toDouble()
    private fun Map<*, *>.i(k: String) = (this[k] as? Number)?.toInt()
    private fun Map<*, *>.l(k: String) = (this[k] as? Number)?.toLong()
}

/** SDK mistake：[code] Consistent with the document ”error code”。 */
class CgmSdkException(val code: String, message: String?) : Exception("$code: $message")
