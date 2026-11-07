import 'package:cgm_sdk/src/ble/gls_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a GLS measurement with mg/dL concentration', () {
    final bytes = GlsProtocol.buildMeasurementNotification(
      sequenceNumber: 12,
      at: DateTime(2026, 11, 7, 10, 30, 0),
      glucoseMgDl: 110,
    );
    final parsed = GlsProtocol.parseMeasurement(bytes);
    expect(parsed, isNotNull);
    expect(parsed!.sequenceNumber, 12);
    expect(parsed.glucoseMgDl, closeTo(110, 1.5));
    expect(parsed.contextFollows, isFalse);
  });

  test('parses measurement context and matches by sequence', () {
    final bytes = GlsProtocol.buildContextNotification(
      sequenceNumber: 12,
      meal: 2,
    );
    final ctx = GlsProtocol.parseMeasurementContext(bytes);
    expect(ctx, isNotNull);
    expect(ctx!.sequenceNumber, 12);
    expect(ctx.meal, 2);
  });

  test('builds incremental RACP greater-or-equal payload', () {
    expect(
      GlsProtocol.racpReportGreaterOrEqual(100),
      [0x01, 0x03, 0x01, 100, 0],
    );
  });

  test('parses RACP success and no-records responses', () {
    final ok = GlsProtocol.parseRacpResponse([0x06, 0x00, 0x01, 0x01]);
    expect(ok!.isSuccess, isTrue);
    final empty = GlsProtocol.parseRacpResponse([0x06, 0x00, 0x01, 0x06]);
    expect(empty!.isSuccess, isTrue);
    expect(empty.message, 'No records found');
  });

  test('detects protocol priority 181F > 1808 > FFF0', () {
    expect(
      GlsProtocol.detectProtocol(['181f', '1808', 'fff0']),
      BleProtocolKind.cgm181f,
    );
    expect(
      GlsProtocol.detectProtocol(['1808', 'fff0']),
      BleProtocolKind.gls,
    );
    expect(
      GlsProtocol.detectProtocol(['0000fff0-0000-1000-8000-00805f9b34fb']),
      BleProtocolKind.fff0,
    );
    expect(
      GlsProtocol.detectProtocol(['180a']),
      BleProtocolKind.unsupported,
    );
  });

  test('builds a legacy 0xB0 frame from GLS glucose', () {
    final frame = GlsProtocol.toLegacyB0Frame(
      glucoseMgDl: 110,
      sequenceNumber: 5,
      at: DateTime.utc(2026, 11, 7, 5, 0, 0),
    );
    expect(frame[0], 0xAA);
    expect(frame[2], 0xB0);
    expect(frame.length, frame[1]);
  });
}
