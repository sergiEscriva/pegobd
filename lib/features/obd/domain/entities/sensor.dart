// lib/obd/ObdSensors.dart
class ObdSensors {
  static const Map<String, Map<String, dynamic>> sensors = {
    "04": {"name": "Carga calculada", "unit": "%"},
    "05": {"name": "Temperatura refrigerante", "unit": "°C"},
    "06": {"name": "Fuel Trim 1 (corto plazo)", "unit": "%"},
    "07": {"name": "Fuel Trim 1 (largo plazo)", "unit": "%"},
    "08": {"name": "Fuel Trim 2 (corto plazo)", "unit": "%"},
    "09": {"name": "Fuel Trim 2 (largo plazo)", "unit": "%"},
    "0A": {"name": "Presión combustible", "unit": "kPa"},
    "0B": {"name": "Presión colector admisión", "unit": "kPa"},
    "0C": {"name": "RPM motor", "unit": "rpm"},
    "0D": {"name": "Velocidad vehículo", "unit": "km/h"},
    "0E": {"name": "Avance encendido", "unit": "°"},
    "0F": {"name": "Temperatura aire admisión", "unit": "°C"},
    "10": {"name": "Flujo de aire MAF", "unit": "g/s"},
    "11": {"name": "Posición acelerador", "unit": "%"},
    "1F": {"name": "Tiempo desde arranque", "unit": "s"},
    "21": {"name": "Distancia con MIL encendido", "unit": "km"},
    "22": {"name": "Presión rail combustible relativa", "unit": "kPa"},
    "23": {"name": "Presión rail combustible absoluta", "unit": "kPa"},
    "2F": {"name": "Nivel combustible", "unit": "%"},
    "31": {"name": "Distancia desde MIL apagado", "unit": "km"},
    "33": {"name": "Presión barométrica", "unit": "kPa"},
    "42": {"name": "Voltaje módulo", "unit": "V"},
    "43": {"name": "Carga absoluta", "unit": "%"},
    "44": {"name": "Relación aire/combustible", "unit": ""},
    "45": {"name": "Posición relativa acelerador", "unit": "%"},
    "46": {"name": "Temperatura ambiente", "unit": "°C"},
    "47": {"name": "Posición acelerador B", "unit": "%"},
    "48": {"name": "Posición acelerador C", "unit": "%"},
    "49": {"name": "Posición pedal acelerador D", "unit": "%"},
    "4A": {"name": "Posición pedal acelerador E", "unit": "%"},
    "4B": {"name": "Posición pedal acelerador F", "unit": "%"},
    "4C": {"name": "Actuador acelerador", "unit": "%"},
    "4D": {"name": "Tiempo con MIL encendido", "unit": "min"},
    "4E": {"name": "Tiempo desde borrado códigos", "unit": "min"},
    "4F": {"name": "Valor máximo relación aire/comb.", "unit": ""},
    "50": {"name": "Máx. flujo aire MAF", "unit": "g/s"},
    "52": {"name": "Porcentaje etanol", "unit": "%"},
    "53": {"name": "Presión absoluta evap.", "unit": "Pa"},
    "54": {"name": "Presión evap.", "unit": "kPa"},
    "5C": {"name": "Temperatura aceite", "unit": "°C"},
    "5E": {"name": "Consumo combustible", "unit": "L/h"},
    "61": {"name": "Torque deseado", "unit": "%"},
    "62": {"name": "Torque referencia", "unit": "%"},
    "63": {"name": "Torque de fricción", "unit": "%"},
    // Añade más sensores según necesidad o para OEMs
  };

  static String getSensorName(String pid) {
    return sensors[pid]?["name"] ?? "Sensor $pid";
  }

  static String getSensorUnit(String pid) {
    return sensors[pid]?["unit"] ?? "";
  }

  static String formatValue(String pid, String rawValue) {
    if (rawValue.isEmpty) return "N/A";
    try {
      // Elimina caracteres no hexadecimales y el prompt '>'
      rawValue = rawValue.replaceAll(RegExp(r'[\r\n>]+'), '').trim();
      List<String> parts = rawValue.split(' ');
      if (parts.length < 3) return rawValue;
      int a = int.parse(parts[2], radix: 16);
      int b = parts.length > 3 ? int.parse(parts[3], radix: 16) : 0;

      switch (pid) {
        case "04": // Carga calculada
        case "11": // Posición acelerador
        case "2F": // Nivel combustible
        case "45": // Posición relativa acelerador
        case "47": // Posición acelerador B
        case "48": // Posición acelerador C
        case "49": // Pedal acelerador D
        case "4A": // Pedal acelerador E
        case "4B": // Pedal acelerador F
        case "4C": // Actuador acelerador
        case "61": // Torque deseado
        case "62": // Torque referencia
        case "63": // Torque de fricción
          return ((a * 100) / 255).toStringAsFixed(1);

        case "05": // Temp refrigerante
        case "0F": // Temp aire admisión
        case "46": // Temp ambiente
        case "5C": // Temp aceite
          return (a - 40).toString();

        case "06": // Fuel trim corto 1
        case "07": // Fuel trim largo 1
        case "08": // Fuel trim corto 2
        case "09": // Fuel trim largo 2
          return (((a - 128) * 100) / 128).toStringAsFixed(1);

        case "0A": // Presión combustible
        case "0B": // Presión colector admisión
        case "33": // Presión barométrica
          return a.toString();

        case "0C": // RPM motor
          if (parts.length < 4) return "Error";
          return (((a * 256) + b) / 4).toStringAsFixed(0);

        case "0D": // Velocidad vehículo
          return a.toString();

        case "0E": // Avance encendido
          return ((a / 2) - 64).toStringAsFixed(1);

        case "10": // MAF
          if (parts.length < 4) return "Error";
          return (((a * 256) + b) / 100).toStringAsFixed(2);

        case "1F": // Tiempo desde arranque (s)
          return ((a * 256) + b).toString();

        case "21": // Distancia con MIL encendido
        case "31": // Distancia desde MIL apagado
          if (parts.length < 4) return "Error";
          return ((a * 256) + b).toString();

        case "22": // Presión rail combustible relativa
        case "23": // Presión rail combustible absoluta
          if (parts.length < 4) return "Error";
          return (((a * 256) + b) * 0.079).toStringAsFixed(1);

        case "42": // Voltaje módulo
          return (((a * 256) + b) / 1000).toStringAsFixed(2);

        case "43": // Carga absoluta
          return ((a * 100) / 255).toStringAsFixed(1);

        case "44": // Relación aire/comb.
          if (parts.length < 4) return "Error";
          return (((a * 256) + b) / 32768).toStringAsFixed(2);

        case "52": // Porcentaje etanol
          return (a * 100 / 255).toStringAsFixed(1);

        case "53": // Presión absoluta evap.
          if (parts.length < 4) return "Error";
          return ((a * 256) + b).toString();

        case "54": // Presión evap.
          if (parts.length < 4) return "Error";
          return (((a * 256) + b) / 1000).toStringAsFixed(2);

        case "5E": // Consumo combustible (L/h)
          if (parts.length < 4) return "Error";
          return (((a * 256) + b) * 0.05).toStringAsFixed(2);

        default:
          return rawValue;
      }
    } catch (e) {
      return "Error: $e";
    }
  }
}
