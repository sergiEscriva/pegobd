import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:pegobd/service/BluetoothService.dart';
import 'package:permission_handler/permission_handler.dart';

import 'MockBluethootService.dart';
import 'Screen/BluetoothDevicesView.dart';
import 'connection/ConnectionManager.dart';
import 'Screen/SensorDashboard.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late BluetoothService _bluetoothService;
  late ConnectionManager _connectionManager;

  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  List<BluetoothDevice> devicesList = [];

  @override
  void initState() {
    super.initState();

    // Creando dependencias (principio de inversión de dependencias)
    _bluetoothService = MockBluetoothService();
    _connectionManager = ConnectionManager(
      _bluetoothService,
      onConnectionChanged: () => setState(() {}),
    );

    _initBluetooth();
  }

  void _initBluetooth() async {
    // Solicitar permisos primero
    bool permissionsGranted = await _requestPermissions();
    if (!permissionsGranted) {
      // Manejar el caso donde los permisos no fueron concedidos
      print("Permisos de Bluetooth no concedidos");
      return;
    }

    _bluetoothService.getState().then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    _bluetoothService.onStateChanged().listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    await _getPairedDevices();
  }

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> _getPairedDevices() async {
    final devices = await _bluetoothService.getPairedDevices();
    setState(() {
      devicesList = devices;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: _connectionManager.isConnected
            ? SensorDashboard(connectionManager: _connectionManager)
            : BluetoothDevicesView(
                bluetoothState: _bluetoothState,
                devices: devicesList,
                connectionManager: _connectionManager,
                onRefreshDevices: _getPairedDevices,
              ),
      ),
    );
  }
}

