/// Device link activity: the local time when the device frame was last received (including duplicate frames lost by deduplication and historical frames fed in by replenishment)）。
/// If there are multiple frames in the same minute, only the first one is recognized, and the device re-pushes the historical frames after reconnection, the link will be kept alive but no new blood glucose rows can be generated.，
/// The home page distinguishes between ”really no data received” and ”received but these frames do not generate new values”. What is recorded is the local time when the frame is received.
/// rather than in the frame measureTime；The process is lost when it is restarted。
class LinkActivity {
  LinkActivity._();

  static DateTime? lastFrameAt;

  /// The local time when the latest blood glucose was calculated and stored in the database. You can only use this to determine whether the data is broken: the firmware timestamp is calculated based on the record sequence number.，
  /// The number of minutes the device misses will be the number of minutes it lags behind. Get measureTime Compared with the mobile phone clock, it will always display ”data connection”.」。
  static DateTime? lastComputedAt;

  static void markFrame(DateTime at) => lastFrameAt = at;

  static void markComputed(DateTime at) => lastComputedAt = at;

  /// Stop collection/unbundle/Change wear Clear it when necessary to avoid holding the active moment of the previous cycle to suppress the interruption prompt.。
  static void reset() {
    lastFrameAt = null;
    lastComputedAt = null;
  }
}
