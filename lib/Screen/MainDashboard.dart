import 'package:flutter/material.dart';
import 'package:pegobd/connection/ConnectionManager.dart';
import 'package:pegobd/Screen/UnifiedDashboard.dart';
import 'package:pegobd/Screen/SensorSelectionView.dart';
import 'package:pegobd/utils/SharedPreferencesHelper.dart';

class MainDashboard extends StatefulWidget {
  final ConnectionManager connectionManager;
  const MainDashboard({super.key, required this.connectionManager});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  List<String> _selectedSensorPids = [];

  @override
  void initState() {
    super.initState();
    _loadSelectedSensors();
  }

  Future<void> _loadSelectedSensors() async {
    final sensors = await SharedPreferencesHelper.getSelectedSensors();
    setState(() {
      _selectedSensorPids = sensors;
    });
  }

  Future<void> _openSensorSelection() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => SensorSelectionView(
          connectionManager: widget.connectionManager,
          onSensorsSelected: (selectedPids) {
            setState(() {
              _selectedSensorPids = selectedPids;
            });
          },
        ),
      ),
    );

    // Si se retornó una lista, actualizar
    if (result != null) {
      setState(() {
        _selectedSensorPids = result;
      });
    }
  }

  void _disconnectAndGoBack() {
    // Mostrar diálogo de confirmación
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 8),
              Text('Desconectar'),
            ],
          ),
          content: Text('¿Estás seguro de que deseas desconectar el dispositivo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                widget.connectionManager.disconnect();
                Navigator.pop(context); // Cerrar diálogo
                Navigator.pop(context); // Volver a búsqueda de dispositivos
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Desconectar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard OBD'),
        leading: IconButton(
          icon: Icon(Icons.bluetooth_disabled),
          tooltip: 'Desconectar',
          onPressed: _disconnectAndGoBack,
        ),
        actions: [
          // Mostrar contador de sensores seleccionados
          if (_selectedSensorPids.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Chip(
                  avatar: Icon(Icons.sensors, size: 16, color: Colors.white),
                  label: Text(
                    '${_selectedSensorPids.length}',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.green[700],
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.tune),
            tooltip: 'Configurar Sensores',
            onPressed: _openSensorSelection,
          ),
        ],
      ),
      body: UnifiedDashboard(
        connectionManager: widget.connectionManager,
        selectedSensorPids: _selectedSensorPids,
      ),
    );
  }
}
