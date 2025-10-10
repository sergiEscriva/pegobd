import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// Sistema de logging para capturar y guardar errores de la aplicación
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  static const String LOG_FILE_NAME = 'app_errors.log';
  static const int MAX_LOG_SIZE = 5 * 1024 * 1024; // 5 MB

  File? _logFile;
  bool _initialized = false;

  /// Inicializa el sistema de logging
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/$LOG_FILE_NAME');

      // Crear archivo si no existe
      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
        await _writeLog('📱 Sistema de logging inicializado', LogLevel.INFO);
      }

      // Verificar tamaño y rotar si es necesario
      await _rotateLogIfNeeded();

      _initialized = true;
      print('✅ Sistema de logging inicializado: ${_logFile!.path}');
    } catch (e) {
      print('❌ Error inicializando logger: $e');
    }
  }

  /// Rotar log si excede el tamaño máximo
  Future<void> _rotateLogIfNeeded() async {
    if (_logFile == null || !await _logFile!.exists()) return;

    final fileSize = await _logFile!.length();
    if (fileSize > MAX_LOG_SIZE) {
      final directory = await getApplicationDocumentsDirectory();
      final backupFile = File('${directory.path}/app_errors_old.log');

      // Mover archivo actual a backup
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
      await _logFile!.rename(backupFile.path);

      // Crear nuevo archivo
      _logFile = File('${directory.path}/$LOG_FILE_NAME');
      await _logFile!.create();
      await _writeLog('📱 Log rotado - Tamaño anterior: ${fileSize / 1024} KB', LogLevel.INFO);
    }
  }

  /// Escribe una línea en el log
  Future<void> _writeLog(String message, LogLevel level) async {
    if (_logFile == null) return;

    try {
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
      final logLine = '[$timestamp] [${level.name}] $message\n';

      await _logFile!.writeAsString(logLine, mode: FileMode.append);
    } catch (e) {
      print('❌ Error escribiendo en log: $e');
    }
  }

  /// Registra un mensaje de información
  Future<void> info(String message, {String? tag}) async {
    final logMessage = tag != null ? '[$tag] $message' : message;
    print('ℹ️ $logMessage');
    await _writeLog(logMessage, LogLevel.INFO);
  }

  /// Registra una advertencia
  Future<void> warning(String message, {String? tag}) async {
    final logMessage = tag != null ? '[$tag] $message' : message;
    print('⚠️ $logMessage');
    await _writeLog(logMessage, LogLevel.WARNING);
  }

  /// Registra un error
  Future<void> error(String message, {dynamic error, StackTrace? stackTrace, String? tag}) async {
    final logMessage = tag != null ? '[$tag] $message' : message;
    final fullMessage = StringBuffer(logMessage);

    if (error != null) {
      fullMessage.write('\nError: $error');
    }

    if (stackTrace != null) {
      fullMessage.write('\nStackTrace:\n$stackTrace');
    }

    print('❌ $fullMessage');
    await _writeLog(fullMessage.toString(), LogLevel.ERROR);
  }

  /// Registra un error crítico
  Future<void> critical(String message, {dynamic error, StackTrace? stackTrace, String? tag}) async {
    final logMessage = tag != null ? '[$tag] $message' : message;
    final fullMessage = StringBuffer('🚨 CRITICAL: $logMessage');

    if (error != null) {
      fullMessage.write('\nError: $error');
    }

    if (stackTrace != null) {
      fullMessage.write('\nStackTrace:\n$stackTrace');
    }

    print('🚨 $fullMessage');
    await _writeLog(fullMessage.toString(), LogLevel.CRITICAL);
  }

  /// Registra un evento de debug
  Future<void> debug(String message, {String? tag}) async {
    final logMessage = tag != null ? '[$tag] $message' : message;
    print('🔍 $logMessage');
    await _writeLog(logMessage, LogLevel.DEBUG);
  }

  /// Obtiene el contenido completo del log
  Future<String> getLogContent() async {
    if (_logFile == null || !await _logFile!.exists()) {
      return 'No hay logs disponibles';
    }

    try {
      return await _logFile!.readAsString();
    } catch (e) {
      return 'Error leyendo logs: $e';
    }
  }

  /// Obtiene las últimas N líneas del log
  Future<List<String>> getLastLines(int count) async {
    final content = await getLogContent();
    final lines = content.split('\n');

    if (lines.length <= count) {
      return lines;
    }

    return lines.sublist(lines.length - count - 1);
  }

  /// Limpia el log
  Future<void> clearLog() async {
    if (_logFile == null) return;

    try {
      await _logFile!.writeAsString('');
      await _writeLog('🗑️ Log limpiado', LogLevel.INFO);
      print('✅ Log limpiado');
    } catch (e) {
      print('❌ Error limpiando log: $e');
    }
  }

  /// Obtiene la ruta del archivo de log
  String? getLogFilePath() {
    return _logFile?.path;
  }

  /// Obtiene el tamaño del log en KB
  Future<double> getLogSize() async {
    if (_logFile == null || !await _logFile!.exists()) {
      return 0.0;
    }

    final size = await _logFile!.length();
    return size / 1024; // Retorna en KB
  }

  /// Exporta el log a un archivo específico
  Future<File?> exportLog(String destinationPath) async {
    if (_logFile == null || !await _logFile!.exists()) {
      return null;
    }

    try {
      final destination = File(destinationPath);
      await _logFile!.copy(destination.path);
      await info('📤 Log exportado a: $destinationPath');
      return destination;
    } catch (e) {
      await error('Error exportando log', error: e);
      return null;
    }
  }
}

/// Niveles de logging
enum LogLevel {
  DEBUG,
  INFO,
  WARNING,
  ERROR,
  CRITICAL,
}

