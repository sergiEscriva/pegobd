import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../connection/ConnectionManager.dart';

class BluetoothDevicesView extends StatefulWidget {
  final BluetoothState bluetoothState;
  final List<BluetoothDevice> devices;
  final ConnectionManager connectionManager;
  final VoidCallback onRefreshDevices;

  const BluetoothDevicesView({
    required this.bluetoothState,
    required this.devices,
    required this.connectionManager,
    required this.onRefreshDevices,
  });

  @override
  _BluetoothDevicesViewState createState() => _BluetoothDevicesViewState();
}

class _BluetoothDevicesViewState extends State<BluetoothDevicesView> {
  bool isScanning = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // Estado del Bluetooth
        Container(
          padding: EdgeInsets.all(16),
          color: _getBluetoothStateColor(),
          width: double.infinity,
          child: Text(
            'Estado Bluetooth: ${_getBluetoothStateText()}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Botones de control
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isScanning ? null : () {
                    setState(() {
                      isScanning = true;
                    });
                    widget.onRefreshDevices();
                    // Simular fin de escaneo después de 15 segundos
                    Timer(Duration(seconds: 15), () {
                      if (mounted) {
                        setState(() {
                          isScanning = false;
                        });
                      }
                    });
                  },
                  icon: isScanning
                      ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Icon(Icons.refresh),
                  label: Text(isScanning ? 'Escaneando...' : 'Buscar Dispositivos'),
                ),
              ),
            ],
          ),
        ),
        // Lista de dispositivos
        Expanded(
          child: widget.devices.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            itemCount: widget.devices.length,
            itemBuilder: (context, index) {
              BluetoothDevice device = widget.devices[index];
              final isConnectedToThisDevice =
                  widget.connectionManager.isConnected &&
                      widget.connectionManager.connectedDevice == device;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    _getDeviceIcon(device),
                    color: isConnectedToThisDevice ? Colors.green : Colors.grey,
                    size: 32,
                  ),
                  title: Text(
                    device.name?.isNotEmpty == true ? device.name! : 'Dispositivo Desconocido',
                    style: TextStyle(
                      fontWeight: isConnectedToThisDevice ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dirección: ${device.address}'),
                      Text(
                        'Estado: ${device.isBonded ? "Emparejado" : "No emparejado"}',
                        style: TextStyle(
                          color: device.isBonded ? Colors.green : Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: isConnectedToThisDevice
                      ? ElevatedButton.icon(
                    onPressed: widget.connectionManager.disconnect,
                    icon: Icon(Icons.close, size: 16),
                    label: Text('Desconectar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  )
                      : ElevatedButton.icon(
                    onPressed: () => widget.connectionManager.connect(device),
                    icon: Icon(Icons.bluetooth_connected, size: 16),
                    label: Text('Conectar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No se encontraron dispositivos OBD2',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Asegúrate de que:\n• El Bluetooth está activado\n• El adaptador ELM327 está encendido\n• El adaptador está en rango',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: widget.onRefreshDevices,
            icon: Icon(Icons.refresh),
            label: Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Color _getBluetoothStateColor() {
    switch (widget.bluetoothState) {
      case BluetoothState.STATE_ON:
        return Colors.green;
      case BluetoothState.STATE_OFF:
        return Colors.red;
      case BluetoothState.STATE_TURNING_ON:
      case BluetoothState.STATE_TURNING_OFF:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getBluetoothStateText() {
    switch (widget.bluetoothState) {
      case BluetoothState.STATE_ON:
        return 'Activado';
      case BluetoothState.STATE_OFF:
        return 'Desactivado';
      case BluetoothState.STATE_TURNING_ON:
        return 'Activando...';
      case BluetoothState.STATE_TURNING_OFF:
        return 'Desactivando...';
      default:
        return 'Desconocido';
    }
  }

  IconData _getDeviceIcon(BluetoothDevice device) {
    final name = device.name?.toUpperCase() ?? '';
    if (name.contains('ELM') || name.contains('OBD')) {
      return Icons.car_repair;
    }
    return Icons.bluetooth;
  }
}