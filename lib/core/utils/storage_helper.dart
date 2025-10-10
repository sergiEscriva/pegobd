import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPreferencesHelper {
  static const String _selectedSensorsKey = 'selected_sensors';
  static const String _operationModeKey = 'operation_mode';
  static const String _vehicleCachePrefix = 'vehicle_cache_';
  static const String _lastConnectedDeviceKey = 'last_connected_device';
  static const String _autoReconnectKey = 'auto_reconnect';
  static const String _themeModeKey = 'theme_mode'; // 'light', 'dark', 'auto'

  /// Guarda la lista de sensores seleccionados
  static Future<void> saveSelectedSensors(List<String> sensorPids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_selectedSensorsKey, sensorPids);
    print("💾 Sensores seleccionados guardados: $sensorPids");
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

  /// Guarda sensores específicos para un vehículo (por dirección MAC del dispositivo)
  static Future<void> saveVehicleSensors(String deviceAddress,
      List<String> sensorPids) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_vehicleCachePrefix$deviceAddress';

    final vehicleData = {
      'sensors': sensorPids,
      'lastUpdated': DateTime.now().toIso8601String(),
      'deviceAddress': deviceAddress,
    };

    await prefs.setString(key, jsonEncode(vehicleData));
    print("💾 Sensores guardados para vehículo: $deviceAddress");
  }

  /// Obtiene sensores guardados para un vehículo específico
  static Future<List<String>?> getVehicleSensors(String deviceAddress) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_vehicleCachePrefix$deviceAddress';
    final dataStr = prefs.getString(key);

    if (dataStr == null) {
      return null;
    }

    try {
      final data = jsonDecode(dataStr) as Map<String, dynamic>;
      final sensors = (data['sensors'] as List).cast<String>();
      print("📖 Sensores recuperados para vehículo: $deviceAddress");
      return sensors;
    } catch (e) {
      print("❌ Error al recuperar sensores del vehículo: $e");
      return null;
    }
  }

  /// Lista todos los vehículos con configuración guardada
  static Future<List<String>> getSavedVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    return keys
        .where((key) => key.startsWith(_vehicleCachePrefix))
        .map((key) => key.replaceFirst(_vehicleCachePrefix, ''))
        .toList();
  }

  /// Elimina la configuración de un vehículo
  static Future<void> removeVehicleCache(String deviceAddress) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_vehicleCachePrefix$deviceAddress';
    await prefs.remove(key);
    print("🗑️ Cache eliminado para vehículo: $deviceAddress");
  }

  /// Guarda el modo de operación
  static Future<void> saveOperationMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_operationModeKey, mode);
    print("💾 Modo de operación guardado: $mode");
  }

  /// Obtiene el modo de operación guardado
  static Future<String> getOperationMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_operationModeKey) ?? 'real';
  }

  /// Guarda el último dispositivo conectado
  static Future<void> saveLastConnectedDevice(String deviceAddress,
      String deviceName) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceData = {
      'address': deviceAddress,
      'name': deviceName,
      'lastConnected': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_lastConnectedDeviceKey, jsonEncode(deviceData));
    print("💾 Último dispositivo guardado: $deviceName ($deviceAddress)");
  }

  /// Obtiene el último dispositivo conectado
  static Future<Map<String, String>?> getLastConnectedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString(_lastConnectedDeviceKey);

    if (dataStr == null) {
      return null;
    }

    try {
      final data = jsonDecode(dataStr) as Map<String, dynamic>;
      return {
        'address': data['address'] as String,
        'name': data['name'] as String,
        'lastConnected': data['lastConnected'] as String,
      };
    } catch (e) {
      print("❌ Error al recuperar último dispositivo: $e");
      return null;
    }
  }

  /// Guarda el estado de reconexión automática
  static Future<void> saveAutoReconnect(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoReconnectKey, enabled);
  }

  /// Obtiene el estado de reconexión automática
  static Future<bool> getAutoReconnect() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoReconnectKey) ?? true; // Por defecto habilitado
  }

  /// Guarda el modo de tema
  static Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
    print("💾 Modo de tema guardado: $mode");
  }

  /// Obtiene el modo de tema
  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey) ?? 'auto'; // Por defecto auto
  }

  /// Limpia todos los datos guardados
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("🗑️ Todos los datos borrados");
  }

  /// Limpia solo la caché de vehículos
  static Future<void> clearVehicleCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith(_vehicleCachePrefix)) {
        await prefs.remove(key);
      }
    }
    print("🗑️ Caché de vehículos borrada");
  }

  /// Exporta toda la configuración
  static Future<Map<String, dynamic>> exportConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final config = <String, dynamic>{};

    for (var key in keys) {
      config[key] = prefs.get(key);
    }

    return config;
  }

  /// Importa configuración
  static Future<void> importConfiguration(Map<String, dynamic> config) async {
    final prefs = await SharedPreferences.getInstance();

    for (var entry in config.entries) {
      final value = entry.value;
      if (value is String) {
        await prefs.setString(entry.key, value);
      } else if (value is bool) {
        await prefs.setBool(entry.key, value);
      } else if (value is int) {
        await prefs.setInt(entry.key, value);
      } else if (value is double) {
        await prefs.setDouble(entry.key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(entry.key, value);
      }
    }

    print("📥 Configuración importada exitosamente");
  }
}
