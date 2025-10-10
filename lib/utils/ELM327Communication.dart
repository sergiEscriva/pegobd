import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../utils/AppLogger.dart';

class ELM327Communication {
  static const List<String> COMMON_PINS = ['1234', '0000', '7890', '1111'];
  static const int MAX_RETRIES = 3;
  static const Duration COMMAND_TIMEOUT = Duration(seconds: 5);
  static const Duration RESET_DELAY = Duration(seconds: 2);
  static final AppLogger _logger = AppLogger();

  /// Inicializa la comunicación con el adaptador ELM327 con reintentos y manejo robusto de errores
  static Future<bool> initializeELM327(BluetoothConnection connection) async {
    int retryCount = 0;

    while (retryCount < MAX_RETRIES) {
      try {
        print("🔧 Intento ${retryCount + 1}/$MAX_RETRIES: Inicializando ELM327...");
        _logger.info("Intento ${retryCount + 1}/$MAX_RETRIES: Inicializando ELM327", tag: 'ELM327');

        bool success = await _performInitialization(connection);

        if (success) {
          print("✅ ELM327 inicializado correctamente");
          _logger.info("ELM327 inicializado correctamente", tag: 'ELM327');
          return true;
        } else {
          print("⚠️ Inicialización falló, reintentando...");
          _logger.warning("Inicialización falló en intento ${retryCount + 1}", tag: 'ELM327');
          retryCount++;
          if (retryCount < MAX_RETRIES) {
            await Future.delayed(Duration(seconds: 1));
          }
        }
      } catch (e, stackTrace) {
        print("❌ Error en intento ${retryCount + 1}: $e");
        _logger.error("Error en inicialización ELM327", error: e, stackTrace: stackTrace, tag: 'ELM327');
        retryCount++;
        if (retryCount < MAX_RETRIES) {
          await Future.delayed(Duration(seconds: 1));
        }
      }
    }

    print("❌ Inicialización ELM327 falló después de $MAX_RETRIES intentos");
    _logger.critical("Inicialización ELM327 falló después de $MAX_RETRIES intentos", tag: 'ELM327');
    return false;
  }

  /// Realiza la secuencia de inicialización completa con manejo robusto de errores
  static Future<bool> _performInitialization(BluetoothConnection connection) async {
    // Secuencia de inicialización ELM327 estándar mejorada
    final commands = [
      {'cmd': 'ATZ', 'desc': 'Reset', 'delay': RESET_DELAY, 'critical': true},
      {'cmd': 'ATE0', 'desc': 'Echo off', 'delay': Duration(milliseconds: 300), 'critical': true},
      {'cmd': 'ATL0', 'desc': 'Line feeds off', 'delay': Duration(milliseconds: 100), 'critical': false},
      {'cmd': 'ATS0', 'desc': 'Spaces off', 'delay': Duration(milliseconds: 100), 'critical': false},
      {'cmd': 'ATH0', 'desc': 'Headers off', 'delay': Duration(milliseconds: 100), 'critical': false},
      {'cmd': 'ATSP0', 'desc': 'Auto protocol', 'delay': Duration(milliseconds: 500), 'critical': true},
      {'cmd': 'ATAT1', 'desc': 'Adaptive timing auto', 'delay': Duration(milliseconds: 100), 'critical': false},
      {'cmd': 'ATST62', 'desc': 'Set timeout 62', 'delay': Duration(milliseconds: 100), 'critical': false},
    ];

    for (var cmdInfo in commands) {
      String cmd = cmdInfo['cmd'] as String;
      String desc = cmdInfo['desc'] as String;
      Duration delay = cmdInfo['delay'] as Duration;
      bool critical = cmdInfo['critical'] as bool;

      print("  📤 Enviando: $cmd ($desc)");
      final response = await sendCommand(connection, cmd);

      if (response == "TIMEOUT" || response == "ERROR") {
        print("  ❌ Falló: $cmd - Respuesta: $response");
        if (critical) {
          return false; // Comando crítico falló
        } else {
          print("  ⚠️ Comando no crítico falló, continuando...");
        }
      } else {
        print("  ✅ OK: $response");
      }

      await Future.delayed(delay);
    }

    // Verificar comunicación con comando básico
    print("  🔍 Verificando comunicación ECU...");
    final testResponse = await sendCommand(connection, "0100");
    bool success = testResponse.isNotEmpty &&
        !testResponse.contains("ERROR") &&
        !testResponse.contains("NO DATA") &&
        !testResponse.contains("UNABLE") &&
        !testResponse.contains("STOPPED") &&
        testResponse != "TIMEOUT";

    if (success) {
      print("  ✅ Comunicación ECU establecida");

      // Detectar protocolo
      final protocol = await detectProtocol(connection);
      print("  📡 Protocolo: $protocol");

    } else {
      print("  ⚠️ No se pudo verificar ECU: $testResponse");
    }

    return success;
  }

