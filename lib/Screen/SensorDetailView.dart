import 'dart:async';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../features/dashboard/domain/entities/sensor_data.dart';

class SensorDetailView extends StatefulWidget {
  final SensorData sensor;
  final Stream<Map<String, SensorData>> sensorStream;

  const SensorDetailView({required this.sensor, required this.sensorStream});

  @override
  State<SensorDetailView> createState() => _SensorDetailViewState();
}

class _SensorDetailViewState extends State<SensorDetailView> {
  late SensorData _currentSensor;
  StreamSubscription? _subscription;
  List<ChartData> _chartData = [];
  final int _maxDataPoints = 50;

  @override
  void initState() {
    super.initState();
    _currentSensor = widget.sensor;

    _subscription = widget.sensorStream.listen((sensorsData) {
      if (sensorsData.containsKey(widget.sensor.pid)) {
        final newSensor = sensorsData[widget.sensor.pid]!;
        setState(() {
          _currentSensor = newSensor;

          // Agregar punto al gráfico
          final value = double.tryParse(newSensor.value);
          if (value != null) {
            _chartData.add(ChartData(DateTime.now(), value));

            // Mantener solo los últimos N puntos
            if (_chartData.length > _maxDataPoints) {
              _chartData.removeAt(0);
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = double.tryParse(_currentSensor.value);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: Text(_currentSensor.name), centerTitle: true),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Gauge principal grande
            _buildMainGauge(value),
            SizedBox(height: 30),

            // Información del sensor
            _buildInfoCards(),
            SizedBox(height: 30),

            // Gráfico en tiempo real
            _buildRealtimeChart(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMainGauge(double? value) {
    final unit = _currentSensor.unit;
    double min = 0;
    double max = 100;

    // Ajustar rangos según la unidad
    if (unit == 'rpm') {
      max = 8000;
    } else if (unit == 'km/h') {
      max = 240;
    } else if (unit == '°C') {
      min = -40;
      max = 150;
    } else if (unit == 'kPa') {
      max = 300;
    } else if (unit == 'V') {
      max = 20;
    }

    return Container(
      height: 350,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: SfRadialGauge(
        axes: [
          RadialAxis(
            minimum: min,
            maximum: max,
            ranges: [
              GaugeRange(
                startValue: min,
                endValue: max * 0.6,
                color: Colors.green,
                startWidth: 10,
                endWidth: 10,
              ),
              GaugeRange(
                startValue: max * 0.6,
                endValue: max * 0.85,
                color: Colors.orange,
                startWidth: 10,
                endWidth: 10,
              ),
              GaugeRange(
                startValue: max * 0.85,
                endValue: max,
                color: Colors.red,
                startWidth: 10,
                endWidth: 10,
              ),
            ],
            pointers: [
              NeedlePointer(
                value: value ?? min,
                enableAnimation: true,
                animationDuration: 500,
                needleStartWidth: 1,
                needleEndWidth: 8,
                needleColor: Colors.black87,
                knobStyle: KnobStyle(
                  knobRadius: 0.1,
                  color: Colors.white,
                  borderColor: Colors.black87,
                  borderWidth: 0.05,
                ),
              ),
            ],
            annotations: [
              GaugeAnnotation(
                widget: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value?.toStringAsFixed(1) ?? 'N/A',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _getSensorColor(unit),
                        ),
                      ),
                      Text(
                        unit,
                        style: TextStyle(fontSize: 20, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                angle: 90,
                positionFactor: 0.75,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            title: 'PID',
            value: _currentSensor.pid,
            icon: Icons.info_outline,
            color: Colors.blue,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            title: 'Unidad',
            value: _currentSensor.unit,
            icon: Icons.straighten,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeChart() {
    return Container(
      height: 250,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: _getSensorColor(_currentSensor.unit),
              ),
              SizedBox(width: 8),
              Text(
                'Gráfico en tiempo real',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child:
                _chartData.isEmpty
                    ? Center(
                      child: Text(
                        'Esperando datos...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : SfCartesianChart(
                      primaryXAxis: DateTimeAxis(isVisible: false),
                      primaryYAxis: NumericAxis(
                        labelStyle: TextStyle(fontSize: 10),
                      ),
                      plotAreaBorderWidth: 0,
                      series: _buildChartSeries(),
                    ),
          ),
        ],
      ),
    );
  }

  List<CartesianSeries<ChartData, DateTime>> _buildChartSeries() {
    return [
      SplineSeries<ChartData, DateTime>(
        dataSource: _chartData,
        xValueMapper: (ChartData data, _) => data.time,
        yValueMapper: (ChartData data, _) => data.value,
        color: _getSensorColor(_currentSensor.unit),
        width: 3,
        markerSettings: MarkerSettings(isVisible: false),
      ),
    ];
  }

  Color _getSensorColor(String unit) {
    if (unit == 'rpm') return Colors.red;
    if (unit == 'km/h') return Colors.blue;
    if (unit == '°C') return Colors.orange;
    if (unit == '%') return Colors.green;
    if (unit == 'V') return Colors.purple;
    return Colors.blueGrey;
  }
}

class ChartData {
  final DateTime time;
  final double value;

  ChartData(this.time, this.value);
}
