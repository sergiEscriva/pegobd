// lib/connection/ConnectionManager.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../../core/utils/app_logger.dart';
import '../../features/dashboard/domain/entities/sensor_data.dart';
import '../../features/obd/data/datasources/elm327_datasource.dart';
import '../../features/obd/data/datasources/obd_reader.dart';
import '../../features/obd/domain/entities/sensor.dart';
import 'bluetooth_service.dart';
import 'mock_bluetooth_service.dart';

class ConnectionManager {
  final BluetoothService _service;
  final AppLogger _logger = AppLogger();

  BluetoothConnection? _connection;
  OBDReader? _obdReader;
  Timer? _sensorTimer;
  Timer? _reconnectionTimer;
  Timer? _connectionCheckTimer;

  bool isConnecting = false;
  bool isConnected = false;
  bool _autoReconnectEnabled = true;
  bool _isReconnecting = false;
  int _reconnectionAttempts = 0;
  static const int MAX_RECONNECTION_ATTEMPTS = 5;
  static const Duration RECONNECTION_DELAY = Duration(seconds: 3);
  static const Duration CONNECTION_CHECK_INTERVAL = Duration(seconds: 10);

  BluetoothDevice? connectedDevice;
  String connectionStatus = 'Desconectado';

  // Detectar si está en modo simulador
  bool get isSimulatorMode => _service is MockBluetoothService;

  // Para notificar cambios de estado
  final VoidCallback onConnectionChanged;

  // Para almacenar datos de sensores
  final Map<String, SensorData> _sensorData = {};
  final StreamController<Map<String, SensorData>> _sensorStreamController =
      StreamController<Map<String, SensorData>>.broadcast();

  // Stream público para acceder a los datos de sensores
  Stream<Map<String, SensorData>> get sensorStream =>
      _sensorStreamController.stream;

  ConnectionManager(this._service, {required this.onConnectionChanged});

  Future<void> connect(BluetoothDevice device) async {
    connectedDevice = device;
    isConnecting = true;
    connectionStatus = 'Conectando...';
    _reconnectionAttempts = 0;
    onConnectionChanged();

    try {
      _logger.info(
        'Iniciando conexión a: ${device.name} (${device.address})',
        tag: 'CONNECTION',
      );

      _connection = await _service.connectToDevice(device);

      if (_connection == null) {
        throw Exception('No se pudo establecer conexión');
      }

      connectionStatus = 'Inicializando ELM327...';
      onConnectionChanged();

      // INICIALIZACIÓN ELM327 MEJORADA
      if (!isSimulatorMode) {
        bool initialized = await ELM327Communication.initializeELM327(
          _connection!,
        );
        if (!initialized) {
          print("⚠️ Advertencia: Inicialización ELM327 falló, continuando...");
          _logger.warning("Inicialización ELM327 parcial", tag: 'CONNECTION');
          connectionStatus = 'Conectado (inicialización parcial)';
        } else {
          connectionStatus = 'Conectado';
          _logger.info("Conexión establecida exitosamente", tag: 'CONNECTION');
        }
      } else {
        connectionStatus = 'Conectado (Simulador)';
        _logger.info("Conexión al simulador establecida", tag: 'CONNECTION');
      }

      isConnected = true;
      onConnectionChanged();

      // Escuchar datos de entrada
      _connection!.input!.listen(
        (data) {
          handleReceivedData(data);
        },
        onDone: () {
          print("🔌 Conexión cerrada por el dispositivo");
          _handleDisconnection();
        },
        onError: (error) {
          print("❌ Error en conexión: $error");
          _handleDisconnection();
        },
      );

      // Inicializar OBDReader
      _obdReader = OBDReader((command) async {
        if (_connection == null || !isConnected) {
          return "";
        }

        final data = Uint8List.fromList('$command\r'.codeUnits);
        _connection!.output.add(data);
        await _connection!.output.allSent;

        await Future.delayed(Duration(milliseconds: 500));
        return "";
      });

      // Iniciar consulta periódica de sensores
      _startPeriodicSensorUpdates();

      // Iniciar monitoreo de conexión
      _startConnectionMonitoring();
    } catch (e, stackTrace) {
      print('❌ Error de conexión: $e');
      _logger.error(
        'Error en conexión',
        error: e,
        stackTrace: stackTrace,
        tag: 'CONNECTION',
      );
      connectionStatus = 'Error: $e';
      isConnected = false;
      onConnectionChanged();

      // Intentar reconexión automática
      if (_autoReconnectEnabled && connectedDevice != null) {
        _scheduleReconnection();
      }
    } finally {
      isConnecting = false;
      onConnectionChanged();
    }
  }

  /// Maneja la desconexión y activa reconexión automática
  void _handleDisconnection() {
    if (!isConnected) return; // Ya estamos desconectados

    print("🔄 Detectada desconexión del dispositivo");
    _logger.warning("Desconexión detectada", tag: 'CONNECTION');

    isConnected = false;
    connectionStatus = 'Desconectado';
    _sensorTimer?.cancel();
    _connectionCheckTimer?.cancel();
    onConnectionChanged();

    // Intentar reconexión automática si está habilitado
    if (_autoReconnectEnabled && connectedDevice != null && !_isReconnecting) {
      _scheduleReconnection();
    }
  }

