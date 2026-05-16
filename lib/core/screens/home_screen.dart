import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/storage_helper.dart';
import '../../core/enums/operation_mode.dart';
import '../../core/providers/app_providers.dart';
import '../../features/bluetooth/presentation/pages/bluetooth_devices_page.dart';
import '../../features/dashboard/presentation/pages/main_dashboard_page.dart';
import '../../features/logging/presentation/pages/log_viewer_page.dart';
import '../../shared/services/bluetooth_service.dart';

/// Pantalla raíz de la app. Muestra:
/// - Panel de selector de modo (si el usuario lo abre)
/// - Banner de conexión
/// - BluetoothDevicesPage o MainDashboard según estado de conexión
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showModeSelector = false;
  StreamSubscription? _discoverySubscription;
  Timer? _discoveryTimer;

  // -------------------------------------------------------------------------
  // Ciclo de vida
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initBluetooth());
  }

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    _discoveryTimer?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Inicialización Bluetooth
  // -------------------------------------------------------------------------

  Future<void> _initBluetooth() async {
    final mode = ref.read(operationModeProvider);
    final service = ref.read(bluetoothServiceProvider);

    if (mode == OperationMode.real) {
      final granted = await _requestPermissions();
      if (!granted) return;
    }

    // Escuchar cambios de estado del adaptador
    service.onStateChanged().listen((state) {
      if (mounted) {
        ref.read(bluetoothStateProvider.notifier).state = state;
      }
    });

    final state = await service.getState();
    if (mounted) {
      ref.read(bluetoothStateProvider.notifier).state = state;
    }

    await _loadDevices();
  }

  Future<void> _loadDevices() async {
    final service = ref.read(bluetoothServiceProvider);
    try {
      final devices = await service.getPairedDevices();
      if (mounted) {
        ref.read(bluetoothDevicesProvider.notifier).state = devices;
      }
    } on BluetoothPermissionException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          action:
              SnackBarAction(label: 'Ajustes', onPressed: openAppSettings),
          duration: const Duration(seconds: 8),
        ));
      }
      return;
    }

    await _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    final mode = ref.read(operationModeProvider);
    if (mode != OperationMode.real) return;

    final service = ref.read(bluetoothServiceProvider);
    try {
      _discoverySubscription?.cancel();
      _discoverySubscription = service.onDiscovery().listen((result) {
        final current = ref.read(bluetoothDevicesProvider);
        if (!current.any((d) => d.address == result.device.address)) {
          ref.read(bluetoothDevicesProvider.notifier).state = [
            ...current,
            result.device,
          ];
        }
      });

      _discoveryTimer?.cancel();
      _discoveryTimer = Timer(const Duration(seconds: 30), () {
        service.stopDiscovery();
        _discoverySubscription?.cancel();
      });
    } catch (e) {
      // Descubrimiento no crítico — fallo silencioso
    }
  }

  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  // -------------------------------------------------------------------------
  // Cambio de modo
  // -------------------------------------------------------------------------

  void _switchMode(OperationMode newMode) {
    ref.read(operationModeProvider.notifier).state = newMode;
    SharedPreferencesHelper.saveOperationMode(newMode.name);
    setState(() => _showModeSelector = false);
    // El connectionManagerProvider se invalida automáticamente al cambiar el
    // bluetoothServiceProvider del que depende.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initBluetooth());
  }

  // -------------------------------------------------------------------------
  // Tema
  // -------------------------------------------------------------------------

  bool get _isDark {
    final mode = ref.read(themeModeProvider);
    if (mode == 'dark') return true;
    if (mode == 'light') return false;
    return SchedulerBinding
            .instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  void _changeTheme(String mode) {
    ref.read(themeModeProvider.notifier).state = mode;
    SharedPreferencesHelper.saveThemeMode(mode);
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(operationModeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final manager = ref.watch(connectionManagerProvider);
    final devices = ref.watch(bluetoothDevicesProvider);
    final btState = ref.watch(bluetoothStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(currentMode == OperationMode.real
                ? Icons.directions_car
                : Icons.build_circle),
            const SizedBox(width: 8),
            Text(currentMode == OperationMode.real
                ? 'Modo Real'
                : 'Modo Simulador'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Ver logs',
            onPressed: () => context.push('/logs'),
          ),
          PopupMenuButton<String>(
            icon: Icon(_themeIcon(themeMode)),
            tooltip: 'Tema',
            onSelected: _changeTheme,
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'light',
                  child: Row(children: [
                    Icon(Icons.light_mode, size: 20),
                    SizedBox(width: 8),
                    Text('Claro'),
                  ])),
              const PopupMenuItem(
                  value: 'dark',
                  child: Row(children: [
                    Icon(Icons.dark_mode, size: 20),
                    SizedBox(width: 8),
                    Text('Oscuro'),
                  ])),
              const PopupMenuItem(
                  value: 'auto',
                  child: Row(children: [
                    Icon(Icons.auto_mode, size: 20),
                    SizedBox(width: 8),
                    Text('Auto'),
                  ])),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuración',
            onPressed: () =>
                setState(() => _showModeSelector = !_showModeSelector),
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector de modo
          if (_showModeSelector) _buildModeSelector(currentMode),

          // Banner de conexión
          if (manager.isConnected) _buildConnectionBanner(manager),

          // Contenido principal
          Expanded(
            child: manager.isConnected
                ? const MainDashboard()
                : BluetoothDevicesView(
                    key: ValueKey('bt_${currentMode.name}'),
                    bluetoothState: btState,
                    devices: devices,
                    onRefreshDevices: _loadDevices,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(OperationMode current) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Modo de operación',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: current == OperationMode.real
                      ? null
                      : () => _switchMode(OperationMode.real),
                  icon: const Icon(Icons.directions_car),
                  label: const Text('Modo Real'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: current == OperationMode.real
                          ? AppTheme.secondaryColor
                          : null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: current == OperationMode.simulator
                      ? null
                      : () => _switchMode(OperationMode.simulator),
                  icon: const Icon(Icons.build_circle),
                  label: const Text('Simulador'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: current == OperationMode.simulator
                          ? AppTheme.primaryColor
                          : null),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBanner(manager) {
    final isReal = !manager.isSimulatorMode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: isReal ? Colors.green : Colors.blue,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isReal
                ? Icons.bluetooth_connected
                : Icons.settings_input_component,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              manager.connectionStatus,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _themeIcon(String mode) => switch (mode) {
        'dark' => Icons.dark_mode,
        'light' => Icons.light_mode,
        _ => Icons.auto_mode,
      };
}
