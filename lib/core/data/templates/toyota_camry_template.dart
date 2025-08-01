import 'package:vector_math/vector_math_64.dart';
import '../../models/car_model.dart';
import '../../models/control_point.dart';

class ToyotaCamryTemplate {
  static CarModel createTemplate() {
    final controlPoints = <ControlPoint>[];

    // Подрамник подвески (из изображения 0001.jpg)
    controlPoints.addAll([
      ControlPoint(
        name: 'Передний подрамник A слева',
        code: 'A-a',
        position: Vector3(-520, -700, -400),
        type: PointType.reference,
      ),
      ControlPoint(
        name: 'Передний подрамник A справа',
        code: 'A-b',
        position: Vector3(520, -700, -400),
        type: PointType.reference,
      ),
      ControlPoint(
        name: 'Передний подрамник B слева',
        code: 'B-a',
        position: Vector3(-658, -879, -450),
        type: PointType.reference,
      ),
      ControlPoint(
        name: 'Передний подрамник B справа',
        code: 'B-b',
        position: Vector3(658, -879, -450),
        type: PointType.reference,
      ),
      ControlPoint(
        name: 'Передний подрамник C слева',
        code: 'C-c',
        position: Vector3(-676, -945, -500),
        type: PointType.reference,
      ),
      ControlPoint(
        name: 'Передний подрамник C справа',
        code: 'C-d',
        position: Vector3(676, -945, -500),
        type: PointType.reference,
      ),
    ]);

    // Нижняя часть кузова (из изображения 0002.jpg)
    controlPoints.addAll([
      ControlPoint(
        name: 'Передняя часть G',
        code: 'G',
        position: Vector3(0, -1186, -300),
        type: PointType.reference,
      ),
      ControlPoint(
        name: 'Передняя часть D',
        code: 'D',
        position: Vector3(0, -734, -200),
        type: PointType.reference,
      ),
      ControlPoint(
        name: 'Центр кузова H',
        code: 'H',
        position: Vector3(-430, -322, -100),
        type: PointType.reference,
      ),
      ControlPoint(
        name: 'Центр кузова J',
        code: 'J',
        position: Vector3(430, -322, -100),
        type: PointType.reference,
      ),
      ControlPoint(
        name: 'Задняя часть K',
        code: 'K',
        position: Vector3(-567, 656, -200),
        type: PointType.reference,
      ),
      ControlPoint(
        name: 'Задняя часть L',
        code: 'L',
        position: Vector3(567, 656, -200),
        type: PointType.reference,
      ),
    ]);

    // Задняя часть кузова (из изображения 0003.jpg)
    controlPoints.addAll([
      ControlPoint(
        name: 'Задний бампер A',
        code: 'ZA',
        position: Vector3(-724, 1859, -300),
        type: PointType.reference,
      ),
      ControlPoint(
        name: 'Задний бампер B',
        code: 'ZB',
        position: Vector3(724, 1859, -300),
        type: PointType.reference,
      ),
      ControlPoint(
        name: 'Багажник C',
        code: 'ZC',
        position: Vector3(-587, 1485, 100),
        type: PointType.reference,
      ),
      ControlPoint(
        name: 'Багажник D',
        code: 'ZD',
        position: Vector3(587, 1485, 100),
        type: PointType.reference,
      ),
    ]);

    // Проемы дверей (из изображений 0004.jpg и 0005.jpg)
    controlPoints.addAll([
      // Передняя дверь
      ControlPoint(
        name: 'Передняя дверь верх',
        code: 'PD-A',
        position: Vector3(-747, 100, 400),
        type: PointType.measurement,
      ),
      ControlPoint(
        name: 'Передняя дверь низ',
        code: 'PD-B',
        position: Vector3(-683, 100, -200),
        type: PointType.measurement,
      ),
      // Задняя дверь
      ControlPoint(
        name: 'Задняя дверь верх',
        code: 'ZD-A',
        position: Vector3(-747, 600, 400),
        type: PointType.measurement,
      ),
      ControlPoint(
        name: 'Задняя дверь низ',
        code: 'ZD-B',
        position: Vector3(-683, 600, -200),
        type: PointType.measurement,
      ),
    ]);

    // Моторный отсек (из изображений 0006.jpg и 0007.jpg)
    controlPoints.addAll([
      ControlPoint(
        name: 'Стакан амортизатора левый',
        code: 'MO-A',
        position: Vector3(-706, -1532, 100),
        type: PointType.reference,
      ),
      ControlPoint(
        name: 'Стакан амортизатора правый',
        code: 'MO-B',
        position: Vector3(706, -1532, 100),
        type: PointType.reference,
      ),
      ControlPoint(
        name: 'Лонжерон передний левый',
        code: 'MO-C',
        position: Vector3(-588, -1657, -200),
        type: PointType.reference,
      ),
      ControlPoint(
        name: 'Лонжерон передний правый',
        code: 'MO-D',
        position: Vector3(588, -1657, -200),
        type: PointType.reference,
      ),
    ]);

    // Устанавливаем связи между точками
    _establishConnections(controlPoints);

    return CarModel(
      manufacturer: 'Toyota',
      model: 'Camry',
      year: '2018-2023',
      variant: 'XV70',
      controlPoints: controlPoints,
    );
  }

