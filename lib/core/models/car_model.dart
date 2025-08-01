import 'package:uuid/uuid.dart';
import 'control_point.dart';

class CarModel {
  final String id;
  final String manufacturer;
  final String model;
  final String? year;
  final String? variant;
  final List<ControlPoint> controlPoints;
  final List<CarSection> sections;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CarModel({
    String? id,
    required this.manufacturer,
    required this.model,
    this.year,
    this.variant,
    List<ControlPoint>? controlPoints,
    List<CarSection>? sections,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? const Uuid().v4(),
        controlPoints = controlPoints ?? [],
        sections = sections ?? _getDefaultSections(),
        createdAt = createdAt ?? DateTime.now();

  String get displayName => '$manufacturer $model ${year ?? ""} ${variant ?? ""}'.trim();

  static List<CarSection> _getDefaultSections() {
    return [
      CarSection(
        name: 'Моторный отсек',
        code: 'engine_bay',
        type: SectionType.engineBay,
      ),
      CarSection(
        name: 'Передняя часть',
        code: 'front',
        type: SectionType.front,
      ),
      CarSection(
        name: 'Задняя часть',
        code: 'rear',
        type: SectionType.rear,
      ),
      CarSection(
        name: 'Левая сторона',
        code: 'left_side',
        type: SectionType.leftSide,
      ),
      CarSection(
        name: 'Правая сторона',
        code: 'right_side',
        type: SectionType.rightSide,
      ),
      CarSection(
        name: 'Крыша',
        code: 'roof',
        type: SectionType.roof,
      ),
      CarSection(
        name: 'Днище',
        code: 'underbody',
        type: SectionType.underbody,
      ),
    ];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'manufacturer': manufacturer,
        'model': model,
        'year': year,
        'variant': variant,
        'controlPoints': controlPoints.map((cp) => cp.toJson()).toList(),
        'sections': sections.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      id: json['id'],
      manufacturer: json['manufacturer'],
      model: json['model'],
      year: json['year'],
      variant: json['variant'],
      controlPoints: (json['controlPoints'] as List)
          .map((cp) => ControlPoint.fromJson(cp))
          .toList(),
      sections: (json['sections'] as List)
          .map((s) => CarSection.fromJson(s))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}

class CarSection {
  final String id;
  final String name;
  final String code;
  final SectionType type;
  final List<String> pointIds;

  CarSection({
    String? id,
    required this.name,
    required this.code,
    required this.type,
    List<String>? pointIds,
  })  : id = id ?? const Uuid().v4(),
        pointIds = pointIds ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'type': type.name,
        'pointIds': pointIds,
      };

  factory CarSection.fromJson(Map<String, dynamic> json) {
    return CarSection(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      type: SectionType.values.firstWhere((e) => e.name == json['type']),
      pointIds: List<String>.from(json['pointIds'] ?? []),
    );
  }
}

enum SectionType {
  engineBay,
  front,
  rear,
  leftSide,
  rightSide,
  roof,
  underbody,
}