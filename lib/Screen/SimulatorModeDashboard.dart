import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../connection/ConnectionManager.dart';
import '../model/SensorData.dart';
import '../theme/app_theme.dart';

class SimulatorModeDashboard extends StatefulWidget {
  final ConnectionManager connectionManager;
  final List<String> selectedSensorPids;

  const SimulatorModeDashboard({
    required this.connectionManager,
    this.selectedSensorPids = const [],
  });

  @override
  State<SimulatorModeDashboard> createState() => _SimulatorModeDashboardState();
}

class _SimulatorModeDashboardState extends State<SimulatorModeDashboard> {
  Map<String, SensorData> _sensors = {};
  StreamSubscription? _sensorSubscription;

  @override
  void initState() {
    super.initState();
    _sensorSubscription = widget.connectionManager.sensorStream.listen((sensorsData) {
      setState(() {
        _sensors = sensorsData;
      });
    });
    widget.connectionManager.requestAllSensors();
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    super.dispose();
  }

  // Filtrar sensores según la selección del usuario
  Map<String, SensorData> get _filteredSensors {
    if (widget.selectedSensorPids.isEmpty) {
      return _sensors; // Mostrar todos si no hay selección
    }

    return Map.fromEntries(
      _sensors.entries.where((entry) => widget.selectedSensorPids.contains(entry.key))
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.connectionManager.isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build_circle_outlined, size: 64, color: Colors.blue[300]),
            SizedBox(height: 16),
            Text(
              'No hay conexión con simulador',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }

    final filteredSensors = _filteredSensors;

    return Column(
      children: [
        // Banner indicativo de modo SIMULADOR mejorado
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryBlue, AppTheme.lightBlue],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.build_circle, color: Colors.white, size: 28),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MODO SIMULADOR',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Datos de prueba simulados',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Contenido principal - SOLO SENSORES SELECCIONADOS
        Expanded(
          child: filteredSensors.isEmpty
              ? _buildEmptyState()
              : _buildSensorGrid(filteredSensors),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sensors_off, size: 80, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            widget.selectedSensorPids.isEmpty
              ? 'No hay sensores seleccionados'
              : 'Esperando datos de sensores...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 12),
          Text(
            widget.selectedSensorPids.isEmpty
              ? 'Presiona el botón ⚙️ para seleccionar sensores'
              : 'Los datos aparecerán aquí en tiempo real',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          if (widget.selectedSensorPids.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ElevatedButton.icon(
                onPressed: () {
                  // El usuario debe presionar el botón de configuración en el AppBar
                },
                icon: Icon(Icons.tune),
                label: Text('Configurar Sensores'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSensorGrid(Map<String, SensorData> sensors) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: sensors.length,
      itemBuilder: (context, index) {
        final sensor = sensors.values.elementAt(index);
        return _buildSensorCard(sensor);
      },
    );
  }

  Widget _buildSensorCard(SensorData sensor) {
    final double? value = double.tryParse(sensor.value);
    final String unit = sensor.unit;
    final String name = sensor.name;

    if (unit == 'rpm' || unit == 'km/h') {
      double max = unit == 'rpm' ? 8000 : 240;
      Color color = unit == 'rpm' ? Colors.red : Colors.blue;
      return _buildGauge(title: name, value: value, min: 0, max: max, unit: unit, color: color);
    } else if (unit == '%') {
      return _buildGauge(title: name, value: value, min: 0, max: 100, unit: unit, color: Colors.green, isSemi: true);
    } else if (unit == '°C') {
      return _buildBar(title: name, value: value, min: -40, max: 150, unit: unit, color: Colors.orange);
    } else if (unit == 'V') {
      return _buildBar(title: name, value: value, min: 0, max: 20, unit: unit, color: Colors.purple);
    } else if (unit == 'kPa' || unit == 'Pa') {
      return _buildBar(title: name, value: value, min: 0, max: 300, unit: unit, color: Colors.blueGrey);
    } else if (unit == 'g/s' || unit == 'L/h') {
      return _buildBar(title: name, value: value, min: 0, max: 100, unit: unit, color: Colors.teal);
    } else if (unit == 's' || unit == 'min' || unit == 'km') {
      return _buildBar(title: name, value: value, min: 0, max: 10000, unit: unit, color: Colors.indigo);
    } else {
      return _buildDigital(title: name, value: sensor.value, unit: unit);
    }
  }

  Widget _buildGauge({
    required String title,
    double? value,
    required double min,
    required double max,
    required String unit,
    required Color color,
    bool isSemi = false,
  }) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título más compacto con elipsis
          Row(
            children: [
              Icon(Icons.speed, color: color, size: 16),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Expanded(
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: min, end: value ?? min),
                duration: Duration(milliseconds: 700),
                curve: Curves.easeInOut,
                builder: (context, animatedValue, child) {
                  return SfRadialGauge(
                    axes: [
                      RadialAxis(
                        minimum: min,
                        maximum: max,
                        startAngle: isSemi ? 180 : 135,
                        endAngle: isSemi ? 0 : 45,
                        showTicks: true,
                        showLabels: false,
                        labelOffset: 10,
                        axisLabelStyle: GaugeTextStyle(fontSize: 8),
                        ranges: [
                          GaugeRange(
                            startValue: min,
                            endValue: max,
                            color: color.withValues(alpha: 0.2),
                          ),
                        ],
                        pointers: [
                          NeedlePointer(
                            value: animatedValue,
                            needleColor: color,
                            needleEndWidth: 4,
                            needleStartWidth: 0.5,
                          ),
                        ],
                        annotations: [
                          GaugeAnnotation(
                            widget: Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                value != null ? '${value.toStringAsFixed(0)}\n$unit' : 'N/A',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            angle: isSemi ? 90 : 90,
                            positionFactor: 0.75,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar({
    required String title,
    double? value,
    required double min,
    required double max,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título más compacto
          Row(
            children: [
              Icon(Icons.show_chart, color: color, size: 16),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0.0,
                    end: value != null ? ((value - min) / (max - min)).clamp(0.0, 1.0) : 0.0,
                  ),
                  duration: Duration(milliseconds: 700),
                  curve: Curves.easeInOut,
                  builder: (context, animatedValue, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: animatedValue,
                        minHeight: 20,
                        backgroundColor: color.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    );
                  },
                ),
                SizedBox(height: 6),
                Text(
                  value != null ? '${value.toStringAsFixed(1)} $unit' : 'N/A',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigital({
    required String title,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título compacto
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 16),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value.isNotEmpty ? '$value $unit' : 'N/A',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
