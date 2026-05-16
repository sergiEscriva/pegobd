import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';

class BluetoothDevicesView extends ConsumerStatefulWidget {
  /// Datos pasados desde HomeScreen para no duplicar la carga.
  final BluetoothState bluetoothState;
  final List<BluetoothDevice> devices;
  final Future<void> Function() onRefreshDevices;

  const BluetoothDevicesView({
    super.key,
    required this.bluetoothState,
    required this.devices,
    required this.onRefreshDevices,
  });

  @override
  ConsumerState<BluetoothDevicesView> createState() =>
      _BluetoothDevicesViewState();
}

class _BluetoothDevicesViewState extends ConsumerState<BluetoothDevicesView> {
  bool _isScanning = false;

  Future<void> _scan() async {
    setState(() => _isScanning = true);
    await widget.onRefreshDevices();
    Timer(const Duration(seconds: 15), () {
      if (mounted) setState(() => _isScanning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(connectionManagerProvider);

    return Column(
      children: [
        // Banner estado Bluetooth
        Container(
          padding: const EdgeInsets.all(16),
          color: _stateColor(widget.bluetoothState),
          width: double.infinity,
          child: Text(
            'Bluetooth: ${_stateText(widget.bluetoothState)}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),

        // Botón de búsqueda
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _scan,
              icon: _isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Icon(Icons.refresh),
              label: Text(_isScanning ? 'Escaneando…' : 'Buscar dispositivos',
                  style: const TextStyle(
                      inherit: false,
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white),
            ),
          ),
        ),

        // Lista de dispositivos
        Expanded(
          child: widget.devices.isEmpty
              ? _EmptyState(onRetry: _scan)
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: widget.devices.length,
                  itemBuilder: (context, i) {
                    final device = widget.devices[i];
                    final connected = manager.isConnected &&
                        manager.connectedDevice?.address == device.address;
                    return _DeviceCard(
                      device: device,
                      isConnected: connected,
                      onConnect: () => manager.connect(device),
                      onDisconnect: manager.disconnect,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Color _stateColor(BluetoothState s) => switch (s) {
        BluetoothState.STATE_ON => Colors.green,
        BluetoothState.STATE_OFF => Colors.red,
        BluetoothState.STATE_TURNING_ON ||
        BluetoothState.STATE_TURNING_OFF =>
          Colors.orange,
        _ => Colors.grey,
      };

  String _stateText(BluetoothState s) => switch (s) {
        BluetoothState.STATE_ON => 'Activado',
        BluetoothState.STATE_OFF => 'Desactivado',
        BluetoothState.STATE_TURNING_ON => 'Activando…',
        BluetoothState.STATE_TURNING_OFF => 'Desactivando…',
        _ => 'Desconocido',
      };
}

// ---------------------------------------------------------------------------
// Tarjeta de dispositivo
// ---------------------------------------------------------------------------
class _DeviceCard extends StatelessWidget {
  final BluetoothDevice device;
  final bool isConnected;
  final VoidCallback onConnect;
  final Future<void> Function() onDisconnect;

  const _DeviceCard({
    required this.device,
    required this.isConnected,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final isObd = _isPossibleObd(device);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isObd ? 4 : 2,
      child: Container(
        decoration: isObd
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green, width: 2))
            : null,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: Stack(
            children: [
              Icon(_iconFor(device),
                  color: isConnected ? Colors.green : Colors.grey, size: 32),
              if (isObd)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.check, size: 8, color: Colors.white),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                    device.name?.isNotEmpty == true
                        ? device.name!
                        : 'Dispositivo desconocido',
                    style: TextStyle(
                        fontWeight: isConnected
                            ? FontWeight.bold
                            : FontWeight.normal),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
              if (isObd)
                Chip(
                  label: const Text('OBD?',
                      style: TextStyle(fontSize: 10)),
                  backgroundColor: Colors.green[100],
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dirección: ${device.address}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(device.isBonded ? 'Emparejado' : 'No emparejado',
                  style: TextStyle(
                      color: device.isBonded ? Colors.green : Colors.orange,
                      fontSize: 12)),
            ],
          ),
          trailing: SizedBox(
            width: 110,
            child: isConnected
                ? ElevatedButton(
                    onPressed: onDisconnect,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        minimumSize: const Size(100, 36)),
                    child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, size: 14),
                          SizedBox(width: 4),
                          Text('Descon.',
                              style: TextStyle(
                                  inherit: false,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                        ]))
                : ElevatedButton(
                    onPressed: onConnect,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        minimumSize: const Size(100, 36)),
                    child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bluetooth_connected, size: 14),
                          SizedBox(width: 4),
                          Text('Conectar',
                              style: TextStyle(
                                  inherit: false,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                        ])),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(BluetoothDevice d) {
    final n = d.name?.toUpperCase() ?? '';
    if (n.contains('ELM') || n.contains('OBD') || n.contains('DIAGNOSTIC')) {
      return Icons.car_repair;
    }
    if (n.contains('HEADPHONE') || n.contains('EARBUDS')) return Icons.headphones;
    if (n.contains('PHONE') || n.contains('ANDROID')) return Icons.phone_android;
    if (n.contains('WATCH') || n.contains('BAND')) return Icons.watch;
    return Icons.bluetooth;
  }

  bool _isPossibleObd(BluetoothDevice d) {
    final n = d.name?.toUpperCase() ?? '';
    final a = d.address.toUpperCase();
    const names = [
      'OBDII', 'OBD2', 'OBD-II', 'ELM327', 'ELM', 'ELMDEV',
      'VLINK', 'ICAR', 'VIECAR', 'VGATE', 'VEEPEAK', 'SCANNER',
      'DIAGNOSTIC', 'TORQUE', 'KIWI', 'HC-05', 'HC-06',
    ];
    const prefixes = [
      '00:1D:A5', '86:F3', '66:66', '20:13', '00:04:3E', '00:0C:78',
    ];
    return names.any(n.contains) || prefixes.any(a.startsWith) || n.isEmpty;
  }
}

// ---------------------------------------------------------------------------
// Estado vacío
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No se encontraron dispositivos OBD2',
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              'Asegúrate de que:\n'
              '• El Bluetooth está activado\n'
              '• El adaptador ELM327 está encendido\n'
              '• El adaptador está en rango',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
}
