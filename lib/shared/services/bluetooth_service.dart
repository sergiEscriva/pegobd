import 'dart:async';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

abstract class BluetoothService {
  Future<bool> checkPermissions();

  Future<BluetoothState> getState();

  Stream<BluetoothState> onStateChanged();

  Future<List<BluetoothDevice>> getPairedDevices();

  // NUEVOS MÉTODOS PARA DESCUBRIMIENTO
  Future<void> startDiscovery();

  Future<void> stopDiscovery();

  Stream<BluetoothDiscoveryResult> onDiscovery();

  Future<bool> isDiscovering();

  Future<BluetoothConnection> connectToDevice(BluetoothDevice device);

  Future<void> disconnect(BluetoothConnection? connection);
}

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

  // NUEVOS MÉTODOS IMPLEMENTADOS
  @override
  Future<void> startDiscovery() async {
    try {
      final isDiscovering = await _bluetooth.isDiscovering;
      if (isDiscovering == true) {
        await _bluetooth.cancelDiscovery();
      }
      await _bluetooth.startDiscovery();
    } catch (e) {
      print("Error iniciando descubrimiento: $e");
    }
  }

  @override
  Future<void> stopDiscovery() async {
    try {
      await _bluetooth.cancelDiscovery();
    } catch (e) {
      print("Error deteniendo descubrimiento: $e");
    }
  }

  @override
  Stream<BluetoothDiscoveryResult> onDiscovery() {
    return _bluetooth.startDiscovery();
  }

  @override
  Future<bool> isDiscovering() async {
    final result = await _bluetooth.isDiscovering;
    return result ?? false;
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
