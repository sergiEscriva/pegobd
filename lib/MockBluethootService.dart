import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:pegobd/service/BluetoothService.dart';
import 'sensors/OBDSensors.dart';

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
  final Random _random = Random();
  Map<String, int> _state = {};

  MockBluetoothConnection() {
    for (final pid in ObdSensors.sensors.keys) {
      _state[pid] = _getRandomValueForPid(pid);
    }
    _startSimulation();
  }

  void _startSimulation() {
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      if (!_isConnected) return;
      for (final pid in ObdSensors.sensors.keys) {
        _state[pid] = _getRandomValueForPid(pid);
        _sendResponse(_buildObdResponse(pid, _state[pid]!));
      }
    });
  }

  int _getRandomValueForPid(String pid) {
    switch (pid) {
      case "04":
      case "11":
      case "2F":
      case "45":
      case "47":
      case "48":
      case "49":
      case "4A":
      case "4B":
      case "4C":
      case "61":
      case "62":
      case "63":
      case "43":
        return _random.nextInt(101);
      case "05":
      case "0F":
      case "46":
      case "5C":
        return 40 + _random.nextInt(151);
      case "0C":
        return 800 + _random.nextInt(5201);
      case "0D":
        return _random.nextInt(201);
      case "0A":
      case "0B":
      case "33":
        return 20 + _random.nextInt(81);
      case "10":
        return _random.nextInt(65536);
      case "1F":
      case "21":
      case "31":
        return _random.nextInt(65536);
      case "22":
      case "23":
        return _random.nextInt(65536);
      case "42":
        return 12000 + _random.nextInt(3001);
      case "44":
      case "4F":
        return _random.nextInt(65536);
      case "50":
        return _random.nextInt(256);
      case "52":
        return _random.nextInt(101);
      case "53":
        return _random.nextInt(65536);
      case "54":
        return _random.nextInt(65536);
      case "5E":
        return _random.nextInt(65536);
      default:
        return _random.nextInt(255);
    }
  }

  String _buildObdResponse(String pid, int value) {
    String a = ((value >> 8) & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase();
    String b = (value & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase();
    if (["0C", "10", "1F", "21", "22", "23", "31", "42", "44", "4F", "53", "54", "5E"].contains(pid)) {
      return '41 $pid $a $b';
    } else {
      return '41 $pid $b';
    }
  }

  void _sendResponse(String response) {
    _controller.add(Uint8List.fromList('$response\r>'.codeUnits));
  }

  @override
  Stream<Uint8List>? get input => _controller.stream;

  @override
  set input(Stream<Uint8List>? input) {}

  @override
  get output => _mockSink as dynamic;

  @override
  set output(sink) {}

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
