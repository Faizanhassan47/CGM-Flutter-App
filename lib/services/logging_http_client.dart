import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Wraps an [http.Client] and logs every request/response to the console
/// (debug/profile builds only) so backend traffic is visible in `flutter run`.
class LoggingHttpClient extends http.BaseClient {
  LoggingHttpClient(this._inner);

  final http.Client _inner;
  static const _tag = '[API]';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (kReleaseMode) return _inner.send(request);

    final sw = Stopwatch()..start();
    debugPrint('$_tag --> ${request.method} ${request.url}');
    try {
      final response = await _inner.send(request);
      sw.stop();
      final status = response.statusCode;
      final mark = status >= 200 && status < 300 ? 'OK ' : 'ERR';
      debugPrint(
        '$_tag <-- $mark $status ${request.method} ${request.url.path} '
        '(${sw.elapsedMilliseconds} ms)',
      );
      return response;
    } catch (e) {
      sw.stop();
      debugPrint(
        '$_tag <-- FAIL ${request.method} ${request.url} '
        '(${sw.elapsedMilliseconds} ms): $e',
      );
      rethrow;
    }
  }

  @override
  void close() => _inner.close();
}
