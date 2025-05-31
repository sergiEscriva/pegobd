// lib/model/SensorData.dart
class SensorData {
  final String name;
  final String value;
  final String unit;
  final String pid;
  final DateTime timestamp;

  SensorData({
    required this.name,
    required this.value,
    required this.unit,
    required this.pid,
    required this.timestamp,
  });
}