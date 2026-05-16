import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../dashboard/domain/entities/sensor_data.dart';
import '../../domain/entities/recording.dart';

/// Repositorio de grabaciones. Persiste en SharedPreferences.
/// (Candidato a migrar a SQLite/Drift en una fase posterior.)
class RecordingRepository {
  static const String _recordingsKey = 'recordings_list';

  bool _isRecording = false;
  DateTime? _recordingStartTime;
  String? _currentId;
  String? _currentName;
  List<String>? _sensorPids;
  Map<String, List<SensorDataPoint>> _buffer = {};
  StreamSubscription? _sensorSubscription;

  bool get isRecording => _isRecording;
  String? get currentRecordingName => _currentName;
  DateTime? get recordingStartTime => _recordingStartTime;

  // -------------------------------------------------------------------------
  // Grabar
  // -------------------------------------------------------------------------

  void startRecording({
    required String name,
    required List<String> sensorPids,
    required Stream<Map<String, SensorData>> sensorStream,
  }) {
    if (_isRecording) throw StateError('Ya hay una grabación en curso');

    _isRecording = true;
    _currentId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentName = name;
    _recordingStartTime = DateTime.now();
    _sensorPids = sensorPids;
    _buffer = {for (final pid in sensorPids) pid: []};

    _sensorSubscription = sensorStream.listen((data) {
      if (!_isRecording) return;
      final now = DateTime.now();
      for (final pid in sensorPids) {
        final value = double.tryParse(data[pid]?.value ?? '');
        if (value != null) {
          _buffer[pid]?.add(SensorDataPoint(timestamp: now, value: value));
        }
      }
    });
  }

  Future<Recording?> stopRecording() async {
    if (!_isRecording) return null;

    _isRecording = false;
    await _sensorSubscription?.cancel();

    final recording = Recording(
      id: _currentId!,
      name: _currentName!,
      startTime: _recordingStartTime!,
      endTime: DateTime.now(),
      sensorPids: List.from(_sensorPids!),
      data: Map.from(_buffer),
    );

    await _saveRecording(recording);
    _clearState();
    return recording;
  }

  void cancelRecording() {
    if (!_isRecording) return;
    _isRecording = false;
    _sensorSubscription?.cancel();
    _clearState();
  }

  void _clearState() {
    _currentId = null;
    _currentName = null;
    _recordingStartTime = null;
    _sensorPids = null;
    _buffer = {};
  }

  // -------------------------------------------------------------------------
  // CRUD en SharedPreferences
  // -------------------------------------------------------------------------

  Future<void> _saveRecording(Recording recording) async {
    final all = await getAllRecordings();
    all.add(recording);
    await _persist(all);
  }

  Future<List<Recording>> getAllRecordings() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_recordingsKey) ?? [];
    return rawList.map((raw) {
      try {
        return Recording.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<Recording>().toList();
  }

  Future<void> deleteRecording(String id) async {
    final all = await getAllRecordings()
      ..removeWhere((r) => r.id == id);
    await _persist(all);
  }

  Future<void> renameRecording(String id, String newName) async {
    final all = await getAllRecordings();
    final idx = all.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    final old = all[idx];
    all[idx] = Recording(
      id: old.id,
      name: newName,
      startTime: old.startTime,
      endTime: old.endTime,
      sensorPids: old.sensorPids,
      data: old.data,
    );
    await _persist(all);
  }

  Future<void> _persist(List<Recording> recordings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _recordingsKey,
      recordings.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  void dispose() => _sensorSubscription?.cancel();
}
