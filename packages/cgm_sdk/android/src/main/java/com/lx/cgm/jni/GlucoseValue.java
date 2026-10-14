package com.lx.cgm.jni;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;

/**
 * Algorithm library V1.2.7 Output backfill objects. Field name/The method signature is libdtProc.so reflection convention, cannot be changed；
 * .so according to SetGluValue(IDDDDDDDDD)V Find method, number of parameters/Wrong order dataProc The whole thing failed。
 * @Keep Defend R8 confusion cropping。
 */
@Keep
public class GlucoseValue {
    private int idx;
    private double value;
    private double current;
    private double current_iir_filter;      // Current value after base drift removal
    private double current_remove_squeeze1; // Current value after squeezing noise removal1（V1.2.7 New）
    private double current_remove_squeeze2; // Current value after squeezing noise removal2（V1.2.7 New）
    private double current_median_filter;   // The current value after removing the base drift from the median value
    private double current_base;            // Baseline current
    private double sensitivity_used;        // Current sensitivity in use

    private double day_kalman_paramQ;    // Daytime Kalman filter parameters
    private double day_kalman_paramR;    //  Daytime Kalman filter parameters
    private double night_kalman_paramQ;  // Nighttime Kalman filter parameters
    private double night_kalman_paramR;  //  Nighttime Kalman filter parameters
    private double glucosePre;           // Predict blood sugar levels（V1.2.7 New）

    public GlucoseValue() {
    }

    // This method is called internally by the algorithm library to fill in the data and is not used by the caller.
    public void SetGluValue(int idx, double value, double current, double current_iir_filter,
                            double current_median_filter, double current_base, double sensitivity_used,
                            double current_remove_squeeze1, double current_remove_squeeze2,
                            double glucosePre) {
        this.idx = idx;   // Data serial number
        this.value = value; // blood sugar level
        this.current = current;  // Current value after filtering
        this.current_iir_filter = current_iir_filter;
        this.current_median_filter = current_median_filter;
        this.current_base = current_base;
        this.sensitivity_used = sensitivity_used;
        this.current_remove_squeeze1 = current_remove_squeeze1;
        this.current_remove_squeeze2 = current_remove_squeeze2;
        this.glucosePre = glucosePre;
    }

    // This method is called internally by the algorithm library to fill in the data and is not used by the caller.
    public void SetKalmanParam(double day_kalman_paramQ, double day_kalman_paramR, double night_kalman_paramQ,
                               double night_kalman_paramR) {
        this.day_kalman_paramQ   = day_kalman_paramQ;
        this.day_kalman_paramR   = day_kalman_paramR;
        this.night_kalman_paramQ = night_kalman_paramQ;
        this.night_kalman_paramR = night_kalman_paramR;
    }

    public int getIdx() {
        return idx;
    }

    public double getValue() {
        return value;
    }

    public double getCurrent() {
        return current;
    }

    public double getCurrent_iir_filter() {
        return current_iir_filter;
    }

    public double getCurrent_median_filter() {
        return current_median_filter;
    }

    public double getCurrent_base() {
        return current_base;
    }

    public double getSensitivity_used() {
        return sensitivity_used;
    }

    public double getDay_kalman_paramQ() {
        return day_kalman_paramQ;
    }

    public double getDay_kalman_paramR() {
        return day_kalman_paramR;
    }

    public double getNight_kalman_paramQ() {
        return night_kalman_paramQ;
    }

    public double getNight_kalman_paramR() {
        return night_kalman_paramR;
    }

    public double getCurrent_remove_squeeze1() {
        return current_remove_squeeze1;
    }

    public double getCurrent_remove_squeeze2() {
        return current_remove_squeeze2;
    }

    public double getGlucosePre() {
        return glucosePre;
    }

    @NonNull
    @Override
    public String toString() {
        return "GlucoseValue{" +
                "idx=" + idx +
                ", value=" + value +
                ", current=" + current +
                ", current_iir_filter=" + current_iir_filter +
                ", current_median_filter=" + current_median_filter +
                ", current_base=" + current_base +
                ", sensitivity_used=" + sensitivity_used +
                ", current_remove_squeeze1=" + current_remove_squeeze1 +
                ", current_remove_squeeze2=" + current_remove_squeeze2 +
                ", glucosePre=" + glucosePre +
                ", day_kalman_paramQ=" + day_kalman_paramQ +
                ", day_kalman_paramR=" + day_kalman_paramR +
                ", night_kalman_paramQ=" + night_kalman_paramQ +
                ", night_kalman_paramR=" + night_kalman_paramR +
                '}';
    }
}
