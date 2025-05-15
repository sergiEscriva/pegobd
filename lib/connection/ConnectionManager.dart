// Gestor de conexión
import 'dart:typed_data'; // Importación correcta para Uint8List
import 'dart:ui';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../service/BluetoothService.dart';

class ConnectionManager {
  final BluetoothService _service;
  BluetoothConnection? _connection;

  bool isConnecting = false;
  bool isConnected = false;
  BluetoothDevice? connectedDevice;

  // Para notificar cambios de estado
  final VoidCallback onConnectionChanged;

  ConnectionManager(this._service, {required this.onConnectionChanged});

  Future<void> connect(BluetoothDevice device) async {
    connectedDevice = device;
    isConnecting = true;
    onConnectionChanged();

    try {
      _connection = await _service.connectToDevice(device);
      isConnected = true;

      _connection!.input!.listen((data) {
        handleReceivedData(data);
      }).onDone(() {
        isConnected = false;
        onConnectionChanged();
      });
    } catch (e) {
      print('Error de conexión: $e');
    } finally {
      isConnecting = false;
      onConnectionChanged();
    }
  }

  void handleReceivedData(Uint8List data) {
    print('Datos recibidos: ${String.fromCharCodes(data)}');
    // Procesamiento de datos aquí
  }

  Future<void> disconnect() async {
    await _service.disconnect(_connection);
    isConnected = false;
    onConnectionChanged();
  }
}