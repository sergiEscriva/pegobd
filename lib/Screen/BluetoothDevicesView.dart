// Componente de UI separado (SRP)
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../connection/ConnectionManager.dart';

class BluetoothDevicesView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text('Estado Bluetooth: $bluetoothState'),
        ElevatedButton(
          onPressed: onRefreshDevices,
          child: Text('Actualizar dispositivos'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              BluetoothDevice device = devices[index];
              final isConnectedToThisDevice =
                  connectionManager.isConnected &&
                  connectionManager.connectedDevice == device;

              return ListTile(
                title: Text(device.name ?? "Desconocido"),
                subtitle: Text(device.address),
                trailing: isConnectedToThisDevice
                  ? ElevatedButton(
                      onPressed: connectionManager.disconnect,
                      child: Text('Desconectar'),
                    )
                  : ElevatedButton(
                      onPressed: () => connectionManager.connect(device),
                      child: Text('Conectar'),
                    ),
              );
            },
          ),
        ),
      ],
    );
  }
}