  /// Envía un comando AT al adaptador ELM327 y espera respuesta con manejo robusto
  static Future<String> sendCommand(BluetoothConnection connection, String command) async {
    try {
      // Limpiar buffer antes de enviar
      await Future.delayed(Duration(milliseconds: 50));

      // Enviar comando con terminador de línea
      final commandBytes = Uint8List.fromList('$command\r'.codeUnits);
      connection.output.add(commandBytes);
      await connection.output.allSent;

      // Esperar respuesta con timeout
      final completer = Completer<String>();
      String responseBuffer = '';
      StreamSubscription? subscription;

      final timer = Timer(COMMAND_TIMEOUT, () {
        if (!completer.isCompleted) {
          subscription?.cancel();
          completer.complete("TIMEOUT");
        }
      });

      subscription = connection.input?.listen(
        (Uint8List data) {
          try {
            responseBuffer += String.fromCharCodes(data);

            // El ELM327 termina las respuestas con '>' (prompt)
            if (responseBuffer.contains('>')) {
              timer.cancel();
              subscription?.cancel();
              if (!completer.isCompleted) {
                String cleanResponse = _cleanResponse(responseBuffer);
                completer.complete(cleanResponse);
              }
            }
          } catch (e) {
            print("❌ Error procesando respuesta: $e");
            timer.cancel();
            subscription?.cancel();
            if (!completer.isCompleted) {
              completer.complete("ERROR");
            }
          }
        },
        onError: (error) {
          print("❌ Error en stream: $error");
          timer.cancel();
          subscription?.cancel();
          if (!completer.isCompleted) {
            completer.complete("ERROR");
          }
        },
        onDone: () {
          print("⚠️ Stream cerrado prematuramente");
          timer.cancel();
          if (!completer.isCompleted) {
            completer.complete("ERROR");
          }
        },
      );

      return await completer.future;
    } catch (e, stackTrace) {
      print("❌ Error enviando comando '$command': $e");
      _logger.error("Error enviando comando ELM327: $command", error: e, stackTrace: stackTrace, tag: 'ELM327');
      return "ERROR";
    }
  }

  /// Limpia la respuesta del ELM327
  static String _cleanResponse(String response) {
    return response
        .replaceAll('>', '')
        .replaceAll('\r', '')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Detecta el protocolo OBD2 utilizado por el vehículo
  static Future<String> detectProtocol(BluetoothConnection connection) async {
    try {
      final protocol = await sendCommand(connection, "ATDPN");
      print("🔌 Protocolo detectado: $protocol");
      return protocol;
    } catch (e) {
      print("❌ Error detectando protocolo: $e");
      return "UNKNOWN";
    }
  }

  /// Verifica si hay comunicación con la ECU del vehículo
  static Future<bool> testECUConnection(BluetoothConnection connection) async {
    try {
      final response = await sendCommand(connection, "0100");
      bool isValid = response.startsWith("41 00") || response.contains("41 00");
      print(isValid ? "✅ ECU conectada" : "⚠️ ECU no responde");
      return isValid;
    } catch (e) {
      print("❌ Error probando conexión ECU: $e");
      return false;
    }
  }

  /// Obtiene el voltaje de la batería
  static Future<String> getVoltage(BluetoothConnection connection) async {
    try {
      final response = await sendCommand(connection, "ATRV");
      if (!response.contains("ERROR") && response.isNotEmpty) {
        return response;
      }
    } catch (e) {
      print("❌ Error leyendo voltaje: $e");
    }
    return "N/A";
  }

  /// Obtiene información del chip ELM327
  static Future<String> getChipInfo(BluetoothConnection connection) async {
    try {
      final response = await sendCommand(connection, "ATI");
      return response;
    } catch (e) {
      print("❌ Error leyendo info chip: $e");
      return "UNKNOWN";
    }
  }

  /// Resetea el adaptador ELM327
  static Future<bool> resetAdapter(BluetoothConnection connection) async {
    try {
      print("🔄 Reseteando adaptador ELM327...");
      final response = await sendCommand(connection, "ATZ");
      await Future.delayed(RESET_DELAY);
      return response != "ERROR" && response != "TIMEOUT";
    } catch (e) {
      print("❌ Error reseteando adaptador: $e");
      return false;
    }
  }
}
