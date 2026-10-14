import 'dart:async';

/// Single consumer serial executor。
///
/// The algorithm library is not thread-safe and has an internal history window.，dataProc Must be carried out in strict order and item by item。Dart No preemptive threads，
/// But two paragraphs async Code interleaving `await` The algorithm is concurrent re-entrancy, so the tasks are strung together into one Future chain。
/// If a single task throws an error, it will only be passed to its own caller，Do not pollute subsequent tasks。
class SerialExecutor {
  Future<void> _tail = Future<void>.value();
  int _pending = 0;
  bool _closed = false;

  /// Is it idle (no tasks queued or executing). debug/For assertion。
  bool get isIdle => _pending == 0;

  /// Submits a task serially, the previous one (along with its internal await）The next one will start only after it is completely finished.。
  Future<T> run<T>(Future<T> Function() task) {
    if (_closed) {
      throw StateError('SerialExecutor Closed, no longer accepting tasks');
    }
    _pending++;
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await task());
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        _pending--;
      }
    });
    return completer.future;
  }

  /// Wait for the current queue to run out. closure/For test closing。
  Future<void> drain() => _tail;

  /// Close the executor, wait for the queued tasks to finish running, and then no longer accept new tasks.。
  Future<void> close() async {
    _closed = true;
    await _tail;
  }
}
