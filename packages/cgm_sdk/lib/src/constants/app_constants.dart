class AppConstants {
  AppConstants._();

  static const String appName = 'LianxinCGM';
  static const String appVersion = '1.0.0';

  // BLE
  static const String bleServiceUuid = '0000FFF0-0000-1000-8000-00805F9B34FB';
  static const String bleCharFff1 = '0000FFF1-0000-1000-8000-00805F9B34FB';
  static const String bleCharFff2 = '0000FFF2-0000-1000-8000-00805F9B34FB';
  static const String bleScanFilterName = 'CLM';
  static const int bleMtuSize = 512;
  static const int bleMaxReconnectAttempts = 3;
  static const int bleReconnectIntervalMs = 3000;

  // blood glucose threshold mmol/L
  static const double glucoseVeryLow = 2.2;
  static const double glucoseLow = 3.9;
  static const double glucoseTargetLow = 3.9;
  static const double glucoseTargetHigh = 10.0;
  static const double glucoseHigh = 10.0;
  static const double glucoseVeryHigh = 13.9;
  static const double glucoseDisplayMax = 27.8;

  // algorithm
  static const int warmupDurationMinutes = 120;
  static const int warmupDataCount =
      119; // Warm-up period 119 bars, per minute 1 strip
  static const int interval5Minutes = 5;
  static const double correctionSlope = 0.88424;
  static const double correctionIntercept = -0.4145;
  static const int dataRecordBytes = 14;

  // The validity period of the sensor is obtained from the prototype activation page. 15 sky
  static const int sensorLifetimeDays = 15;

  // performance red line
  static const int coldStartMaxMs = 3000;
  static const int glucoseCalcMaxMs = 100;
  static const int memoryMaxMb = 150;

  // MethodChannel
  static const String algorithmChannel = 'com.linkxin.cgm/algorithm';
}
