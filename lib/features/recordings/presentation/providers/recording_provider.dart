import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/recording_repository.dart';
import '../../domain/entities/recording.dart';

// ---------------------------------------------------------------------------
// Repositorio (singleton por sesión)
// ---------------------------------------------------------------------------
final recordingRepositoryProvider = Provider<RecordingRepository>((ref) {
  final repo = RecordingRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

// ---------------------------------------------------------------------------
// Lista de grabaciones — se recarga tras cada mutación
// ---------------------------------------------------------------------------
final recordingsListProvider =
    FutureProvider.autoDispose<List<Recording>>((ref) async {
  final repo = ref.watch(recordingRepositoryProvider);
  final recordings = await repo.getAllRecordings();
  // Más recientes primero
  return recordings..sort((a, b) => b.startTime.compareTo(a.startTime));
});

// ---------------------------------------------------------------------------
// Estado de la grabación en curso (nombre + hora de inicio)
// ---------------------------------------------------------------------------
class RecordingState {
  final bool isRecording;
  final String? name;
  final DateTime? startTime;

  const RecordingState({
    this.isRecording = false,
    this.name,
    this.startTime,
  });

  RecordingState copyWith({bool? isRecording, String? name, DateTime? startTime}) =>
      RecordingState(
        isRecording: isRecording ?? this.isRecording,
        name: name ?? this.name,
        startTime: startTime ?? this.startTime,
      );
}

class RecordingNotifier extends Notifier<RecordingState> {
  @override
  RecordingState build() => const RecordingState();

  void markStarted(String name) => state = RecordingState(
        isRecording: true,
        name: name,
        startTime: DateTime.now(),
      );

  void markStopped() => state = const RecordingState();
}

final recordingStateProvider =
    NotifierProvider<RecordingNotifier, RecordingState>(RecordingNotifier.new);
