import 'dart:async';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../core/theme/app_theme.dart';
import '../features/dashboard/domain/entities/sensor_data.dart';
import '../services/RecordingService.dart';
import '../shared/services/connection_manager.dart';
import 'RecordingsListView.dart';
import 'SensorDetailView.dart';

class UnifiedDashboard extends StatefulWidget {
  final ConnectionManager connectionManager;
  final List<String> selectedSensorPids;

  const UnifiedDashboard({
    required this.connectionManager,
    this.selectedSensorPids = const [],
  });

  @override
  State<UnifiedDashboard> createState() => _UnifiedDashboardState();
}

class _UnifiedDashboardState extends State<UnifiedDashboard> {
  Map<String, SensorData> _sensors = {};
  StreamSubscription? _sensorSubscription;
  final RecordingService _recordingService = RecordingService();
  bool _isRecording = false;
  DateTime? _recordingStartTime;

  @override
  void initState() {
    super.initState();
    _sensorSubscription = widget.connectionManager.sensorStream.listen((
      sensorsData,
    ) {
      setState(() {
        _sensors = sensorsData;
      });
    });
    widget.connectionManager.requestAllSensors();
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _recordingService.dispose();
    super.dispose();
  }

  Map<String, SensorData> get _filteredSensors {
    if (widget.selectedSensorPids.isEmpty) {
      return _sensors;
    }
    return Map.fromEntries(
      _sensors.entries.where(
        (entry) => widget.selectedSensorPids.contains(entry.key),
      ),
    );
  }

  Future<void> _startRecording() async {
    if (widget.selectedSensorPids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debes seleccionar al menos un sensor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final name = await _showRecordingNameDialog();
    if (name == null || name.isEmpty) return;

    _recordingService.startRecording(
      name: name,
      sensorPids: widget.selectedSensorPids,
      sensorStream: widget.connectionManager.sensorStream,
    );

    setState(() {
      _isRecording = true;
      _recordingStartTime = DateTime.now();
    });
  }

  Future<void> _stopRecording() async {
    final recording = await _recordingService.stopRecording();

    setState(() {
      _isRecording = false;
      _recordingStartTime = null;
    });

    if (recording != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Grabación guardada: ${recording.name}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Ver',
            textColor: Colors.white,
            onPressed: () => _openRecordingsList(),
          ),
        ),
      );
    }
  }

  Future<String?> _showRecordingNameDialog() async {
    final controller = TextEditingController(
      text: 'Grabación ${DateTime.now().toString().substring(0, 16)}',
    );

    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Nombre de la grabación'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: Text('Iniciar'),
              ),
            ],
          ),
    );
  }

  void _openRecordingsList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                RecordingsListView(recordingService: _recordingService),
      ),
    );
  }

  void _openSensorDetail(SensorData sensor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SensorDetailView(
              sensor: sensor,
              sensorStream: widget.connectionManager.sensorStream,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.connectionManager.isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay conexión',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    final filteredSensors = _filteredSensors;

    return Column(
      children: [
        // Banner con info de grabación
        _buildRecordingBanner(),
        // Grid de sensores
        Expanded(
          child:
              filteredSensors.isEmpty
                  ? _buildEmptyState()
                  : _buildSensorGrid(filteredSensors),
        ),
      ],
    );
  }

  Widget _buildRecordingBanner() {
    if (_isRecording) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red[700]!, Colors.red[500]!],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Indicador parpadeante
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.3, end: 1.0),
              duration: Duration(milliseconds: 800),
              builder: (context, double value, child) {
                return Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: value),
                    shape: BoxShape.circle,
                  ),
                );
              },
              onEnd: () => setState(() {}),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GRABANDO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _getRecordingDuration(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _stopRecording,
              icon: Icon(Icons.stop, size: 20),
              label: Text('Detener'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red[700],
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              widget.connectionManager.isSimulatorMode
                  ? [AppTheme.primaryBlue, AppTheme.lightBlue]
                  : [AppTheme.primaryGreen, AppTheme.lightGreen],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                widget.connectionManager.isSimulatorMode
                    ? Icons.build_circle
                    : Icons.directions_car,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                widget.connectionManager.isSimulatorMode
                    ? 'SIMULADOR'
                    : 'MODO REAL',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: _openRecordingsList,
                icon: Icon(Icons.history, color: Colors.white),
                tooltip: 'Ver grabaciones',
              ),
              ElevatedButton.icon(
                onPressed: _startRecording,
                icon: Icon(Icons.fiber_manual_record, size: 18),
                label: Text('Grabar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor:
                      widget.connectionManager.isSimulatorMode
                          ? AppTheme.primaryBlue
                          : AppTheme.primaryGreen,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRecordingDuration() {
    if (_recordingStartTime == null) return '';

    final duration = DateTime.now().difference(_recordingStartTime!);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sensors_off, size: 80, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            'No hay sensores seleccionados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Presiona el botón ⚙️ para seleccionar sensores',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorGrid(Map<String, SensorData> sensors) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: sensors.length,
      itemBuilder: (context, index) {
        final sensor = sensors.values.elementAt(index);
        return _buildSensorCard(sensor);
      },
    );
  }

  Widget _buildSensorCard(SensorData sensor) {
    return GestureDetector(
      onTap: () => _openSensorDetail(sensor),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey[50]!],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getSensorIcon(sensor.pid),
                color: _getSensorColor(sensor.unit),
                size: 28,
              ),
              SizedBox(height: 4),
              Text(
                sensor.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                sensor.value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getSensorColor(sensor.unit),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                sensor.unit,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSensorIcon(String pid) {
    switch (pid) {
      case '04':
        return Icons.flash_on;
      case '05':
        return Icons.device_thermostat;
      case '0C':
        return Icons.speed;
      case '0D':
        return Icons.directions_car;
      case '0F':
        return Icons.ac_unit;
      case '10':
        return Icons.air;
      case '11':
        return Icons.tune;
      case '2F':
        return Icons.local_gas_station;
      case '5C':
        return Icons.oil_barrel;
      case '42':
        return Icons.battery_charging_full;
      default:
        return Icons.sensors;
    }
  }

  Color _getSensorColor(String unit) {
    if (unit == 'rpm') return Colors.red;
    if (unit == 'km/h') return Colors.blue;
    if (unit == '°C') return Colors.orange;
    if (unit == '%') return Colors.green;
    if (unit == 'V') return Colors.purple;
    return Colors.blueGrey;
  }
}
