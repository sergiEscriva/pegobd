import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String _selectedSensorsKey = 'selected_sensors';
  static const String _operationModeKey = 'operation_mode';

  /// Guarda la lista de sensores seleccionados
  static Future<void> saveSelectedSensors(List<String> sensorPids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_selectedSensorsKey, sensorPids);
  }

  /// Obtiene la lista de sensores seleccionados
  static Future<List<String>> getSelectedSensors() async {
    final prefs = await SharedPreferences.getInstance();
    final sensors = prefs.getStringList(_selectedSensorsKey);

    // Si no hay sensores guardados, retornar lista predeterminada
    if (sensors == null || sensors.isEmpty) {
      return ['04', '05', '0C', '0D', '0F', '10', '11', '2F', '5C'];
    }

    return sensors;
  }

  /// Guarda el modo de operación
  static Future<void> saveOperationMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_operationModeKey, mode);
  }

  /// Obtiene el modo de operación guardado
  static Future<String> getOperationMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_operationModeKey) ?? 'simulator';
  }

  /// Limpia todos los datos guardados
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Verifica si hay sensores guardados
  static Future<bool> hasSelectedSensors() async {
    final prefs = await SharedPreferences.getInstance();
    final sensors = prefs.getStringList(_selectedSensorsKey);
    return sensors != null && sensors.isNotEmpty;
  }
}
