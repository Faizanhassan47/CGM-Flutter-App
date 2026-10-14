#pragma once

#include "stdbool.h"
#include "stdint.h"

typedef struct  {
    int idx;
    double value;
    double current;
    double current_iir_filter; // Current value after base drift removal
    double current_median_filter; // Current value after base drift removal
    double current_remove_squeeze1;  // Current value after squeezing noise removal1
		double current_remove_squeeze2;  // Current value after squeezing noise removal2
    double current_base;    // Baseline current
    double sensitivity_used;  // Current sensitivity in use
    double day_kalman_paramQ;  // Daytime Kalman filter parameters
    double day_kalman_paramR;  // Daytime Kalman filter parameters
    double night_kalman_paramQ; // Nighttime Kalman filter parameters
    double night_kalman_paramR; // Nighttime Kalman filter parameters
		double glucosePre;          // Predict blood sugar levels
}GluValueRet;
