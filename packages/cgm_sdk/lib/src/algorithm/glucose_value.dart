/// dataProc() output. Field alignment native GlucoseValue.java / GluValueRet(iOS)，JNI backfill by reflection，
/// The native side field name cannot be changed。V1.2.4 The starting algorithm will not return stage / algoslope / algointercept / i_t_used；
/// V1.2.7 New current_remove_squeeze1/2、glucosePre Three diagnostic fields。
class GlucoseValue {
  /// blood sugar level（mmol/L）。
  final double value;

  final int idx;

  final double current;

  /// Current value after base drift removal（IIR filter）。
  final double currentIirFilter;

  /// The current value after removing the base drift from the median value。
  final double currentMedianFilter;

  final double currentBase;

  /// The current actual sensitivity used (effective slope）。
  final double sensitivityUsed;

  final double dayKalmanParamQ;

  final double dayKalmanParamR;

  final double nightKalmanParamQ;

  final double nightKalmanParamR;

  /// Current value after squeezing noise removal 1 / 2（V1.2.7 New, for diagnosis）。
  final double currentRemoveSqueeze1;
  final double currentRemoveSqueeze2;

  /// Predict blood sugar levels（V1.2.7 New, for diagnosis）。
  final double glucosePre;

  const GlucoseValue({
    required this.value,
    required this.idx,
    required this.current,
    required this.currentIirFilter,
    required this.currentMedianFilter,
    required this.currentBase,
    required this.sensitivityUsed,
    required this.dayKalmanParamQ,
    required this.dayKalmanParamR,
    required this.nightKalmanParamQ,
    required this.nightKalmanParamR,
    this.currentRemoveSqueeze1 = 0,
    this.currentRemoveSqueeze2 = 0,
    this.glucosePre = 0,
  });

  /// from Map Assembly, key name alignment native GlucoseValue/GluValueRet，Missing fields press 0 reveal all the details。
  factory GlucoseValue.fromMap(Map<String, dynamic> m) {
    double d(String k) => (m[k] as num?)?.toDouble() ?? 0.0;
    int i(String k) => (m[k] as num?)?.toInt() ?? 0;
    return GlucoseValue(
      value: d('value'),
      idx: i('idx'),
      current: d('current'),
      currentIirFilter: d('current_iir_filter'),
      currentMedianFilter: d('current_median_filter'),
      currentBase: d('current_base'),
      sensitivityUsed: d('sensitivity_used'),
      dayKalmanParamQ: d('day_kalman_paramQ'),
      dayKalmanParamR: d('day_kalman_paramR'),
      nightKalmanParamQ: d('night_kalman_paramQ'),
      nightKalmanParamR: d('night_kalman_paramR'),
      currentRemoveSqueeze1: d('current_remove_squeeze1'),
      currentRemoveSqueeze2: d('current_remove_squeeze2'),
      glucosePre: d('glucosePre'),
    );
  }
}
