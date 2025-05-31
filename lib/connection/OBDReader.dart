class OBDReader {
  final Future<String> Function(String) sendCommand;

  OBDReader(this.sendCommand);

  // Devuelve una lista de PIDs soportados (hex string: "01", "0C", etc.)
  Future<List<String>> getSupportedPIDs() async {
    List<String> supportedPIDs = [];

    // Hay que consultar varios rangos: 0100, 0120, 0140...
    for (int base = 0x00; base <= 0xE0; base += 0x20) {
      String cmd = '01${base.toRadixString(16).padLeft(2, '0').toUpperCase()}';
      String response = await sendCommand(cmd);

      if (response == null || response.isEmpty) break;

      // El resultado típico: "41 00 BE 1F A8 13"
      List<String> parts = response.split(' ');
      if (parts.length < 6) break;

      // Solo nos interesan los 4 bytes de datos (ej: BE 1F A8 13)
      for (int i = 0; i < 4; i++) {
        int byteVal = int.parse(parts[2 + i], radix: 16);
        for (int bit = 0; bit < 8; bit++) {
          if ((byteVal & (0x80 >> bit)) != 0) {
            int pid = base + i * 8 + bit + 1;
            supportedPIDs.add(pid.toRadixString(16).padLeft(2, '0').toUpperCase());
          }
        }
      }

      // El último bit del primer byte indica si hay más pids (según OBDII spec)
      // Pero lo más seguro es consultar todos los rangos.
    }

    return supportedPIDs;
  }

  // Pide todos los valores de sensores soportados
  Future<Map<String, String>> readAllSensors() async {
    final pids = await getSupportedPIDs();
    Map<String, String> sensorValues = {};

    for (var pid in pids) {
      String cmd = '01$pid';
      String response = await sendCommand(cmd);
      sensorValues[pid] = response;
      // Aquí puedes parsear cada valor según el PID si lo necesitas legible
    }
    return sensorValues;
  }
}
