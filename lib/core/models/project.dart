import 'package:uuid/uuid.dart';
import 'car_model.dart';
import 'measurement.dart';

class Project {
  final String id;
  final String name;
  final String? description;
  final String carModelId;
  final CarModel? carModel;
  final String? vin;
  final String? plateNumber;
  final String? customerName;
  final String? insuranceClaimNumber;
  final List<Measurement> measurements;
  final ProjectStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  Project({
    String? id,
    required this.name,
    this.description,
    required this.carModelId,
    this.carModel,
    this.vin,
    this.plateNumber,
    this.customerName,
    this.insuranceClaimNumber,
    List<Measurement>? measurements,
    this.status = ProjectStatus.active,
    DateTime? createdAt,
    this.updatedAt,
    this.completedAt,
    this.metadata,
  })  : id = id ?? const Uuid().v4(),
        measurements = measurements ?? [],
        createdAt = createdAt ?? DateTime.now();

  double get completionProgress {
    if (measurements.isEmpty) return 0.0;
    final measuredCount = measurements.where((m) => m.actualValue != null).length;
    return measuredCount / measurements.length;
  }

  ProjectHealth get health {
    if (measurements.isEmpty) return ProjectHealth.unknown;
    
    final severities = measurements
        .where((m) => m.actualValue != null)
        .map((m) => m.severity)
        .toList();
    
    if (severities.any((s) => s == DeviationSeverity.severe)) {
      return ProjectHealth.poor;
    }
    if (severities.any((s) => s == DeviationSeverity.critical)) {
      return ProjectHealth.fair;
    }
    if (severities.any((s) => s == DeviationSeverity.warning)) {
      return ProjectHealth.good;
    }
    return ProjectHealth.excellent;
  }

  Project copyWith({
    String? name,
    String? description,
    String? carModelId,
    CarModel? carModel,
    String? vin,
    String? plateNumber,
    String? customerName,
    String? insuranceClaimNumber,
    List<Measurement>? measurements,
    ProjectStatus? status,
    DateTime? updatedAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      carModelId: carModelId ?? this.carModelId,
      carModel: carModel ?? this.carModel,
      vin: vin ?? this.vin,
      plateNumber: plateNumber ?? this.plateNumber,
      customerName: customerName ?? this.customerName,
      insuranceClaimNumber: insuranceClaimNumber ?? this.insuranceClaimNumber,
      measurements: measurements ?? this.measurements,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'carModelId': carModelId,
        'vin': vin,
        'plateNumber': plateNumber,
        'customerName': customerName,
        'insuranceClaimNumber': insuranceClaimNumber,
        'measurements': measurements.map((m) => m.toJson()).toList(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'metadata': metadata,
      };

  factory Project.fromJson(Map<String, dynamic> json, {CarModel? carModel}) {
    return Project(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      carModelId: json['carModelId'],
      carModel: carModel,
      vin: json['vin'],
      plateNumber: json['plateNumber'],
      customerName: json['customerName'],
      insuranceClaimNumber: json['insuranceClaimNumber'],
      measurements: (json['measurements'] as List)
          .map((m) => Measurement.fromJson(m))
          .toList(),
      status: ProjectStatus.values.firstWhere((e) => e.name == json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      metadata: json['metadata'],
    );
  }
}

enum ProjectStatus {
  active,
  completed,
  archived,
}

enum ProjectHealth {
  unknown,
  excellent,
  good,
  fair,
  poor,
}