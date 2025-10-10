import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:pegobd/service/BluetoothService.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'MockBluethootService.dart';
import 'Screen/BluetoothDevicesView.dart';
import 'connection/ConnectionManager.dart';
import 'Screen/MainDashboard.dart';
import 'theme/app_theme.dart';

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
  OperationMode _currentMode = OperationMode.simulator;
  bool _showModeSelector = false;
  bool _isInitialized = false;
  bool _isConnectedToRealDevice = false; // Nueva bandera para controlar conexión real

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

    // Crear ConnectionManager con callback para detectar tipo de conexión
    _connectionManager = ConnectionManager(
      _bluetoothService!,
      onConnectionChanged: () {
        setState(() {
          // Detectar si está conectado a un dispositivo real
          if (_connectionManager!.isConnected) {
            _isConnectedToRealDevice = !_connectionManager!.isSimulatorMode;
          } else {
            _isConnectedToRealDevice = false;
          }
        });
      },
    );

    setState(() {
      _isInitialized = true;
    });

    _initBluetooth();
  }

  Future<void> _getPairedDevices() async {
    if (_bluetoothService == null) return;

    // Obtener dispositivos emparejados
    final pairedDevices = await _bluetoothService!.getPairedDevices();

    setState(() {
      devicesList = pairedDevices;
    });

    // Iniciar búsqueda de dispositivos no emparejados
    await _startDeviceDiscovery();
  }

  // NUEVO MÉTODO PARA DESCUBRIMIENTO DE DISPOSITIVOS
  Future<void> _startDeviceDiscovery() async {
    if (_bluetoothService == null || _currentMode != OperationMode.real) return;

    try {
      await _bluetoothService!.startDiscovery();

      // Escuchar dispositivos descubiertos
      _bluetoothService!.onDiscovery().listen((result) {
        if (_isOBDDevice(result.device)) {
          // Agregar solo si no está ya en la lista
          if (!devicesList.any((device) => device.address == result.device.address)) {
            setState(() {
              devicesList.add(result.device);
            });
          }
        }
      });

      // Detener búsqueda después de 15 segundos
      Timer(Duration(seconds: 15), () async {
        await _bluetoothService!.stopDiscovery();
      });
    } catch (e) {
      print("Error en descubrimiento de dispositivos: $e");
    }
  }

  // NUEVO MÉTODO PARA DETECTAR DISPOSITIVOS OBD
  bool _isOBDDevice(BluetoothDevice device) {
    final name = device.name?.toUpperCase() ?? '';
    final address = device.address.toUpperCase();

    // Nombres comunes de adaptadores ELM327
    final obdNames = [
      'OBDII', 'OBD2', 'OBD-II', 'ELM327', 'ELM',
      'VLINK', 'V-LINK', 'ICAR', 'VIECAR', 'VGATE',
      'MINI', 'SCANNER', 'DIAGNOSTIC', 'AUTO'
    ];

    // También verificar patrones de direcciones MAC comunes
    final commonPrefixes = ['00:1D:A5', '86:F3', '66:66'];

    bool nameMatch = obdNames.any((obdName) => name.contains(obdName));
    bool addressMatch = commonPrefixes.any((prefix) => address.startsWith(prefix));

    return nameMatch || addressMatch || name.isEmpty; // Algunos dispositivos aparecen sin nombre
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


  @override
  Widget build(BuildContext context) {
    // Mostrar pantalla de carga mientras se inicializa
    if (!_isInitialized || _connectionManager == null) {
      return MaterialApp(
        theme: AppTheme.getSimulatorModeTheme(),
        home: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.primaryBlue, AppTheme.lightBlue],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 4,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Inicializando PegOBD...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'PegOBD',
      theme: _currentMode == OperationMode.real
          ? AppTheme.getRealModeTheme()
          : AppTheme.getSimulatorModeTheme(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _currentMode == OperationMode.real
                    ? Icons.directions_car
                    : Icons.build_circle,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(_currentMode == OperationMode.real ? 'Modo Real' : 'Modo Simulador'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              tooltip: 'Configuración',
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
            // Selector de modo mejorado
            if (_showModeSelector)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey[100]!, Colors.grey[200]!],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Seleccionar Modo de Operación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModeButton(
                            mode: OperationMode.real,
                            icon: Icons.directions_car,
                            label: 'Modo Real',
                            color: AppTheme.primaryGreen,
                            isEnabled: _isConnectedToRealDevice,
                            subtitle: _isConnectedToRealDevice
                                ? 'Dispositivo conectado'
                                : 'Requiere dispositivo OBD',
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildModeButton(
                            mode: OperationMode.simulator,
                            icon: Icons.build_circle,
                            label: 'Simulador',
                            color: AppTheme.primaryBlue,
                            isEnabled: true,
                            subtitle: 'Datos de prueba',
                          ),
                        ),
                      ],
                    ),
                    if (!_isConnectedToRealDevice && _currentMode == OperationMode.real)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange[800], size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Conecta un dispositivo OBD real para activar el Modo Real',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange[900],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildModeButton({
    required OperationMode mode,
    required IconData icon,
    required String label,
    required Color color,
    required bool isEnabled,
    required String subtitle,
  }) {
    final isSelected = _currentMode == mode;
    final canSelect = isEnabled && !isSelected;

    return Material(
      elevation: isSelected ? 8 : 2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: canSelect ? () => _switchMode(mode) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.7)],
                  )
                : LinearGradient(
                    colors: [Colors.white, Colors.grey[50]!],
                  ),
            border: Border.all(
              color: isSelected ? color : (isEnabled ? Colors.grey[300]! : Colors.grey[200]!),
              width: isSelected ? 3 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 40,
                color: isSelected
                    ? Colors.white
                    : (isEnabled ? color : Colors.grey[400]),
              ),
              SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (isEnabled ? AppTheme.textPrimary : Colors.grey[500]),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.9)
                      : (isEnabled ? AppTheme.textSecondary : Colors.grey[400]),
                ),
                textAlign: TextAlign.center,
              ),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ACTIVO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
