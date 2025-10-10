import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/utils/storage_helper.dart';
import '../../../../shared/services/connection_manager.dart';
import '../../domain/entities/sensor.dart';
import '../../domain/usecases/detect_sensors_usecase.dart';


class SensorSelectionView extends StatefulWidget {
  final ConnectionManager connectionManager;
  final Function(List<String>) onSensorsSelected;

  const SensorSelectionView({
    Key? key,
    required this.connectionManager,
    required this.onSensorsSelected,
  }) : super(key: key);

  @override
  _SensorSelectionViewState createState() => _SensorSelectionViewState();
}

class _SensorSelectionViewState extends State<SensorSelectionView> {
  Map<String, bool> availableSensors = {};
  Map<String, bool> selectedSensors = {};
  bool isScanning = false;
  bool hasScanned = false;
  Timer? scanTimer;

  @override
  void initState() {
    super.initState();
    _loadSavedSensors();
  }

  Future<void> _loadSavedSensors() async {
    // Cargar sensores previamente guardados
    List<String> savedSensors =
        await SharedPreferencesHelper.getSelectedSensors();

    setState(() {
      // Inicializar con todos los PIDs conocidos
      for (String pid in OBDSensorDetector.STANDARD_PIDS.keys) {
        availableSensors[pid] = false;
        selectedSensors[pid] = savedSensors.contains(pid);
      }
    });

    if (widget.connectionManager.isConnected) {
      _scanForAvailableSensors();
    }
  }

  void _initializeDefaultSensors() {
    // Sensores básicos que suelen estar disponibles
    final defaultPids = ['04', '05', '0C', '0D', '0F', '10', '11', '2F', '5C'];

    for (String pid in defaultPids) {
      availableSensors[pid] = false; // No confirmado aún
      selectedSensors[pid] = false;
    }
  }

  Future<void> _scanForAvailableSensors() async {
    if (!widget.connectionManager.isConnected) return;

    setState(() {
      isScanning = true;
      hasScanned = false;
    });

    try {
      // Usar el detector automático de sensores
      Map<String, bool> detected =
          await OBDSensorDetector.detectAvailableSensors(
            widget.connectionManager.isSimulatorMode ? null : null,
            isSimulatorMode: widget.connectionManager.isSimulatorMode,
          );

      setState(() {
        availableSensors = detected;
        // Inicializar selectedSensors con los disponibles
        for (String pid in availableSensors.keys) {
          selectedSensors[pid] = false;
        }
      });
    } catch (e) {
      print('Error escaneando sensores: $e');
    } finally {
      if (mounted) {
        setState(() {
          isScanning = false;
          hasScanned = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleccionar Sensores'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: isScanning ? null : _scanForAvailableSensors,
          ),
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _hasSelectedSensors() ? _saveSensorSelection : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Estado de la conexión y escaneo
          Container(
            padding: EdgeInsets.all(16),
            color:
                widget.connectionManager.isConnected
                    ? Colors.green[100]
                    : Colors.red[100],
            width: double.infinity,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.connectionManager.isConnected
                          ? Icons.check_circle
                          : Icons.error,
                      color:
                          widget.connectionManager.isConnected
                              ? Colors.green
                              : Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text(
                      widget.connectionManager.isConnected
                          ? 'Conectado'
                          : 'No conectado',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            widget.connectionManager.isConnected
                                ? Colors.green[800]
                                : Colors.red[800],
                      ),
                    ),
                  ],
                ),
                if (isScanning) ...[
                  SizedBox(height: 8),
                  LinearProgressIndicator(),
                  SizedBox(height: 4),
                  Text('Escaneando sensores disponibles...'),
                ],
              ],
            ),
          ),

          // Botones de acción
          if (!isScanning)
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          widget.connectionManager.isConnected
                              ? _scanForAvailableSensors
                              : null,
                      icon: Icon(Icons.search),
                      label: Text('Escanear Sensores'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectAllAvailable,
                      icon: Icon(Icons.select_all),
                      label: Text('Seleccionar Disponibles'),
                    ),
                  ),
                ],
              ),
            ),

          // Lista de sensores
          Expanded(
            child:
                availableSensors.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      itemCount: availableSensors.length,
                      itemBuilder: (context, index) {
                        String pid = availableSensors.keys.elementAt(index);
                        bool isAvailable = availableSensors[pid] ?? false;
                        bool isSelected = selectedSensors[pid] ?? false;

                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          elevation: isAvailable ? 3 : 1,
                          child: ListTile(
                            leading: Stack(
                              children: [
                                Icon(
                                  _getSensorIcon(pid),
                                  color:
                                      isAvailable ? Colors.green : Colors.grey,
                                  size: 32,
                                ),
                                if (isAvailable)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        size: 8,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              ObdSensors.getSensorName(pid),
                              style: TextStyle(
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color: isAvailable ? Colors.black : Colors.grey,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PID: $pid'),
                                Text(
                                  'Unidad: ${ObdSensors.getSensorUnit(pid)}',
                                ),
                                if (!isAvailable && hasScanned)
                                  Text(
                                    'No disponible en este vehículo',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged:
                                  isAvailable
                                      ? (bool? value) {
                                        setState(() {
                                          selectedSensors[pid] = value ?? false;
                                        });
                                      }
                                      : null,
                            ),
                            onTap:
                                isAvailable
                                    ? () {
                                      setState(() {
                                        selectedSensors[pid] =
                                            !(selectedSensors[pid] ?? false);
                                      });
                                    }
                                    : null,
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton:
          _hasSelectedSensors()
              ? FloatingActionButton.extended(
                onPressed: _saveSensorSelection,
                icon: Icon(Icons.save),
                label: Text('Guardar (${_getSelectedCount()})'),
              )
              : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sensors_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No hay sensores configurados',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Conecta un dispositivo OBD2 y escanea para encontrar sensores disponibles',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  IconData _getSensorIcon(String pid) {
    switch (pid) {
      case '04':
        return Icons.flash_on; // Load
      case '05':
        return Icons.device_thermostat; // Coolant temp
      case '0C':
        return Icons.speed; // RPM
      case '0D':
        return Icons.directions_car; // Speed
      case '0F':
        return Icons.ac_unit; // Intake temp
      case '10':
        return Icons.air; // MAF
      case '11':
        return Icons.tune; // Throttle
      case '2F':
        return Icons.local_gas_station; // Fuel level
      case '5C':
        return Icons.oil_barrel; // Oil temp
      default:
        return Icons.sensors;
    }
  }

  bool _hasSelectedSensors() {
    return selectedSensors.values.any((selected) => selected);
  }

  int _getSelectedCount() {
    return selectedSensors.values.where((selected) => selected).length;
  }

  void _selectAllAvailable() {
    setState(() {
      availableSensors.forEach((pid, isAvailable) {
        if (isAvailable) {
          selectedSensors[pid] = true;
        }
      });
    });
  }

  Future<void> _saveSensorSelection() async {
    List<String> selected =
        selectedSensors.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    // Guardar en SharedPreferences
    await SharedPreferencesHelper.saveSelectedSensors(selected);

    widget.onSensorsSelected(selected);
    Navigator.pop(context, selected); // Retornar la lista
  }

  @override
  void dispose() {
    scanTimer?.cancel();
    super.dispose();
  }
}
