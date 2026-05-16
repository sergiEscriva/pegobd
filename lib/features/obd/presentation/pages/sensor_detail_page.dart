import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../../../core/providers/app_providers.dart';
import '../../domain/entities/sensor.dart';
import '../../../dashboard/domain/entities/sensor_data.dart';

class SensorDetailPage extends ConsumerStatefulWidget {
  final String pid;
  const SensorDetailPage({super.key, required this.pid});

  @override
  ConsumerState<SensorDetailPage> createState() => _SensorDetailPageState();
}

class _SensorDetailPageState extends ConsumerState<SensorDetailPage> {
  SensorData? _current;
  StreamSubscription? _sub;
  final List<_ChartPoint> _history = [];
  static const int _maxPoints = 50;

  @override
  void initState() {
    super.initState();
    final manager = ref.read(connectionManagerProvider);
    _sub = manager.sensorStream.listen((data) {
      final sensor = data[widget.pid];
      if (sensor == null) return;
      final value = double.tryParse(sensor.value);
      setState(() {
        _current = sensor;
        if (value != null) {
          _history.add(_ChartPoint(DateTime.now(), value));
          if (_history.length > _maxPoints) _history.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = ObdSensors.getSensorName(widget.pid);
    final unit = ObdSensors.getSensorUnit(widget.pid);
    final value = double.tryParse(_current?.value ?? '');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: Text(name), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildGauge(value, unit),
            const SizedBox(height: 30),
            _buildInfoCards(unit),
            const SizedBox(height: 30),
            _buildChart(unit),
          ],
        ),
      ),
    );
  }

  Widget _buildGauge(double? value, String unit) {
    final (min, max) = _rangeFor(unit);
    return Container(
      height: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5))
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
                  endValue: min + (max - min) * 0.6,
                  color: Colors.green,
                  startWidth: 10,
                  endWidth: 10),
              GaugeRange(
                  startValue: min + (max - min) * 0.6,
                  endValue: min + (max - min) * 0.85,
                  color: Colors.orange,
                  startWidth: 10,
                  endWidth: 10),
              GaugeRange(
                  startValue: min + (max - min) * 0.85,
                  endValue: max,
                  color: Colors.red,
                  startWidth: 10,
                  endWidth: 10),
            ],
            pointers: [
              NeedlePointer(
                value: value?.clamp(min, max) ?? min,
                enableAnimation: true,
                animationDuration: 500,
                needleStartWidth: 1,
                needleEndWidth: 8,
                needleColor: Colors.black87,
                knobStyle: const KnobStyle(
                    knobRadius: 0.1,
                    color: Colors.white,
                    borderColor: Colors.black87,
                    borderWidth: 0.05),
              ),
            ],
            annotations: [
              GaugeAnnotation(
                angle: 90,
                positionFactor: 0.75,
                widget: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8)
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
                            color: _colorFor(unit)),
                      ),
                      Text(unit,
                          style: TextStyle(
                              fontSize: 20, color: Colors.grey[700])),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(String unit) {
    return Row(
      children: [
        Expanded(
            child: _InfoCard(
                title: 'PID',
                value: widget.pid,
                icon: Icons.info_outline,
                color: Colors.blue)),
        const SizedBox(width: 16),
        Expanded(
            child: _InfoCard(
                title: 'Unidad',
                value: unit,
                icon: Icons.straighten,
                color: Colors.green)),
      ],
    );
  }

  Widget _buildChart(String unit) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.show_chart, color: _colorFor(unit)),
            const SizedBox(width: 8),
            const Text('Tiempo real',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: _history.isEmpty
                ? const Center(
                    child: Text('Esperando datos…',
                        style: TextStyle(color: Colors.grey)))
                : SfCartesianChart(
                    primaryXAxis: const DateTimeAxis(isVisible: false),
                    primaryYAxis: const NumericAxis(
                        labelStyle: TextStyle(fontSize: 10)),
                    plotAreaBorderWidth: 0,
                    series: [
                      SplineSeries<_ChartPoint, DateTime>(
                        dataSource: _history,
                        xValueMapper: (p, _) => p.time,
                        yValueMapper: (p, _) => p.value,
                        color: _colorFor(unit),
                        width: 3,
                        markerSettings:
                            const MarkerSettings(isVisible: false),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  (double, double) _rangeFor(String unit) => switch (unit) {
        'rpm' => (0, 8000),
        'km/h' => (0, 240),
        '°C' => (-40, 150),
        'kPa' => (0, 300),
        'V' => (0, 20),
        _ => (0, 100),
      };

  Color _colorFor(String unit) => switch (unit) {
        'rpm' => Colors.red,
        'km/h' => Colors.blue,
        '°C' => Colors.orange,
        '%' => Colors.green,
        'V' => Colors.purple,
        _ => Colors.blueGrey,
      };
}

class _ChartPoint {
  final DateTime time;
  final double value;
  _ChartPoint(this.time, this.value);
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _InfoCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
