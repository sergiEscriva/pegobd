import 'dart:async';
      import 'dart:typed_data';
      import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
      import 'package:pegobd/service/BluetoothService.dart';

      class MockBluetoothService extends BluetoothService {
        @override
        Future<List<BluetoothDevice>> getPairedDevices() async {
          return [
            BluetoothDevice(
              name: 'Virtual OBD Scanner',
              address: '00:11:22:33:44:55',
              type: BluetoothDeviceType.unknown,
              bondState: BluetoothBondState.bonded,
            ),
          ];
        }

        @override
        Future<BluetoothConnection> connectToDevice(BluetoothDevice device) async {
          return MockBluetoothConnection();
        }
      }

      class MockBluetoothConnection implements BluetoothConnection {
        final _controller = StreamController<Uint8List>();
        Timer? _timer;
        bool _isConnected = true;
        final _mockSink = _MockSink();

        MockBluetoothConnection() {
          _startSimulation();
        }

        void _startSimulation() {
          _timer = Timer.periodic(Duration(seconds: 1), (_) {
            if (!_isConnected) return;

            // Simulate OBD responses
            _sendResponse('41 05 7A'); // Engine temp

            Future.delayed(Duration(milliseconds: 300), () {
              if (!_isConnected) return;
              _sendResponse('41 0C 1A F8'); // RPM
            });

            Future.delayed(Duration(milliseconds: 600), () {
              if (!_isConnected) return;
              _sendResponse('41 0D 52'); // Speed
            });
          });
        }

        void _sendResponse(String response) {
          _controller.add(Uint8List.fromList('$response\r>'.codeUnits));
        }

        @override
        Stream<Uint8List>? get input => _controller.stream;

        @override
        set input(Stream<Uint8List>? input) {
          // No implementation needed for mock
        }

        @override
         get output => _mockSink as dynamic; // Devuelve null para simplicidad del mock

        @override
        set output(sink) {
          // No implementation needed for mock
        }


        @override
        Future<void> close() async {
          _isConnected = false;
          _timer?.cancel();
          await _controller.close();
        }

        @override
        bool get isConnected => _isConnected;

        @override
        Future<void> finish() async {
          _isConnected = false;
          _timer?.cancel();
        }

        @override
        Future<void> dispose() async {
          _isConnected = false;
          _timer?.cancel();
          await _controller.close();
        }

        @override
        Future<void> cancel() async {
          _isConnected = false;
          _timer?.cancel();
          await _controller.close();
        }
      }
class _MockSink implements StreamSink<Uint8List> {
  @override
  void add(Uint8List event) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream<Uint8List> stream) {
    return Future.value();
  }

  @override
  Future close() {
    return Future.value();
  }

  @override
  Future get done => Future.value();
}