import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class CarBody3DSimple extends StatefulWidget {
  final bool showFactoryModel;
  final bool showActualModel;

  const CarBody3DSimple({
    super.key,
    this.showFactoryModel = true,
    this.showActualModel = true,
  });

  @override
  State<CarBody3DSimple> createState() => _CarBody3DSimpleState();
}

class _CarBody3DSimpleState extends State<CarBody3DSimple> {
  double _rotationX = -0.3;
  double _rotationY = 0.5;
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
                      _scale = (_scale - event.scrollDelta.dy * 0.001).clamp(0.5, 3.0);
                    });
                  }
                },
                child: CustomPaint(
                  size: Size.infinite,
                  painter: CubePainter(
                    showFactoryModel: widget.showFactoryModel,
                    showActualModel: widget.showActualModel,
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
                    Text('3D Кабина', style: Theme.of(context).textTheme.labelSmall),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restart_alt),
                          onPressed: () {
                            setState(() {
                              _rotationX = -0.3;
                              _rotationY = 0.5;
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

class CubePainter extends CustomPainter {
  final bool showFactoryModel;
  final bool showActualModel;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final double scale;

  CubePainter({
    required this.showFactoryModel,
    required this.showActualModel,
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

    // Рисуем оси координат
    _drawAxes(canvas, matrix);

    // Размер куба
    const cubeSize = 100.0;

    // Рисуем заводской куб (синий)
    if (showFactoryModel) {
      _drawCube(
        canvas,
        matrix,
        vm.Vector3(-120, 0, 0), // Позиция слева
        cubeSize,
        Colors.blue.withValues(alpha: 0.7),
        'Заводская модель',
      );
    }

    // Рисуем деформированный куб (красный)
    if (showActualModel) {
      _drawDeformedCube(
        canvas,
        matrix,
        vm.Vector3(120, 0, 0), // Позиция справа
        cubeSize,
        Colors.red.withValues(alpha: 0.7),
        'Деформированная',
      );
    }
  }

  void _drawAxes(Canvas canvas, Matrix4 matrix) {
    const axisLength = 200.0;
    
    // X axis - красный
    final origin = _project3D(vm.Vector3.zero(), matrix);
    final xEnd = _project3D(vm.Vector3(axisLength, 0, 0), matrix);
    canvas.drawLine(origin, xEnd, Paint()..color = Colors.red..strokeWidth = 2);

    // Y axis - зеленый
    final yEnd = _project3D(vm.Vector3(0, axisLength, 0), matrix);
    canvas.drawLine(origin, yEnd, Paint()..color = Colors.green..strokeWidth = 2);

    // Z axis - синий
    final zEnd = _project3D(vm.Vector3(0, 0, axisLength), matrix);
    canvas.drawLine(origin, zEnd, Paint()..color = Colors.blue..strokeWidth = 2);
  }

  void _drawCube(
    Canvas canvas,
    Matrix4 matrix,
    vm.Vector3 position,
    double size,
    Color color,
    String label,
  ) {
    // Вершины трапеции (имитация кабины)
    // Нижняя часть шире, верхняя уже (как лобовое стекло)
    final width = size;
    final height = size * 0.8;
    final depth = size * 1.5;
    const topNarrowing = 0.3; // Сужение верхней части
    
    final vertices = [
      // Нижние вершины (пол кабины)
      vm.Vector3(-width/2, -height/2, -depth/2) + position,
      vm.Vector3(width/2, -height/2, -depth/2) + position,
      vm.Vector3(width/2, -height/2, depth/2) + position,
      vm.Vector3(-width/2, -height/2, depth/2) + position,
      // Верхние вершины (крыша кабины) - сужены спереди
      vm.Vector3(-width/2 * (1-topNarrowing), height/2, -depth/2) + position,
      vm.Vector3(width/2 * (1-topNarrowing), height/2, -depth/2) + position,
      vm.Vector3(width/2, height/2, depth/2) + position,
      vm.Vector3(-width/2, height/2, depth/2) + position,
    ];

    // Проецируем вершины
    final projectedVertices = vertices.map((v) => _project3D(v, matrix)).toList();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color.withValues(alpha: 1.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Рисуем грани трапеции
    // Нижняя грань (пол)
    _drawFace(canvas, [projectedVertices[0], projectedVertices[1], projectedVertices[2], projectedVertices[3]], paint, strokePaint);
    // Верхняя грань (крыша)
    _drawFace(canvas, [projectedVertices[4], projectedVertices[5], projectedVertices[6], projectedVertices[7]], paint, strokePaint);
    // Передняя грань (лобовое стекло - трапеция)
    _drawFace(canvas, [projectedVertices[0], projectedVertices[1], projectedVertices[5], projectedVertices[4]], paint, strokePaint);
    // Задняя грань (заднее стекло)
    _drawFace(canvas, [projectedVertices[3], projectedVertices[2], projectedVertices[6], projectedVertices[7]], paint, strokePaint);
    // Левая грань
    _drawFace(canvas, [projectedVertices[0], projectedVertices[3], projectedVertices[7], projectedVertices[4]], paint, strokePaint);
    // Правая грань
    _drawFace(canvas, [projectedVertices[1], projectedVertices[2], projectedVertices[6], projectedVertices[5]], paint, strokePaint);

    // Рисуем подпись
    final centerPoint = _project3D(position + vm.Vector3(0, -size/2 - 30, 0), matrix);
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color.withValues(alpha: 1.0),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, centerPoint - Offset(textPainter.width / 2, 0));
  }

  void _drawDeformedCube(
    Canvas canvas,
    Matrix4 matrix,
    vm.Vector3 position,
    double size,
    Color color,
    String label,
  ) {
    // Вершины деформированной трапеции (имитация поврежденной кабины)
    final width = size;
    final height = size * 0.8;
    final depth = size * 1.5;
    const topNarrowing = 0.3;
    
    // Деформации имитируют типичные повреждения после ДТП
    final vertices = [
      // Нижние вершины (деформированный пол)
      vm.Vector3(-width/2 * 0.9, -height/2, -depth/2 * 0.95) + position,
      vm.Vector3(width/2 * 1.05, -height/2, -depth/2 * 0.95) + position,
      vm.Vector3(width/2 * 1.1, -height/2, depth/2) + position,
      vm.Vector3(-width/2 * 0.95, -height/2, depth/2) + position,
      // Верхние вершины (деформированная крыша) - сильнее сужены и смещены
      vm.Vector3(-width/2 * (1-topNarrowing) * 0.85, height/2 * 0.9, -depth/2 * 0.9) + position,
      vm.Vector3(width/2 * (1-topNarrowing) * 1.1, height/2 * 0.9, -depth/2 * 0.9) + position,
      vm.Vector3(width/2 * 1.15, height/2 * 0.85, depth/2) + position,
      vm.Vector3(-width/2 * 0.9, height/2 * 0.85, depth/2) + position,
    ];

    // Проецируем вершины
    final projectedVertices = vertices.map((v) => _project3D(v, matrix)).toList();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color.withValues(alpha: 1.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Рисуем грани деформированной трапеции
    // Нижняя грань (деформированный пол)
    _drawFace(canvas, [projectedVertices[0], projectedVertices[1], projectedVertices[2], projectedVertices[3]], paint, strokePaint);
    // Верхняя грань (деформированная крыша)
    _drawFace(canvas, [projectedVertices[4], projectedVertices[5], projectedVertices[6], projectedVertices[7]], paint, strokePaint);
    // Передняя грань (деформированное лобовое стекло)
    _drawFace(canvas, [projectedVertices[0], projectedVertices[1], projectedVertices[5], projectedVertices[4]], paint, strokePaint);
    // Задняя грань 
    _drawFace(canvas, [projectedVertices[3], projectedVertices[2], projectedVertices[6], projectedVertices[7]], paint, strokePaint);
    // Левая грань
    _drawFace(canvas, [projectedVertices[0], projectedVertices[3], projectedVertices[7], projectedVertices[4]], paint, strokePaint);
    // Правая грань
    _drawFace(canvas, [projectedVertices[1], projectedVertices[2], projectedVertices[6], projectedVertices[5]], paint, strokePaint);

    // Рисуем подпись
    final centerPoint = _project3D(position + vm.Vector3(0, -size/2 - 30, 0), matrix);
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color.withValues(alpha: 1.0),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, centerPoint - Offset(textPainter.width / 2, 0));
  }

  void _drawFace(Canvas canvas, List<Offset> vertices, Paint fillPaint, Paint strokePaint) {
    final path = Path()
      ..moveTo(vertices[0].dx, vertices[0].dy);
    
    for (int i = 1; i < vertices.length; i++) {
      path.lineTo(vertices[i].dx, vertices[i].dy);
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  Offset _project3D(vm.Vector3 point, Matrix4 matrix) {
    final transformed = matrix.transform3(point);
    // Простая перспективная проекция
    const perspective = 800.0;
    final scale = perspective / (perspective + transformed.z);
    return Offset(
      transformed.x * scale,
      transformed.y * scale,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}