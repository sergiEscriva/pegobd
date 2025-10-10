import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../connection/ConnectionManager.dart';
import '../model/SensorData.dart';
import '../theme/app_theme.dart';

class SimulatorModeDashboard extends StatefulWidget {
  final ConnectionManager connectionManager;
  const SimulatorModeDashboard({required this.connectionManager});

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
                child: Icon(Icons.build, color: Colors.white, size: 28),
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
                    'Datos de prueba generados',
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
        // Dashboard de sensores
        Expanded(child: _buildDashboard()),
      ],
    );
  }

  Widget _buildDashboard() {
    if (_sensors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text('Generando datos simulados...'),
          ],
        ),
      );
    }

    final sensorList = _sensors.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sensorList.length,
      itemBuilder: (context, index) {
        final sensor = sensorList[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSensorWidget(sensor),
          ),
        );
      },
    );
  }

  Widget _buildSensorWidget(SensorData sensor) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.speed, color: color, size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Center(
          child: SizedBox(
            width: 220,
            height: isSemi ? 140 : 200,
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
                      showLabels: true,
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
                          needleEndWidth: 6,
                        ),
                      ],
                      annotations: [
                        GaugeAnnotation(
                          widget: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              value != null ? '${value.toStringAsFixed(1)} $unit' : 'N/A',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          angle: isSemi ? 90 : 90,
                          positionFactor: 0.7,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.show_chart, color: color, size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 0.0,
            end: value != null ? ((value - min) / (max - min)).clamp(0.0, 1.0) : 0.0,
          ),
          duration: Duration(milliseconds: 700),
          curve: Curves.easeInOut,
          builder: (context, animatedValue, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: animatedValue,
                minHeight: 28,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            );
          },
        ),
        SizedBox(height: 8),
        Text(
          value != null ? '${value.toStringAsFixed(1)} $unit' : 'N/A',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDigital({
    required String title,
    required String value,
    required String unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Text(
            value.isNotEmpty ? '$value $unit' : 'N/A',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
        ),
      ],
    );
  }
}
