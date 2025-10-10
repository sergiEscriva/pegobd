import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ELM327Communication {
  static const List<String> COMMON_PINS = ['1234', '0000', '7890', '1111'];

  /// Inicializa la comunicación con el adaptador ELM327
  static Future<bool> initializeELM327(BluetoothConnection connection) async {
    try {
      print("Iniciando secuencia de inicialización ELM327...");

      // Secuencia de inicialización recomendada
      await sendCommand(connection, "ATZ"); // Reset
      await Future.delayed(Duration(seconds: 2)); // Espera importante después del reset
      await sendCommand(connection, "ATE0"); // Echo off
      await sendCommand(connection, "ATL0"); // Line feeds off
      await sendCommand(connection, "ATS0"); // Spaces off
      await sendCommand(connection, "ATH0"); // Headers off
      await sendCommand(connection, "ATSP0"); // Auto protocol detection

      // Verificar comunicación con comando básico
      final response = await sendCommand(connection, "0100");
      bool success = response.isNotEmpty &&
          !response.contains("ERROR") &&
          !response.contains("NO DATA");

      if (success) {
        print("ELM327 inicializado correctamente");
      } else {
        print("Error en inicialización ELM327: $response");
      }

      return success;
    } catch (e) {
      print("Error inicializando ELM327: $e");
      return false;
    }
  }

  /// Envía un comando AT al adaptador ELM327 y espera respuesta
  static Future<String> sendCommand(BluetoothConnection connection, String command) async {
    try {
      // Enviar comando
      final commandBytes = Uint8List.fromList('$command\r\n'.codeUnits);
      connection.output.add(commandBytes);
      await connection.output.allSent;

      // Esperar respuesta con timeout
      final completer = Completer<String>();
      String responseBuffer = '';
      StreamSubscription? subscription;

      // Timeout de 5 segundos
      final timer = Timer(Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          subscription?.cancel();
          completer.complete("TIMEOUT");
        }
      });

      subscription = connection.input?.listen((Uint8List data) {
        responseBuffer += String.fromCharCodes(data);

        // El ELM327 termina las respuestas con '>' (prompt)
        if (responseBuffer.contains('>')) {
          timer.cancel();
          subscription?.cancel();
          if (!completer.isCompleted) {
            // Limpiar la respuesta
            String cleanResponse = responseBuffer
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
      print("Error enviando comando '$command': $e");
      return "ERROR";
    }
  }

  /// Detecta el protocolo OBD2 utilizado por el vehículo
  static Future<String> detectProtocol(BluetoothConnection connection) async {
    try {
      final protocol = await sendCommand(connection, "ATDPN");
      print("Protocolo detectado: $protocol");
      return protocol;
    } catch (e) {
      print("Error detectando protocolo: $e");
      return "UNKNOWN";
    }
  }

  /// Verifica si hay comunicación con la ECU del vehículo
  static Future<bool> testECUConnection(BluetoothConnection connection) async {
    try {
      // Comando estándar para verificar PIDs soportados
      final response = await sendCommand(connection, "0100");
      // Una respuesta válida debe empezar con "41 00" seguido de datos
      return response.startsWith("41 00") || response.contains("41 00");
    } catch (e) {
      print("Error probando conexión ECU: $e");
      return false;
    }
  }

  /// Lista de comandos comunes para diagnóstico inicial
  static const Map<String, String> DIAGNOSTIC_COMMANDS = {
    'ATI': 'Información del chip ELM327',
    'ATZ': 'Reset del adaptador',
    'ATRV': 'Leer voltaje',
    'ATSP0': 'Detección automática de protocolo',
    '0100': 'PIDs soportados (01-20)',
    '0120': 'PIDs soportados (21-40)',
    '0140': 'PIDs soportados (41-60)',
  };
}
