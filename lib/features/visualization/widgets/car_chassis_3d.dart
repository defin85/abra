import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class CarChassis3D extends StatefulWidget {
  final bool showMeasurements;
  final bool showLabels;
  final bool showDeformed;

  const CarChassis3D({
    super.key,
    this.showMeasurements = true,
    this.showLabels = true,
    this.showDeformed = false,
  });

  @override
  State<CarChassis3D> createState() => _CarChassis3DState();
}

class _CarChassis3DState extends State<CarChassis3D> {
  double _rotationX = -0.6;
  double _rotationY = 0.4;
  double _rotationZ = 0.0;
  double _scale = 1.0;
  
  Offset? _lastPanPosition;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[300]!,
            Colors.grey[100]!,
          ],
        ),
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          GestureDetector(
            onPanStart: (details) {
              setState(() {
                _lastPanPosition = details.localPosition;
              });
            },
            onPanUpdate: (details) {
              if (_lastPanPosition != null) {
                final delta = details.localPosition - _lastPanPosition!;
                setState(() {
                  _rotationY += delta.dx * 0.01;
                  _rotationX -= delta.dy * 0.01;
                  _lastPanPosition = details.localPosition;
                });
              }
            },
            child: MouseRegion(
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    setState(() {
                      _scale = (_scale - event.scrollDelta.dy * 0.001).clamp(0.3, 2.0);
                    });
                  }
                },
                child: CustomPaint(
                  size: Size.infinite,
                  painter: ChassisPainter(
                    showMeasurements: widget.showMeasurements,
                    showLabels: widget.showLabels,
                    showDeformed: widget.showDeformed,
                    rotationX: _rotationX,
                    rotationY: _rotationY,
                    rotationZ: _rotationZ,
                    scale: _scale,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text('Силовой каркас', style: Theme.of(context).textTheme.labelSmall),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restart_alt),
                          onPressed: () {
                            setState(() {
                              _rotationX = -0.6;
                              _rotationY = 0.4;
                              _rotationZ = 0.0;
                              _scale = 1.0;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChassisPainter extends CustomPainter {
  final bool showMeasurements;
  final bool showLabels;
  final bool showDeformed;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final double scale;

  ChassisPainter({
    required this.showMeasurements,
    required this.showLabels,
    required this.showDeformed,
    required this.rotationX,
    required this.rotationY,
    required this.rotationZ,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Матрица трансформации
    final matrix = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..scale(scale, scale, scale)
      ..rotateX(rotationX)
      ..rotateY(rotationY)
      ..rotateZ(rotationZ);

    // Масштаб для координат
    // Реальные размеры каркаса: длина ~4-5м, ширина ~1.5-2м, высота ~0.3-0.5м
    // Масштаб преобразует миллиметры в экранные единицы
    const s = 0.1; // 1мм = 0.1 экранных единиц
    
    // Высота порогов относительно пола
    const floorHeight = 0.0;
    const sillHeight = 50.0; // Уменьшаем высоту для реалистичности
    
    // Определяем структуру каркаса
    // Реальные размеры в мм: ширина ~1800мм, длина ~4500мм
    // Левый порог (от центра 900мм)
    final leftSillFront = vm.Vector3(-900 * s, sillHeight, -1500 * s);  // X: -900мм, Z: -1500мм
    final leftSillCenter = vm.Vector3(-900 * s, sillHeight, 0);
    final leftSillRear = vm.Vector3(-900 * s, sillHeight, 1500 * s);   // X: -900мм, Z: 1500мм
    
    // Правый порог (от центра 900мм)
    final rightSillFront = vm.Vector3(900 * s, sillHeight, -1500 * s); // X: 900мм, Z: -1500мм
    final rightSillCenter = vm.Vector3(900 * s, sillHeight, 0);
    final rightSillRear = vm.Vector3(900 * s, sillHeight, 1500 * s);   // X: 900мм, Z: 1500мм
    
    // Контрольные точки на порогах
    final pointC = vm.Vector3(-900 * s, sillHeight, -1000 * s);
    final pointE = vm.Vector3(900 * s, sillHeight, -1000 * s);
    final pointI = vm.Vector3(-900 * s, sillHeight, 1000 * s);
    final pointJ = vm.Vector3(900 * s, sillHeight, 1000 * s);
    
    // Точки на самых задних концах порогов
    final pointK = leftSillRear;
    final pointL = vm.Vector3(0, sillHeight, 1500 * s);
    final pointM = rightSillRear;
    
    // Передний подрамник (уже порогов)
    final frontLeft = vm.Vector3(-700 * s, floorHeight + 40, -2000 * s);
    final frontRight = vm.Vector3(700 * s, floorHeight + 40, -2000 * s);
    
    // Задняя часть - закомментируем пока
    // final rearLeft = vm.Vector3(-450 * s, floorHeight + 60, 1000 * s);
    // final rearCenter = vm.Vector3(0, floorHeight + 60, 1000 * s);
    // final rearRight = vm.Vector3(450 * s, floorHeight + 60, 1000 * s);
    
    // Центральный тоннель
    final tunnelFront = vm.Vector3(0, floorHeight + 60, -1000 * s);
    final tunnelCenter = vm.Vector3(0, floorHeight + 60, 0);
    final tunnelRear = vm.Vector3(0, floorHeight + 60, 1000 * s);
    
    // Поперечины (не используются)


    // Рисуем оси
    _drawAxes(canvas, matrix);

    // Рисуем каркас - разные цвета для разных частей
    final frontPaint = Paint()  // Зеленый для передней части
      ..color = Colors.green[700]!
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
      
    final middlePaint = Paint()  // Красный для средней части (пол)
      ..color = Colors.red[700]!
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
      
    // rearPaint не используется

    // ПЕРЕДНЯЯ ЧАСТЬ (ЗЕЛЕНЫЙ)
    // Передний подрамник
    _drawBox(canvas, matrix, frontLeft, frontRight, 50, 50, frontPaint);
    _drawBox(canvas, matrix, frontLeft, leftSillFront, 40, 40, frontPaint);
    _drawBox(canvas, matrix, frontRight, rightSillFront, 40, 40, frontPaint);
    
    // Передняя поперечина
    _drawBox(canvas, matrix, leftSillFront, rightSillFront, 30, 40, frontPaint);
    
    // СРЕДНЯЯ ЧАСТЬ - ПОЛ (КРАСНЫЙ)
    // Пороги
    // Левый порог (передняя половина)
    _drawBox(canvas, matrix, leftSillFront, leftSillCenter, 40, 60, middlePaint);
    // Правый порог (передняя половина)
    _drawBox(canvas, matrix, rightSillFront, rightSillCenter, 40, 60, middlePaint);
    // Средняя поперечина
    _drawBox(canvas, matrix, leftSillCenter, rightSillCenter, 30, 40, middlePaint);
    
    // Левый порог (задняя половина)
    _drawBox(canvas, matrix, leftSillCenter, leftSillRear, 40, 60, middlePaint);
    // Правый порог (задняя половина)
    _drawBox(canvas, matrix, rightSillCenter, rightSillRear, 40, 60, middlePaint);
    // Задняя поперечина
    _drawBox(canvas, matrix, leftSillRear, rightSillRear, 30, 40, middlePaint);
    
    // Центральный тоннель (тоже часть пола - красный)
    _drawBox(canvas, matrix, tunnelFront, tunnelCenter, 80, 80, middlePaint);
    _drawBox(canvas, matrix, tunnelCenter, tunnelRear, 80, 80, middlePaint);
    
    // Диагональные усилители (цвета по секциям)
    _drawSimpleBeam(canvas, matrix, leftSillFront, tunnelFront, middlePaint);
    _drawSimpleBeam(canvas, matrix, rightSillFront, tunnelFront, middlePaint);
    _drawSimpleBeam(canvas, matrix, leftSillCenter, tunnelCenter, middlePaint);
    _drawSimpleBeam(canvas, matrix, rightSillCenter, tunnelCenter, middlePaint);
    
    // Задняя часть (синий) - закомментируем задние лонжероны
    // _drawBox(canvas, matrix, leftSillRear, rearLeft, 40, 40, rearPaint);
    // _drawBox(canvas, matrix, rightSillRear, rearRight, 40, 40, rearPaint);
    // _drawBox(canvas, matrix, rearLeft, rearCenter, 30, 30, rearPaint);
    // _drawBox(canvas, matrix, rearCenter, rearRight, 30, 30, rearPaint);
    
    // Дополнительные усилители в задней части
    // _drawSimpleBeam(canvas, matrix, tunnelRear, rearCenter, rearPaint);
    
    // Панель пола (полупрозрачная) - убираем, так как она создает визуальные артефакты

    // Рисуем размеры
    if (showMeasurements) {
      final measurePaint = Paint()
        ..color = Colors.orange[700]!
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      // Используем точки на самом каркасе, а не контрольные точки
      _drawMeasurement(canvas, matrix, frontLeft, frontRight, '1400', measurePaint);
      _drawMeasurement(canvas, matrix, leftSillFront, rightSillFront, '1800', measurePaint);
      _drawMeasurement(canvas, matrix, leftSillRear, rightSillRear, '1800', measurePaint);
      // _drawMeasurement(canvas, matrix, rearLeft, rearRight, '900', measurePaint);
    }
    
    // Рисуем контрольные точки в последнюю очередь, чтобы они были поверх всего
    // Рисуем каждую точку отдельно для отладки
    // Оранжевый цвет для всех точек для лучшей видимости
    // Точки A и B должны быть на переднем подрамнике
    _drawSinglePoint(canvas, matrix, frontLeft, 'A', Colors.orange);
    _drawSinglePoint(canvas, matrix, frontRight, 'B', Colors.orange);
    _drawSinglePoint(canvas, matrix, pointC, 'C', Colors.orange);
    _drawSinglePoint(canvas, matrix, vm.Vector3(-450 * s, sillHeight, -1000 * s), 'D', Colors.orange);
    _drawSinglePoint(canvas, matrix, pointE, 'E', Colors.orange);
    _drawSinglePoint(canvas, matrix, vm.Vector3(450 * s, sillHeight, -1000 * s), 'F', Colors.orange);
    // Точки G и H должны быть на центре порогов
    _drawSinglePoint(canvas, matrix, leftSillCenter, 'G', Colors.orange);
    _drawSinglePoint(canvas, matrix, rightSillCenter, 'H', Colors.orange);
    _drawSinglePoint(canvas, matrix, pointI, 'I', Colors.orange);
    _drawSinglePoint(canvas, matrix, pointJ, 'J', Colors.orange);
    // Точки на задних концах
    _drawSinglePoint(canvas, matrix, pointK, 'K', Colors.orange);
    _drawSinglePoint(canvas, matrix, pointL, 'L', Colors.orange);
    _drawSinglePoint(canvas, matrix, pointM, 'M', Colors.orange);
  }

  void _drawAxes(Canvas canvas, Matrix4 matrix) {
    const axisLength = 200.0;
    
    final origin = _project3D(vm.Vector3.zero(), matrix);
    
    // X axis - красный
    final xEnd = _project3D(vm.Vector3(axisLength, 0, 0), matrix);
    canvas.drawLine(origin, xEnd, Paint()..color = Colors.red..strokeWidth = 2);

    // Y axis - зеленый
    final yEnd = _project3D(vm.Vector3(0, -axisLength, 0), matrix);
    canvas.drawLine(origin, yEnd, Paint()..color = Colors.green..strokeWidth = 2);

    // Z axis - синий
    final zEnd = _project3D(vm.Vector3(0, 0, axisLength), matrix);
    canvas.drawLine(origin, zEnd, Paint()..color = Colors.blue..strokeWidth = 2);
  }

  void _drawBox(Canvas canvas, Matrix4 matrix, vm.Vector3 start, vm.Vector3 end, 
                double width, double height, Paint paint) {
    final direction = (end - start).normalized();
    final up = vm.Vector3(0, -1, 0);
    final right = direction.cross(up).normalized() * (width / 2);
    final actualUp = vm.Vector3(0, -height / 2, 0);
    
    // 8 вершин коробки
    final vertices = [
      start - right + actualUp,
      start + right + actualUp,
      start + right - actualUp,
      start - right - actualUp,
      end - right + actualUp,
      end + right + actualUp,
      end + right - actualUp,
      end - right - actualUp,
    ];
    
    // Проецируем и рисуем
    final projected = vertices.map((v) => _project3D(v, matrix)).toList();
    
    // Рисуем все ребра
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(projected[i], projected[(i + 1) % 4], paint);
      canvas.drawLine(projected[i + 4], projected[((i + 1) % 4) + 4], paint);
      canvas.drawLine(projected[i], projected[i + 4], paint);
    }
  }

  void _drawSimpleBeam(Canvas canvas, Matrix4 matrix, vm.Vector3 start, vm.Vector3 end, Paint paint) {
    final p1 = _project3D(start, matrix);
    final p2 = _project3D(end, matrix);
    canvas.drawLine(p1, p2, paint);
  }

  // void _drawFloor(Canvas canvas, Matrix4 matrix, List<vm.Vector3> corners, Paint paint) {
  //   // Метод не используется
  // }

  void _drawSinglePoint(Canvas canvas, Matrix4 matrix, vm.Vector3 point, String label, Color color) {
    final projected = _project3D(point, matrix);
    
    // Точка
    final pointPaint = Paint()
      ..color = color
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
  }

  // void _drawControlPoints(Canvas canvas, Matrix4 matrix, Map<String, vm.Vector3> points) {
  //   // Метод не используется
  // }

  // Метод больше не используется, так как мы рисуем размеры напрямую
  // void _drawMeasurements(Canvas canvas, Matrix4 matrix, Map<String, vm.Vector3> points) {
  //   ...
  // }

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

  Offset _project3D(vm.Vector3 point, Matrix4 matrix) {
    final transformed = matrix.transform3(point);
    const perspective = 1000.0;
    final scale = perspective / (perspective + transformed.z);
    return Offset(
      transformed.x * scale,
      transformed.y * scale,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}