import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class CarUnderbody3D extends StatefulWidget {
  final bool showMeasurements;
  final bool showLabels;

  const CarUnderbody3D({
    super.key,
    this.showMeasurements = true,
    this.showLabels = true,
  });

  @override
  State<CarUnderbody3D> createState() => _CarUnderbody3DState();
}

class _CarUnderbody3DState extends State<CarUnderbody3D> {
  double _rotationX = -0.8; // Наклон для лучшего обзора
  double _rotationY = 0.5;
  double _rotationZ = 0.0;
  double _scale = 0.8;
  
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
                  painter: UnderbodyPainter(
                    showMeasurements: widget.showMeasurements,
                    showLabels: widget.showLabels,
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
                    Text('Нижняя часть кузова', style: Theme.of(context).textTheme.labelSmall),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restart_alt),
                          onPressed: () {
                            setState(() {
                              _rotationX = -0.8;
                              _rotationY = 0.5;
                              _rotationZ = 0.0;
                              _scale = 0.8;
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

class UnderbodyPainter extends CustomPainter {
  final bool showMeasurements;
  final bool showLabels;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final double scale;

  UnderbodyPainter({
    required this.showMeasurements,
    required this.showLabels,
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

    // Определяем контрольные точки на основе схемы
    // Масштаб: 1 единица = 1 мм, но уменьшено в 2.5 раза для отображения
    const pointScale = 0.4;
    final points = <String, vm.Vector3>{
      // Передняя часть (подрамник) - ниже основного уровня
      'A': vm.Vector3(-590 * pointScale, 100, -1400 * pointScale),
      'B': vm.Vector3(590 * pointScale, 100, -1400 * pointScale),
      'C': vm.Vector3(-500 * pointScale, 80, -600 * pointScale),
      'D': vm.Vector3(-300 * pointScale, 80, -600 * pointScale),
      'E': vm.Vector3(500 * pointScale, 80, -600 * pointScale),
      'F': vm.Vector3(300 * pointScale, 80, -600 * pointScale),
      
      // Центральная часть (пол салона) - основной уровень
      'G': vm.Vector3(-350 * pointScale, 0, -200 * pointScale),
      'H': vm.Vector3(350 * pointScale, 0, -200 * pointScale),
      'I': vm.Vector3(-550 * pointScale, 20, 400 * pointScale),
      'J': vm.Vector3(550 * pointScale, 20, 400 * pointScale),
      
      // Задняя часть - приподнята
      'K': vm.Vector3(-430 * pointScale, 40, 650 * pointScale),
      'L': vm.Vector3(0, 40, 650 * pointScale),
      'M': vm.Vector3(430 * pointScale, 40, 650 * pointScale),
    };

    // Рисуем сетку основания
    _drawGroundGrid(canvas, matrix);

    // Рисуем оси
    _drawAxes(canvas, matrix);

    // Рисуем раму днища
    _drawUnderbodyFrame(canvas, matrix, points);

    // Рисуем контрольные точки
    _drawControlPoints(canvas, matrix, points);

    // Рисуем размеры
    if (showMeasurements) {
      _drawMeasurements(canvas, matrix, points);
    }
  }

  void _drawGroundGrid(Canvas canvas, Matrix4 matrix) {
    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const gridSize = 200.0;
    const gridCount = 10;

    for (int i = -gridCount; i <= gridCount; i++) {
      final x = i * gridSize;
      
      final start1 = _project3D(vm.Vector3(x, 50, -gridCount * gridSize), matrix);
      final end1 = _project3D(vm.Vector3(x, 50, gridCount * gridSize), matrix);
      canvas.drawLine(start1, end1, gridPaint);

      final start2 = _project3D(vm.Vector3(-gridCount * gridSize, 50, x), matrix);
      final end2 = _project3D(vm.Vector3(gridCount * gridSize, 50, x), matrix);
      canvas.drawLine(start2, end2, gridPaint);
    }
  }

  void _drawAxes(Canvas canvas, Matrix4 matrix) {
    const axisLength = 300.0;
    
    final origin = _project3D(vm.Vector3.zero(), matrix);
    
    // X axis - красный (ширина автомобиля)
    final xEnd = _project3D(vm.Vector3(axisLength, 0, 0), matrix);
    canvas.drawLine(origin, xEnd, Paint()..color = Colors.red..strokeWidth = 2);

    // Y axis - зеленый (высота)
    final yEnd = _project3D(vm.Vector3(0, -axisLength, 0), matrix);
    canvas.drawLine(origin, yEnd, Paint()..color = Colors.green..strokeWidth = 2);

    // Z axis - синий (длина автомобиля)
    final zEnd = _project3D(vm.Vector3(0, 0, axisLength), matrix);
    canvas.drawLine(origin, zEnd, Paint()..color = Colors.blue..strokeWidth = 2);
  }

  void _drawUnderbodyFrame(Canvas canvas, Matrix4 matrix, Map<String, vm.Vector3> points) {
    final framePaint = Paint()
      ..color = Colors.blue[700]!
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Левый лонжерон
    _drawBeam(canvas, matrix, points['A']!, points['C']!, framePaint);
    _drawBeam(canvas, matrix, points['C']!, points['G']!, framePaint);
    _drawBeam(canvas, matrix, points['G']!, points['I']!, framePaint);
    _drawBeam(canvas, matrix, points['I']!, points['K']!, framePaint);

    // Правый лонжерон
    _drawBeam(canvas, matrix, points['B']!, points['E']!, framePaint);
    _drawBeam(canvas, matrix, points['E']!, points['H']!, framePaint);
    _drawBeam(canvas, matrix, points['H']!, points['J']!, framePaint);
    _drawBeam(canvas, matrix, points['J']!, points['M']!, framePaint);

    // Поперечные связи
    _drawBeam(canvas, matrix, points['A']!, points['B']!, framePaint);
    _drawBeam(canvas, matrix, points['C']!, points['D']!, framePaint);
    _drawBeam(canvas, matrix, points['D']!, points['F']!, framePaint);
    _drawBeam(canvas, matrix, points['F']!, points['E']!, framePaint);
    _drawBeam(canvas, matrix, points['G']!, points['H']!, framePaint);
    _drawBeam(canvas, matrix, points['I']!, points['J']!, framePaint);
    _drawBeam(canvas, matrix, points['K']!, points['L']!, framePaint);
    _drawBeam(canvas, matrix, points['L']!, points['M']!, framePaint);

    // Диагональные усилители
    final diagonalPaint = Paint()
      ..color = Colors.blue[400]!
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    _drawBeam(canvas, matrix, points['C']!, points['F']!, diagonalPaint);
    _drawBeam(canvas, matrix, points['D']!, points['E']!, diagonalPaint);
    _drawBeam(canvas, matrix, points['G']!, points['J']!, diagonalPaint);
    _drawBeam(canvas, matrix, points['H']!, points['I']!, diagonalPaint);

    // Рисуем платформу (пол)
    _drawFloorPanel(canvas, matrix, [
      points['A']!, points['B']!, points['E']!, points['C']!
    ], fillPaint);
    
    _drawFloorPanel(canvas, matrix, [
      points['C']!, points['E']!, points['H']!, points['G']!
    ], fillPaint);
    
    _drawFloorPanel(canvas, matrix, [
      points['G']!, points['H']!, points['J']!, points['I']!
    ], fillPaint);
    
    _drawFloorPanel(canvas, matrix, [
      points['I']!, points['J']!, points['M']!, points['K']!
    ], fillPaint);
  }

  void _drawBeam(Canvas canvas, Matrix4 matrix, vm.Vector3 start, vm.Vector3 end, Paint paint) {
    // Рисуем балку как 3D коробку
    const width = 20.0;
    const height = 40.0;
    
    // Вычисляем направление балки
    final direction = (end - start).normalized();
    final up = vm.Vector3(0, -1, 0);
    final right = direction.cross(up).normalized() * (width / 2);
    final actualUp = right.cross(direction).normalized() * (height / 2);
    
    // 8 вершин балки
    final vertices = [
      start - right - actualUp,
      start + right - actualUp,
      start + right + actualUp,
      start - right + actualUp,
      end - right - actualUp,
      end + right - actualUp,
      end + right + actualUp,
      end - right + actualUp,
    ];
    
    // Проецируем вершины
    final projected = vertices.map((v) => _project3D(v, matrix)).toList();
    
    // Определяем видимые грани (простая проверка по Z) - не используется
    
    // Рисуем грани
    final fillPaint = Paint()
      ..color = paint.color.withValues(alpha: paint.color.a * 0.3)
      ..style = PaintingStyle.fill;
    
    // Нижняя грань
    _drawFace(canvas, [projected[0], projected[1], projected[5], projected[4]], fillPaint);
    // Верхняя грань
    _drawFace(canvas, [projected[3], projected[2], projected[6], projected[7]], fillPaint);
    // Боковые грани
    _drawFace(canvas, [projected[0], projected[3], projected[7], projected[4]], fillPaint);
    _drawFace(canvas, [projected[1], projected[2], projected[6], projected[5]], fillPaint);
    // Торцы
    _drawFace(canvas, [projected[0], projected[1], projected[2], projected[3]], fillPaint);
    _drawFace(canvas, [projected[4], projected[5], projected[6], projected[7]], fillPaint);
    
    // Рисуем контуры
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(projected[i], projected[(i + 1) % 4], paint);
      canvas.drawLine(projected[i + 4], projected[((i + 1) % 4) + 4], paint);
      canvas.drawLine(projected[i], projected[i + 4], paint);
    }
  }
  
  void _drawFace(Canvas canvas, List<Offset> points, Paint paint) {
    final path = Path()
      ..moveTo(points[0].dx, points[0].dy);
    
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }

  void _drawFloorPanel(Canvas canvas, Matrix4 matrix, List<vm.Vector3> vertices, Paint paint) {
    final path = Path();
    bool first = true;
    
    for (final vertex in vertices) {
      final projected = _project3D(vertex, matrix);
      if (first) {
        path.moveTo(projected.dx, projected.dy);
        first = false;
      } else {
        path.lineTo(projected.dx, projected.dy);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }

  void _drawControlPoints(Canvas canvas, Matrix4 matrix, Map<String, vm.Vector3> points) {
    points.forEach((label, point) {
      final projected = _project3D(point, matrix);
      
      // Рисуем точку
      final pointPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(projected, 8, pointPaint);
      
      // Рисуем обводку
      final strokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawCircle(projected, 8, strokePaint);
      
      // Рисуем метку
      if (showLabels) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, projected + const Offset(10, -10));
      }
    });
  }

  void _drawMeasurements(Canvas canvas, Matrix4 matrix, Map<String, vm.Vector3> points) {
    final measurePaint = Paint()
      ..color = Colors.orange[700]!
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Основные размеры из схемы
    _drawMeasurement(canvas, matrix, points['A']!, points['B']!, '1180', measurePaint);
    _drawMeasurement(canvas, matrix, points['C']!, points['E']!, '800', measurePaint);
    _drawMeasurement(canvas, matrix, points['G']!, points['H']!, '700', measurePaint);
    _drawMeasurement(canvas, matrix, points['I']!, points['J']!, '1100', measurePaint);
    _drawMeasurement(canvas, matrix, points['K']!, points['M']!, '860', measurePaint);
    
    // Продольные размеры
    _drawMeasurement(canvas, matrix, points['A']!, points['C']!, '800', measurePaint);
    _drawMeasurement(canvas, matrix, points['C']!, points['G']!, '400', measurePaint);
    _drawMeasurement(canvas, matrix, points['G']!, points['I']!, '600', measurePaint);
    _drawMeasurement(canvas, matrix, points['I']!, points['K']!, '250', measurePaint);
  }

  void _drawMeasurement(Canvas canvas, Matrix4 matrix, vm.Vector3 start, vm.Vector3 end, String value, Paint paint) {
    final p1 = _project3D(start, matrix);
    final p2 = _project3D(end, matrix);
    
    // Линия измерения
    canvas.drawLine(p1, p2, paint);
    
    // Засечки
    const tickSize = 10.0;
    final delta = p2 - p1;
    final length = delta.distance;
    final normalized = delta / length;
    final perpendicular = Offset(-normalized.dy, normalized.dx) * tickSize;
    
    canvas.drawLine(p1 - perpendicular / 2, p1 + perpendicular / 2, paint);
    canvas.drawLine(p2 - perpendicular / 2, p2 + perpendicular / 2, paint);
    
    // Текст с размером
    final midPoint = Offset(
      (p1.dx + p2.dx) / 2,
      (p1.dy + p2.dy) / 2,
    );
    
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