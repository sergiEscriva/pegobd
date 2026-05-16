import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/domain/entities/sensor_data.dart';
import '../../shared/services/bluetooth_service.dart';
import '../../shared/services/connection_manager.dart';
import '../../shared/services/mock_bluetooth_service.dart';
import '../enums/operation_mode.dart';
import '../router/app_router.dart';

// ---------------------------------------------------------------------------
// Modo de operación
// ---------------------------------------------------------------------------
final operationModeProvider = StateProvider<OperationMode>(
  (ref) => OperationMode.simulator,
);

// ---------------------------------------------------------------------------
// Tema
// ---------------------------------------------------------------------------
final themeModeProvider = StateProvider<String>((ref) => 'auto');

// ---------------------------------------------------------------------------
// Sensores seleccionados (PIDs)
// ---------------------------------------------------------------------------
final selectedSensorsProvider = StateProvider<List<String>>(
  (ref) => ['04', '05', '0C', '0D', '0F', '10', '11', '2F', '5C'],
);

// ---------------------------------------------------------------------------
// Lista de dispositivos Bluetooth disponibles
// ---------------------------------------------------------------------------
final bluetoothDevicesProvider = StateProvider<List<BluetoothDevice>>(
  (ref) => [],
);

// ---------------------------------------------------------------------------
// Estado del adaptador Bluetooth (encendido, apagado…)
// ---------------------------------------------------------------------------
final bluetoothStateProvider = StateProvider<BluetoothState>(
  (ref) => BluetoothState.UNKNOWN,
);

// ---------------------------------------------------------------------------
// Servicio Bluetooth — se recrea automáticamente al cambiar de modo
// ---------------------------------------------------------------------------
final bluetoothServiceProvider = Provider<BluetoothService>((ref) {
  final mode = ref.watch(operationModeProvider);
  return mode == OperationMode.real
      ? RealBluetoothService()
      : MockBluetoothService();
});

// ---------------------------------------------------------------------------
// ConnectionManager — ChangeNotifier, se invalida al cambiar de modo
// ---------------------------------------------------------------------------
final connectionManagerProvider = ChangeNotifierProvider<ConnectionManager>((
  ref,
) {
  final service = ref.watch(bluetoothServiceProvider);
  final manager = ConnectionManager(service);

  // Al cambiar de modo el provider anterior se descarta: desconectamos primero.
  ref.onDispose(() async {
    await manager.disconnect();
    manager.dispose();
  });

  return manager;
});

// ---------------------------------------------------------------------------
// Stream de datos de sensores en tiempo real
// ---------------------------------------------------------------------------
final sensorDataProvider = StreamProvider<Map<String, SensorData>>((ref) {
  final manager = ref.watch(connectionManagerProvider);
  return manager.sensorStream;
});

// ---------------------------------------------------------------------------
// Router — GoRouter singleton
// ---------------------------------------------------------------------------
final routerProvider = Provider<GoRouter>((ref) => buildRouter(ref));
