class Recording {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> sensorPids;
  final Map<String, List<SensorDataPoint>> data;

  Recording({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.sensorPids,
    required this.data,
  });

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'sensorPids': sensorPids,
        'data': data.map(
          (key, value) =>
              MapEntry(key, value.map((p) => p.toJson()).toList()),
        ),
      };

  factory Recording.fromJson(Map<String, dynamic> json) => Recording(
        id: json['id'] as String,
        name: json['name'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        sensorPids: List<String>.from(json['sensorPids'] as List),
        data: (json['data'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(
            key,
            (value as List)
                .map((p) => SensorDataPoint.fromJson(p as Map<String, dynamic>))
                .toList(),
          ),
        ),
      );
}

class SensorDataPoint {
  final DateTime timestamp;
  final double value;

  const SensorDataPoint({required this.timestamp, required this.value});

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'value': value,
      };

  factory SensorDataPoint.fromJson(Map<String, dynamic> json) =>
      SensorDataPoint(
        timestamp: DateTime.parse(json['timestamp'] as String),
        value: (json['value'] as num).toDouble(),
      );
}
