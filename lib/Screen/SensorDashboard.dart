import 'dart:async';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../connection/ConnectionManager.dart';
import '../model/SensorData.dart';
import '../sensors/OBDSensors.dart';

class SensorDashboard extends StatefulWidget {
  final ConnectionManager connectionManager;
  const SensorDashboard({required this.connectionManager});

  @override
  State<SensorDashboard> createState() => _SensorDashboardState();
}

class _SensorDashboardState extends State<SensorDashboard> {
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

  double? _getDouble(String pid) {
    final val = _sensors[pid]?.value;
    if (val == null) return null;
    return double.tryParse(val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tacógrafo OBD')),
      body: widget.connectionManager.isConnected
          ? _buildDashboard()
          : Center(child: Text('No hay conexión con dispositivo OBD')),
    );
  }

  Widget _buildDashboard() {
    if (_sensors.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    // Ordenar por nombre de sensor
    final sensorList = _sensors.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sensorList.length,
      itemBuilder: (context, index) {
        final sensor = sensorList[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
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
    final String pid = sensor.pid;
    // Selección de tipo de gráfico según unidad o nombre
    if (unit == 'rpm' || unit == 'km/h') {
      // Gauge circular para RPM y velocidad
      double max = unit == 'rpm' ? 8000 : 240;
      Color color = unit == 'rpm' ? Colors.red : Colors.blue;
      return _buildGauge(title: name, value: value, min: 0, max: max, unit: unit, color: color);
    } else if (unit == '%') {
      // Gauge semicircular para porcentajes
      return _buildGauge(title: name, value: value, min: 0, max: 100, unit: unit, color: Colors.green, isSemi: true);
    } else if (unit == '°C') {
      // Barra para temperaturas
      double min = -40, max = 150;
      return _buildBar(title: name, value: value, min: min, max: max, unit: unit, color: Colors.orange);
    } else if (unit == 'V') {
      // Barra para voltaje
      return _buildBar(title: name, value: value, min: 0, max: 20, unit: unit, color: Colors.purple);
    } else if (unit == 'kPa' || unit == 'Pa') {
      // Barra para presiones
      return _buildBar(title: name, value: value, min: 0, max: 300, unit: unit, color: Colors.blueGrey);
    } else if (unit == 'g/s' || unit == 'L/h') {
      // Barra para flujo de aire o consumo
      return _buildBar(title: name, value: value, min: 0, max: 100, unit: unit, color: Colors.teal);
    } else if (unit == 's' || unit == 'min' || unit == 'km') {
      // Barra para tiempo o distancia
      return _buildBar(title: name, value: value, min: 0, max: 10000, unit: unit, color: Colors.indigo);
    } else {
      // Valor digital por defecto
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
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(
          width: 200,
          height: isSemi ? 120 : 180,
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
                      GaugeRange(startValue: min, endValue: max, color: color.withOpacity(0.2)),
                    ],
                    pointers: [
                      NeedlePointer(value: animatedValue),
                    ],
                    annotations: [
                      GaugeAnnotation(
                        widget: Text(
                          value != null ? '${value.toStringAsFixed(1)} $unit' : 'N/A',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: value != null ? ((value - min) / (max - min)).clamp(0.0, 1.0) : 0.0),
          duration: Duration(milliseconds: 700),
          curve: Curves.easeInOut,
          builder: (context, animatedValue, child) {
            return LinearProgressIndicator(
              value: animatedValue,
              minHeight: 24,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            );
          },
        ),
        SizedBox(height: 4),
        Text(value != null ? '${value.toStringAsFixed(1)} $unit' : 'N/A', style: TextStyle(fontSize: 16)),
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
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text(
          value.isNotEmpty ? '$value $unit' : 'N/A',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }
}
