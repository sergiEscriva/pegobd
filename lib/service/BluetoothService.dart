// Servicio de Bluetooth
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  Future<bool> checkPermissions() async {
    return await Permission.bluetoothConnect.isGranted &&
        await Permission.bluetoothScan.isGranted;
  }

  Future<BluetoothState> getState() async {
    return await _bluetooth.state;
  }

  Stream<BluetoothState> onStateChanged() {
    return _bluetooth.onStateChanged();
  }

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

  Future<BluetoothConnection> connectToDevice(BluetoothDevice device) async {
    if (!(await checkPermissions())) {
      throw Exception("Permisos Bluetooth no concedidos");
    }
    return await BluetoothConnection.toAddress(device.address);
  }

  Future<void> disconnect(BluetoothConnection? connection) async {
    await connection?.close();
  }
}