import 'package:uuid/uuid.dart';

class Measurement {
  final String id;
  final String projectId;
  final String fromPointId;
  final String toPointId;
  final double factoryValue;
  final double? actualValue;
  final MeasurementType type;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;

  Measurement({
    String? id,
    required this.projectId,
    required this.fromPointId,
    required this.toPointId,
    required this.factoryValue,
    this.actualValue,
    this.type = MeasurementType.linear,
    DateTime? createdAt,
    this.updatedAt,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get deviation => actualValue != null ? actualValue! - factoryValue : 0;

  double get deviationPercent =>
      actualValue != null ? (deviation / factoryValue) * 100 : 0;

  bool get isWithinTolerance => deviation.abs() <= tolerance;

  double get tolerance {
    switch (type) {
      case MeasurementType.linear:
        return 3.0; // ±3mm
      case MeasurementType.diagonal:
        return 5.0; // ±5mm
      case MeasurementType.height:
        return 2.0; // ±2mm
      case MeasurementType.width:
        return 3.0; // ±3mm
      case MeasurementType.length:
        return 3.0; // ±3mm
      case MeasurementType.reference:
        return 2.0; // ±2mm
    }
  }

  DeviationSeverity get severity {
    if (actualValue == null) return DeviationSeverity.normal;
    
    final absDeviationPercent = deviationPercent.abs();

    if (absDeviationPercent < 2.0) return DeviationSeverity.normal;
    if (absDeviationPercent < 5.0) return DeviationSeverity.warning;
    if (absDeviationPercent < 10.0) return DeviationSeverity.critical;
    return DeviationSeverity.severe;
  }

  Measurement copyWith({
    String? projectId,
    String? fromPointId,
    String? toPointId,
    double? factoryValue,
    double? actualValue,
    MeasurementType? type,
    DateTime? updatedAt,
    String? notes,
  }) {
    return Measurement(
      id: id,
      projectId: projectId ?? this.projectId,
      fromPointId: fromPointId ?? this.fromPointId,
      toPointId: toPointId ?? this.toPointId,
      factoryValue: factoryValue ?? this.factoryValue,
      actualValue: actualValue ?? this.actualValue,
      type: type ?? this.type,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'fromPointId': fromPointId,
        'toPointId': toPointId,
        'factoryValue': factoryValue,
        'actualValue': actualValue,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'notes': notes,
      };

  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
      id: json['id'],
      projectId: json['projectId'],
      fromPointId: json['fromPointId'],
      toPointId: json['toPointId'],
      factoryValue: json['factoryValue'].toDouble(),
      actualValue: json['actualValue']?.toDouble(),
      type: MeasurementType.values.firstWhere((e) => e.name == json['type']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      notes: json['notes'],
    );
  }
}

enum MeasurementType {
  linear,
  diagonal,
  height,
  width,
  length,
  reference,
}

enum DeviationSeverity {
  normal,
  warning,
  critical,
  severe,
}