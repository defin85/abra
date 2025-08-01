import 'package:uuid/uuid.dart';
import 'package:vector_math/vector_math_64.dart';

class ControlPoint {
  final String id;
  final String name;
  final String code;
  final Vector3 position;
  final String? description;
  final PointType type;
  final List<String> connectedPointIds;

  ControlPoint({
    String? id,
    required this.name,
    required this.code,
    required this.position,
    this.description,
    this.type = PointType.reference,
    List<String>? connectedPointIds,
  })  : id = id ?? const Uuid().v4(),
        connectedPointIds = connectedPointIds ?? [];

  // Геттеры для координат
  double get x => position.x;
  double get y => position.y;
  double get z => position.z;

  // Пустая точка для случаев, когда точка не найдена
  factory ControlPoint.empty() {
    return ControlPoint(
      name: '',
      code: '',
      position: Vector3.zero(),
    );
  }

  ControlPoint copyWith({
    String? name,
    String? code,
    Vector3? position,
    String? description,
    PointType? type,
    List<String>? connectedPointIds,
  }) {
    return ControlPoint(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      position: position ?? this.position,
      description: description ?? this.description,
      type: type ?? this.type,
      connectedPointIds: connectedPointIds ?? this.connectedPointIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'position': {
          'x': position.x,
          'y': position.y,
          'z': position.z,
        },
        'description': description,
        'type': type.name,
        'connectedPointIds': connectedPointIds,
      };

  factory ControlPoint.fromJson(Map<String, dynamic> json) {
    return ControlPoint(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      position: Vector3(
        json['position']['x'].toDouble(),
        json['position']['y'].toDouble(),
        json['position']['z'].toDouble(),
      ),
      description: json['description'],
      type: PointType.values.firstWhere((e) => e.name == json['type']),
      connectedPointIds: List<String>.from(json['connectedPointIds'] ?? []),
    );
  }
}

enum PointType {
  reference,
  measurement,
  auxiliary,
}