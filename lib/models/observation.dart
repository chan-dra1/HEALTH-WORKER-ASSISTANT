class Observation {
  final String id;
  final String patientId;
  final String type; // 'temperature', 'blood_pressure', 'weight'
  final double value;
  final String unit; // 'C', 'mmHg', 'kg'
  final DateTime recordedAt;
  final String recordedBy;
  final bool synced;

  Observation({
    required this.id,
    required this.patientId,
    required this.type,
    required this.value,
    required this.unit,
    required this.recordedBy,
    DateTime? recordedAt,
    this.synced = false,
  }) : recordedAt = recordedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'type': type,
        'value': value,
        'unit': unit,
        'recordedAt': recordedAt.toIso8601String(),
        'recordedBy': recordedBy,
        'synced': synced ? 1 : 0,
      };

  factory Observation.fromJson(Map<String, dynamic> json) => Observation(
        id: json['id'] as String,
        patientId: json['patientId'] as String,
        type: json['type'] as String,
        value: (json['value'] as num).toDouble(),
        unit: json['unit'] as String,
        recordedBy: json['recordedBy'] as String,
        recordedAt: DateTime.parse(json['recordedAt'] as String),
        synced: (json['synced'] as int) == 1,
      );
}
