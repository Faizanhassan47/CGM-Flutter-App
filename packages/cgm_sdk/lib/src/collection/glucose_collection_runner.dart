import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'package:cgm_sdk/src/log/dev_log.dart';
import 'package:cgm_sdk/src/log/breadcrumb_log.dart';
import 'package:cgm_sdk/src/status/connect_status.dart';
import 'package:cgm_sdk/src/status/link_activity.dart';
import 'package:cgm_sdk/src/algorithm/algorithm_gateway.dart';
import 'package:cgm_sdk/src/algorithm/jni_algorithm_gateway.dart';
import 'package:cgm_sdk/src/algorithm/linear_algorithm_gateway.dart';
import 'package:cgm_sdk/src/domain/ble_adapter_monitor.dart';
import 'package:cgm_sdk/src/domain/cgm_ble_gate.dart';
import 'package:cgm_sdk/src/domain/wear_lifecycle_resolver.dart';
import 'package:cgm_sdk/src/domain/sdk_tuning.dart';
import 'package:cgm_sdk/src/algorithm/glucose_value.dart';
import 'package:cgm_sdk/src/db/cgm_database.dart';
import 'package:cgm_sdk/src/collection/cgm_replay_dataset.dart';
import 'package:cgm_sdk/src/collection/device_clock_skew.dart';
import 'package:cgm_sdk/src/collection/foreground_service_controller.dart';

import 'package:cgm_sdk/src/glucose/algo_param_store.dart';
import 'package:cgm_sdk/src/glucose/bgm_calibration_store.dart';
import 'package:cgm_sdk/src/pipeline/glucose_pipeline_repository.dart';
import 'package:cgm_sdk/src/wear/wear_repository.dart';

import 'package:cgm_sdk/src/collection/device_timeline_audit.dart';
import 'package:cgm_sdk/src/collection/device_timeline_migration.dart';

import 'package:cgm_sdk/src/collection/glucose_backfill_coordinator.dart';
import 'package:cgm_sdk/src/collection/glucose_timeline_repair.dart';
import 'package:cgm_sdk/src/collection/live_glucose_collector.dart';
import 'package:cgm_sdk/src/collection/replay_glucose_collector.dart';

/// `--dart-define=USE_LINEAR_ALGO=true` Force linear conversion without using true algorithm .so。
const bool _forceLinearAlgo = bool.fromEnvironment('USE_LINEAR_ALGO');

/// No. [tries] times (from 0 (starting) Waiting before reconnecting：15s、30s、1min，fixed after 2 minute。
/// The first few rounds are a little denser to catch the moment when the old phone releases the transmitter when changing phones; after that, it must fall back 2 minute，
/// Continuous scanning will consume the battery of the transmitter and mobile phone.。
Duration reconnectRetryDelay(int tries) => switch (tries) {
  0 => const Duration(seconds: 15),
  1 => const Duration(seconds: 30),
  2 => const Duration(minutes: 1),
  _ => const Duration(minutes: 2),
};

/// `--dart-define=REPLAY_ONLY=true`：Only take option one Excel Playback, skipping real device detection。
/// default false，No blood sugar will be generated without a real device connection; only no device joint debugging/Open during demonstration。
const bool kReplayOnly = bool.fromEnvironment('REPLAY_ONLY');

/// Official version switch：`--dart-define=FINAL_BUILD=true`。Only take true device current + Backend true calibration + real .so，
/// No linear conversion Excel Guaranteed; factory calibration is missing/The occupancy directly refuses to start measurement.。
/// cgmbase For missing exceptions, use [_fallbackCgmBase] reveal all the details（cgmbase=0 will let algoK=-Infinity），Really worth the rush when it arrives。
const bool kFinalBuild = bool.fromEnvironment('FINAL_BUILD');

/// Whether the content issued by the backend is placeholder calibration：k/b/L3~G5 The dimensions are different, and it is impossible for the eight values ​​to be congruent in true calibration.。
/// Position calibration feeding .so will get algoK=0，Blood sugar is base Keep it still。
bool isPlaceholderCalibration(List<double> values) =>
    values.isNotEmpty && values.every((v) => v == values.first);

/// Linear conversion coefficients（Excel calibration constant), local fitting fitAround Use when unavailable。
const double _devReplaySlope = 2.8632;
const double _devReplayIntercept = -0.04;

/// cgmbase Pocket the bottom line, avoid benchmarks=0 lead to algoK=-Infinity；The back-end true value arrives and is calibrated and fingerprinted.。
const double _fallbackCgmBase = 6.8;

/// Collection master switch（DI Single case): The collector starts when activated by wearing it, and stops when not activated. driven by monitoring page
/// [ensureRunning]/[stop]，same wear Don’t start again. Uploaded by independent [GlucoseUploadService] Responsible。
///
/// Three gates: Bluetooth adapter Off, the device link is disconnected/If it cannot be connected, has expired or has been unbundled, collection will stop if any hit is made.。
class GlucoseCollectionRunner {
  final CgmDatabase db;
  final WearRepository wearRepo;
  final Duration interval;

  /// To replenish the guard inspection cycle, see [_scheduleBackfillSweep]。default 10 minutes, any shorter and the link will be disconnected and reconnected frequently.。
  final Duration backfillSweepPeriod;

  /// The retreat capping interval of the same batch of holes, default 6 hours; first two rounds [_sameHolesBackoff]，Use this value later。
  final Duration sameHolesRetry;

  /// Synchronize the restart interval after all confiscation, see [_scheduleResyncReconnect]。default 10 Second，
  /// That is, the ”disconnect, clean status, and reconnect” intervals specified in the backfill flow chart。
  final Duration resyncDelay;

  /// 0xD3 After the stream is disconnected, wait silently before sending the next instruction, transfer
  /// [GlucoseBackfillCoordinator.settleAfterBrokenStream]；The protocol requires that no commands be issued during synchronization.。
  final Duration syncSettle;

  /// real device BLE Seam: Option 2 automatically connects equipment to get real current。null Then only playback plan 1。
  final CgmBleGate? gate;

  /// Bluetooth adapter status gate，null=Not enabled。adapter OFF Stop all collectors from time to time and turn off the gate
  /// [ensureRunning]，Restart automatic recovery。
  final BleAdapterMonitor? adapterMonitor;

  /// Front-end service controller: start as soon as collection is started and stop when it is completely stopped。null=Not enabled。
  final ForegroundServiceController? foregroundService;

  /// Every time a new blood sugar is calculated, it will be called back (uploaded pokeNow + Value type alarm determination). The alarm must be hung here，
  /// If you refresh the homepage App There will be no judgment if you cut the background。
  final void Function(double value, DateTime at)? onDataComputed;

  /// The complete scene (frame) of each calculated + algorithm output），SDK The facade is based on this glucose / algoResult event。
  final void Function(BleFrameBufferRow frame, GlucoseValue out)?
  onFrameComputed;

  /// Wearing record not saved accountId The source of the secret (the account is under the control of the host)，SDK Don’t read the account list）；null according to 0。
  final Future<int?> Function()? fallbackAccountId;

  GlucosePipelineRepository? _pipeline;

  /// The parameters used by the current acquisition and feeding algorithm，[recomputeCurrentWear] use。
  GluCalcParameter? _runningParams;
  ReplayGlucoseCollector? _collector;
  LiveGlucoseCollector? _liveCollector;
  int? _runningWearId;

  /// Disconnection to make up for what has been completed wear。You must look at the fingerprint gate before it is short-circuited: when the backfill fails [_startLiveDevice]
  /// It still returns successfully, otherwise there will be no second replenishment during the entire wearing cycle.。
  int? _backfillDoneWearId;

  /// I have had to do it over several times when the recovery failed. There is an upper limit: otherwise the collection will be overturned and rebuilt every time it is woken up.。
  int _backfillRetries = 0;
  static const int _maxBackfillRetries = 3;

  /// The timeline signature of the last inspection is used to determine whether there has been any compensation in the last restart.。
  ///
  /// These three fields must be saved across processes（app_meta）：If you only store memory App Cleared as soon as backoff is restarted，
  /// first inspection tick Must pinch the link once。
  String? _lastSweepSig;
  DateTime? _lastSweepAt;
  int _sameHolesRounds = 0;

  /// The patrol retreat status has changed from app_meta Read back (once per process, if not read, press ”Not Saved”)）。
  bool _sweepStateLoaded = false;

  /// Retry backoff for the same batch of holes, first fast and then slow: Holes such as link instantaneous disconnections can be remedied by retrying earlier, and the equipment FLASH
  /// The holes that were not there in the first place cannot be filled in no matter how many times you try again. The fixed interval is short and consumes power, and the fixed interval is too long to allow the holes that can be filled to dry up, etc.。
  static const List<Duration> _sameHolesBackoff = [
    Duration(minutes: 30),
    Duration(hours: 2),
  ];