  static void _establishConnections(List<ControlPoint> points) {
    // Соединяем точки подрамника
    _connectPoints(points, 'A-a', 'A-b');
    _connectPoints(points, 'B-a', 'B-b');
    _connectPoints(points, 'C-c', 'C-d');
    _connectPoints(points, 'A-a', 'B-a');
    _connectPoints(points, 'A-b', 'B-b');
    _connectPoints(points, 'B-a', 'C-c');
    _connectPoints(points, 'B-b', 'C-d');

    // Соединяем точки кузова
    _connectPoints(points, 'G', 'D');
    _connectPoints(points, 'H', 'J');
    _connectPoints(points, 'K', 'L');
    _connectPoints(points, 'D', 'H');
    _connectPoints(points, 'D', 'J');
    _connectPoints(points, 'H', 'K');
    _connectPoints(points, 'J', 'L');

    // Соединяем заднюю часть
    _connectPoints(points, 'ZA', 'ZB');
    _connectPoints(points, 'ZC', 'ZD');
    _connectPoints(points, 'ZA', 'ZC');
    _connectPoints(points, 'ZB', 'ZD');

    // Соединяем проемы дверей
    _connectPoints(points, 'PD-A', 'PD-B');
    _connectPoints(points, 'ZD-A', 'ZD-B');
    _connectPoints(points, 'PD-A', 'ZD-A');
    _connectPoints(points, 'PD-B', 'ZD-B');

    // Соединяем моторный отсек
    _connectPoints(points, 'MO-A', 'MO-B');
    _connectPoints(points, 'MO-C', 'MO-D');
    _connectPoints(points, 'MO-A', 'MO-C');
    _connectPoints(points, 'MO-B', 'MO-D');

    // Соединяем моторный отсек с кузовом
    _connectPoints(points, 'MO-C', 'G');
    _connectPoints(points, 'MO-D', 'G');
    _connectPoints(points, 'MO-A', 'A-a');
    _connectPoints(points, 'MO-B', 'A-b');
    
    // Дополнительные соединения для лучшей визуализации каркаса
    _connectPoints(points, 'G', 'D');
    _connectPoints(points, 'D', 'H');
    _connectPoints(points, 'D', 'J');
    _connectPoints(points, 'H', 'K');
    _connectPoints(points, 'J', 'L');
    _connectPoints(points, 'K', 'ZA');
    _connectPoints(points, 'L', 'ZB');
    _connectPoints(points, 'ZA', 'ZC');
    _connectPoints(points, 'ZB', 'ZD');
  }

  static void _connectPoints(List<ControlPoint> points, String code1, String code2) {
    final point1 = points.firstWhere((p) => p.code == code1, orElse: () => points.first);
    final point2 = points.firstWhere((p) => p.code == code2, orElse: () => points.first);

    if (point1 != points.first && point2 != points.first) {
      if (!point1.connectedPointIds.contains(point2.id)) {
        point1.connectedPointIds.add(point2.id);
      }
      if (!point2.connectedPointIds.contains(point1.id)) {
        point2.connectedPointIds.add(point1.id);
      }
    }
  }

  static List<Map<String, dynamic>> getDefaultMeasurements() {
    return [
      // Подрамник подвески
      {'from': 'A-a', 'to': 'A-b', 'value': 700.0, 'type': 'linear'},
      {'from': 'B-a', 'to': 'B-b', 'value': 879.0, 'type': 'linear'},
      {'from': 'C-c', 'to': 'C-d', 'value': 945.0, 'type': 'linear'},
      {'from': 'A-a', 'to': 'B-a', 'value': 616.0, 'type': 'diagonal'},
      {'from': 'A-b', 'to': 'B-b', 'value': 616.0, 'type': 'diagonal'},

      // Нижняя часть кузова
      {'from': 'G', 'to': 'D', 'value': 734.0, 'type': 'linear'},
      {'from': 'H', 'to': 'J', 'value': 1093.0, 'type': 'linear'},
      {'from': 'K', 'to': 'L', 'value': 1203.0, 'type': 'linear'},
      {'from': 'D', 'to': 'H', 'value': 1007.0, 'type': 'diagonal'},
      {'from': 'D', 'to': 'J', 'value': 1007.0, 'type': 'diagonal'},

      // Задняя часть
      {'from': 'ZA', 'to': 'ZB', 'value': 1320.0, 'type': 'linear'},
      {'from': 'ZC', 'to': 'ZD', 'value': 1156.0, 'type': 'linear'},

      // Проемы дверей
      {'from': 'PD-A', 'to': 'PD-B', 'value': 1004.0, 'type': 'height'},
      {'from': 'ZD-A', 'to': 'ZD-B', 'value': 1080.0, 'type': 'height'},
      {'from': 'PD-A', 'to': 'ZD-A', 'value': 1141.0, 'type': 'linear'},

      // Моторный отсек
      {'from': 'MO-A', 'to': 'MO-B', 'value': 1345.0, 'type': 'linear'},
      {'from': 'MO-C', 'to': 'MO-D', 'value': 1078.0, 'type': 'linear'},
      {'from': 'MO-A', 'to': 'MO-C', 'value': 475.0, 'type': 'height'},
      {'from': 'MO-B', 'to': 'MO-D', 'value': 475.0, 'type': 'height'},
    ];
  }
}