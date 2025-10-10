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
    required this.onRefreshDevices, required ValueKey<String> key,
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
                  label: Text(
                    isScanning ? 'Escaneando...' : 'Buscar Dispositivos',
                    style: TextStyle(inherit: false, color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
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
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: widget.devices.length,
            itemBuilder: (context, index) {
              BluetoothDevice device = widget.devices[index];
              final isConnectedToThisDevice =
                  widget.connectionManager.isConnected &&
                      widget.connectionManager.connectedDevice == device;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: _isPossibleOBDDevice(device) ? 4 : 2,
                child: Container(
                  decoration: _isPossibleOBDDevice(device) ? BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green, width: 2),
                  ) : null,
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: Stack(
                      children: [
                        Icon(
                          _getDeviceIcon(device),
                          color: isConnectedToThisDevice ? Colors.green : Colors.grey,
                          size: 32,
                        ),
                        if (_isPossibleOBDDevice(device))
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
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            device.name?.isNotEmpty == true ? device.name! : 'Dispositivo Desconocido',
                            style: TextStyle(
                              fontWeight: isConnectedToThisDevice ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isPossibleOBDDevice(device))
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Chip(
                              label: Text('OBD?', style: TextStyle(fontSize: 10)),
                              backgroundColor: Colors.green[100],
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.symmetric(horizontal: 4),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dirección: ${device.address}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Estado: ${device.isBonded ? "Emparejado" : "No emparejado"}',
                          style: TextStyle(
                            color: device.isBonded ? Colors.green : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: SizedBox(
                      width: 110,
                      child: isConnectedToThisDevice
                          ? ElevatedButton(
                        onPressed: widget.connectionManager.disconnect,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close, size: 14),
                            SizedBox(width: 4),
                            Text('Descon.', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          minimumSize: Size(100, 36),
                          textStyle: TextStyle(inherit: false, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      )
                          : ElevatedButton(
                        onPressed: () => widget.connectionManager.connect(device),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bluetooth_connected, size: 14),
                            SizedBox(width: 4),
                            Text('Conectar', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          minimumSize: Size(100, 36),
                          textStyle: TextStyle(inherit: false, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
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

    // Identificar tipo de dispositivo
    if (name.contains('ELM') || name.contains('OBD') || name.contains('DIAGNOSTIC')) {
      return Icons.car_repair; // Icono de coche para OBD
    } else if (name.contains('HEADPHONE') || name.contains('EARBUDS') || name.contains('AUDIO')) {
      return Icons.headphones;
    } else if (name.contains('PHONE') || name.contains('ANDROID') || name.contains('IPHONE')) {
      return Icons.phone_android;
    } else if (name.contains('WATCH') || name.contains('BAND')) {
      return Icons.watch;
    } else if (name.contains('KEYBOARD')) {
      return Icons.keyboard;
    } else if (name.contains('MOUSE')) {
      return Icons.mouse;
    }

    return Icons.bluetooth; // Icono genérico para otros dispositivos
  }

  // NUEVO MÉTODO PARA IDENTIFICAR SI ES POSIBLE DISPOSITIVO OBD
  bool _isPossibleOBDDevice(BluetoothDevice device) {
    final name = device.name?.toUpperCase() ?? '';
    final address = device.address.toUpperCase();

    final obdNames = [
      'OBDII', 'OBD2', 'OBD-II', 'ELM327', 'ELM', 'ELMDEV',
      'VLINK', 'V-LINK', 'ICAR', 'VIECAR', 'VGATE', 'VEEPEAK',
      'MINI', 'SCANNER', 'DIAGNOSTIC', 'AUTO', 'CAR', 'VEHICLE',
      'TORQUE', 'KIWI', 'BAFX', 'BLUETOOTH-V', 'HC-05', 'HC-06'
    ];

    final commonPrefixes = [
      '00:1D:A5', '86:F3', '66:66', '20:13', '20:14', '20:15', '20:16',
      '00:04:3E', '00:0C:78', '00:15:83', '00:21:13', 'AA:BB:CC'
    ];

    bool nameMatch = obdNames.any((obdName) => name.contains(obdName));
    bool addressMatch = commonPrefixes.any((prefix) => address.startsWith(prefix));

    return nameMatch || addressMatch || name.isEmpty; // Sin nombre también podría ser OBD
  }
}