  /// Is it long enough since the last restart of the same batch of holes? If it is long enough, give it another chance.。
  bool get _sameHolesRetryDue {
    final t = _lastSweepAt;
    if (t == null) return true;
    final wait = _sameHolesRounds < _sameHolesBackoff.length
        ? _sameHolesBackoff[_sameHolesRounds]
        : sameHolesRetry;
    return DateTime.now().difference(t) >= wait;
  }

  /// The fingerprint of the calibration used in the current acquisition (engine + All calibration parameters): Same as wear Hot restart, no short circuit after time change。
  String? _runningCalFp;

  /// Last received transmitter 0xB0 frame moment. When sending frame(<1.5×interval)Silent pocket timer gives way。
  DateTime? _lastRealFrameAt;

  /// The device serial number of the latest frame is used to determine how many records the device produced between this frame and the previous frame. We did not get it.」。
  int? _lastFrameSeq;

  /// The local time when this round of real-time acquisition starts. When not a single frame is received, the starting point for the determination of ”continuous but not pushing frames”。
  DateTime? _liveSinceAt;

  /// Solution 1: Real device retry timer at runtime: upgrade immediately after connection Solution 2。
  Timer? _liveRetryTimer;

  /// Path rejected (unreachable)/Disconnect/Calibration is not ready) reconnection retry timer, one-time, failed path self-resumption。
  Timer? _retryTimer;

  /// Wear the expiration self-stop timer: stop when the point is reached, regardless of whether the page is in the foreground。
  Timer? _expiryTimer;

  /// After reconnection 0xB0 Silent pocket timer: protocol 6.1 Says it is connected 0xB0 Automatic periodic reporting, normal situation
  /// idling；interval×3 If a frame has not arrived and the device is confirmed to be under test, write it again. 0xC4 Measurement parameters resume reporting。
  Timer? _reportingFallbackTimer;

  /// Replenishing the guard inspection timer: Periodic hole inspections must also be carried out, see [_scheduleBackfillSweep]。
  Timer? _backfillSweepTimer;

  /// adapter Change subscription (tied to runner life cycle，[dispose] Cancel）。
  StreamSubscription<bool>? _adapterSub;

  /// Have run the device timeline self-test wear，See [_logFrameSkew]。Change wear Will run again。
  int? _skewAuditedWearId;

  /// If the device lags behind for more than this many seconds, run a timeline self-check.。5 minutes is much greater than the normal frame jitter。
  static const int _skewAuditThresholdSec = 300;

  /// Device link disconnection subscription (tied runner life cycle，[dispose] Cancel）。
  StreamSubscription<bool>? _linkSub;

  /// equipment FLASH Full subscription (agreement 6.3 of 0xF1），tie runner life cycle。
  StreamSubscription<void>? _flashSub;

  /// Connect to the frame buffer between real-time acquisitions, see [_startEarlyBuffer]。
  StreamSubscription<List<int>>? _earlyFrameSub;
  final List<List<int>> _earlyFrames = [];

  /// Buffering limit: one frame per minute, per frame 21 byte，2000 It’s enough to last a whole day and only takes up a few dozen KB。
  static const int _maxEarlyFrames = 2000;

  /// Whether the collection was stopped ”due to Bluetooth shutdown”: only in this case, it will be automatically resumed when Bluetooth is turned back on.，
  /// business stopped（[stop]）will be cleared to avoid restarting Bluetooth and accidentally starting collections that should not be run.。
  bool _stoppedByAdapterOff = false;

  /// The short sentence on the top bar of ”Bluetooth is not turned on”: write/The two places to be removed must have the same constant, otherwise they cannot be removed.。
  static const String _btOffHint =
      'Bluetooth is not turned on,Please turn on Bluetooth';

  /// runner Complete set of diagnostic phrases set by yourself, only clear your own when clearing。
  static const Set<String> _ownHints = {
    'Device information is not ready,Automatically retrying',
    'Transmitter not connected,Retrying·Please log out of the old phone before changing the phone.App',
    'Equipment calibration is not ready,Waiting for configuration·Automatic retrying',
    _btOffHint,
    'Transmitter disconnected,Reconnecting',
    _notMeasuringHint,
  };

  /// The short sentence in the top bar when the device self-reports ”not measured”: There will be no new data when the device is stopped, and the interface must say this.。
  static const String _notMeasuringHint =
      'The transmitter has stopped measuring,Please contact customer service or replace the sensor';
  bool get _ownsHint => _ownHints.contains(ConnectStatus.hint.value);

  /// Real machine measured current playback set (lazy loading of cache). Tests can be injected with small data sets。
  final Future<CgmReplayDataset> Function() _loadReplay;
  CgmReplayDataset? _replayData;

  GlucoseCollectionRunner({
    required this.db,
    required this.wearRepo,
    this.gate,
    this.adapterMonitor,
    this.foregroundService,
    this.onDataComputed,
    this.onFrameComputed,
    this.fallbackAccountId,
    this.interval = const Duration(minutes: 1),
    this.backfillSweepPeriod = const Duration(minutes: 10),
    this.sameHolesRetry = const Duration(hours: 6),
    this.resyncDelay = const Duration(seconds: 10),
    this.syncSettle = const Duration(seconds: 2),
    Future<CgmReplayDataset> Function()? replayLoader,
  }) : _loadReplay = replayLoader ?? CgmReplayDataset.load {
    // When Bluetooth is turned off, all collectors will stop and will automatically resume when turned on again.
    _adapterSub = adapterMonitor?.onChanges.listen((on) {
      if (on) {
        _handleAdapterOn();
      } else {
        _handleAdapterOff();
      }
    });
    // If the link is disconnected, there will be no real current. Immediately stop output and reconnect and try again.；
    // push true Can only come from Overwatch Reconnection（[CgmBleGate.watchReconnect]）
    _linkSub = gate?.connectionChanges.listen((connected) {
      if (connected) {
        _handleLinkRestored();
      } else {
        _handleLinkLost();
      }
    });
    // equipment FLASH Full (agreement 6.3 of 0xF1）：The device has stopped measuring and no more data will be output no matter how many times it is reconnected.
    _flashSub = gate?.flashOverflow.listen((_) => _handleFlashOverflow());
  }

  bool get isRunning => _collector != null || _liveCollector != null;
  int? get runningWearId => _runningWearId;

  /// Is the real device link connected?（[_liveCollector] only in 0xB0 Real-time collection is valuable when running）。
  /// 「”Data Interruption Reminder” premise, no reminder when not connected。
  bool get isDeviceLinked => _liveCollector != null;

  /// Start and stop serial queue：ensureRunning/stop Always line up. Two-way concurrency without mutual exclusion poke Will both pass
  /// Fingerprint check, dual collectors/Dual connection。
  Future<void> _opQueue = Future<void>.value();

  Future<void> _enqueue(Future<void> Function() op) {
    final next = _opQueue.then((_) => op());
    _opQueue = next.catchError(
      (_) {},
    ); // Single failure does not block the queue
    return next;
  }

  /// Activation ensures collection + Upload is running (same as wear No restart); not activated/Stop if not wearing。
  /// Automatic switching: connected to real equipment → Option 2 (real current); unable to connect → Option 1 (playback）。
  Future<void> ensureRunning() => _enqueue(_ensureRunningImpl);

