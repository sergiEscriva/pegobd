// lib/Screen/SensorsScreen.dart
import 'package:flutter/material.dart';
import '../connection/ConnectionManager.dart';
import '../model/SensorData.dart';

class SensorsScreen extends StatefulWidget {
  final ConnectionManager connectionManager;

  const SensorsScreen({required this.connectionManager});

  @override
  _SensorsScreenState createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  Map<String, SensorData> _sensors = {};

  @override
  void initState() {
    super.initState();
    widget.connectionManager.sensorStream.listen((sensorsData) {
      setState(() {
        _sensors = sensorsData;
      });
    });

    // Solicita todos los sensores al iniciar
    widget.connectionManager.requestAllSensors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sensores OBD'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => widget.connectionManager.requestAllSensors(),
          ),
        ],
      ),
      body: _buildSensorsList(),
    );
  }

  Widget _buildSensorsList() {
    if (!widget.connectionManager.isConnected) {
      return Center(child: Text('No hay conexión con dispositivo OBD'));
    }

    if (_sensors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando sensores...')
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: _sensors.length,
      itemBuilder: (context, index) {
        final String pid = _sensors.keys.elementAt(index);
        final SensorData sensor = _sensors[pid]!;

        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(sensor.name),
            subtitle: Text('PID: ${sensor.pid}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${sensor.value} ${sensor.unit}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                  ),
                ),
                Text(
                  _formatTimestamp(sensor.timestamp),
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }
}