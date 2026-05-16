import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/sensor_data.dart';
import '../../../recordings/data/repositories/recording_repository.dart';
import '../../../recordings/presentation/providers/recording_provider.dart';

class UnifiedDashboardPage extends ConsumerStatefulWidget {
  const UnifiedDashboardPage({super.key});

  @override
  ConsumerState<UnifiedDashboardPage> createState() =>
      _UnifiedDashboardPageState();
}

class _UnifiedDashboardPageState extends ConsumerState<UnifiedDashboardPage> {
  DateTime? _recordingStartTime;

  @override
  Widget build(BuildContext context) {
    final sensorsAsync = ref.watch(sensorDataProvider);
    final selectedPids = ref.watch(selectedSensorsProvider);
    final recordingState = ref.watch(recordingStateProvider);
    final manager = ref.watch(connectionManagerProvider);

    final sensors = sensorsAsync.valueOrNull ?? {};
    final filtered = selectedPids.isEmpty
        ? sensors
        : Map.fromEntries(
            sensors.entries.where((e) => selectedPids.contains(e.key)));

    return Column(
      children: [
        _buildBanner(recordingState.isRecording, manager.isSimulatorMode,
            recordingState.startTime),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : _buildGrid(filtered),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Banner: grabando / info de modo
  // -------------------------------------------------------------------------
  Widget _buildBanner(
      bool isRecording, bool isSimulator, DateTime? startTime) {
    if (isRecording) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.red[700]!, Colors.red[500]!]),
          boxShadow: [
            BoxShadow(
                color: Colors.red.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.3, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (_, double v, __) => Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: v),
                    shape: BoxShape.circle),
              ),
              onEnd: () => setState(() {}),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GRABANDO',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text(_duration(startTime),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12)),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _stopRecording,
              icon: const Icon(Icons.stop, size: 20),
              label: const Text('Detener'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red[700]),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSimulator
              ? [AppTheme.primaryBlue, AppTheme.lightBlue]
              : [AppTheme.primaryGreen, AppTheme.lightGreen],
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(isSimulator ? Icons.build_circle : Icons.directions_car,
                color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(isSimulator ? 'SIMULADOR' : 'MODO REAL',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ]),
          Row(children: [
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
              tooltip: 'Grabaciones',
              onPressed: () => context.push('/recordings'),
            ),
            ElevatedButton.icon(
              onPressed: _startRecording,
              icon: const Icon(Icons.fiber_manual_record, size: 18),
              label: const Text('Grabar'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor:
                      isSimulator ? AppTheme.primaryBlue : AppTheme.primaryGreen),
            ),
          ]),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Grid de sensores
  // -------------------------------------------------------------------------
  Widget _buildGrid(Map<String, SensorData> sensors) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1),
      itemCount: sensors.length,
      itemBuilder: (context, i) {
        final sensor = sensors.values.elementAt(i);
        return _SensorCard(sensor: sensor);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sensors_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text('No hay sensores seleccionados',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700])),
          const SizedBox(height: 12),
          Text('Pulsa ⚙️ para seleccionar sensores',
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Grabación
  // -------------------------------------------------------------------------
  Future<void> _startRecording() async {
    final pids = ref.read(selectedSensorsProvider);
    if (pids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecciona al menos un sensor antes de grabar'),
          backgroundColor: Colors.orange));
      return;
    }

    final name = await _askRecordingName();
    if (name == null || name.isEmpty) return;

    final manager = ref.read(connectionManagerProvider);
    ref.read(recordingRepositoryProvider).startRecording(
          name: name,
          sensorPids: pids,
          sensorStream: manager.sensorStream,
        );
    ref.read(recordingStateProvider.notifier).markStarted(name);
  }

  Future<void> _stopRecording() async {
    final recording =
        await ref.read(recordingRepositoryProvider).stopRecording();
    ref.read(recordingStateProvider.notifier).markStopped();
    ref.invalidate(recordingsListProvider);

    if (recording != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Grabación guardada: ${recording.name}'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () => context.push('/recordings'),
        ),
      ));
    }
  }

  Future<String?> _askRecordingName() async {
    final ctrl = TextEditingController(
        text: 'Grabación ${DateTime.now().toString().substring(0, 16)}');
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nombre de la grabación'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
              labelText: 'Nombre', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: const Text('Iniciar')),
        ],
      ),
    );
  }

  String _duration(DateTime? start) {
    if (start == null) return '';
    final d = DateTime.now().difference(start);
    return '${d.inMinutes.toString().padLeft(2, '0')}:'
        '${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de sensor
// ---------------------------------------------------------------------------
class _SensorCard extends StatelessWidget {
  final SensorData sensor;
  const _SensorCard({required this.sensor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/sensor/${sensor.pid}'),
      child: Card(
        elevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey[50]!]),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconFor(sensor.pid),
                  color: _colorFor(sensor.unit), size: 28),
              const SizedBox(height: 4),
              Text(sensor.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
              const SizedBox(height: 4),
              Text(sensor.value,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _colorFor(sensor.unit)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(sensor.unit,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String pid) => switch (pid) {
        '04' => Icons.flash_on,
        '05' => Icons.device_thermostat,
        '0C' => Icons.speed,
        '0D' => Icons.directions_car,
        '0F' => Icons.ac_unit,
        '10' => Icons.air,
        '11' => Icons.tune,
        '2F' => Icons.local_gas_station,
        '5C' => Icons.oil_barrel,
        '42' => Icons.battery_charging_full,
        _ => Icons.sensors,
      };

  Color _colorFor(String unit) => switch (unit) {
        'rpm' => Colors.red,
        'km/h' => Colors.blue,
        '°C' => Colors.orange,
        '%' => Colors.green,
        'V' => Colors.purple,
        _ => Colors.blueGrey,
      };
}