  Future<void> _ensureRunningImpl() async {
    // adapter OFF Just stop all collectors; option 1 (Bluetooth is on but cannot connect to the device) will not be affected.。
    if (adapterMonitor != null && !adapterMonitor!.isOnNow) {
      // Not marked ”Stop because Bluetooth is off”, when Bluetooth is turned back on [_handleAdapterOn] will be direct return，Collection does not resume
      _stoppedByAdapterOff = true;
      await _stopImpl();
      await foregroundService?.stop();
      ConnectStatus.hint.value = _btOffHint;
      return;
    }
    final snap = await wearRepo.currentWearSnapshot();
    if (snap == null) {
      await _stopImpl();
      await foregroundService?.stop();
      return;
    }
    final activeTime = snap.activeTime;
    final wearId = snap.wearId;
    // Only preheating/Collection is allowed during monitoring and expires/It will stop if it is unbound. The same judgment function as the monitoring page。
    final stage = resolveWearStage(
      activeTime: activeTime,
      lastWearTime: activeTime,
      handleStatus: int.tryParse(snap.handleStatus ?? ''),
      lifetimeDays: kWearLifetimeDays,
      warmupMinutes: SdkTuning.warmupMinutes,
    );
    if (stage != WearLifecycleStage.warmingUp &&
        stage != WearLifecycleStage.monitoring) {
      await _stopImpl();
      await foregroundService?.stop();
      if (stage == WearLifecycleStage.expired) {
        // Top column copywriting submission AutoUnbindService，Only logs are left on the collection side
        DevLog.instance.add(
          'ble',
          'Wear has expired/Unbound→Refuses to start collection and does not produce any blood sugar',
        );
      }
      return;
    }
    // The foreground service is kept alive and the frame is closed after switching to the background.+The upload will not be frozen by the system; it will also be maintained during reconnection and retry.。
    await foregroundService?.ensureRunning();
    // The calibration fingerprint has changed（cgmbase/Factory calibration asynchronous arrival or update) will be hot restart to collect new parameters, if not changed, short circuit。
    // profile The pull is asynchronous, and the caller will poke once ensureRunning。
    final calFp = await _calFingerprint(activeTime);
    // Change wear It will be recalculated and the inspection signature of the previous one will be invalid.。
    if (_backfillDoneWearId != null && _backfillDoneWearId != wearId) {
      _backfillRetries = 0;
      _lastSweepSig = null;
      _lastSweepAt = null;
      _sameHolesRounds = 0;
      _sweepStateLoaded =
          false; // Change wear：Go read a new book during the next round of inspection wear own share
    }
    // The short-circuit is allowed only if the recovery has been successfully completed; if the recovery is not completed, several chances to try again will be given, otherwise the entire section will be disconnected and permanently lost.。
    final backfillPending =
        _backfillDoneWearId != wearId && _backfillRetries < _maxBackfillRetries;
    if (_runningWearId == wearId &&
        calFp == _runningCalFp &&
        !backfillPending) {
      return;
    }
    if (_runningWearId == wearId && calFp == _runningCalFp) {
      _backfillRetries++;
      if (kDebugMode) {
        debugPrint(
          '[collection] The last round of break-up was unsuccessful. → Come back again $_backfillRetries Second-rate'
          '(upper limit $_maxBackfillRetries)',
        );
      }
    }
    if (_runningWearId == wearId && kDebugMode) {
      debugPrint(
        '[collection] Calibration parameters have been updated（cgmbase/Factory calibration arrives or changes）→ Restart collection and cut new parameters',
      );
    }
    await _stopImpl();
    _runningCalFp = calFp;
    _scheduleExpiryStop(activeTime);

    final userId = snap.userId;
    // Wearing records may not be saved accountId，Take it from the account list, otherwise upload it accountId yes 0
    var accountId = snap.accountId ?? 0;
    if (accountId <= 0) {
      accountId = await fallbackAccountId?.call() ?? 0;
    }

    // There is a Bluetooth address and it can connect to the real current of plan 2, otherwise it will return to plan 1 and playback
    final addr = await AlgoParamStore(db).readBluetoothAddr();
    final live =
        !kReplayOnly &&
        gate != null &&
        addr != null &&
        await gate!.connect(addr);
    if (live) {
      await _startLiveDevice(
        wearId: wearId,
        activeTime: activeTime,
        userId: userId,
        accountId: accountId,
        warmingUp: stage == WearLifecycleStage.warmingUp,
      );
    } else if (gate != null && !kReplayOnly) {
      // If the device is not connected, it will not count.。_runningWearId Leave it unset, press escape and try again - the transmitter may still be blocked after changing the device.
      // Old cell phone occupied. During the disconnection period, the device is FLASH Save the number, after reconnecting 0xD3 backfill true value。
      if (kDebugMode) {
        debugPrint(
          '[collection] Real device not connected→No blood sugar is produced, automatically retrying.(15s/30s/1min→2min)',
        );
      }
      await gate!.disconnect();
      ConnectStatus.hint.value = addr == null
          ? 'Device information is not ready,Automatically retrying'
          : 'Transmitter not connected,Retrying·Please log out of the old phone before changing the phone.App';
      _scheduleReconnectRetry();
    } else {
      await _startDevReplay(
        wearId: wearId,
        activeTime: activeTime,
        userId: userId,
        accountId: accountId,
      );
    }
  }

  /// Solution 1·Playback: Used when the device cannot be connected Excel Current feeds the main engine to output blood sugar and then uploads it。
  /// The engine and the solution are of the same caliber: use real calibration .so，Linear without true calibration（Excel Fitting coefficient）。
  Future<void> _startDevReplay({
    required int wearId,
    required DateTime activeTime,
    required int userId,
    required int accountId,
  }) async {
    final dataset = _replayData ??= await _loadReplay();

    final (calParams, useRealAlgo, _) = await _buildAlgoParams(activeTime);
    // Linear main engine must use Excel fit coefficient, true k/b If you feed the linearity, the calculation will be on the low side.
    final params = useRealAlgo
        ? calParams
        : GluCalcParameter(
            slope: _devReplaySlope,
            intercept: _devReplayIntercept,
            startTs: activeTime.toUtc().millisecondsSinceEpoch ~/ 1000,
            paramL3: 0,
            paramG3: 0,
            paramL4: 0,
            paramG4: 0,
            paramL5: 0,
            paramG5: 0,
            paramBGMbase: 0,
          );

    final pipeline = GlucosePipelineRepository(
      db: db,
      algorithm: useRealAlgo
          ? JniAlgorithmGateway()
          // localFit Fit dynamically by neighborhood a/b，Following the sensitivity drift, the fixed coefficient has a large deviation in the middle and later stages.
          : LinearAlgorithmGateway(
              a: _devReplaySlope,
              b: _devReplayIntercept,
              localFit: dataset.fitAround,
              localFitPeriodSec: interval.inSeconds,
            ),
      substituteCurrentForSeq: (seq) => dataset.sampleForSeq(seq).current,
      ownerUserId: userId,
      ownerAccountId: accountId,
      // Pass it on as soon as it’s in the library, no wait 5 minute timer
      onComputed: (frame, out) {
        onDataComputed?.call(out.value, frame.measureTime);
        onFrameComputed?.call(frame, out);
      },
    );
    // Fix the local timeline first: misplaced lines are recalculated according to real time record_seq、Missing minutes from Excel complete，
    // Guaranteed serial number↔New numbers are generated after time identity mapping
    await GlucoseTimelineRepair(
      db: db,
      pipeline: pipeline,
      dataset: dataset,
      recordPeriod: interval,
    ).run(wearId: wearId, activeTime: activeTime, params: params);

    final collector = ReplayGlucoseCollector(
      pipeline: pipeline,
      dataset: dataset,
      params: params,
      wearId: wearId,
      interval: interval,
      startSeq: await _nextSeq(wearId),
      anchorTs: activeTime,
    );
    _pipeline = pipeline;
    _collector = collector;
    _runningWearId = wearId;
    _runningParams = params;

    collector.start();
    // Take one immediately to let users see the data as soon as possible
    await collector.collectOnce();
    DevLog.instance.add(
      'ble',
      'Option 1ExcelPlayback starts(The real device is not connected/No address)，Every2Retry real connection after 1 minute, connect to automatic upgrade plan 2',
    );
    _scheduleLiveRetry(wearId);
  }

