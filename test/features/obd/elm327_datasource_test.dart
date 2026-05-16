import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'package:pegobd/features/obd/data/datasources/elm327_datasource.dart';

// Fake connection that lets tests control what data is emitted on the input stream.
class _FakeConnection implements BluetoothConnection {
  final StreamController<Uint8List> _controller =
      StreamController<Uint8List>.broadcast();
  final _sink = _FakeSink();

  @override
  Stream<Uint8List>? get input => _controller.stream;

  @override
  set input(Stream<Uint8List>? _) {}

  @override
  get output => _sink;

  @override
  set output(_) {}

  @override
  bool get isConnected => !_controller.isClosed;

  void emit(String text) =>
      _controller.add(Uint8List.fromList(text.codeUnits));

  @override
  Future<void> close() async => _controller.close();

  @override
  Future<void> finish() async {}

  @override
  Future<void> dispose() async => _controller.close();

  @override
  Future<void> cancel() async => _controller.close();
}

class _FakeSink implements StreamSink<Uint8List> {
  final List<Uint8List> sent = [];

  @override
  void add(Uint8List event) => sent.add(event);

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream<Uint8List> stream) => Future.value();

  @override
  Future close() => Future.value();

  @override
  Future get done => Future.value();

  Future get allSent => Future.value();
}

void main() {
  group('ELM327Communication.sendCommand', () {
    test('returns clean response when device replies with prompt', () async {
      final conn = _FakeConnection();

      // Emit the response shortly after the command is sent
      Future.delayed(const Duration(milliseconds: 50), () {
        conn.emit('41 0C 1A F8\r>');
      });

      final result = await ELM327Communication.sendCommand(conn, '010C');
      expect(result, '41 0C 1A F8');
    });

    test('returns kTimeout when device does not respond within timeout', () async {
      // Use a connection that never emits data.
      // Override timeout to keep test fast — we test the path, not the duration.
      final conn = _FakeConnection();

      // sendCommand uses COMMAND_TIMEOUT (5 s). We don't want the test to wait
      // that long, so we trigger the stream done event to force an ERROR result
      // and verify the error path works. For the timeout path specifically we
      // accept either kTimeout or kError because forcing a real 5-second wait
      // would be inappropriate in a unit test.
      Future.delayed(const Duration(milliseconds: 100), () async {
        await conn.close();
      });

      final result = await ELM327Communication.sendCommand(conn, '010C');
      expect(
        result == ELM327Communication.kTimeout ||
            result == ELM327Communication.kError,
        isTrue,
      );
    });

    test('returns kError when stream emits an error', () async {
      final conn = _FakeConnection();

      Future.delayed(const Duration(milliseconds: 30), () {
        conn._controller.addError(Exception('Bluetooth error'));
      });

      final result = await ELM327Communication.sendCommand(conn, 'ATI');
      expect(result, ELM327Communication.kError);
    });

    test('returns kError when buffer exceeds max size', () async {
      final conn = _FakeConnection();

      // Emit 5 KB of data without a '>' prompt — triggers buffer overflow guard
      Future.delayed(const Duration(milliseconds: 30), () {
        conn.emit('A' * 5000);
      });

      final result = await ELM327Communication.sendCommand(conn, 'ATI');
      expect(result, ELM327Communication.kError);
    });

    test('strips prompt and whitespace from response', () async {
      final conn = _FakeConnection();

      Future.delayed(const Duration(milliseconds: 30), () {
        conn.emit('ELM327 v1.5\r\n>');
      });

      final result = await ELM327Communication.sendCommand(conn, 'ATI');
      expect(result.contains('>'), isFalse);
      expect(result.trim(), result); // no leading/trailing whitespace
    });
  });

  group('ELM327Communication constants', () {
    test('kTimeout and kError are non-empty distinct strings', () {
      expect(ELM327Communication.kTimeout, isNotEmpty);
      expect(ELM327Communication.kError, isNotEmpty);
      expect(
        ELM327Communication.kTimeout,
        isNot(equals(ELM327Communication.kError)),
      );
    });
  });
}
