import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/storage_helper.dart';
import '../../../obd/presentation/pages/sensor_selection_page.dart';
import 'unified_dashboard_page.dart';

/// Scaffold del dashboard con AppBar propia: título + indicador de conexión,
/// botón de desconexión y botón de configuración de sensores.
class MainDashboard extends ConsumerStatefulWidget {
  const MainDashboard({super.key});

  @override
  ConsumerState<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends ConsumerState<MainDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSensors());
  }

  Future<void> _loadSensors() async {
    final manager = ref.read(connectionManagerProvider);
    final deviceAddress = manager.connectedDevice?.address;

    List<String> sensors;
    if (deviceAddress != null) {
      sensors = await SharedPreferencesHelper.getVehicleSensors(deviceAddress) ??
          await SharedPreferencesHelper.getSelectedSensors();
    } else {
      sensors = await SharedPreferencesHelper.getSelectedSensors();
    }

    if (mounted) {
      ref.read(selectedSensorsProvider.notifier).state = sensors;
    }
  }

  Future<void> _openSensorSelection() async {
    final manager = ref.read(connectionManagerProvider);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SensorSelectionView(
          connectionManager: manager,
          onSensorsSelected: (pids) async {
            ref.read(selectedSensorsProvider.notifier).state = pids;
            await SharedPreferencesHelper.saveSelectedSensors(pids);
            final addr = manager.connectedDevice?.address;
            if (addr != null) {
              await SharedPreferencesHelper.saveVehicleSensors(addr, pids);
            }
          },
        ),
      ),
    );
  }

  Future<void> _confirmDisconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber, color: Colors.orange),
          SizedBox(width: 8),
          Text('Desconectar'),
        ]),
        content: const Text('¿Deseas desconectar el dispositivo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desconectar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(connectionManagerProvider).disconnect();
      // GoRouter redirige automáticamente a HomeScreen porque
      // connectionManagerProvider notifica el cambio a sus oyentes.
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(connectionManagerProvider);
    final selectedPids = ref.watch(selectedSensorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Dashboard OBD', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: manager.isConnected
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 6),
                Text(manager.connectionStatus,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.normal)),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.bluetooth_disabled),
          tooltip: 'Desconectar',
          onPressed: _confirmDisconnect,
        ),
        actions: [
          if (selectedPids.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Chip(
                  avatar: const Icon(Icons.sensors, size: 16, color: Colors.white),
                  label: Text('${selectedPids.length}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.green[700],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Configurar sensores',
            onPressed: _openSensorSelection,
          ),
        ],
      ),
      body: const UnifiedDashboardPage(),
    );
  }
}