  /// Every 2 Detect the real device once every minute, connect it and clear the fingerprint to restart collection and upgrade plan 2. If you don’t try again, the activation will be instantaneous.
  /// connect Failure (such as the device being occupied by a binding stream) will be locked idempotently by the fingerprint, and only the Excel data。
  void _scheduleLiveRetry(int wearId) {
    _liveRetryTimer?.cancel();
    if (kReplayOnly || gate == null) return;
    _liveRetryTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _enqueue(() async {
        // Stopped/Change wear/Already the second option, cancel the timer
        if (_runningWearId != wearId || _liveCollector != null) {
          _liveRetryTimer?.cancel();
          _liveRetryTimer = null;
          return;
        }
        final addr = await AlgoParamStore(db).readBluetoothAddr();
        if (addr == null) return;
        final ok = await gate!.connect(addr);
        DevLog.instance.add(
          'ble',
          ok
              ? 'Solution 1: Retry to connect to real device successfully→Upgrade plan two(true current)'
              : 'Solution 1: Retrying to connect to the real device fails，2Try again in minutes',
        );
        if (!ok) return;
        _runningCalFp =
            null; // The fingerprint is forcibly invalidated and restarted completely (Option 2 will be selected)）
        await _ensureRunningImpl();
      });
    });
  }

  /// Receive the frames in the window that is ”connected, but real-time acquisition has not started yet”。
  ///
  /// [CgmBleGate.measurements] yes broadcast Stream, the frames pushed when there are no subscribers are directly discarded.；
  /// [_startLiveDevice] To make up for it、drain、Real-time collection will not start until the recalculation is completed. This period may be measured in minutes.。
  void _startEarlyBuffer() {
    _earlyFrames.clear();
    _earlyFrameSub?.cancel();
    _earlyFrameSub = gate?.measurements().listen((b) {
      if (_earlyFrames.length < _maxEarlyFrames) _earlyFrames.add(b);
    });
  }

  Future<List<List<int>>> _takeEarlyBuffer() async {
    final taken = List<List<int>>.from(_earlyFrames);
    await _earlyFrameSub?.cancel();
    _earlyFrameSub = null;
    _earlyFrames.clear();
    return taken;
  }

  /// Option 2·Real machine：[gate] Already in [ensureRunning] Connected, one message every minute. Press frame by frame when the frame current is
  /// pipeline Routing: current≠0 Feed the main engine, current≈0 according to seq Pick Excel The current follows a linear path; when the transmitter is silent
  /// [ReplayGlucoseCollector] Timer out synthesis frame. Two collectors share the same pipeline serial queue。
  Future<void> _startLiveDevice({
    required int wearId,
    required DateTime activeTime,
    required int userId,
    required int accountId,
    required bool warmingUp,
  }) async {
    // Once connected, catch the frame first. See [_startEarlyBuffer]
    _startEarlyBuffer();
    // The official version does not load Excel Playback set, data can only come from the device
    final CgmReplayDataset? dataset = kFinalBuild
        ? null
        : (_replayData ??= await _loadReplay());

    // Read device measurement status first(0xE3)：Under test and SN>0 Only then can we have a true reading.
    var measuring = false;
    var latestSn = 0;
    var stateOk = false;
    try {
      final st = await gate!.readMeasureState();
      measuring = st.measuring;
      latestSn = st.latestSn;
      stateOk = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[collection] Read device status(0xE3)fail(neglect): $e');
      }
    }
    final hasRealSignal = measuring && latestSn > 0;
    // Only after confirming read status and SN=0 There is no true signal when it is judged, and the reading fails.=The status is unknown, be conservative and assume there is a signal
    final noRealSignal = stateOk && !hasRealSignal;
    // 「The device is stopped. Only the self-reported position of the device is recognized: when first activated, the first one will have to wait for one sampling period.，SN=0 is normal。
    final deviceStopped = stateOk && !measuring;

    // Use true calibration .so，If not, linear occupancy
    final (params, useRealAlgo, calReal) = await _buildAlgoParams(activeTime);
    // The official version is missing factory calibration/If the position is occupied, it refuses to start measurement and does not feed. .so Malformation parameters。
    // cgmbase Not within the rejection criteria, missing has been replaced by [_fallbackCgmBase] Guaranteed, true value, automatic eagerness upon arrival。
    if (kFinalBuild && !useRealAlgo) {
      if (kDebugMode) {
        debugPrint(
          '[collection] Official version: Factory calibration is missing/Placeholder→Refused to start measurement, automatically retrying',
        );
      }
      await gate!.disconnect();
      await _takeEarlyBuffer(); // There are not many ways to go, and there are no channels through which buffered frames can be dropped.
      ConnectStatus.hint.value =
          'Equipment calibration is not ready,Waiting for configuration·Automatic retrying';
      _scheduleReconnectRetry();
      return;
    }
    // The engine only looks at the calibration, not the SN Entire field degradation: frame-by-frame routing has ensured that only real current flows .so，
    // cannot be caused by the activation moment SN=0 Just lock the linearity for the entire field。
    final useRealNow = useRealAlgo;
    // Linear main engine must use Excel fit coefficient, true k/b If you feed the linearity, the calculation will be on the low side.
    final runParams = useRealNow
        ? params
        : GluCalcParameter(
            slope: _devReplaySlope,
            intercept: _devReplayIntercept,
            startTs: params.startTs,
            paramL3: 0,
            paramG3: 0,
            paramL4: 0,
            paramG4: 0,
            paramL5: 0,
            paramG5: 0,
            paramBGMbase: 0,
          );
    final pipeline = GlucosePipelineRepository(
      db: db,
      algorithm: useRealNow
          ? JniAlgorithmGateway()
          : LinearAlgorithmGateway(
              a: _devReplaySlope,
              b: _devReplayIntercept,
              // Neighborhood fitting dynamics a/b Follow the sensitivity drift. If there is no data set in the official version, use a fixed coefficient.
              localFit: dataset?.fitAround,
              localFitPeriodSec: interval.inSeconds,
            ),
      // Zero current frame press seq Pick Excel After the current replacement, the same main engine is fed, and the official version will not replace it.
      substituteCurrentForSeq: dataset == null
          ? null
          : (seq) => dataset.sampleForSeq(seq).current,
      ownerUserId: userId,
      ownerAccountId: accountId,
      // Pass it on as soon as it’s in the library, no wait 5 minute timer
      onComputed: (frame, out) {
        onDataComputed?.call(out.value, frame.measureTime);
        onFrameComputed?.call(frame, out);
      },
    );

    _pipeline = pipeline;
    _runningWearId = wearId;
    _runningParams = runParams;

    // Device clock skew is restored across processes and must be preceded by backfill: new processes rely only on 0xD3 The estimated coarse seeds are the same as before
    // If the calibration value differs by more than ten seconds, the two adjacent ones before and after the breakpoint will fall into the same minute and be deleted and discarded.。
    await _restoreClockSkew(wearId);

    // Stock timeline return: must be run before any new lines are written in this round, otherwise the new lines that are already real axes will be translated again.
    // once. Only run once per wearing cycle, see [DeviceTimelineMigration]。
    try {
      await DeviceTimelineMigration(db).runOnce(wearId: wearId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[collection] Timeline homing failed(neglect): $e');
      }
    }

    // Filling the disconnection gap must be done in real time when the connection is restored. 0xB0 Before consumption; device not measured(SN=0)then start the measurement sequence。
    // Failure is not fatal, and the status read above is reused without repeated reading. 0xE3。
    try {
      // 0xE3 If it is not read (the firmware response is slow after a long disconnection), it must be supplemented, otherwise the disconnected section FLASH history
      // I will never pull it again; I just won’t reuse the unread state and let the backfill read it again.。
      if (hasRealSignal || !stateOk) {
        final coordinator = GlucoseBackfillCoordinator(
          db: db,
          gate: gate!,
          pipeline: pipeline,
          dataset: dataset,
          recordPeriod: interval,
          settleAfterBrokenStream: syncSettle,
        );
        final n = await coordinator.backfill(
          wearId: wearId,
          params: runParams,
          activeTime: activeTime,
          // After reading it, reuse it and connect it 6 Will be sent within seconds 0xD3，Can’t make another round trip; didn’t read the message null
          // Let the backfill reread it by itself. If it still cannot read it, it will return. 0，Will not give random orders。
          knownState: stateOk
              ? (measuring: measuring, measuredSec: 0, latestSn: latestSn)
              : null,
        );
        if (kDebugMode && n > 0) {
          debugPrint(
            '[collection] Reconnect to fill the disconnection gap $n strip→The double table has been dropped into the inventory',
          );
        }
        // The backfill flow chart requires that once a package is confiscated, it will be disconnected and the status cleared.、10 Reconnect and resynchronize after seconds. number of times
        // [_maxBackfillRetries] Constraints: Device FLASH The records that are already missing cannot be filled in, and there is no limit to reconnection.
        // Real-time data will be included together。
        final owed = coordinator.lastUnresolvedGaps;
        if (owed > 0 && _backfillRetries < _maxBackfillRetries) {
          _backfillRetries++;
          DevLog.instance.add(
            'collect',
            'Synchronous confiscation of all: still owed $owed I never asked for it → Disconnect and clear status according to Party A’s flow chart，'
                '${resyncDelay.inSeconds} Reconnect and run again after seconds'
                '(No. $_backfillRetries/$_maxBackfillRetries Second-rate)',
          );
          // Do not stop and recreate the wear after an incomplete D3
          // response. That resets activation/warm-up and prevents live 0xB0
          // readings from becoming uploadable. The periodic backfill sweep
          // can retry while this session continues real-time collection.
          _backfillDoneWearId = wearId;
        } else {
          if (owed > 0) {
            DevLog.instance.add(
              'collect',
              'Synchronization is still missing $owed but the number of attempts has been exhausted($_maxBackfillRetries)→ Don’t disconnect and try again，'
                  'Leave it to the replenishment guardian to judge based on the timeline signature.',
            );
          }
          _backfillDoneWearId = wearId;
        }
        // You can no longer set the time with the device here.（0xD1）：Firmware does not recognize keepSn=1，Every time the equipment is shipped SN Calculate from scratch，
        // and FLASH History button SN Addressing, disconnecting that period of real data will never be retrieved. Time drift is clicked on the display layer
        // activation time+SN Correction, see CgmBleGate.syncClock。
      } else if (stateOk) {
        // Do not take it when the device reports that it has not measured. Excel Fill in the timeline: Each item filled out is created and will be uploaded as usual
        // Mixed into the production library. Not tuned either startMeasureSequence()：at the end of it 0xD1 Will clear the device SN，
        // and 0xE3 The position measurement will cause false alarms after long disconnection and when the sensor is first plugged in. 0，Misjudgment once FLASH history
        // It will be invalid. Only make up 0xC4 Write measurement parameters (do not touch SN），Silence is probably due to the upload cycle not being set。
        await gate!.startReporting(DateTime.now());
        // The device is confirmed not being tested. = There is nothing left to add, so mark it as completed to avoid having to do it again every time you wake up.。
        _backfillDoneWearId = wearId;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[collection] complement/Failed to start measurement(ignore, watch ble log): $e',
        );
      }
    }

    // If the previous round of ”recalculation after replenishment” was ROM Killing in the middle, Curry will leave half of the error value and may not be triggered again.，
    // Make up the run here. Must be before resuming real-time consumption: recalculation requires refeeding the entire history in order。
    try {
      await pipeline.resumePendingRecompute(runParams, wearId: wearId);
    } catch (e) {
      DevLog.instance.add(
        'algo',
        'Recalculation of unfinished make-up runs failed(Does not affect collection): $e',
      );
    }

    _lastRealFrameAt = null;
    _lastFrameSeq = null;
    _liveSinceAt = DateTime.now();
    // Enqueued frame by frame as is, the engine routes in pipeline Judge according to the current frame; mark any frame received _lastRealFrameAt
    // Give way to the pocket timer
    final liveCollector = LiveGlucoseCollector(
      gate: gate!,
      pipeline: pipeline,
      params: runParams,
      wearId: wearId,
      onFrame: (measureTime, seq) {
        _lastRealFrameAt = DateTime.now();
        // 0xE3 The measured position may be falsely reported 0，Dismiss the ”Measurement Stopped” prompt as soon as the true frame arrives.
        if (ConnectStatus.hint.value == _notMeasuringHint) {
          ConnectStatus.hint.value = null;
        }
        _logFrameSkew(wearId, measureTime);
        _checkSeqContinuity(wearId, seq);
      },
    );
    // Silent pocket timer (development stage only): The minute the transmitter does not send a frame, the entire frame will be output according to the slot. Excel，The frame is sent by
    // shouldSkip Give way. Taken when the anchor point has no true signal (1, activation time)，Otherwise, the last anchor record has been dropped into the database.
    // Extrapolate along the device time axis to avoid spatial misalignment with the device serial number。
    ReplayGlucoseCollector? replayCollector;
    // When the device self-reports ”not measured”, nothing is generated.：Excel Just keep it in mind ”The equipment is measuring but the current≈0」，The device stopped
    // There will no longer be real data, and the created values ​​will be abnormalFlag=0 Upload as true value。
    if (noRealSignal) {
      DevLog.instance.add(
        'collect',
        'No real reading(0xE3 measuring=$measuring，up to dateSN=$latestSn)→ Can’t afford to collect everything、'
            'Not a single one was made. Values ​​created when there is no real data source will be uploaded as real values.',
      );
      BreadcrumbLog.write(
        'No real reading→Can’t afford to collect everything wearId=$wearId Under test=$measuring SN=$latestSn',
      );
    }
    if (dataset != null && !noRealSignal) {
      final anchor = noRealSignal ? null : await _lastLocalAnchor(wearId);
      replayCollector = ReplayGlucoseCollector(
        pipeline: pipeline,
        dataset: dataset,
        params: runParams,
        wearId: wearId,
        interval: interval,
        startSeq: await _nextSeq(wearId),
        anchorSeq: anchor?.seq ?? 1,
        anchorTs: anchor?.ts ?? activeTime,
        // The anchor is the equipment time and the slot is advanced according to the mobile phone clock. The basis is ”the moment when the anchor point is obtained” so that it will not be lost. Excel
        // Minutes ahead that take up real frames；anchor=null time anchor (1, activeTime) This is a mobile phone clock。
        anchorWallClock: anchor == null ? activeTime : DateTime.now(),
        shouldSkip: () {
          final t = _lastRealFrameAt;
          return t != null &&
              DateTime.now().difference(t) < interval + (interval ~/ 2);
        },
      );
    }
    _liveCollector = liveCollector;
    _collector = replayCollector;
    _reconnectTries =
        0; // It’s connected. Next time you disconnect it, start from the dense level again.
    BreadcrumbLog.write(
      'Collection start plan two wearId=$wearId true signal=$hasRealSignal',
    );
    if (_ownsHint) {
      ConnectStatus.hint.value = null; // Connected,Withdraw diagnosis phrases
    }
    // The device will prompt on the spot if it reports that it has not measured. No prompt during warm-up period: when the sensor is just inserted 0xE3 I know how to do positioning
    // return 0，And there is no blood sugar produced during the warm-up period; and [shouldAlertDataInterrupt] of warmedUp The same gate
    // caliber, as soon as warm-up is completed 30 If there is no data for a minute, a data interruption reminder will appear.。
    if (deviceStopped && !warmingUp) {
      ConnectStatus.hint.value = _notMeasuringHint;
    }
    liveCollector.start();
    // Real-time subscription first, then buffering: briefly overlapping duplicate frames are pipeline Re-block it every minute，
    // You can’t make up for the minute the seam is lost.。
    await liveCollector.ingestBuffered(await _takeEarlyBuffer());
    // The power-saving mode is turned off only after entering a steady state. Can’t put it down connect() Li: connect 6 Will be sent within seconds 0xD3，You have to keep that part
    // Fast link. When there is a gap, the filling path will complete the downshift by itself. This is the path without a gap.。
    try {
      await gate!.setFastLink(false);
    } catch (e) {
      DevLog.instance.add(
        'ble',
        'Failed to switch to power saving mode in steady state(Does not affect collection): $e',
      );
    }
    // Unconditionally hang on silently：0xE3 When the read fails, the above two branches will not be taken, and the device may not be configured to upload at all.
    // cycle. When the timer receives a true frame no-op。
    _scheduleReportingFallback(wearId);
    _scheduleBackfillSweep(wearId);
    replayCollector?.start();
    // Publish one immediately, and the interface will have the count as soon as possible
    await replayCollector?.collectOnce();
    if (kDebugMode) {
      debugPrint(
        kFinalBuild
            ? '[collection] Option 2(Official version)：Completion of true data after disconnection→Frame-by-frame real current feeding algorithm, without any hesitation'
            : '[collection] Option 2: The number of broken connections has been filled up→frame by frame(current≈0ChangeExcelcurrent)Feed the same main engine + Keep quietExcel',
      );
    }
  }

  /// Replenishment Guardian: Periodically self-check the timeline while connected, and run another round of replenishment if a hole or tail is found.，
  /// Quilt to cover large gaps maxSingleReads Truncated remaining segments and occasional missed frames in steady state。
  ///
  /// The action is to restart the entire round of collection（[_stopImpl] + [_ensureRunningImpl]），Cannot be replenished on the spot：
  /// Stateful .so It can only be fed in ascending order of time. Filling in the holes made a few hours ago will destroy the internal baseline.。
  void _scheduleBackfillSweep(int wearId) {
    _backfillSweepTimer?.cancel();
    _backfillSweepTimer = Timer.periodic(
      backfillSweepPeriod,
      (_) => _runBackfillSweep(wearId),
    );
  }

  /// When the real-time frame serial number jumps, that is, there is a record in the middle where the device has been produced but has not been obtained, it will be filled in immediately without waiting for inspection.。
  ///
  /// This is iOS The only reliable triggering time: in the background Dart Timer Full stop, no running for inspection，
  /// and CoreBluetooth Each frame sent will wake up the process and execute it here。
  void _checkSeqContinuity(int wearId, int seq) {
    final last = _lastFrameSeq;
    _lastFrameSeq = seq;
    // The first frame is not comparable to the previous frame: the backfill has just been run when the collection was started and handed over to it; the sequence number is backwards＝Equipment replacement is not a concern here either.
    if (last == null || seq <= last + 1) return;
    DevLog.instance.add(
      'collect',
      'Real-time frame sequence number jump: Previous frame SN=$last → This frame SN=$seq，'
          'middle ${seq - last - 1} The equipment was produced and we didn’t get it. → Replenish immediately(No waiting for inspection)',
    );
    unawaited(_runBackfillSweep(wearId));
  }

  /// Return to the front desk/When you wake up, take the initiative to check the timeline and fill in any holes.。iOS suspend period Dart Timer full stop，
  /// The inspection will not make up for the run. Returning to the foreground is another opportunity that will definitely be executed besides receiving the frame.。
  Future<void> pokeBackfill() async {
    final wearId = _runningWearId;
    if (wearId == null || _liveCollector == null) return;
    await _runBackfillSweep(wearId);
  }

  /// Run a round of replenishment physical examination: if there is a hole or tail drop, restart the whole round of collection and replenishment.。
  Future<void> _runBackfillSweep(int wearId) {
    return _enqueue(() async {
      if (_runningWearId != wearId || _liveCollector == null) return;
      // An incomplete D3 response is already marked as handled for this wear.
      // Do not restart the whole collection cycle: that creates a new wear ID,
      // resets activation time, and keeps the sensor permanently in warm-up.
      if (_backfillDoneWearId == wearId) return;
      await _loadSweepState(
        wearId,
      ); // The back-off state spans processes and restarts do not restart the timer.
      final sig = await _timelineSignature(wearId);
      if (sig == null || !sig.needsBackfill) return;
      // If the number of holes is the same as the previous round, it means that restarting cannot make up for it. You can only run again when the number of holes changes or the retreat expires.；
      // stale（Continuous frames (without pushing frames) are not bound by this gate. Reconnecting is the only way to save it.。
      if (!sig.stale && sig.key == _lastSweepSig && !_sameHolesRetryDue) {
        return;
      }
      // The number of holes has changed＝If the situation progresses, the retreat will start from the shortest level again; if there is no change, continue to retreat.。
      _sameHolesRounds = sig.key == _lastSweepSig ? _sameHolesRounds + 1 : 0;
      _lastSweepSig = sig.key;
      _lastSweepAt = DateTime.now();
      await _saveSweepState(wearId);
      DevLog.instance.add(
        'collect',
        'Replenish guard: Check out${sig.reason} → Run again to make up for it(${sig.key})',
      );
      _backfillDoneWearId =
          null; // Let this round really make up for it and not be short-circuited by the fingerprint gate.
      _backfillRetries = 0;
      await _stopImpl();
      await _ensureRunningImpl();
    });
  }

  /// Book wear Timeline physical examination: Is there any hole in the serial number span? Is the last one too far behind?。
  /// [_TimelineSignature.key] The same means ”no change from the last inspection」。
  Future<_TimelineSignature?> _timelineSignature(int wearId) async {
    final t = db.userlocalGlucoseData;
    final minSeq = t.recordSeq.min();
    final maxSeq = t.recordSeq.max();
    // must DISTINCT：In terms of number of rows, one duplicate row offsets a real gap.
    final cnt = t.recordSeq.count(distinct: true);
    final q = db.selectOnly(t)
      ..addColumns([minSeq, maxSeq, cnt])
      ..where(t.wearId.equals(wearId) & t.recordSeq.isNotNull());
    final row = await q.getSingleOrNull();
    if (row == null) return null;
    final lo = row.read(minSeq);
    final hi = row.read(maxSeq);
    final n = row.read(cnt) ?? 0;
    if (lo == null || hi == null) return null;
    // Also subtract the serial numbers that were received but lost by deduplication at the same minute: the same (wear, whole minute) Only the first one is left，
    // Later frames are only buffered in the frame buffer DONE。Don’t lose these SN It will always be considered short, and every round of inspections will be broken and replenished in vain.。
    final dedup = await _bufferedOnlySeqCount(wearId, lo, hi);
    // Caught under the pocket 0：The duplicate row has been replaced by DISTINCT Exclude, but replace/Dirty data can still make the difference negative，
    // Negative numbers will make needsBackfill constant false，It’s like quietly turning off backfilling
    final holes = ((hi - lo + 1) - n - dedup).clamp(0, 1 << 30);
    // 「”Continuous but not pushing frames” can only be judged based on the time when the machine receives the frame, not the last one. measure_time Compare：
    // That is the firmware timestamp (activation moment + seq×60，none RTC），Every time you miss a note, you will be permanently one minute behind.，
    // After accumulation, this gate will always be true.。
    final since = _lastRealFrameAt ?? _liveSinceAt;
    final quiet = since == null ? null : DateTime.now().difference(since);
    // silence over 5 cycles: connected but unable to receive frames, the device FLASH There’s probably stuff in there that we didn’t get.
    final stale = quiet != null && quiet > interval * 5;
    return _TimelineSignature(
      key: 'holes:$holes',
      needsBackfill: holes > 0 || stale,
      stale: stale,
      reason: holes > 0
          ? 'serial number $lo..$hi Internal deficiency $holes strip'
          : 'already ${quiet?.inMinutes} No frames received for minutes',
    );
  }

  /// interval `[lo,hi]` The number of serial numbers in ”the frame buffer has been processed but the display table has not been processed” is deduplicated in the same minute.
  /// Dropped frames. The framebuffer is not discarded automatically, only it recognizes these SN；This type SN Not a gap。
  Future<int> _bufferedOnlySeqCount(int wearId, int lo, int hi) async {
    final rows = await db
        .customSelect(
          'SELECT COUNT(DISTINCT b.record_seq) AS c FROM ble_frame_buffer b '
          'WHERE b.wear_id = ?1 AND b.status = ?2 AND b.record_seq IS NOT NULL '
          'AND b.record_seq BETWEEN ?3 AND ?4 '
          'AND NOT EXISTS (SELECT 1 FROM userlocal_glucose_data g '
          'WHERE g.wear_id = b.wear_id AND g.record_seq = b.record_seq)',
          variables: [
            Variable<int>(wearId),
            Variable<String>(FrameBufferStatus.done),
            Variable<int>(lo),
            Variable<int>(hi),
          ],
        )
        .get();
    return rows.isEmpty ? 0 : (rows.first.read<int?>('c') ?? 0);
  }

  /// After reconnection 0xB0 Silent security: one-time, only sent once, normal frame collection/Stop and withdraw。
  void _scheduleReportingFallback(int wearId) {
    _reportingFallbackTimer?.cancel();
    _reportingFallbackTimer = Timer(interval * 3, () {
      _reportingFallbackTimer = null;
      _enqueue(() async {
        if (_runningWearId != wearId || _liveCollector == null) return;
        if (_lastRealFrameAt != null) {
          return; // Already receiving frame,No intervention required
        }
        DevLog.instance.add(
          'ble',
          'After reconnection${interval * 3}Not received0xB0,Supplementary writing0xC4Measurement parameters are restored and reported(Not sent0xD1,it will be clearedSN)',
        );
        try {
          await gate!.startReporting(DateTime.now());
        } catch (e) {
          DevLog.instance.add(
            'ble',
            'Recovery report failed(Does not affect collection protection): $e',
          );
        }
      });
    });
  }

  /// Starting over after simultaneous confiscation：[resyncDelay] Then disconnect, clear the status, reconnect and rerun a round of synchronization.。
  /// and [_scheduleReconnectRetry] Different, this one is that the link is normal but all the packets are confiscated; during the waiting period
  /// Receive frame photos in real time, only when the time comes `_stopImpl`。The number of times pressed by the caller [_maxBackfillRetries] check。
  void _scheduleResyncReconnect() {
    _retryTimer?.cancel();
    _retryTimer = Timer(resyncDelay, () {
      _retryTimer = null;
      _enqueue(() async {
        // _stopImpl Will clear _runningWearId，_ensureRunningImpl Therefore, the retry count will not be incremented again.
        await _stopImpl();
        await _ensureRunningImpl();
      });
    });
  }

  /// If connected, it will be cleared to zero. See you. [_startLiveDevice] success with [stop]。
  int _reconnectTries = 0;

  void _scheduleReconnectRetry() {
    _retryTimer?.cancel();
    final wait = reconnectRetryDelay(_reconnectTries);
    _reconnectTries++;
    _retryTimer = Timer(wait, () {
      _retryTimer = null;
      _enqueue(() async {
        if (isRunning) return;
        await _ensureRunningImpl();
      });
    });
  }

  /// Current calibration fingerprint: reuse [_buildAlgoParams]，If any parameter changes, the fingerprint will change.。
  Future<String> _calFingerprint(DateTime activeTime) async {
    final (p, useReal, calReal) = await _buildAlgoParams(activeTime);
    return _fmtCalParams(p, useRealAlgo: useReal, calReal: calReal);
  }

  Future<void> stop() => _enqueue(() async {
    _stoppedByAdapterOff =
        false; // The service is stopped automatically, and Bluetooth should not automatically resume when it is reopened.
    _reconnectTries = 0;
    await _stopImpl();
    // Business stopped (unbundled)/Log out/dispose）No more background keepalives required
    await foregroundService?.stop();
  });

  Future<void> _stopImpl() async {
    BreadcrumbLog.write('Collection stopped wearId=$_runningWearId');
    _liveRetryTimer?.cancel();
    _liveRetryTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _reportingFallbackTimer?.cancel();
    _reportingFallbackTimer = null;
    _backfillSweepTimer?.cancel();
    _backfillSweepTimer = null;
    await _takeEarlyBuffer();
    if (_ownsHint) ConnectStatus.hint.value = null;
    _lastRealFrameAt = null;
    // After the collection is stopped, the frame collection time of the previous cycle can no longer be used to suppress the ”Data Connecting” prompt on the home page.
    LinkActivity.reset();
    // Device clock deviation is valid according to ”generation”: replace the sensor t0 It has changed and cannot be used. After reconnection 0xD3/0xB0
    // The measurement will be re-measured within a few seconds, and there will be no empty window after clearing (see [DeviceClockSkew]）。
    DeviceClockSkew.reset();
    _runningCalFp = null;
    _collector?.stop();
    _liveCollector?.stop();
    await _pipeline?.dispose();
    if (gate != null) await gate!.disconnect();
    _collector = null;
    _liveCollector = null;
    _pipeline = null;
    _runningParams = null;
    _runningWearId = null;
  }

  /// After the calibration is updated, all blood glucose that has been dropped into the database during this wearing period will be recalculated and written back based on the current parameters.（SDK facade setAlgoParams use）。
  /// Collection is not running and returns 0，The caller changes the ”pending recalculation” breakpoint and recalculates it when starting the collection.。
  Future<int> recomputeCurrentWear() async {
    final p = _pipeline;
    final wearId = _runningWearId;
    final params = _runningParams;
    if (p == null || wearId == null || params == null) return 0;
    final snap = await wearRepo.currentWearSnapshot();
    if (snap == null || snap.wearId != wearId) return 0;
    return p.recomputeFrom(params, wearId: wearId, fromTs: snap.activeTime);
  }

  Future<void> dispose() async {
    await _adapterSub?.cancel();
    _adapterSub = null;
    await _linkSub?.cancel();
    _linkSub = null;
    await _flashSub?.cancel();
    _flashSub = null;
    await stop();
  }

  /// It will stop automatically when the wearer expires and does not depend on whether the monitoring page is in the foreground. Expired at startup [_ensureRunningImpl]
  /// The life cycle gate is blocked, and it only runs to the point。
  void _scheduleExpiryStop(DateTime activeTime) {
    _expiryTimer?.cancel();
    final left = activeTime
        .add(const Duration(days: kWearLifetimeDays))
        .difference(DateTime.now());
    if (left.isNegative) return;
    _expiryTimer = Timer(left, () {
      _expiryTimer = null;
      BreadcrumbLog.write('Wear due→Automatically stop collection');
      DevLog.instance.add(
        'ble',
        'Wearing period expires→Automatically stops collection and no longer produces blood sugar',
      );
      // Top column copywriting submission AutoUnbindService，You can no longer write your own short sentences here：stop() Queued asynchronous execution，
      // _stopImpl inside `if (_ownsHint) hint=null` Maybe I’ll run away and clear out what I just wrote.
      unawaited(stop());
    });
  }

  /// equipment FLASH Full (agreement 6.3 of 0xF1）：The device has stopped measuring and will no longer 0xB0，The interface should be clearly explained。
  /// Continuous collection and continuous chaining：FLASH It stops when it is full instead of covering in a circular manner. The history is still in the device and can only be used if it is connected. 0xD3 Pull back。
  Future<void> _handleFlashOverflow() => _enqueue(() async {
    const hint =
        'Transmitter storage is full,Measurement stopped,Please replace the sensor';
    BreadcrumbLog.write(
      'equipmentFLASHFull(0xF1)→The device has stopped measuring',
    );
    DevLog.instance.add(
      'ble',
      'equipment FLASH Full(0xF1)：The device has stopped measuring and there will be no new data。'
          'History is still in the device FLASH inside(Stop when full, non-circular coverage)，Stay connected and continue to replenish',
    );
    ConnectStatus.hint.value = hint;
  });

  /// The device link is disconnected: If there is no connection, there will be no real current. Stop all collectors immediately.。
  /// The disconnection gap is caused by the reconnection gap. 0xD3 slave device FLASH Backfill the true value。
  Future<void> _handleLinkLost() => _enqueue(() async {
    if (_liveCollector == null) {
      return; // It’s not the real machine collection running, it has nothing to do with me
    }
    BreadcrumbLog.write('Device link disconnected→Stop collection');
    DevLog.instance.add(
      'ble',
      'Device connection has been disconnected→Stop collection(no longer produces any blood sugar)，2Automatically reconnect after minutes',
    );
    await _stopImpl();
    ConnectStatus.hint.value = 'Transmitter disconnected,Reconnecting';
    _scheduleReconnectRetry();
    // iOS Retry while hanging in background Timer Even if you don’t run and scan in the background, it won’t work. Hang up. pending connect
    // Wait for the device to come back by itself and connect it App wake（Android empty implementation）。
    try {
      await gate?.watchReconnect();
    } catch (e) {
      DevLog.instance.add(
        'ble',
        'Failed to reconnect while hanging watch(Does not affect scheduled retries): $e',
      );
    }
  });

  /// Watch reconnected: start normally and reconnect. → 0xD3 Covering the disconnection gap → Resume real-time collection。
  Future<void> _handleLinkRestored() => _enqueue(() async {
    if (isRunning) return; // The regular path has already started collection.
    BreadcrumbLog.write('Watch reconnection successful→Resume collection');
    DevLog.instance.add(
      'ble',
      'Device reconnects(Watch and reconnect)→Resume collection and make up for disconnection gaps',
    );
    await _ensureRunningImpl();
  });

  /// app_meta Inspection inspection withdrawal status is stored in key（according to wear：Changing the sensor is another timeline and cannot be used.）。
  static String _sweepKey(int wearId) => 'backfill_sweep_state_wear_$wearId';

  /// Read back the last patrol backoff status. Format `sign|millisecond timestamp|rounds`，If the analysis doesn’t work, click Save.。
  Future<void> _loadSweepState(int wearId) async {
    if (_sweepStateLoaded) return;
    _sweepStateLoaded = true;
    try {
      final row =
          await (db.select(db.appMeta)
                ..where((t) => t.key.equals(_sweepKey(wearId)))
                ..limit(1))
              .getSingleOrNull();
      final parts = row?.value?.split('|');
      if (parts == null || parts.length != 3) return;
      final ms = int.tryParse(parts[1]);
      final rounds = int.tryParse(parts[2]);
      if (ms == null || rounds == null) return;
      _lastSweepSig = parts[0];
      _lastSweepAt = DateTime.fromMillisecondsSinceEpoch(ms);
      _sameHolesRounds = rounds;
      DevLog.instance.add(
        'collect',
        'Replenish guard: Restore retreat status $_lastSweepSig @$_lastSweepAt No.$_sameHolesRounds wheel'
            '（App Restart without restarting the timer to avoid pinching the link every time you wake up）',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[collection] Failed to restore patrol backoff state(neglect): $e',
        );
      }
    }
  }

  Future<void> _saveSweepState(int wearId) async {
    final at = _lastSweepAt;
    if (_lastSweepSig == null || at == null) return;
    try {
      await db
          .into(db.appMeta)
          .insertOnConflictUpdate(
            AppMetaCompanion.insert(
              key: _sweepKey(wearId),
              value: Value(
                '$_lastSweepSig|${at.millisecondsSinceEpoch}|$_sameHolesRounds',
              ),
              updatedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
            ),
          );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[collection] Failed to save patrol backoff status(neglect): $e',
        );
      }
    }
  }

  /// app_meta Stores device clock bias key（according to wear，Replace sensor t0 It changed）。
  static String _skewKey(int wearId) => 'device_clock_skew_wear_$wearId';

  /// Restore the deviation from the last real-time calibration and hang up the writeback hook。
  Future<void> _restoreClockSkew(int wearId) async {
    DeviceClockSkew.persist = (sec) => unawaited(
      db
          .into(db.appMeta)
          .insertOnConflictUpdate(
            AppMetaCompanion.insert(
              key: _skewKey(wearId),
              value: Value('$sec'),
              updatedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
            ),
          ),
    );
    try {
      final row =
          await (db.select(db.appMeta)
                ..where((t) => t.key.equals(_skewKey(wearId)))
                ..limit(1))
              .getSingleOrNull();
      final v = int.tryParse(row?.value ?? '');
      if (v != null) DeviceClockSkew.restore(v);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[collection] Failed to restore device clock skew(neglect): $e',
        );
      }
    }
  }

  /// The deviation between the device timestamp and the mobile phone time is recorded for each frame: the device time axis is tied to the measurement count. If you measure less, it will be permanent.
  /// When you are one minute behind and no longer correct, the deviation will only increase rather than decrease.。
  ///
  /// Deviation exceeds [_skewAuditThresholdSec] every time wear run once [DeviceTimelineAudit]，
  /// from ble_frame_buffer In which segment of the real frame is the location lost?。
  void _logFrameSkew(int wearId, DateTime measureTime) {
    // measureTime Pressed [DeviceClockSkew] Translate to the real axis, what you want to focus on is the translation amount itself
    final skewSec = DeviceClockSkew.skewSec;
    DevLog.instance.add(
      'ble',
      'Frame drop time=${_hhmmss(measureTime)}（The mobile phone has been returned to its original position according to the measured deviation.=${_hhmmss(DateTime.now())}）；'
          'Accumulated equipment production is low ${(skewSec / 60).toStringAsFixed(1)} Minutes of recording',
    );
    if (skewSec > _skewAuditThresholdSec && _skewAuditedWearId != wearId) {
      _skewAuditedWearId = wearId;
      unawaited(DeviceTimelineAudit(db).logFor(wearId: wearId));
    }
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
  static String _hhmmss(DateTime t) =>
      '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

  /// Bluetooth is turned off: stop all collectors, and remember ”stopped because Bluetooth is turned off” so that it can be automatically restored when turned on again.。
  Future<void> _handleAdapterOff() => _enqueue(() async {
    _stoppedByAdapterOff = isRunning || _retryTimer != null;
    await _stopImpl();
    ConnectStatus.hint.value = _btOffHint;
  });

  /// Restart Bluetooth: First cancel the ”Bluetooth is not turned on” prompt, and then resume the collection of ”Stopped because Bluetooth is turned off”。
  /// The withdrawal reminder must be in [_stoppedByAdapterOff] before making a judgment, otherwise the prompt will be permanently stuck when the collection book is not running.。
  Future<void> _handleAdapterOn() => _enqueue(() async {
    if (ConnectStatus.hint.value == _btOffHint) {
      ConnectStatus.hint.value = null;
    }
    if (!_stoppedByAdapterOff) return;
    _stoppedByAdapterOff = false;
    if (_ownsHint) ConnectStatus.hint.value = null;
    await _ensureRunningImpl();
  });

  /// Return to the front desk to proactively review adapter Real status (Home page resumed call）。
  /// iOS The user switches Bluetooth on and off in the control center during suspension.，CoreBluetooth Status changes do not guarantee replacement delivery
  /// Dart Side, just lean on [onChanges] Will miss events。
  Future<void> syncAdapterState() async {
    final monitor = adapterMonitor;
    if (monitor == null) return;
    if (monitor.isOnNow) {
      await _handleAdapterOn();
    } else if (ConnectStatus.hint.value != _btOffHint) {
      await _handleAdapterOff();
    }
  }

  /// Algorithm calibration parameters + Select engine: Backend when binding sensorAttr Issue k/b/l3~g5 with users cgmbase。
  /// true calibration + Real phone (Android/iOS）True algorithm, place holder/Missing regression linear conversion, automatically switches back after the backend is configured with true calibration。
  /// return (parameter, Use it real.so?, Is it really factory calibrated??)。
  Future<(GluCalcParameter, bool, bool)> _buildAlgoParams(
    DateTime activeTime,
  ) async {
    final store = AlgoParamStore(db);
    final cal = await store.readSensorCalibration();
    final cgmBase = await store.readCgmBase();
    final tuning = await store.readAlgoTuning();
    final bgm = await BgmCalibrationStore(db).readLatest();
    // The characteristic of placeholder calibration is that all parameters take the same constant and are judged to be ”congruent with each other” rather than hard-coded to judge a certain value.，
    // Replace the backend 1.0 / 2.2 / 0.0 can all be recognized (see [isPlaceholderCalibration]）
    final calValues = cal == null
        ? const <double>[]
        : <double>[
            cal.k,
            cal.b,
            cal.l3,
            cal.g3,
            cal.l4,
            cal.g4,
            cal.l5,
            cal.g5,
          ];
    final placeholder = isPlaceholderCalibration(calValues);
    final realCal = cal != null && !placeholder;
    // cgmbase Missing/≤0 Hello .so meeting algoK=-Infinity，use [_fallbackCgmBase] reveal all the details，
    // The true value of the interface arrives and the calibrated fingerprint is eagerly replaced.
    final rawCgmBase = cgmBase ?? bgm?.value ?? 0;
    final baseFallback = rawCgmBase <= 0;
    final cgmBaseVal = baseFallback ? _fallbackCgmBase : rawCgmBase;
    // True algorithm for both ends：iOS of libCgmAlgo.a with android libdtProc.so Same version, same
    // MethodChannel contract, otherwise two sets of blood glucose values ​​will be calculated at both ends of the same batch of current.
    final useRealAlgo =
        realCal && (Platform.isAndroid || Platform.isIOS) && !_forceLinearAlgo;
    // True calibration uses the back-end true value, placeholder/If missing, always use linear fitting coefficient
    final c = realCal ? cal : null;
    final params = GluCalcParameter(
      slope: c?.k ?? _devReplaySlope,
      intercept: c?.b ?? _devReplayIntercept,
      startTs: activeTime.toUtc().millisecondsSinceEpoch ~/ 1000,
      paramL3: c?.l3 ?? 0,
      paramG3: c?.g3 ?? 0,
      paramL4: c?.l4 ?? 0,
      paramG4: c?.g4 ?? 0,
      paramL5: c?.l5 ?? 0,
      paramG5: c?.g5 ?? 0,
      paramBGMbase: cgmBaseVal,
      tuning: tuning,
    );
    if (kDebugMode) {
      final rawCal = cal == null
          ? 'none(The backend is not delivered)'
          : 'k=${cal.k} b=${cal.b} l3=${cal.l3} g3=${cal.g3} '
                'l4=${cal.l4} g4=${cal.g4} l5=${cal.l5} g5=${cal.g5}';
      final src = cal == null
          ? 'Calibration is not issued to the backend'
          : placeholder
          ? '⚠️The backend issues the occupancy calibration(Eight ginseng congruent=${calValues.first}，Not true calibration)→regression line'
          : baseFallback
          ? '⚠️The backend is not issued and is valid.cgmbase(=$rawCgmBase)→reveal all the details5.4top'
                '(The authoritative value can only be obtained through the interface.,Automatically eager to arrive true value)'
          : 'The back-end is shipped with true factory calibration.→Use it real.so';
      debugPrint(
        '[CGMCalibration source] $src｜backend raw[$rawCal] '
        'cgmbase=$cgmBaseVal${baseFallback ? "(reveal all the details)" : ""}',
      );
      debugPrint(
        '[CGMCalibration parameters] '
        '${_fmtCalParams(params, useRealAlgo: useRealAlgo, calReal: realCal)}',
      );
    }
    return (params, useRealAlgo, realCal);
  }

  /// The maximum number of items that have been dropped into storage during this wearing period record_seq + 1（No data from 1 rise）。
  Future<int> _nextSeq(int wearId) async {
    final maxSeq = db.userlocalGlucoseData.recordSeq.max();
    final q = db.selectOnly(db.userlocalGlucoseData)
      ..addColumns([maxSeq])
      ..where(db.userlocalGlucoseData.wearId.equals(wearId));
    final row = await q.getSingleOrNull();
    return (row?.read(maxSeq) ?? 0) + 1;
  }

  /// Book wear maximum record_seq That record (serial number, Measurement time)，Serves as slot anchor point for pocket collector。
  /// No data returned null，Caller deactivation time anchor。
  Future<({int seq, DateTime ts})?> _lastLocalAnchor(int wearId) async {
    final row =
        await (db.select(db.userlocalGlucoseData)
              ..where((t) => t.wearId.equals(wearId) & t.recordSeq.isNotNull())
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.recordSeq,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (row == null || row.recordSeq == null) return null;
    return (seq: row.recordSeq!, ts: row.measureTime);
  }
}

/// The results of a time line physical examination are used for replenishment and protection.。
class _TimelineSignature {
  const _TimelineSignature({
    required this.key,
    required this.needsBackfill,
    required this.stale,
    required this.reason,
  });

  /// 「There are still a few missing.” Only the hole itself is recognized. Cannot incorporate the number of entries or the last entry moment: those change every time a frame is received，
  /// 「The ”skip without progress” gate will never close during normal frame closing.。
  final String key;
  final bool needsBackfill;

  /// The device is connected but does not push frames. Reconnection is the only way to save it and it will resolve itself upon receiving the frame and is not subject to the same fingerprint gate.。
  final bool stale;
  final String reason;
}

/// Organize the calibration parameters fed to the algorithm into a log line。
String _fmtCalParams(
  GluCalcParameter p, {
  required bool useRealAlgo,
  required bool calReal,
}) =>
    'engine=${useRealAlgo ? "true algorithm(AndroidlibdtProc.so/iOS libCgmAlgo.a)" : "Linear conversion(current→blood sugar)"} '
    'Calibration=${calReal ? "True factory calibration(rear endsensorAttr)" : "No true calibration(Placeholder/Missing)→Linear0.62/1.75"} '
    'K/slope=${p.slope} B/intercept=${p.intercept} '
    'L3=${p.paramL3} G3=${p.paramG3} L4=${p.paramL4} G4=${p.paramG4} '
    'L5=${p.paramL5} G5=${p.paramG5} cgmbase/paramBGMbase=${p.paramBGMbase} '
    'paramA=${p.paramA} paramB=${p.paramB} paramC=${p.paramC} paramD=${p.paramD} '
    'startTs=${p.startTs} Optional parameters=${p.tuning}';
