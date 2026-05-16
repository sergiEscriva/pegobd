import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../obd/domain/entities/sensor.dart';
import '../../domain/entities/recording.dart';

class RecordingDetailPage extends StatefulWidget {
  final Recording recording;
  final Recording? comparisonRecording;

  const RecordingDetailPage({
    super.key,
    required this.recording,
    this.comparisonRecording,
  });

  @override
  State<RecordingDetailPage> createState() => _RecordingDetailPageState();
}

class _RecordingDetailPageState extends State<RecordingDetailPage> {
  String? _selectedPid;

  @override
  void initState() {
    super.initState();
    if (widget.recording.sensorPids.isNotEmpty) {
      _selectedPid = widget.recording.sensorPids.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recording.name),
      ),
      body: Column(
        children: [
          _buildInfoHeader(),
          _buildPidSelector(),
          Expanded(
            child: _selectedPid != null
                ? _buildChart(_selectedPid!)
                : const Center(child: Text('Selecciona un sensor')),
          ),
          if (_selectedPid != null) _buildStats(_selectedPid!),
        ],
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.blue[100]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _InfoChip(
              icon: Icons.calendar_today,
              label: _formatDate(widget.recording.startTime)),
          _InfoChip(
              icon: Icons.access_time,
              label: _formatTime(widget.recording.startTime)),
          _InfoChip(
              icon: Icons.timer,
              label: _formatDuration(widget.recording.duration)),
        ],
      ),
    );
  }

  Widget _buildPidSelector() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: widget.recording.sensorPids.length,
        itemBuilder: (context, i) {
          final pid = widget.recording.sensorPids[i];
          final selected = pid == _selectedPid;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(ObdSensors.getSensorName(pid),
                  style: const TextStyle(fontSize: 12)),
              selected: selected,
              selectedColor: Colors.blue[700],
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => setState(() => _selectedPid = pid),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChart(String pid) {
    final data = widget.recording.data[pid] ?? [];
    final comparison = widget.comparisonRecording?.data[pid];

    if (data.isEmpty) {
      return const Center(
          child: Text('Sin datos', style: TextStyle(color: Colors.grey)));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SfCartesianChart(
        title: ChartTitle(
            text: ObdSensors.getSensorName(pid),
            textStyle: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        primaryXAxis: DateTimeAxis(
            labelStyle: const TextStyle(fontSize: 10),
            dateFormat: intl.DateFormat('HH:mm:ss')),
        primaryYAxis: NumericAxis(
            title: AxisTitle(text: ObdSensors.getSensorUnit(pid)),
            labelStyle: const TextStyle(fontSize: 10)),
        tooltipBehavior: TooltipBehavior(
            enable: true,
            format: 'point.y ${ObdSensors.getSensorUnit(pid)}'),
        zoomPanBehavior: ZoomPanBehavior(
            enablePinching: true,
            enablePanning: true,
            zoomMode: ZoomMode.x),
        series: <CartesianSeries>[
          LineSeries<SensorDataPoint, DateTime>(
            name: widget.recording.name,
            dataSource: data,
            xValueMapper: (p, _) => p.timestamp,
            yValueMapper: (p, _) => p.value,
            color: Colors.blue[700],
            width: 2,
            markerSettings: const MarkerSettings(isVisible: false),
          ),
          if (comparison != null && comparison.isNotEmpty)
            LineSeries<SensorDataPoint, DateTime>(
              name: widget.comparisonRecording!.name,
              dataSource: comparison,
              xValueMapper: (p, _) => p.timestamp,
              yValueMapper: (p, _) => p.value,
              color: Colors.orange[700],
              width: 2,
              dashArray: const [5, 5],
              markerSettings: const MarkerSettings(isVisible: false),
            ),
        ],
      ),
    );
  }

  Widget _buildStats(String pid) {
    final data = widget.recording.data[pid] ?? [];
    if (data.isEmpty) return const SizedBox.shrink();

    final values = data.map((e) => e.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    final unit = ObdSensors.getSensorUnit(pid);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border(top: BorderSide(color: Colors.grey[300]!))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatCard('Mínimo', '${min.toStringAsFixed(1)} $unit', Colors.green),
          _StatCard('Promedio', '${avg.toStringAsFixed(1)} $unit', Colors.blue),
          _StatCard('Máximo', '${max.toStringAsFixed(1)} $unit', Colors.red),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  String _formatDuration(Duration d) => '${d.inMinutes}m ${d.inSeconds % 60}s';
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[900])),
        ],
      );
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      );
}
