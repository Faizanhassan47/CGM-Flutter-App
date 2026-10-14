import 'package:cgm_sdk/src/log/dev_log.dart';

/// Device clock offset: the number of seconds that translates the ”device frame timestamp” into the ”real time”。
///
/// The transmitter does not RTC，The timestamp in the frame is equal to `t0 + SN×60`（t0 = When activated 0xD1 written benchmark，
/// The time will no longer be corrected after that), the essence is that the sampling count is not a clock: every time the device produces one less record, the axis will always lag behind by one minute.。
/// Just take it as `measure_time` After being dropped into the library, the restored records will be covered to the last few hours, and the last few hours of the home page will be covered.
/// Always empty, uploaded `measureTime` Also move forward。
///
/// The only source of real time is the local clock: real time 0xB0 Just measured when received，0xD3 In bulk package SN largest
/// That one was also just tested.。`skew = This machine is at this moment − The frame device timestamp`，within the same generation SN continuous，
/// The translation amount is common to the entire generation. You can only observe the frame that has just been measured, and the historical frame will be skew count as hours。
class DeviceClockSkew {
  DeviceClockSkew._();

  /// The jitter between real-time frames is updated after more than this many seconds to avoid jittering a little in each frame and shaking off the minute key for deduplication.。
  static const int _updateThresholdSec = 90;

  /// frame period。0xD3 The latest item in the batch package is at most FLASH I’ve been lying there for so long。
  static const int _periodSec = 60;

  static int _skewSec = 0;
  static bool _known = false;

  /// Whether the current value comes from a ”live frame”. The batch package only gives a nether seed, which must be removed as soon as the real-time frame arrives.。
  static bool _fromLive = false;

  /// Current translation amount (seconds), when not observed 0（Keep the original value of the device）。
  static int get skewSec => _skewSec;

  static bool get isKnown => _known;

  /// Device timestamp → real moment。
  static int toRealSec(int deviceTsSec) => deviceTsSec + _skewSec;

  /// The minimum interval between two real-time observations. The device only produces one frame per minute. Continuous observations shorter than this are the same batch of frames being connected.
  /// Feed them in, and use them to compare the deviations. Each frame will be less panned than the previous frame, and finally collapse to the same minute.。
  static const int _minObserveGapSec = 30;

  static DateTime? _lastObserveAt;

  /// Write back to the persistence layer when the deviation changes. Depend on [GlucoseCollectionRunner] injection。
  ///
  /// Must be saved across processes：App After restarting, the new process can only rely on 0xD3 Batch estimate a coarse seed (lower bound, maximum difference
  /// One production frame period), which is more than ten seconds different from the accurate value calibrated by the real-time frame before killing, two adjacent records before and after the breakpoint
  /// Will be counted into the same minute, and one will be lost when deduplicating by minutes.。
  static void Function(int skewSec)? persist;

  /// When the process starts, restore the last real-time calibrated value, so that the same ruler can be used for backfill and breakpoint.。
  static void restore(int skewSec) {
    if (_known) {
      return; // This process already has actual measured values, so there is no need to overwrite the old values.
    }
    _skewSec = skewSec;
    _known = true;
    _fromLive = true; // What is saved is calibrated in real time.
    DevLog.instance.add(
      'collect',
      'The device clock deviation has been restored to the last measured value +${_min(skewSec)} Minutes (use the same ruler before backfill and breakpoint）',
    );
  }

  /// Observe a record，[at] is the moment the machine receives it。
  ///
  /// Observations = at − equipmentts = (receive − Measured) + The true deviation is always an upper bound. The fresher the record, the tighter the upper bound.：
  /// - [live]=true（real time 0xB0，Measured as received): Observed value≈True value, adopted directly；
  /// - [live]=false（0xD3 In bulk package SN The largest one): in FLASH There is at most one production frame period，
  ///   Take the bound ”observation value − 60」，It would be better to pan one minute less than to set the record to a future moment later than this moment.。
  ///   It is only used as a seed when there is no real-time value. It will be removed as soon as the real-time frame arrives.。
  static void observe(int deviceTsSec, DateTime at, {bool live = true}) {
    if (deviceTsSec <= 0) return;
    final last = _lastObserveAt;
    if (live &&
        last != null &&
        at.difference(last).inSeconds < _minObserveGapSec) {
      return;
    }
    if (live) _lastObserveAt = at;
    final nowSec = at.toUtc().millisecondsSinceEpoch ~/ 1000;
    final observed = nowSec - deviceTsSec;
    if (!live) {
      if (_known) {
        return; // If there is already a value (even if it is a seed), there is no need to cover it with a thicker upper bound.
      }
      final seed = observed - _periodSec;
      _apply(
        seed < 0 ? 0 : seed,
        fromLive: false,
        note:
            '（0xD3 Lower bound for batch package estimation，'
            'The real-time frame will be calibrated when it arrives.）',
      );
      return;
    }
    // If the seed is in place, it will be removed unconditionally, and the real-time value will always be more accurate than it.
    if (!_known || !_fromLive) {
      _apply(observed, fromLive: true, note: '');
      return;
    }
    // The observed value is an upper bound, so：
    // - Smaller than the current value: a tighter upper bound, adopt it directly, and rely on it to converge when the frame is closed occasionally a few seconds faster，
    //   Otherwise, the larger old value will be used and the record will be overwritten later than now.。
    // - Much larger than the current value: the equipment has been shut down, and the deviation has indeed increased. Keep up.。
    // - Just a little bigger: frame jitter, ignore it, so as not to shake the minute-by-minute deduplication button.。
    if (observed < _skewSec) {
      _apply(observed, fromLive: true, note: '');
    } else if (observed - _skewSec >= _updateThresholdSec) {
      _apply(observed, fromLive: true, note: '');
    }
  }

  static void _apply(
    int value, {
    required bool fromLive,
    required String note,
  }) {
    final prev = _skewSec;
    final first = !_known;
    _skewSec = value;
    _known = true;
    _fromLive = fromLive;
    if (fromLive) persist?.call(value);
    final tail = first
        ? ''
        : '（Original +${_min(prev)} Minutes, the equipment produced less during this period. ${_min(value - prev)} Minutes of recording）';
    DevLog.instance.add(
      'collect',
      'Device clock skew${first ? "Determined" : "renew"}: Device frame timestamp to +${_min(value)} minute'
          'is the real moment$note${first ? '' : tail}',
    );
  }

  /// Change wear / Clear when stopping collection: different sensors t0 Differently, deviations cannot be carried across generations。
  static void reset() {
    _skewSec = 0;
    _known = false;
    _fromLive = false;
    _lastObserveAt = null;
  }

  static String _min(int sec) => (sec / 60).toStringAsFixed(1);
}
