import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import '../../../core/geometry/adaptive_chassis.dart';

enum CameraMode { orbital, free, testCube }

class AdaptiveChassisPainter extends CustomPainter {
  final bool showMeasurements;
  final bool showLabels;
  final bool showDeformed;
  final bool showAxes;
  final bool useCurvedElements;
  final CameraMode cameraMode;
  // Орбитальная камера
  final double azimuth;
  final double elevation;
  final double distance;
  final vm.Vector3 target;
  
  // Центр экрана для проекции
  late Offset screenCenter;
  // Свободная камера
  final vm.Vector3 freeCameraPosition;
  final double freeCameraPitch;
  final double freeCameraYaw;
  final double freeCameraRoll;
  // Углы поворота каркаса в свободном режиме
  final double chassisRotationX;
  final double chassisRotationY;
  final double chassisRotationZ;
  final AdaptiveChassis factoryChassis;
  final AdaptiveChassis? deformedChassis;
  // Параметры тестовой камеры
  final double testAzimuth;
  final double testElevation;
  final int testUpVector;

  AdaptiveChassisPainter({
    required this.showMeasurements,
    required this.showLabels,
    required this.showDeformed,
    required this.showAxes,
    required this.useCurvedElements,
    required this.cameraMode,
    required this.azimuth,
    required this.elevation,
    required this.distance,
    required this.target,
    required this.freeCameraPosition,
    required this.freeCameraPitch,
    required this.freeCameraYaw,
    required this.freeCameraRoll,
    required this.chassisRotationX,
    required this.chassisRotationY,
    required this.chassisRotationZ,
    required this.factoryChassis,
    this.deformedChassis,
    required this.testAzimuth,
    required this.testElevation,
    required this.testUpVector,
  });

  @override
  void paint(Canvas canvas, Size size) {
    screenCenter = Offset(size.width / 2, size.height / 2);
    
    // Выбираем матрицу трансформации в зависимости от режима камеры
    final Matrix4 matrix;
    if (cameraMode == CameraMode.testCube) {
      // Тестовый режим - простая орбитальная камера с фиксированными параметрами
      matrix = _createTestCubeCamera(screenCenter);
    } else if (cameraMode == CameraMode.orbital) {
      matrix = _createOrbitCamera(screenCenter);
    } else {
      // Свободная камера (полёт в пространстве)
      matrix = _createFreeCamera(screenCenter);
    }
    
    if (cameraMode == CameraMode.testCube) {
      // Рисуем только тестовый куб и оси
      _drawAxes(canvas, matrix);
      _drawTestCube(canvas, matrix);
      return;
    }
    
    // Теперь геометрия AdaptiveChassis использует стандартную систему координат
    // X=длина, Y=ширина, Z=высота - базовые повороты не нужны
    final objectMatrix = Matrix4.identity();
    
    // В свободном режиме добавляем вращение каркаса
    if (cameraMode == CameraMode.free) {
      objectMatrix
        ..rotateX(chassisRotationX)
        ..rotateY(chassisRotationY)
        ..rotateZ(chassisRotationZ);
    }
    
    final finalMatrix = matrix * objectMatrix;

    // Рисуем оси координат (если включены)
    if (showAxes) {
      _drawAxes(canvas, matrix);
    }

    // Рисуем заводской каркас (с поворотом)
    _drawChassis(canvas, finalMatrix, factoryChassis, false);

    // Рисуем деформированный каркас (если включен)
    if (showDeformed && deformedChassis != null) {
      _drawChassis(canvas, finalMatrix, deformedChassis!, true);
    }

    // Рисуем контрольные точки (если включены)
    if (showLabels) {
      _drawControlPoints(canvas, finalMatrix, factoryChassis);
    }

    // Рисуем измерения (если включены)
    if (showMeasurements) {
      _drawMeasurements(canvas, finalMatrix, factoryChassis);
    }
  }

