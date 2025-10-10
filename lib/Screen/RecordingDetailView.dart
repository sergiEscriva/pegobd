import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:syncfusion_flutter_charts/charts.dart';

import '../features/obd/domain/entities/sensor.dart';
import '../model/Recording.dart';

class RecordingDetailView extends StatefulWidget {
  final Recording recording;
  final Recording? comparisonRecording;

  const RecordingDetailView({
    required this.recording,
    this.comparisonRecording,
  });

  @override
  State<RecordingDetailView> createState() => _RecordingDetailViewState();
}

class _RecordingDetailViewState extends State<RecordingDetailView> {
  String? _selectedSensorPid;

  @override
  void initState() {
    super.initState();
    if (widget.recording.sensorPids.isNotEmpty) {
      _selectedSensorPid = widget.recording.sensorPids.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recording.name),
        actions: [
          if (widget.comparisonRecording == null)
            IconButton(
              icon: Icon(Icons.compare_arrows),
              onPressed: _selectComparisonRecording,
              tooltip: 'Comparar con otra grabación',
            ),
          if (widget.comparisonRecording != null)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            RecordingDetailView(recording: widget.recording),
                  ),
                );
              },
              tooltip: 'Cerrar comparación',
            ),
        ],
      ),
      body: Column(
        children: [
          // Información de la grabación
          _buildRecordingInfo(),

          // Selector de sensor
          _buildSensorSelector(),

          // Gráfico
          Expanded(
            child:
                _selectedSensorPid != null
                    ? _buildChart()
                    : Center(child: Text('Selecciona un sensor')),
          ),

          // Estadísticas
          if (_selectedSensorPid != null) _buildStatistics(),
        ],
      ),
    );
  }

  Widget _buildRecordingInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.blue[100]!)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoChip(
                icon: Icons.calendar_today,
                label: _formatDate(widget.recording.startTime),
              ),
              _buildInfoChip(
                icon: Icons.access_time,
                label: _formatTime(widget.recording.startTime),
              ),
              _buildInfoChip(
                icon: Icons.timer,
                label: _formatDuration(widget.recording.duration),
              ),
            ],
          ),
          if (widget.comparisonRecording != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.compare_arrows,
                    size: 16,
                    color: Colors.orange[900],
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Comparando con: ${widget.comparisonRecording!.name}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[900],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.blue[700]),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.blue[900],
          ),
        ),
      ],
    );
  }

  Widget _buildSensorSelector() {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: widget.recording.sensorPids.length,
        itemBuilder: (context, index) {
          final pid = widget.recording.sensorPids[index];
          final isSelected = pid == _selectedSensorPid;

          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                ObdSensors.getSensorName(pid),
                style: TextStyle(fontSize: 12),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedSensorPid = pid;
                });
              },
              selectedColor: Colors.blue[700],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChart() {
    final data = widget.recording.data[_selectedSensorPid!] ?? [];
    final comparisonData =
        widget.comparisonRecording?.data[_selectedSensorPid!];

    if (data.isEmpty) {
      return Center(
        child: Text(
          'No hay datos para este sensor',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      child: SfCartesianChart(
        title: ChartTitle(
          text: ObdSensors.getSensorName(_selectedSensorPid!),
          textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        legend: Legend(
          isVisible: widget.comparisonRecording != null,
          position: LegendPosition.bottom,
        ),
        primaryXAxis: DateTimeAxis(
          labelStyle: TextStyle(fontSize: 10),
          dateFormat: intl.DateFormat('HH:mm:ss'),
        ),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: ObdSensors.getSensorUnit(_selectedSensorPid!)),
          labelStyle: TextStyle(fontSize: 10),
        ),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          format: 'point.y ${ObdSensors.getSensorUnit(_selectedSensorPid!)}',
        ),
        zoomPanBehavior: ZoomPanBehavior(
          enablePinching: true,
          enablePanning: true,
          zoomMode: ZoomMode.x,
        ),
        series: <CartesianSeries>[
          LineSeries<SensorDataPoint, DateTime>(
            name: widget.recording.name,
            dataSource: data,
            xValueMapper: (point, _) => point.timestamp,
            yValueMapper: (point, _) => point.value,
            color: Colors.blue[700],
            width: 2,
            markerSettings: MarkerSettings(isVisible: false),
          ),
          if (comparisonData != null && comparisonData.isNotEmpty)
            LineSeries<SensorDataPoint, DateTime>(
              name: widget.comparisonRecording!.name,
              dataSource: comparisonData,
              xValueMapper: (point, _) => point.timestamp,
              yValueMapper: (point, _) => point.value,
              color: Colors.orange[700],
              width: 2,
              dashArray: [5, 5],
              markerSettings: MarkerSettings(isVisible: false),
            ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final data = widget.recording.data[_selectedSensorPid!] ?? [];

    if (data.isEmpty) return SizedBox.shrink();

    final values = data.map((e) => e.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    final unit = ObdSensors.getSensorUnit(_selectedSensorPid!);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            'Mínimo',
            '${min.toStringAsFixed(1)} $unit',
            Colors.green,
          ),
          _buildStatCard(
            'Promedio',
            '${avg.toStringAsFixed(1)} $unit',
            Colors.blue,
          ),
          _buildStatCard(
            'Máximo',
            '${max.toStringAsFixed(1)} $unit',
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _selectComparisonRecording() async {
    // Navegar a una vista para seleccionar otra grabación
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Comparar grabaciones'),
            content: Text(
              'Esta funcionalidad abrirá la lista de grabaciones para seleccionar una y compararla.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}
