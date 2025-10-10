import 'package:flutter/material.dart';

import '../model/Recording.dart';
import '../services/RecordingService.dart';
import 'RecordingDetailView.dart';

class RecordingsListView extends StatefulWidget {
  final RecordingService recordingService;

  const RecordingsListView({required this.recordingService});

  @override
  State<RecordingsListView> createState() => _RecordingsListViewState();
}

class _RecordingsListViewState extends State<RecordingsListView> {
  List<Recording> _recordings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    setState(() => _isLoading = true);
    final recordings = await widget.recordingService.getAllRecordings();
    setState(() {
      _recordings =
          recordings..sort((a, b) => b.startTime.compareTo(a.startTime));
      _isLoading = false;
    });
  }

  Future<void> _deleteRecording(Recording recording) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Eliminar grabación'),
            content: Text(
              '¿Estás seguro de que deseas eliminar "${recording.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await widget.recordingService.deleteRecording(recording.id);
      _loadRecordings();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Grabación eliminada')));
      }
    }
  }

  Future<void> _renameRecording(Recording recording) async {
    final controller = TextEditingController(text: recording.name);

    final newName = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Renombrar grabación'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nuevo nombre',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: Text('Guardar'),
              ),
            ],
          ),
    );

    if (newName != null && newName.isNotEmpty && newName != recording.name) {
      await widget.recordingService.renameRecording(recording.id, newName);
      _loadRecordings();
    }
  }

  void _openRecordingDetail(Recording recording) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordingDetailView(recording: recording),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grabaciones'),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadRecordings),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _recordings.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _recordings.length,
                itemBuilder: (context, index) {
                  final recording = _recordings[index];
                  return _buildRecordingCard(recording);
                },
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            'No hay grabaciones',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Inicia una grabación desde el dashboard',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingCard(Recording recording) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openRecordingDetail(recording),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.videocam,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recording.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatDateTime(recording.startTime),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename') {
                        _renameRecording(recording);
                      } else if (value == 'delete') {
                        _deleteRecording(recording);
                      }
                    },
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Renombrar'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Eliminar',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    icon: Icons.timer,
                    label: 'Duración',
                    value: _formatDuration(recording.duration),
                  ),
                  _buildStat(
                    icon: Icons.sensors,
                    label: 'Sensores',
                    value: '${recording.sensorPids.length}',
                  ),
                  _buildStat(
                    icon: Icons.data_usage,
                    label: 'Puntos',
                    value: _getTotalDataPoints(recording).toString(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blue[700]),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  int _getTotalDataPoints(Recording recording) {
    int total = 0;
    recording.data.forEach((key, value) {
      total += value.length;
    });
    return total;
  }
}
