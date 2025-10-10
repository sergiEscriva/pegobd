import 'dart:async';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../../../shared/services/connection_manager.dart';
import '../../domain/entities/sensor_data.dart';


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
    _sensorSubscription = widget.connectionManager.sensorStream.listen((
      sensorsData,
    ) {
      if (mounted) {
        setState(() {
          _sensors = sensorsData;
        });
      }
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Tacógrafo OBD'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              widget.connectionManager.requestAllSensors();
            },
            tooltip: 'Actualizar sensores',
          ),
        ],
      ),
      body:
          widget.connectionManager.isConnected
              ? Column(
                children: [
                  // Banner indicativo de modo
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8),
                    color:
                        widget.connectionManager.isSimulatorMode
                            ? Colors.blue[100]
                            : Colors.green[100],
                    child: Text(
                      widget.connectionManager.isSimulatorMode
                          ? '🔧 MODO SIMULADOR - Datos de prueba'
                          : '🚗 MODO REAL - Datos del vehículo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            widget.connectionManager.isSimulatorMode
                                ? Colors.blue[800]
                                : Colors.green[800],
                      ),
                    ),
                  ),
                  // Dashboard de sensores con scroll
                  Expanded(child: _buildDashboard()),
                ],
              )
              : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bluetooth_disabled,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No hay conexión con dispositivo OBD',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.arrow_back),
                      label: Text('Volver a conexiones'),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildDashboard() {
    if (_sensors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando sensores...'),
          ],
        ),
      );
    }

    // Ordenar por nombre de sensor
    final sensorList =
        _sensors.values.toList()..sort((a, b) => a.name.compareTo(b.name));

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sensorList.length,
      itemBuilder: (context, index) {
        final sensor = sensorList[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
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

    // Selección de tipo de gráfico según unidad o nombre
    if (unit == 'rpm' || unit == 'km/h') {
      // Gauge circular para RPM y velocidad
      double max = unit == 'rpm' ? 8000 : 240;
      Color color = unit == 'rpm' ? Colors.red : Colors.blue;
      return _buildGauge(
        title: name,
        value: value,
        min: 0,
        max: max,
        unit: unit,
        color: color,
      );
    } else if (unit == '%') {
      // Gauge semicircular para porcentajes
      return _buildGauge(
        title: name,
        value: value,
        min: 0,
        max: 100,
        unit: unit,
        color: Colors.green,
        isSemi: true,
      );
    } else if (unit == '°C') {
      // Barra para temperaturas
      double min = -40, max = 150;
      return _buildBar(
        title: name,
        value: value,
        min: min,
        max: max,
        unit: unit,
        color: Colors.orange,
      );
    } else if (unit == 'V') {
      // Barra para voltaje
      return _buildBar(
        title: name,
        value: value,
        min: 0,
        max: 20,
        unit: unit,
        color: Colors.purple,
      );
    } else if (unit == 'kPa' || unit == 'Pa') {
      // Barra para presiones
      return _buildBar(
        title: name,
        value: value,
        min: 0,
        max: 300,
        unit: unit,
        color: Colors.blueGrey,
      );
    } else if (unit == 'g/s' || unit == 'L/h') {
      // Barra para flujo de aire o consumo
      return _buildBar(
        title: name,
        value: value,
        min: 0,
        max: 100,
        unit: unit,
        color: Colors.teal,
      );
    } else if (unit == 's' || unit == 'min' || unit == 'km') {
      // Barra para tiempo o distancia
      return _buildBar(
        title: name,
        value: value,
        min: 0,
        max: 10000,
        unit: unit,
        color: Colors.indigo,
      );
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
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Center(
          child: SizedBox(
            width: double.infinity,
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
                        GaugeRange(
                          startValue: min,
                          endValue: max,
                          color: color.withOpacity(0.2),
                        ),
                      ],
                      pointers: [NeedlePointer(value: animatedValue)],
                      annotations: [
                        GaugeAnnotation(
                          widget: Text(
                            value != null
                                ? '${value.toStringAsFixed(1)} $unit'
                                : 'N/A',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: min, end: value ?? min),
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                builder: (context, animatedValue, child) {
                  double progress = ((animatedValue - min) / (max - min)).clamp(
                    0.0,
                    1.0,
                  );
                  return LinearProgressIndicator(
                    value: progress,
                    minHeight: 20,
                    backgroundColor: color.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: Text(
                value != null ? '${value.toStringAsFixed(1)} $unit' : 'N/A',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDigital({
    required String title,
    required String value,
    required String unit,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          '$value $unit',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
      ],
    );
  }
}