  void _drawAxes(Canvas canvas, Matrix4 matrix) {
    const axisLength = 200.0;
    
    final origin = _project3D(vm.Vector3.zero(), matrix);
    
    // Автомобильная система координат:
    // X - продольная ось (вперед/назад) - красный
    final xEnd = _project3D(vm.Vector3(axisLength, 0, 0), matrix);
    canvas.drawLine(origin, xEnd, Paint()..color = Colors.red..strokeWidth = 2);
    _drawAxisLabel(canvas, xEnd, 'X', Colors.red);
    
    // Y - поперечная ось (влево/вправо) - зеленый
    final yEnd = _project3D(vm.Vector3(0, axisLength, 0), matrix);
    canvas.drawLine(origin, yEnd, Paint()..color = Colors.green..strokeWidth = 2);
    _drawAxisLabel(canvas, yEnd, 'Y', Colors.green);
    
    // Z - вертикальная ось (вверх/вниз) - синий
    final zEnd = _project3D(vm.Vector3(0, 0, axisLength), matrix);
    canvas.drawLine(origin, zEnd, Paint()..color = Colors.blue..strokeWidth = 2);
    _drawAxisLabel(canvas, zEnd, 'Z', Colors.blue);
  }

  void _drawAxisLabel(Canvas canvas, Offset position, String label, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  void _drawTestCube(Canvas canvas, Matrix4 matrix) {
    const size = 50.0;
    
    // Вершины куба
    final vertices = [
      vm.Vector3(-size/2, -size/2, -size/2), // 0
      vm.Vector3(size/2, -size/2, -size/2),  // 1
      vm.Vector3(size/2, size/2, -size/2),   // 2
      vm.Vector3(-size/2, size/2, -size/2),  // 3
      vm.Vector3(-size/2, -size/2, size/2),  // 4
      vm.Vector3(size/2, -size/2, size/2),   // 5
      vm.Vector3(size/2, size/2, size/2),    // 6
      vm.Vector3(-size/2, size/2, size/2),   // 7
    ];
    
    // Проецируем вершины
    final projected = vertices.map((v) => _project3D(v, matrix)).toList();
    
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Рисуем рёбра куба
    // Нижняя грань
    canvas.drawLine(projected[0], projected[1], paint);
    canvas.drawLine(projected[1], projected[2], paint);
    canvas.drawLine(projected[2], projected[3], paint);
    canvas.drawLine(projected[3], projected[0], paint);
    
    // Верхняя грань
    canvas.drawLine(projected[4], projected[5], paint);
    canvas.drawLine(projected[5], projected[6], paint);
    canvas.drawLine(projected[6], projected[7], paint);
    canvas.drawLine(projected[7], projected[4], paint);
    
    // Вертикальные рёбра
    canvas.drawLine(projected[0], projected[4], paint);
    canvas.drawLine(projected[1], projected[5], paint);
    canvas.drawLine(projected[2], projected[6], paint);
    canvas.drawLine(projected[3], projected[7], paint);
  }

  // Добавьте остальные методы рисования из оригинального файла...
  
  Matrix4 _createOrbitCamera(Offset screenCenter) {
    // Создаем матрицу камеры для орбитального режима
    final matrix = Matrix4.identity();
    
    // Перемещение в центр экрана
    matrix.translate(screenCenter.dx, screenCenter.dy, 0.0);
    
    // Применяем перспективу
    const perspective = 0.001;
    matrix.setEntry(3, 2, -perspective);
    
    // Отодвигаем камеру на расстояние
    matrix.translate(0.0, 0.0, -distance);
    
    // Вращение вокруг X (элевация)
    matrix.rotateX(elevation);
    
    // Вращение вокруг Y (азимут)
    matrix.rotateY(azimuth);
    
    // Смещение к цели
    matrix.translate(-target.x, -target.y, -target.z);
    
    return matrix;
  }

  Matrix4 _createFreeCamera(Offset screenCenter) {
    // Создаем матрицу свободной камеры
    final matrix = Matrix4.identity();
    
    // Перемещение в центр экрана
    matrix.translate(screenCenter.dx, screenCenter.dy, 0.0);
    
    // Применяем перспективу
    const perspective = 0.001;
    matrix.setEntry(3, 2, -perspective);
    
    // Применяем вращения камеры в обратном порядке
    matrix.rotateZ(freeCameraRoll);
    matrix.rotateX(freeCameraPitch);
    matrix.rotateY(freeCameraYaw);
    
    // Перемещаем мир относительно камеры (инвертированная позиция)
    matrix.translate(-freeCameraPosition.x, -freeCameraPosition.y, -freeCameraPosition.z);
    
    return matrix;
  }

  Matrix4 _createTestCubeCamera(Offset screenCenter) {
    // Простая орбитальная камера для тестового куба
    final matrix = Matrix4.identity();
    
    // Перемещение в центр экрана
    matrix.translate(screenCenter.dx, screenCenter.dy, 0.0);
    
    // Применяем перспективу
    const perspective = 0.001;
    matrix.setEntry(3, 2, -perspective);
    
    // Фиксированное расстояние для тестового куба
    const testDistance = 300.0;
    matrix.translate(0.0, 0.0, -testDistance);
    
    // Вращение вокруг X (элевация)
    matrix.rotateX(testElevation);
    
    // Вращение вокруг Y (азимут)
    matrix.rotateY(testAzimuth);
    
    return matrix;
  }

  Offset _project3D(vm.Vector3 point, Matrix4 matrix) {
    final transformed = matrix.transform3(point);
    
    // Применяем перспективную проекцию
    if (transformed.z != 0) {
      final scale = 1000 / (1000 + transformed.z);
      return Offset(transformed.x * scale, transformed.y * scale);
    }
    
    return Offset(transformed.x, transformed.y);
  }

  void _drawChassis(Canvas canvas, Matrix4 matrix, AdaptiveChassis chassis, bool isDeformed) {
    final elements = useCurvedElements 
      ? chassis.generateChassisElementsWithCurves()
      : chassis.generateChassisElements();
    
    for (final element in elements) {
      final paint = _getPaintForFrameType(element.type, isDeformed);
      _drawChassisElement(canvas, matrix, element, paint);
    }
  }

  Paint _getPaintForFrameType(FrameType type, bool isDeformed) {
    Color color;
    double strokeWidth = 3.0;
    
    switch (type) {
      case FrameType.subframe:
        color = Colors.green[700]!;  // Передние лонжероны
        break;
      case FrameType.rearLongeron:
        color = Colors.blue[700]!;   // Задние лонжероны
        break;
      case FrameType.sill:
        color = Colors.red[700]!;    // Пороги
        break;
      case FrameType.tunnel:
        color = Colors.indigo[600]!; // Тоннель (тёмно-синий)
        strokeWidth = 2.5;
        break;
      case FrameType.crossMember:
        color = Colors.grey[600]!;   // Поперечины
        strokeWidth = 2.0;
        break;
    }
    
    if (isDeformed) {
      color = color.withValues(alpha: 0.6);
      strokeWidth *= 0.8;
    }
    
    return Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
  }

  void _drawChassisElement(Canvas canvas, Matrix4 matrix, ChassisElement element, Paint paint) {
    // Если есть кастомный путь, рисуем простую кривую линию
    if (element.customPath != null && element.customPath!.length > 1) {
      final path = element.customPath!;
      
      // Проецируем все точки пути
      final projectedPath = path.map((v) => _project3D(v, matrix)).toList();
      
      // Рисуем простую кривую толстой линией
      final curvePaint = Paint()
        ..color = paint.color
        ..strokeWidth = paint.strokeWidth + 2
        ..style = PaintingStyle.stroke;
      
      // Соединяем все точки линиями
      for (int i = 0; i < projectedPath.length - 1; i++) {
        canvas.drawLine(projectedPath[i], projectedPath[i + 1], curvePaint);
      }
      
      // Добавляем маленькие кружки на точках кривой для наглядности
      final pointPaint = Paint()
        ..color = paint.color.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      
      for (final point in projectedPath) {
        canvas.drawCircle(point, 3, pointPaint);
      }
    } else {
      // Стандартная отрисовка коробки
      final vertices = element.generateVertices();
      final edges = element.getEdges();
      final projectedVertices = vertices.map((v) => _project3D(v, matrix)).toList();
      
      // Рисуем все рёбра коробки
      for (final edge in edges) {
        final p1 = projectedVertices[edge[0]];
        final p2 = projectedVertices[edge[1]];
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  void _drawControlPoints(Canvas canvas, Matrix4 matrix, AdaptiveChassis chassis) {
    final controlPoints = chassis.generateControlPoints();
    
    controlPoints.forEach((label, point) {
      final projected = _project3D(point, matrix);
      
      // Точка
      final pointPaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(projected, 6, pointPaint);
      
      // Обводка
      final strokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawCircle(projected, 6, strokePaint);
      
      // Метка
      if (showLabels) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, projected + const Offset(8, -8));
      }
    });
  }

  void _drawMeasurements(Canvas canvas, Matrix4 matrix, AdaptiveChassis chassis) {
    final measurePaint = Paint()
      ..color = Colors.orange[700]!
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final controlPoints = chassis.generateControlPoints();
    
    // Основные измерения
    _drawMeasurement(canvas, matrix, controlPoints['A']!, controlPoints['B']!, 
                    '${(chassis.trackWidth * 0.8).toInt()}', measurePaint);
    _drawMeasurement(canvas, matrix, controlPoints['C']!, controlPoints['E']!, 
                    '${chassis.trackWidth.toInt()}', measurePaint);
    _drawMeasurement(canvas, matrix, controlPoints['G']!, controlPoints['H']!, 
                    '${chassis.trackWidth.toInt()}', measurePaint);
    _drawMeasurement(canvas, matrix, controlPoints['I']!, controlPoints['J']!, 
                    '${chassis.trackWidth.toInt()}', measurePaint);
    _drawMeasurement(canvas, matrix, controlPoints['K']!, controlPoints['M']!, 
                    '${chassis.trackWidth.toInt()}', measurePaint);
  }

  void _drawMeasurement(Canvas canvas, Matrix4 matrix, vm.Vector3 start, vm.Vector3 end, 
                        String value, Paint paint) {
    final p1 = _project3D(start, matrix);
    final p2 = _project3D(end, matrix);
    
    canvas.drawLine(p1, p2, paint);
    
    final midPoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$value мм',
        style: TextStyle(
          color: Colors.orange[700],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white.withValues(alpha: 0.9),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, midPoint - Offset(textPainter.width / 2, textPainter.height / 2));
  }


  @override
  bool shouldRepaint(covariant AdaptiveChassisPainter oldDelegate) {
    return showMeasurements != oldDelegate.showMeasurements ||
        showLabels != oldDelegate.showLabels ||
        showDeformed != oldDelegate.showDeformed ||
        showAxes != oldDelegate.showAxes ||
        useCurvedElements != oldDelegate.useCurvedElements ||
        cameraMode != oldDelegate.cameraMode ||
        azimuth != oldDelegate.azimuth ||
        elevation != oldDelegate.elevation ||
        distance != oldDelegate.distance ||
        target != oldDelegate.target ||
        freeCameraPosition != oldDelegate.freeCameraPosition ||
        freeCameraPitch != oldDelegate.freeCameraPitch ||
        freeCameraYaw != oldDelegate.freeCameraYaw ||
        freeCameraRoll != oldDelegate.freeCameraRoll ||
        chassisRotationX != oldDelegate.chassisRotationX ||
        chassisRotationY != oldDelegate.chassisRotationY ||
        chassisRotationZ != oldDelegate.chassisRotationZ ||
        testAzimuth != oldDelegate.testAzimuth ||
        testElevation != oldDelegate.testElevation ||
        testUpVector != oldDelegate.testUpVector ||
        factoryChassis != oldDelegate.factoryChassis ||
        deformedChassis != oldDelegate.deformedChassis;
  }
}