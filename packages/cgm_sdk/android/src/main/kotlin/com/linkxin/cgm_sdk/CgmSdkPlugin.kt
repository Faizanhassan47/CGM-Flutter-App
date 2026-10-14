package com.linkxin.cgm_sdk

import android.util.Log
import com.lx.cgm.jni.GlucoseValue
import com.lx.cgm.jni.cgmAlgoV1
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * CGM Algorithm library MethodChannel bridging（V1.2.7）。.so Depend on JNI Reflective writeback GlucoseValue，
 * can only be JVM Side adjustment，dart:ffi No way; the algorithm has a history window and is not thread-safe, and the serialization is Dart side guarantee。
 * Original App Inside CgmAlgorithmPlugin Import the plug-in as it is, and GeneratedPluginRegistrant Automatic registration。
 */
class CgmSdkPlugin : FlutterPlugin {
    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler { call, result -> handle(call, result) }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    companion object {
        private const val CHANNEL = "com.linkxin.cgm/algorithm"
        private const val TAG = "CgmSdkPlugin"
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "init" -> {
                    cgmAlgoV1.initLibrary()
                    val a = call.arguments as Map<*, *>
                    // slope→tempcoef1(Factory sensitivityk)、intercept→tempcoef2(Factory interceptb)。
                    val ok = cgmAlgoV1.init(
                        a.i("startTs"), a.d("paramBGMbase"),
                        a.d("slope"), a.d("intercept")
                    )
                    if (ok) applyTuning(a)
                    result.success(ok)
                }

                "dataProc" -> {
                    val a = call.arguments as Map<*, *>
                    val gv = GlucoseValue()
                    val ok = cgmAlgoV1.dataProc(
                        a.d("srcData"), a.d("temperature"), a.i("ts"), gv
                    )
                    result.success(if (ok) gv.toMap() else null)
                }

                "version" -> result.success(cgmAlgoV1.getVersionString())

                "uninit" -> result.success(cgmAlgoV1.uninit())

                else -> result.notImplemented()
            }
        } catch (e: Throwable) {
            result.error("ALGO_ERR", e.message, null)
        }
    }

    /**
     * init After success, apply the optional tuning parameters (algorithm library’s setXxx，In-factory testing/For background distribution）：Dart Keys that are not transmitted on the side
     * No correspondence setter，The algorithm library uses built-in default。setter return false Only logs and does not block（init Successfully）。
     */
    private fun applyTuning(a: Map<*, *>) {
        fun check(name: String, ok: Boolean) {
            if (!ok) Log.w(TAG, "$name return false，The value is not accepted by the algorithm library")
        }
        a.dn("positiveSlope1")?.let { check("setPositiveslope1", cgmAlgoV1.setPositiveslope1(it)) }
        a.dn("negativeSlope1")?.let { check("setNegativeslope1", cgmAlgoV1.setNegativeslope1(it)) }
        a.dn("positiveSlope2")?.let {
            check("setPositiveslope2", cgmAlgoV1.setPositiveslope2(it, a["positiveSlope2Fixed"] == true))
        }
        a.dn("negativeSlope2")?.let { check("setNegativeslope2", cgmAlgoV1.setNegativeslope2(it)) }
        val dq = a.dn("dayKalmanQ")
        val dr = a.dn("dayKalmanR")
        if (dq != null && dr != null) check("setDayKalman", cgmAlgoV1.setDayKalman(dq, dr))
        val nq = a.dn("nightKalmanQ")
        val nr = a.dn("nightKalmanR")
        if (nq != null && nr != null) check("setNightKalman", cgmAlgoV1.setNightKalman(nq, nr))
    }

    private fun GlucoseValue.toMap(): Map<String, Any> = mapOf(
        "idx" to idx,
        "value" to value,
        "current" to current,
        "current_iir_filter" to current_iir_filter,
        "current_median_filter" to current_median_filter,
        "current_remove_squeeze1" to current_remove_squeeze1,
        "current_remove_squeeze2" to current_remove_squeeze2,
        "current_base" to current_base,
        "sensitivity_used" to sensitivity_used,
        "day_kalman_paramQ" to day_kalman_paramQ,
        "day_kalman_paramR" to day_kalman_paramR,
        "night_kalman_paramQ" to night_kalman_paramQ,
        "night_kalman_paramR" to night_kalman_paramR,
        "glucosePre" to glucosePre
    )

    private fun Map<*, *>.d(k: String): Double = (this[k] as? Number)?.toDouble() ?: 0.0
    private fun Map<*, *>.dn(k: String): Double? = (this[k] as? Number)?.toDouble()
    private fun Map<*, *>.i(k: String): Int = (this[k] as? Number)?.toInt() ?: 0
}
