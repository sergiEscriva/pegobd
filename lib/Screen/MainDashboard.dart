import 'package:flutter/material.dart';
import 'package:pegobd/connection/ConnectionManager.dart';
import 'package:pegobd/Screen/RealModeDashboard.dart';
import 'package:pegobd/Screen/SimulatorModeDashboard.dart';

class MainDashboard extends StatefulWidget {
  final ConnectionManager connectionManager;
  const MainDashboard({super.key, required this.connectionManager});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          RealModeDashboard(connectionManager: widget.connectionManager),
          SimulatorModeDashboard(connectionManager: widget.connectionManager),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: _selectedIndex == 0 ? Colors.green[700] : Colors.blue[700],
        unselectedItemColor: Colors.grey[400],
        selectedFontSize: 14,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            activeIcon: Icon(Icons.directions_car, size: 32),
            label: 'Modo Real',
            tooltip: 'Ver datos reales del vehículo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            activeIcon: Icon(Icons.build, size: 32),
            label: 'Modo Simulador',
            tooltip: 'Ver datos simulados de prueba',
          ),
        ],
      ),
    );
  }
}
