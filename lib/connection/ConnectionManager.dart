// lib/connection/ConnectionManager.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../MockBluethootService.dart';
import '../model/SensorData.dart';
import '../sensors/OBDSensors.dart';  // Importación de la clase de sensores
import '../service/BluetoothService.dart';
import 'OBDReader.dart';

class ConnectionManager {
  final BluetoothService _service;
  BluetoothConnection? _connection;
  OBDReader? _obdReader;
  Timer? _sensorTimer;

  bool isConnecting = false;
  bool isConnected = false;
  BluetoothDevice? connectedDevice;

  // Para notificar cambios de estado
  final VoidCallback onConnectionChanged;

  // Para almacenar datos de sensores
  final Map<String, SensorData> _sensorData = {};
  final StreamController<Map<String, SensorData>> _sensorStreamController =
  StreamController<Map<String, SensorData>>.broadcast();

  // Stream público para acceder a los datos de sensores
  Stream<Map<String, SensorData>> get sensorStream => _sensorStreamController.stream;

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
        _sensorTimer?.cancel();
        onConnectionChanged();
      });

      // Inicializar OBDReader
      _obdReader = OBDReader((command) async {
        if (_connection == null || !isConnected) {
          return "";
        }

        final data = Uint8List.fromList('$command\r'.codeUnits);
        _connection!.output.add(data);
        await _connection!.output.allSent;

        // Esperar respuesta (implementación simple)
        await Future.delayed(Duration(milliseconds: 500));
        return ""; // La respuesta real se maneja en handleReceivedData
      });

      // Iniciar consulta periódica de sensores
      _startPeriodicSensorUpdates();

    } catch (e) {
      print('Error de conexión: $e');
    } finally {
      isConnecting = false;
      onConnectionChanged();
    }
  }

  void _startPeriodicSensorUpdates() {
    _sensorTimer?.cancel();
    _sensorTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (!isConnected) return;

      // Lista de PIDs que queremos consultar periódicamente
      final priorityPIDs = ["04", "05", "0C", "0D", "0F", "10", "11", "2F", "5C"];
      _requestSensors(priorityPIDs);
    });
  }

  Future<void> _requestSensors(List<String> pids) async {
    for (String pid in pids) {
      if (!isConnected) return;

      final command = "01$pid";

      // Comprobación especial para evitar el error con el mock
      if (_connection is MockBluetoothConnection) {
        print("Simulando envío de comando: $command");
        await Future.delayed(Duration(milliseconds: 200));
        continue;
      }

      final data = Uint8List.fromList('$command\r'.codeUnits);
      _connection!.output.add(data);
      await _connection!.output.allSent;
      await Future.delayed(Duration(milliseconds: 200));
    }
  }

  void handleReceivedData(Uint8List data) {
    String response = String.fromCharCodes(data).trim();
    print('Datos recibidos: $response');

    // Procesar respuesta de OBD (formato: 41 XX YY ZZ donde XX es el PID)
    if (response.startsWith('41 ')) {
      try {
        List<String> parts = response.split(' ');
        if (parts.length >= 3) {
          String pid = parts[1];

          // Formatear el valor según el tipo de PID
          String formattedValue = ObdSensors.formatValue(pid, response);
          print('PID: $pid, Valor crudo: $response, Valor formateado: $formattedValue');

          // Crear objeto SensorData con la información del sensor
          SensorData sensor = SensorData(
            name: ObdSensors.getSensorName(pid),
            value: formattedValue,
            unit: ObdSensors.getSensorUnit(pid),
            pid: pid,
            timestamp: DateTime.now(),
          );

          // Guardar en el mapa de datos y notificar a los oyentes
          _sensorData[pid] = sensor;
          _sensorStreamController.add(Map.from(_sensorData));
        }
      } catch (e) {
        print('Error procesando respuesta: $e');
      }
    }
  }

  // Método para solicitar todos los sensores disponibles
  Future<void> requestAllSensors() async {
    if (_obdReader == null || !isConnected) return;

    try {
      // Obtenemos PIDs soportados por el vehículo
      List<String> supportedPIDs = await _obdReader!.getSupportedPIDs();
      print('PIDs soportados: $supportedPIDs');

      // Solicitamos datos para cada PID
      _requestSensors(supportedPIDs);
    } catch (e) {
      print('Error al solicitar sensores: $e');
    }
  }

  Future<void> disconnect() async {
    _sensorTimer?.cancel();
    await _service.disconnect(_connection);
    isConnected = false;
    onConnectionChanged();
  }

  void dispose() {
    _sensorTimer?.cancel();
    _sensorStreamController.close();
  }
}