  /// Programa un intento de reconexión
  void _scheduleReconnection() {
    if (_reconnectionAttempts >= MAX_RECONNECTION_ATTEMPTS) {
      print("❌ Número máximo de intentos de reconexión alcanzado");
      connectionStatus = 'Reconexión fallida';
      onConnectionChanged();
      return;
    }

    _reconnectionAttempts++;
    _isReconnecting = true;

    connectionStatus =
        'Reconectando (${_reconnectionAttempts}/$MAX_RECONNECTION_ATTEMPTS)...';
    onConnectionChanged();

    print("🔄 Programando reconexión (intento $_reconnectionAttempts)...");

    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer(RECONNECTION_DELAY, () async {
      if (connectedDevice != null) {
        print("🔄 Intentando reconectar a ${connectedDevice!.name}...");
        await connect(connectedDevice!);
        _isReconnecting = false;
      }
    });
  }

  /// Monitorea la conexión periódicamente
  void _startConnectionMonitoring() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(CONNECTION_CHECK_INTERVAL, (
      timer,
    ) async {
      if (!isConnected || _connection == null || isSimulatorMode) return;

      try {
        // Verificar conexión enviando comando simple
        final response = await ELM327Communication.sendCommand(
          _connection!,
          "ATI",
        );

        if (response == "TIMEOUT" || response == "ERROR") {
          print("⚠️ Conexión perdida detectada por timeout");
          _handleDisconnection();
        } else {
          // Resetear contador de reconexión si la conexión está estable
          _reconnectionAttempts = 0;
        }
      } catch (e) {
        print("⚠️ Error verificando conexión: $e");
        _handleDisconnection();
      }
    });
  }

  void _startPeriodicSensorUpdates() {
    _sensorTimer?.cancel();
    _sensorTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (!isConnected) {
        timer.cancel();
        return;
      }

      final priorityPIDs = [
        "04",
        "05",
        "0C",
        "0D",
        "0F",
        "10",
        "11",
        "2F",
        "5C",
      ];
      _requestSensors(priorityPIDs);
    });
  }

  Future<void> _requestSensors(List<String> pids) async {
    for (String pid in pids) {
      if (!isConnected) return;

      final command = "01$pid";

      if (_connection is MockBluetoothConnection) {
        await Future.delayed(Duration(milliseconds: 200));
        continue;
      }

      try {
        final data = Uint8List.fromList('$command\r'.codeUnits);
        _connection!.output.add(data);
        await _connection!.output.allSent;
        await Future.delayed(Duration(milliseconds: 200));
      } catch (e) {
        print("⚠️ Error solicitando sensor $pid: $e");
        _handleDisconnection();
        return;
      }
    }
  }

  void handleReceivedData(Uint8List data) {
    String response = String.fromCharCodes(data).trim();
    print('📥 Datos recibidos: $response');

    if (response.startsWith('41 ')) {
      try {
        List<String> parts = response.split(' ');
        if (parts.length >= 3) {
          String pid = parts[1];

          String formattedValue = ObdSensors.formatValue(pid, response);
          print('📊 PID: $pid, Valor: $formattedValue');

          SensorData sensor = SensorData(
            name: ObdSensors.getSensorName(pid),
            value: formattedValue,
            unit: ObdSensors.getSensorUnit(pid),
            pid: pid,
            timestamp: DateTime.now(),
          );

          _sensorData[pid] = sensor;
          _sensorStreamController.add(Map.from(_sensorData));
        }
      } catch (e) {
        print('❌ Error procesando respuesta: $e');
      }
    }
  }

  Future<void> requestAllSensors() async {
    if (_obdReader == null || !isConnected) return;

    try {
      List<String> supportedPIDs = await _obdReader!.getSupportedPIDs();
      print('📋 PIDs soportados: $supportedPIDs');
      _requestSensors(supportedPIDs);
    } catch (e) {
      print('❌ Error al solicitar sensores: $e');
    }
  }

  /// Habilita o deshabilita la reconexión automática
  void setAutoReconnect(bool enabled) {
    _autoReconnectEnabled = enabled;
    print(
      "🔄 Reconexión automática: ${enabled ? 'HABILITADA' : 'DESHABILITADA'}",
    );
  }

  Future<void> disconnect() async {
    print("🔌 Desconectando manualmente...");

    // Deshabilitar reconexión automática para desconexión manual
    _autoReconnectEnabled = false;

    _sensorTimer?.cancel();
    _reconnectionTimer?.cancel();
    _connectionCheckTimer?.cancel();

    await _service.disconnect(_connection);

    isConnected = false;
    connectionStatus = 'Desconectado';
    connectedDevice = null;

    onConnectionChanged();

    // Re-habilitar reconexión automática para futuras conexiones
    _autoReconnectEnabled = true;
  }

  void dispose() {
    _sensorTimer?.cancel();
    _reconnectionTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _sensorStreamController.close();
  }
}
