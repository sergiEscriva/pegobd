import 'dart:async';

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
  Timer? _statusUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadSelectedSensors();
    _startStatusMonitoring();
  }

  @override
  void dispose() {
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  // Monitorear estado de conexión
  void _startStatusMonitoring() {
    _statusUpdateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // Actualizar UI con estado de conexión
      }
    });
  }

  Future<void> _loadSelectedSensors() async {
    // Intentar cargar sensores específicos del vehículo conectado
    final deviceAddress = widget.connectionManager.connectedDevice?.address;

    List<String> sensors;
    if (deviceAddress != null) {
      // Intentar cargar sensores específicos del vehículo
      final vehicleSensors = await SharedPreferencesHelper.getVehicleSensors(deviceAddress);

      if (vehicleSensors != null) {
        sensors = vehicleSensors;
        print("📂 Sensores cargados del caché del vehículo");
      } else {
        // Cargar sensores por defecto
        sensors = await SharedPreferencesHelper.getSelectedSensors();
        print("📋 Sensores por defecto cargados");
      }
    } else {
      sensors = await SharedPreferencesHelper.getSelectedSensors();
    }

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
          onSensorsSelected: (selectedPids) async {
            setState(() {
              _selectedSensorPids = selectedPids;
            });

            // Guardar en caché global
            await SharedPreferencesHelper.saveSelectedSensors(selectedPids);

            // Guardar en caché específico del vehículo
            final deviceAddress = widget.connectionManager.connectedDevice?.address;
            if (deviceAddress != null) {
              await SharedPreferencesHelper.saveVehicleSensors(deviceAddress, selectedPids);
            }
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedSensorPids = result;
      });

      // Guardar también aquí
      await SharedPreferencesHelper.saveSelectedSensors(result);
      final deviceAddress = widget.connectionManager.connectedDevice?.address;
      if (deviceAddress != null) {
        await SharedPreferencesHelper.saveVehicleSensors(deviceAddress, result);
      }
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
              onPressed: () async {
                await widget.connectionManager.disconnect();
                if (mounted) {
                  Navigator.pop(context); // Cerrar diálogo
                  // No necesitamos Navigator.pop adicional porque main.dart maneja el cambio
                }
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
    final deviceName = widget.connectionManager.connectedDevice?.name ?? 'Dispositivo';
    final connectionStatus = widget.connectionManager.connectionStatus;
    final isConnected = widget.connectionManager.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Dashboard OBD', style: TextStyle(fontSize: 18)),
            SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  connectionStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
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
