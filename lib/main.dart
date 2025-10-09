import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:pegobd/service/BluetoothService.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'MockBluethootService.dart';
import 'Screen/BluetoothDevicesView.dart';
import 'connection/ConnectionManager.dart';
import 'Screen/MainDashboard.dart';

// Enum para modos de operación
enum OperationMode {
  real,
  simulator,
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BluetoothService? _bluetoothService;
  ConnectionManager? _connectionManager;

  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  List<BluetoothDevice> devicesList = [];
  OperationMode _currentMode = OperationMode.simulator; // Por defecto simulador
  bool _showModeSelector = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadSavedMode();
  }

  // Cargar modo guardado
  Future<void> _loadSavedMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('operation_mode') ?? 'simulator';

    setState(() {
      _currentMode = savedMode == 'real' ? OperationMode.real : OperationMode.simulator;
    });

    _initializeServices();
  }

  // Guardar modo seleccionado
  Future<void> _saveMode(OperationMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('operation_mode', mode.toString().split('.').last);
  }

  // Inicializar servicios según el modo
  void _initializeServices() {
    // Crear servicio según el modo seleccionado
    if (_currentMode == OperationMode.real) {
      _bluetoothService = RealBluetoothService();
    } else {
      _bluetoothService = MockBluetoothService();
    }

    // Crear ConnectionManager
    _connectionManager = ConnectionManager(
      _bluetoothService!,
      onConnectionChanged: () => setState(() {}),
    );

    setState(() {
      _isInitialized = true;
    });

    _initBluetooth();
  }

  // Cambiar modo de operación
  void _switchMode(OperationMode newMode) {
    setState(() {
      _currentMode = newMode;
      _showModeSelector = false;
    });

    _saveMode(newMode);

    // Reinicializar servicios
    _connectionManager?.disconnect();
    _initializeServices();
  }

  void _initBluetooth() async {
    if (_bluetoothService == null) return;

    // Solicitar permisos solo en modo real
    if (_currentMode == OperationMode.real) {
      bool permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        print("Permisos de Bluetooth no concedidos");
        return;
      }
    }

    _bluetoothService!.getState().then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    _bluetoothService!.onStateChanged().listen((BluetoothState state) {
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
    if (_bluetoothService == null) return;

    final devices = await _bluetoothService!.getPairedDevices();
    setState(() {
      devicesList = devices;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar pantalla de carga mientras se inicializa
    if (!_isInitialized || _connectionManager == null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Inicializando aplicación...'),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'PegOBD',
      theme: ThemeData(
        primarySwatch: _currentMode == OperationMode.real ? Colors.green : Colors.blue,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('PegOBD - ${_currentMode == OperationMode.real ? 'Modo Real' : 'Modo Simulador'}'),
          backgroundColor: _currentMode == OperationMode.real ? Colors.green : Colors.blue,
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                setState(() {
                  _showModeSelector = !_showModeSelector;
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Selector de modo
            if (_showModeSelector)
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.grey[200],
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _currentMode == OperationMode.real
                            ? null
                            : () => _switchMode(OperationMode.real),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentMode == OperationMode.real
                              ? Colors.green
                              : Colors.grey,
                        ),
                        child: Text('Modo Real'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _currentMode == OperationMode.simulator
                            ? null
                            : () => _switchMode(OperationMode.simulator),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentMode == OperationMode.simulator
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        child: Text('Modo Simulador'),
                      ),
                    ),
                  ],
                ),
              ),

            // Contenido principal
            Expanded(
              child: _connectionManager!.isConnected
                  ? MainDashboard(connectionManager: _connectionManager!)
                  : BluetoothDevicesView(
                bluetoothState: _bluetoothState,
                devices: devicesList,
                connectionManager: _connectionManager!,
                onRefreshDevices: _getPairedDevices,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
