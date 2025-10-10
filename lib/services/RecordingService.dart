import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../features/dashboard/domain/entities/sensor_data.dart';
import '../model/Recording.dart';

class RecordingService {
  static const String _recordingsKey = 'recordings_list';

  bool _isRecording = false;
  DateTime? _recordingStartTime;
  String? _currentRecordingId;
  String? _currentRecordingName;
  List<String>? _recordingSensorPids;
  Map<String, List<SensorDataPoint>> _recordingData = {};

  StreamSubscription? _sensorSubscription;

  bool get isRecording => _isRecording;

  String? get currentRecordingName => _currentRecordingName;

  DateTime? get recordingStartTime => _recordingStartTime;

  /// Inicia una nueva grabación
  void startRecording({
    required String name,
    required List<String> sensorPids,
    required Stream<Map<String, SensorData>> sensorStream,
  }) {
    if (_isRecording) {
      throw Exception('Ya hay una grabación en curso');
    }

    _isRecording = true;
    _currentRecordingId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentRecordingName = name;
    _recordingStartTime = DateTime.now();
    _recordingSensorPids = sensorPids;
    _recordingData.clear();

    // Inicializar listas para cada sensor
    for (String pid in sensorPids) {
      _recordingData[pid] = [];
    }

    // Escuchar cambios en los sensores
    _sensorSubscription = sensorStream.listen((sensorsData) {
      if (!_isRecording) return;

      final now = DateTime.now();

      for (String pid in sensorPids) {
        if (sensorsData.containsKey(pid)) {
          final sensor = sensorsData[pid]!;
          final value = double.tryParse(sensor.value);

          if (value != null) {
            _recordingData[pid]?.add(
              SensorDataPoint(timestamp: now, value: value),
            );
          }
        }
      }
    });

    print('📹 Grabación iniciada: $name');
  }

  /// Detiene la grabación actual y la guarda
  Future<Recording?> stopRecording() async {
    if (!_isRecording) return null;

    _isRecording = false;
    _sensorSubscription?.cancel();

    final recording = Recording(
      id: _currentRecordingId!,
      name: _currentRecordingName!,
      startTime: _recordingStartTime!,
      endTime: DateTime.now(),
      sensorPids: _recordingSensorPids!,
      data: Map.from(_recordingData),
    );

    await _saveRecording(recording);

    // Limpiar
    _currentRecordingId = null;
    _currentRecordingName = null;
    _recordingStartTime = null;
    _recordingSensorPids = null;
    _recordingData.clear();

    print('⏹️ Grabación detenida y guardada: ${recording.name}');

    return recording;
  }

  /// Guarda una grabación en SharedPreferences
  Future<void> _saveRecording(Recording recording) async {
    final prefs = await SharedPreferences.getInstance();

    // Obtener grabaciones existentes
    final recordings = await getAllRecordings();
    recordings.add(recording);

    // Guardar lista actualizada
    final recordingsJson =
        recordings.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_recordingsKey, recordingsJson);
  }

  /// Obtiene todas las grabaciones guardadas
  Future<List<Recording>> getAllRecordings() async {
    final prefs = await SharedPreferences.getInstance();
    final recordingsJson = prefs.getStringList(_recordingsKey) ?? [];

    return recordingsJson
        .map((json) {
          try {
            return Recording.fromJson(jsonDecode(json));
          } catch (e) {
            print('Error al cargar grabación: $e');
            return null;
          }
        })
        .whereType<Recording>()
        .toList();
  }

  /// Elimina una grabación
  Future<void> deleteRecording(String recordingId) async {
    final prefs = await SharedPreferences.getInstance();
    final recordings = await getAllRecordings();

    recordings.removeWhere((r) => r.id == recordingId);

    final recordingsJson =
        recordings.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_recordingsKey, recordingsJson);
  }

  /// Renombra una grabación
  Future<void> renameRecording(String recordingId, String newName) async {
    final recordings = await getAllRecordings();
    final index = recordings.indexWhere((r) => r.id == recordingId);

    if (index != -1) {
      final oldRecording = recordings[index];
      recordings[index] = Recording(
        id: oldRecording.id,
        name: newName,
        startTime: oldRecording.startTime,
        endTime: oldRecording.endTime,
        sensorPids: oldRecording.sensorPids,
        data: oldRecording.data,
      );

      final prefs = await SharedPreferences.getInstance();
      final recordingsJson =
          recordings.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_recordingsKey, recordingsJson);
    }
  }

  /// Limpia todos los datos de la grabación actual si se cancela
  void cancelRecording() {
    if (_isRecording) {
      _isRecording = false;
      _sensorSubscription?.cancel();
      _currentRecordingId = null;
      _currentRecordingName = null;
      _recordingStartTime = null;
      _recordingSensorPids = null;
      _recordingData.clear();
      print('❌ Grabación cancelada');
    }
  }

  void dispose() {
    _sensorSubscription?.cancel();
  }
}
