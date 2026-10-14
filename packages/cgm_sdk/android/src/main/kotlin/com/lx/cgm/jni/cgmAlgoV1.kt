package com.lx.cgm.jni

import android.util.Log

/**
 * Lianxin CGM Algorithm library V1.2.7 JNI interface。external Signed with libdtProc.so one-to-one correspondence；
 * package name com.lx.cgm.jni yes .so The reflection convention is hard-coded and cannot be changed.。
 */
object cgmAlgoV1 {
    private const val TAG = "cgmAlgoV1"
    private var isLoaded = false

    // .so must be in any external Load before calling, put object in initialization block —— Kotlin object first time
    // Executed on access，version/init/dataProc No matter which entrance comes first, you can’t go around it.。
    //
    // Originally there were only MethodChannel of "init" branch tone initLibrary()，and JniAlgorithmGateway.init()
    // The first line is ”First enter an algorithm library version number」→ Walk "version" branch → The library has not been installed yet →
    // UnsatisfiedLinkError → init() Throw away the whole → The algorithm can never be initialized and a blood glucose cannot be calculated.。
    // 2026-08-31 Real machine release Empirical evidence: one per frame
    // 「No implementation found for byte[] com.lx.cgm.jni.cgmAlgoV1.version()」，
    // Zero all the way [algo] Logs, zero uploads. Single test walk Mock Gateway, this real channel cannot be detected。
    init {
        initLibrary()
    }

    fun initLibrary() {
        if (isLoaded) return
        try {
            System.loadLibrary("dtProc")
        } catch (e: Throwable) {
            Log.e(TAG, "Loading failedso: ${e.message}")
        } finally {
            isLoaded = true
        }
    }

    // catch Throwable instead of Exception：When loading fails native The call throws UnsatisfiedLinkError，
    // it is Error no Exception，catch(Exception) If it cannot be caught, it will be thrown all the way to the bridge layer and become ALGO_ERR。
    // The version number is just diagnostic information. If you can’t get it, report it. Unknown，Never bring the caller down。
    fun getVersionString(): String = try {
        version().decodeToString()
    } catch (e: Throwable) {
        Log.e(TAG, "Failed to get algorithm library version: ${e.message}")
        "Unknown"
    }

    external fun version(): ByteArray

    // step 1: Load algorithm library + Write core calibration。tempcoef1=Factory sensitivityk、tempcoef2=Factory interceptb。
    external fun init(
        startTs: Int,
        paramBGMbase: Double,
        tempcoef1: Double,
        tempcoef2: Double
    ): Boolean

    // step 2: Call in a loop to calculate blood sugar one by one. The result is given by .so Reflection backfills the incoming GlucoseValue。
    external fun dataProc(
        srcData: Double,
        temperature: Double,
        ts: Int,
        result: GlucoseValue
    ): Boolean

    // step 3: Uninstall algorithm library
    external fun uninit(): Boolean

    // ── The following are optional，init Adjust it later; the item algorithm library that has not been adjusted uses the built-in default ──

    // Optional: Set the positive sensitivity parameter of the algorithm Phase 1
    external fun setPositiveslope1(dVal: Double): Boolean

    // Optional: Set the negative sensitivity parameter of the algorithm Phase 1
    external fun setNegativeslope1(dVal: Double): Boolean

    // Optional: Set the positive sensitivity parameter of the algorithm Phase 2。bUseBgSet=true This value is forced to be used and will not be modified by the algorithm library.
    external fun setPositiveslope2(dVal: Double, bUseBgSet: Boolean): Boolean

    // Optional: Set the negative sensitivity parameter of the algorithm Phase 2
    external fun setNegativeslope2(dVal: Double): Boolean

    // Optional: Set daytime Kalman filter parameters
    external fun setDayKalman(dQ: Double, dR: Double): Boolean

    // Optional: Set nighttime Kalman filter parameters
    external fun setNightKalman(dQ: Double, dR: Double): Boolean
}
