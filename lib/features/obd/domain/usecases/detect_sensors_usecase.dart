import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class OBDSensorDetector {
  static const Map<String, String> STANDARD_PIDS = {
    // PIDs básicos más comunes
    '01': 'Monitor de estado DTC',
    '04': 'Carga calculada del motor',
    '05': 'Temperatura del refrigerante',
    '06': 'Trim de combustible a corto plazo - Banco 1',
    '07': 'Trim de combustible a largo plazo - Banco 1',
    '08': 'Trim de combustible a corto plazo - Banco 2',
    '09': 'Trim de combustible a largo plazo - Banco 2',
    '0A': 'Presión de combustible',
    '0B': 'Presión absoluta del colector',
    '0C': 'RPM del motor',
    '0D': 'Velocidad del vehículo',
    '0E': 'Avance de encendido',
    '0F': 'Temperatura del aire de admisión',
    '10': 'Flujo de aire MAF',
    '11': 'Posición del acelerador',
    '21': 'Distancia recorrida con MIL encendido',
    '22': 'Presión de combustible relativa al colector',
    '23': 'Presión de combustible (diesel)',
    '2F': 'Nivel de combustible',
    '33': 'Presión barométrica',
    '42': 'Voltaje del módulo de control',
    '43': 'Carga absoluta del motor',
    '44': 'Relación de equivalencia de combustible',
    '45': 'Posición relativa del acelerador',
    '46': 'Temperatura del aire ambiente',
    '47': 'Posición absoluta del acelerador B',
    '48': 'Posición absoluta del acelerador C',
    '49': 'Posición del pedal acelerador D',
    '4A': 'Posición del pedal acelerador E',
    '4B': 'Posición del pedal acelerador F',
    '4C': 'Posición del acelerador comandada',
    '5C': 'Temperatura del aceite del motor',
    '5D': 'Tiempo de inyección de combustible',
    '5E': 'Consumo de combustible del motor',
  };

  /// Detecta todos los sensores disponibles en el vehículo
  static Future<Map<String, bool>> detectAvailableSensors(
    BluetoothConnection? connection, {
    bool isSimulatorMode = false,
  }) async {
    Map<String, bool> availableSensors = {};

    if (isSimulatorMode) {
      // En modo simulador, simular que hay sensores disponibles
      List<String> simulatedSensors = [
        '04',
        '05',
        '0C',
        '0D',
        '0F',
        '10',
        '11',
        '2F',
        '5C',
        '42',
      ];

      for (String pid in STANDARD_PIDS.keys) {
        availableSensors[pid] = simulatedSensors.contains(pid);
      }

      await Future.delayed(Duration(seconds: 2)); // Simular tiempo de escaneo
      return availableSensors;
    }

    if (connection == null) {
      // Sin conexión, marcar todos como no disponibles
      for (String pid in STANDARD_PIDS.keys) {
        availableSensors[pid] = false;
      }
      return availableSensors;
    }

    try {
      // 1. Primero consultar PIDs soportados usando comandos estándar
      Map<String, bool> supportedPids = await _querySupportedPids(connection);

      // 2. Luego probar individualmente los PIDs más importantes
      List<String> priorityPids = [
        '04',
        '05',
        '0C',
        '0D',
        '0F',
        '10',
        '11',
        '2F',
        '5C',
      ];

      for (String pid in priorityPids) {
        if (supportedPids.containsKey(pid) && supportedPids[pid]!) {
          // Ya marcado como soportado por query inicial
          availableSensors[pid] = true;
        } else {
          // Probar individualmente
          bool isAvailable = await _testSinglePid(connection, pid);
          availableSensors[pid] = isAvailable;

          // Pequeña pausa para no saturar el adaptador
          await Future.delayed(Duration(milliseconds: 200));
        }
      }

      // 3. Para el resto de PIDs, usar información de supportedPids
      for (String pid in STANDARD_PIDS.keys) {
        if (!availableSensors.containsKey(pid)) {
          availableSensors[pid] = supportedPids[pid] ?? false;
        }
      }
    } catch (e) {
      print('Error detectando sensores: $e');
      // En caso de error, marcar algunos básicos como disponibles
      List<String> basicPids = ['04', '05', '0C', '0D'];
      for (String pid in STANDARD_PIDS.keys) {
        availableSensors[pid] = basicPids.contains(pid);
      }
    }

    return availableSensors;
  }

  /// Consulta los PIDs soportados usando comandos estándar OBD2
  static Future<Map<String, bool>> _querySupportedPids(
    BluetoothConnection connection,
  ) async {
    Map<String, bool> supportedPids = {};

    try {
      // Consultar PIDs 01-20
      String response1 = await _sendOBDCommand(connection, '0100');
      _parseSupportedPidsResponse(response1, 1, supportedPids);

      await Future.delayed(Duration(milliseconds: 500));

      // Consultar PIDs 21-40
      String response2 = await _sendOBDCommand(connection, '0120');
      _parseSupportedPidsResponse(response2, 33, supportedPids); // 0x21 = 33

      await Future.delayed(Duration(milliseconds: 500));

      // Consultar PIDs 41-60
      String response3 = await _sendOBDCommand(connection, '0140');
      _parseSupportedPidsResponse(response3, 65, supportedPids); // 0x41 = 65
    } catch (e) {
      print('Error consultando PIDs soportados: $e');
    }

    return supportedPids;
  }

  /// Analiza la respuesta de PIDs soportados y marca en el mapa
  static void _parseSupportedPidsResponse(
    String response,
    int baseValue,
    Map<String, bool> supportedPids,
  ) {
    if (response.isEmpty ||
        response.contains('ERROR') ||
        response.contains('NO DATA')) {
      return;
    }

    try {
      // Formato esperado: "41 00 XX XX XX XX" donde XXXXXXXX es bitmap de PIDs
      List<String> parts = response.split(' ');
      if (parts.length >= 6) {
        String hexData = parts[2] + parts[3] + parts[4] + parts[5];
        int bitmap = int.parse(hexData, radix: 16);

        // Analizar cada bit para determinar PIDs soportados
        for (int i = 0; i < 32; i++) {
          if ((bitmap & (1 << (31 - i))) != 0) {
            String pid = (baseValue + i)
                .toRadixString(16)
                .toUpperCase()
                .padLeft(2, '0');
            if (STANDARD_PIDS.containsKey(pid)) {
              supportedPids[pid] = true;
            }
          }
        }
      }
    } catch (e) {
      print('Error parseando respuesta de PIDs: $e');
    }
  }

  /// Prueba un PID individual enviando comando y esperando respuesta válida
  static Future<bool> _testSinglePid(
    BluetoothConnection connection,
    String pid,
  ) async {
    try {
      String response = await _sendOBDCommand(connection, '01$pid');

      // Una respuesta válida debe empezar con "41" seguido del PID
      return response.startsWith('41 $pid') || response.contains('41 $pid');
    } catch (e) {
      print('Error probando PID $pid: $e');
      return false;
    }
  }

  /// Envía comando OBD y espera respuesta
  static Future<String> _sendOBDCommand(
    BluetoothConnection connection,
    String command,
  ) async {
    final completer = Completer<String>();
    String responseBuffer = '';
    StreamSubscription? subscription;

    try {
      // Enviar comando
      final commandBytes = Uint8List.fromList('$command\r'.codeUnits);
      connection.output.add(commandBytes);
      await connection.output.allSent;

      // Configurar timeout
      final timer = Timer(Duration(seconds: 3), () {
        if (!completer.isCompleted) {
          subscription?.cancel();
          completer.complete('TIMEOUT');
        }
      });

      // Escuchar respuesta
      subscription = connection.input?.listen((Uint8List data) {
        responseBuffer += String.fromCharCodes(data);

        // ELM327 termina respuestas con '>'
        if (responseBuffer.contains('>')) {
          timer.cancel();
          subscription?.cancel();

          if (!completer.isCompleted) {
            String cleanResponse =
                responseBuffer
                    .replaceAll('>', '')
                    .replaceAll('\r', '')
                    .replaceAll('\n', ' ')
                    .trim();
            completer.complete(cleanResponse);
          }
        }
      });

      return await completer.future;
    } catch (e) {
      if (!completer.isCompleted) {
        completer.complete('ERROR: $e');
      }
      return 'ERROR';
    }
  }

  /// Obtiene el nombre descriptivo de un PID
  static String getSensorName(String pid) {
    return STANDARD_PIDS[pid] ?? 'Sensor desconocido ($pid)';
  }

  /// Obtiene lista de PIDs prioritarios para vehículos comunes
  static List<String> getPriorityPids() {
    return ['04', '05', '0C', '0D', '0F', '10', '11', '2F', '5C', '42'];
  }
}
