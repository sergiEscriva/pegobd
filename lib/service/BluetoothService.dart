// Hacer BluetoothService abstracta o crear RealBluetoothService
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

abstract class BluetoothService {
  Future<bool> checkPermissions();
  Future<BluetoothState> getState();
  Stream<BluetoothState> onStateChanged();
  Future<List<BluetoothDevice>> getPairedDevices();
  Future<BluetoothConnection> connectToDevice(BluetoothDevice device);
  Future<void> disconnect(BluetoothConnection? connection);
}

// Crear implementación real
class RealBluetoothService extends BluetoothService {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  @override
  Future<bool> checkPermissions() async {
    return await Permission.bluetoothConnect.isGranted &&
        await Permission.bluetoothScan.isGranted;
  }

  @override
  Future<BluetoothState> getState() async {
    return await _bluetooth.state;
  }

  @override
  Stream<BluetoothState> onStateChanged() {
    return _bluetooth.onStateChanged();
  }

  @override
  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      if (!(await checkPermissions())) {
        return [];
      }
      return await _bluetooth.getBondedDevices();
    } catch (e) {
      print("Error obteniendo dispositivos emparejados: $e");
      return [];
    }
  }

  @override
  Future<BluetoothConnection> connectToDevice(BluetoothDevice device) async {
    if (!(await checkPermissions())) {
      throw Exception("Permisos Bluetooth no concedidos");
    }
    return await BluetoothConnection.toAddress(device.address);
  }

  @override
  Future<void> disconnect(BluetoothConnection? connection) async {
    await connection?.close();
  }
}
