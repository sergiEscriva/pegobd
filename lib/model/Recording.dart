class Recording {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> sensorPids;
  final Map<String, List<SensorDataPoint>> data; // PID -> Lista de puntos

  Recording({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.sensorPids,
    required this.data,
  });

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'sensorPids': sensorPids,
      'data': data.map((key, value) =>
          MapEntry(
            key,
            value.map((point) => point.toJson()).toList(),
          )),
    };
  }

  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id'],
      name: json['name'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      sensorPids: List<String>.from(json['sensorPids']),
      data: (json['data'] as Map<String, dynamic>).map(
            (key, value) =>
            MapEntry(
              key,
              (value as List)
                  .map((point) => SensorDataPoint.fromJson(point))
                  .toList(),
            ),
      ),
    );
  }
}

class SensorDataPoint {
  final DateTime timestamp;
  final double value;

  SensorDataPoint({
    required this.timestamp,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'value': value,
    };
  }

  factory SensorDataPoint.fromJson(Map<String, dynamic> json) {
    return SensorDataPoint(
      timestamp: DateTime.parse(json['timestamp']),
      value: json['value'],
    );
  }
}
