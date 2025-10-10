import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../connection/ConnectionManager.dart';
import '../theme/app_theme.dart';

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
    final bool isSimulatorMode = connectionManager.isSimulatorMode;
    final Color themeColor = isSimulatorMode ? AppTheme.primaryBlue : AppTheme.primaryGreen;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundLight,
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: <Widget>[
          // Header con estado de Bluetooth
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeColor, themeColor.withValues(alpha: 0.8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  bluetoothState == BluetoothState.STATE_ON
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: Colors.white,
                  size: 48,
                ),
                SizedBox(height: 12),
                Text(
                  bluetoothState == BluetoothState.STATE_ON
                      ? 'Bluetooth Activado'
                      : 'Bluetooth Desactivado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  isSimulatorMode
                      ? 'Modo Simulador - Datos de Prueba'
                      : 'Buscar dispositivos OBD reales',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Botón de actualizar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRefreshDevices,
                icon: Icon(Icons.refresh, size: 24),
                label: Text(
                  'Actualizar Dispositivos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  elevation: 4,
                  shadowColor: themeColor.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          // Lista de dispositivos
          Expanded(
            child: devices.isEmpty
                ? _buildEmptyState(isSimulatorMode, themeColor)
                : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                BluetoothDevice device = devices[index];
                final isConnectedToThisDevice =
                connectionManager.isConnected &&
                    connectionManager.connectedDevice == device;

                return _buildDeviceCard(
                  device: device,
                  isConnected: isConnectedToThisDevice,
                  themeColor: themeColor,
                  onConnect: () => connectionManager.connect(device),
                  onDisconnect: connectionManager.disconnect,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSimulatorMode, Color themeColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSimulatorMode ? Icons.devices : Icons.bluetooth_searching,
            size: 80,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            isSimulatorMode
                ? 'No hay dispositivos disponibles'
                : 'No se encontraron dispositivos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              isSimulatorMode
                  ? 'Presiona "Actualizar" para cargar el dispositivo simulado'
                  : 'Asegúrate de que tu dispositivo OBD esté emparejado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard({
    required BluetoothDevice device,
    required bool isConnected,
    required Color themeColor,
    required VoidCallback onConnect,
    required VoidCallback onDisconnect,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: isConnected ? 8 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isConnected ? themeColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: isConnected ? null : onConnect,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icono del dispositivo
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isConnected
                      ? themeColor.withOpacity(0.2)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                  color: isConnected ? themeColor : Colors.grey[600],
                  size: 32,
                ),
              ),
              SizedBox(width: 16),

              // Información del dispositivo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name ?? "Dispositivo Desconocido",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: AppTheme.textSecondary),
                        SizedBox(width: 4),
                        Text(
                          device.address,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (isConnected)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: themeColor, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 14, color: themeColor),
                              SizedBox(width: 4),
                              Text(
                                'CONECTADO',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: themeColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Botón de acción
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: isConnected ? onDisconnect : onConnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected ? Colors.red[600] : themeColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isConnected ? 'Desconectar' : 'Conectar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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