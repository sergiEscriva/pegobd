import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/theme/app_theme.dart';
// Utilidades core
import 'core/utils/app_logger.dart';
import 'core/utils/storage_helper.dart';
// Páginas de features
import 'features/bluetooth/presentation/pages/bluetooth_devices_page.dart';
import 'features/dashboard/presentation/pages/main_dashboard_page.dart';
import 'features/logging/presentation/pages/log_viewer_page.dart';
// Servicios compartidos
import 'shared/services/bluetooth_service.dart';
import 'shared/services/connection_manager.dart';
import 'shared/services/mock_bluetooth_service.dart';
// Widgets compartidos
import 'shared/widgets/animated_splash.dart';

// Enum para modos de operación
enum OperationMode { real, simulator }

void main() async {
  // Capturar errores de Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger().error(
      'Flutter Error',
      error: details.exception,
      stackTrace: details.stack,
      tag: 'FLUTTER',
    );
  };

  // Capturar errores no manejados
  runZonedGuarded(
    () {
      runApp(MyApp());
    },
    (error, stackTrace) {
      AppLogger().critical(
        'Error no manejado en la aplicación',
        error: error,
        stackTrace: stackTrace,
        tag: 'APP',
      );
    },
  );
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
  bool _showingSplash = true;
  bool _isConnectedToRealDevice = false;
  String _themeMode = 'auto'; // 'light', 'dark', 'auto'

  final AppLogger _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _connectionManager?.dispose();
    super.dispose();
  }

  // Inicialización completa de la app
  Future<void> _initializeApp() async {
    try {
      // Inicializar el sistema de logging
      await _logger.initialize();
      await _logger.info('Aplicación iniciada', tag: 'APP');

      await _loadSavedSettings();
      await Future.delayed(
        Duration(milliseconds: 500),
      ); // Mínimo tiempo para splash
    } catch (e, stackTrace) {
      await _logger.error(
        'Error en inicialización',
        error: e,
        stackTrace: stackTrace,
        tag: 'INIT',
      );
    }
  }

  // Cargar configuración guardada
  Future<void> _loadSavedSettings() async {
    final savedMode = await SharedPreferencesHelper.getOperationMode();
    final savedTheme = await SharedPreferencesHelper.getThemeMode();

    setState(() {
      _currentMode =
          savedMode == 'real' ? OperationMode.real : OperationMode.simulator;
      _themeMode = savedTheme;
    });

    _initializeServices();
  }

  // Guardar modo seleccionado
  Future<void> _saveMode(OperationMode mode) async {
    await SharedPreferencesHelper.saveOperationMode(
      mode.toString().split('.').last,
    );
  }

  // Inicializar servicios según el modo
  void _initializeServices() {
    try {
      _connectionManager?.dispose();

      if (_currentMode == OperationMode.real) {
        _bluetoothService = RealBluetoothService();
        _logger.info('Servicio Bluetooth Real inicializado', tag: 'SERVICE');
      } else {
        _bluetoothService = MockBluetoothService() as BluetoothService?;
        _logger.info(
          'Servicio Bluetooth Simulador inicializado',
          tag: 'SERVICE',
        );
      }

      _connectionManager = ConnectionManager(
        _bluetoothService!,
        onConnectionChanged: () {
          if (mounted) {
            setState(() {
              if (_connectionManager!.isConnected) {
                _isConnectedToRealDevice = !_connectionManager!.isSimulatorMode;
                _logger.info(
                  'Conectado a dispositivo: ${_connectionManager!.connectedDevice?.name}',
                  tag: 'CONNECTION',
                );
              } else {
                _isConnectedToRealDevice = false;
                _logger.info('Desconectado del dispositivo', tag: 'CONNECTION');
              }
            });
          }
        },
      );

      setState(() {
        _isInitialized = true;
      });

      _initBluetooth();
    } catch (e, stackTrace) {
      _logger.error(
        'Error inicializando servicios',
        error: e,
        stackTrace: stackTrace,
        tag: 'SERVICE',
      );
    }
  }

  Future<void> _getPairedDevices() async {
    if (_bluetoothService == null) return;

    try {
      final pairedDevices = await _bluetoothService!.getPairedDevices();
      if (mounted) {
        setState(() {
          devicesList = pairedDevices;
        });
      }
    } on BluetoothPermissionException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            action: SnackBarAction(
              label: 'Ajustes',
              onPressed: openAppSettings,
            ),
            duration: const Duration(seconds: 8),
          ),
        );
      }
      return;
    }

    await _startDeviceDiscovery();
  }

  Future<void> _startDeviceDiscovery() async {
    if (_bluetoothService == null || _currentMode != OperationMode.real) return;

    try {
      print("🔍 Iniciando búsqueda de dispositivos...");
      await _bluetoothService!.startDiscovery();

      _bluetoothService!.onDiscovery().listen((result) {
        print(
          "📱 Dispositivo encontrado: ${result.device.name ?? 'Sin nombre'} - ${result.device.address}",
        );

        if (!devicesList.any(
          (device) => device.address == result.device.address,
        )) {
          if (mounted) {
            setState(() {
              devicesList.add(result.device);
            });
          }
          print("✅ Dispositivo agregado a la lista");
        }
      });

      Timer(Duration(seconds: 30), () async {
        await _bluetoothService!.stopDiscovery();
        print("🛑 Búsqueda de dispositivos completada");
      });
    } catch (e) {
      print("❌ Error en descubrimiento de dispositivos: $e");
    }
  }

  void _switchMode(OperationMode newMode) {
    setState(() {
      _currentMode = newMode;
      _showModeSelector = false;
    });

    _saveMode(newMode);
    _connectionManager?.disconnect();
    _initializeServices();
  }

  void _initBluetooth() async {
    if (_bluetoothService == null) return;

    if (_currentMode == OperationMode.real) {
      bool permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        print("Permisos de Bluetooth no concedidos");
        return;
      }
    }

    _bluetoothService!.getState().then((state) {
      if (mounted) {
        setState(() {
          _bluetoothState = state;
        });
      }
    });

    _bluetoothService!.onStateChanged().listen((BluetoothState state) {
      if (mounted) {
        setState(() {
          _bluetoothState = state;
        });
      }
    });

    await _getPairedDevices();
  }

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses =
        await [
          Permission.bluetooth,
          Permission.bluetoothConnect,
          Permission.bluetoothScan,
          Permission.location,
        ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  // Cambiar tema
  void _changeTheme(String mode) {
    setState(() {
      _themeMode = mode;
    });
    SharedPreferencesHelper.saveThemeMode(mode);
  }

  // Determinar si usar tema oscuro
  bool get _isDarkMode {
    if (_themeMode == 'dark') return true;
    if (_themeMode == 'light') return false;
    // Auto: usar tema del sistema
    return SchedulerBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar splash screen
    if (_showingSplash) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(
          onInitializationComplete: () {
            if (mounted) {
              setState(() {
                _showingSplash = false;
              });
            }
          },
        ),
      );
    }

    // Pantalla de carga si aún no está inicializado
    if (!_isInitialized || _connectionManager == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: AppTheme.getThemeMode(_themeMode),
        home: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: AppTheme.getThemeMode(_themeMode),
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
              Text(
                _currentMode == OperationMode.real
                    ? 'Modo Real'
                    : 'Modo Simulador',
              ),
            ],
          ),
          actions: [
            // Botón para ver logs
            IconButton(
              icon: Icon(Icons.bug_report),
              tooltip: 'Ver Logs',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LogViewerScreen()),
                );
              },
            ),
            // Selector de tema
            PopupMenuButton<String>(
              icon: Icon(
                _themeMode == 'dark'
                    ? Icons.dark_mode
                    : _themeMode == 'light'
                    ? Icons.light_mode
                    : Icons.auto_mode,
              ),
              onSelected: _changeTheme,
              tooltip: 'Cambiar tema',
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'light',
                      child: Row(
                        children: [
                          Icon(Icons.light_mode, size: 20),
                          SizedBox(width: 8),
                          Text('Claro'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'dark',
                      child: Row(
                        children: [
                          Icon(Icons.dark_mode, size: 20),
                          SizedBox(width: 8),
                          Text('Oscuro'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'auto',
                      child: Row(
                        children: [
                          Icon(Icons.auto_mode, size: 20),
                          SizedBox(width: 8),
                          Text('Auto'),
                        ],
                      ),
                    ),
                  ],
            ),
            IconButton(
              icon: Icon(Icons.settings),
              tooltip: 'Configuración',
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _showModeSelector = !_showModeSelector;
                  });
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Selector de modo si está visible
            if (_showModeSelector)
              Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Selecciona el modo de operación',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _currentMode == OperationMode.real
                                    ? null
                                    : () => _switchMode(OperationMode.real),
                            icon: Icon(Icons.directions_car),
                            label: Text('Modo Real'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _currentMode == OperationMode.real
                                      ? AppTheme.secondaryColor
                                      : null,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _currentMode == OperationMode.simulator
                                    ? null
                                    : () =>
                                        _switchMode(OperationMode.simulator),
                            icon: Icon(Icons.build_circle),
                            label: Text('Simulador'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _currentMode == OperationMode.simulator
                                      ? AppTheme.primaryColor
                                      : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Mensaje de estado de conexión con mejor visibilidad
            if (_connectionManager != null && _connectionManager!.isConnected)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: _isConnectedToRealDevice ? Colors.green : Colors.blue,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isConnectedToRealDevice
                          ? Icons.bluetooth_connected
                          : Icons.settings_input_component,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _connectionManager!.connectionStatus,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Vista principal
            Expanded(
              child:
                  _connectionManager!.isConnected
                      ? MainDashboard(connectionManager: _connectionManager!)
                      : BluetoothDevicesView(
                        key: ValueKey('bluetooth_${_currentMode.toString()}'),
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
