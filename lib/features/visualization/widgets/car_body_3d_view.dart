import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../../../core/models/control_point.dart';
import '../../../core/models/measurement.dart';
import '../../../core/models/car_model.dart';

class CarBody3DView extends StatefulWidget {
  final CarModel carModel;
  final List<Measurement> measurements;
  final bool showFactoryModel;
  final bool showActualModel;
  final Function(ControlPoint)? onPointSelected;
  final String? selectedPointId;

  const CarBody3DView({
    super.key,
    required this.carModel,
    required this.measurements,
    this.showFactoryModel = true,
    this.showActualModel = true,
    this.onPointSelected,
    this.selectedPointId,
  });

  @override
  State<CarBody3DView> createState() => _CarBody3DViewState();
}

class _CarBody3DViewState extends State<CarBody3DView> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late TransformationController _transformationController;
  
  double _rotationX = -0.3;
  double _rotationY = 0.5;
  double _rotationZ = 0.0;
  double _scale = 2.0;
  
  Offset? _lastPanPosition;
  bool _isPanning = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

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
                _isPanning = true;
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
            onPanEnd: (details) {
              setState(() {
                _isPanning = false;
              });
            },
            child: MouseRegion(
              onHover: (event) {
                // Handle mouse hover for desktop
              },
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
                  painter: CarBody3DPainter(
                    carModel: widget.carModel,
                    measurements: widget.measurements,
                    showFactoryModel: widget.showFactoryModel,
                    showActualModel: widget.showActualModel,
                    selectedPointId: widget.selectedPointId,
                    rotationX: _rotationX,
                    rotationY: _rotationY,
                    rotationZ: _rotationZ,
                    scale: _scale,
                    onPointTap: widget.onPointSelected,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3D Вид',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.rotate_left),
                          onPressed: () {
                            setState(() {
                              _rotationY -= 0.2;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.rotate_right),
                          onPressed: () {
                            setState(() {
                              _rotationY += 0.2;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.zoom_in),
                          onPressed: () {
                            setState(() {
                              _scale = (_scale + 0.1).clamp(0.5, 3.0);
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.zoom_out),
                          onPressed: () {
                            setState(() {
                              _scale = (_scale - 0.1).clamp(0.5, 3.0);
                            });
                          },
                        ),
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
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 250,
                      child: CheckboxListTile(
                        dense: true,
                        title: const Text('Заводская модель'),
                        subtitle: const Text('Синий каркас', style: TextStyle(color: Colors.blue)),
                        value: widget.showFactoryModel,
                        onChanged: (value) {
                          // Обновление через родительский виджет
                        },
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: CheckboxListTile(
                        dense: true,
                        title: const Text('Фактическая модель'),
                        subtitle: const Text('Красный каркас', style: TextStyle(color: Colors.red)),
                        value: widget.showActualModel,
                        onChanged: (value) {
                          // Обновление через родительский виджет
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isPanning)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Используйте мышь для вращения модели',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CarBody3DPainter extends CustomPainter {
  final CarModel carModel;
  final List<Measurement> measurements;
  final bool showFactoryModel;
  final bool showActualModel;
  final String? selectedPointId;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final double scale;
  final Function(ControlPoint)? onPointTap;

  CarBody3DPainter({
    required this.carModel,
    required this.measurements,
    required this.showFactoryModel,
    required this.showActualModel,
    this.selectedPointId,
    required this.rotationX,
    required this.rotationY,
    required this.rotationZ,
    required this.scale,
    this.onPointTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Создаем матрицу трансформации
    final matrix = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..scale(scale * 0.8, scale * 0.8, scale * 0.8)
      ..rotateX(rotationX)
      ..rotateY(rotationY)
      ..rotateZ(rotationZ);

    // Рисуем плоскость земли
    _drawGroundPlane(canvas, size, matrix);

    // Рисуем оси координат
    _drawAxes(canvas, matrix);

    // Получаем все точки
    final points = carModel.controlPoints;

    // Рисуем заводскую модель
    if (showFactoryModel) {
      _draw3DModel(
        canvas,
        points,
        matrix,
        Colors.blue.withValues(alpha: 0.6),
        false,
      );
    }

    // Рисуем фактическую модель
    if (showActualModel) {
      _draw3DModel(
        canvas,
        points,
        matrix,
        Colors.red.withValues(alpha: 0.8),
        true,
      );
    }

    // Рисуем контрольные точки
    _drawControlPoints(canvas, points, matrix);
    
    // Рисуем размеры
    _drawMeasurements(canvas, points, matrix);
  }

  void _drawGroundPlane(Canvas canvas, Size size, Matrix4 matrix) {

    final gridPaint = Paint()
      ..color = Colors.grey[600]!.withValues(alpha: 0.2)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Создаем точки плоскости
    const gridSize = 200.0;
    const gridCount = 10;

    for (int i = -gridCount; i <= gridCount; i++) {
      final x = i * gridSize;
      
      // Горизонтальные линии
      final start1 = _project3DPoint(vm.Vector3(x, -gridCount * gridSize, -800), matrix);
      final end1 = _project3DPoint(vm.Vector3(x, gridCount * gridSize, -800), matrix);
      canvas.drawLine(start1, end1, gridPaint);

      // Вертикальные линии
      final start2 = _project3DPoint(vm.Vector3(-gridCount * gridSize, x, -800), matrix);
      final end2 = _project3DPoint(vm.Vector3(gridCount * gridSize, x, -800), matrix);
      canvas.drawLine(start2, end2, gridPaint);
    }
  }

  void _drawAxes(Canvas canvas, Matrix4 matrix) {
    const axisLength = 500.0;
    
    // X axis - красный
    final xStart = _project3DPoint(vm.Vector3.zero(), matrix);
    final xEnd = _project3DPoint(vm.Vector3(axisLength, 0, 0), matrix);
    canvas.drawLine(xStart, xEnd, Paint()..color = Colors.red..strokeWidth = 2);

    // Y axis - зеленый
    final yEnd = _project3DPoint(vm.Vector3(0, axisLength, 0), matrix);
    canvas.drawLine(xStart, yEnd, Paint()..color = Colors.green..strokeWidth = 2);

    // Z axis - синий
    final zEnd = _project3DPoint(vm.Vector3(0, 0, axisLength), matrix);
    canvas.drawLine(xStart, zEnd, Paint()..color = Colors.blue..strokeWidth = 2);
  }

  void _draw3DModel(
    Canvas canvas,
    List<ControlPoint> points,
    Matrix4 matrix,
    Color color,
    bool useActualMeasurements,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Группируем точки по секциям для создания поверхностей
    final sections = _groupPointsBySections(points);

    for (final section in sections) {
      final path = Path();
      bool first = true;

      for (final point in section) {
        var position = point.position;
        
        if (useActualMeasurements) {
          position = _applyDeformation(point, points, position);
        }

        final projected = _project3DPoint(position, matrix);
        
        if (first) {
          path.moveTo(projected.dx, projected.dy);
          first = false;
        } else {
          path.lineTo(projected.dx, projected.dy);
        }
      }

      if (section.length > 2) {
        path.close();
        canvas.drawPath(path, fillPaint);
      }
      canvas.drawPath(path, paint);
    }

    // Рисуем соединения между точками
    for (final point in points) {
      final fromPos = useActualMeasurements 
          ? _applyDeformation(point, points, point.position)
          : point.position;
      final fromProjected = _project3DPoint(fromPos, matrix);

      for (final connectedId in point.connectedPointIds) {
        final connectedPoint = points.firstWhere(
          (p) => p.id == connectedId,
          orElse: () => point,
        );

        if (connectedPoint != point) {
          final toPos = useActualMeasurements
              ? _applyDeformation(connectedPoint, points, connectedPoint.position)
              : connectedPoint.position;
          final toProjected = _project3DPoint(toPos, matrix);
          
          canvas.drawLine(fromProjected, toProjected, paint);
        }
      }
    }
  }

  List<List<ControlPoint>> _groupPointsBySections(List<ControlPoint> points) {
    // Группируем точки по логическим секциям кузова
    final sections = <List<ControlPoint>>[];
    
    // Моторный отсек
    sections.add(points.where((p) => p.code.startsWith('MO-')).toList());
    
    // Передняя часть
    sections.add(points.where((p) => 
      p.code.startsWith('A-') || 
      p.code.startsWith('B-') || 
      p.code.startsWith('C-')
    ).toList());
    
    // Двери
    sections.add(points.where((p) => 
      p.code.startsWith('PD-') || 
      p.code.startsWith('ZD-')
    ).toList());
    
    // Задняя часть
    sections.add(points.where((p) => p.code.startsWith('Z')).toList());
    
    return sections.where((s) => s.isNotEmpty).toList();
  }

  vm.Vector3 _applyDeformation(
    ControlPoint point,
    List<ControlPoint> allPoints,
    vm.Vector3 originalPosition,
  ) {
    // Находим все измерения, связанные с этой точкой
    final relatedMeasurements = measurements.where(
      (m) => m.fromPointId == point.id || m.toPointId == point.id,
    );

    if (relatedMeasurements.isEmpty || relatedMeasurements.every((m) => m.actualValue == null)) {
      return originalPosition;
    }

    // Применяем деформацию на основе измерений
    var deformedPosition = originalPosition.clone();
    
    for (final measurement in relatedMeasurements) {
      if (measurement.actualValue != null) {
        final otherPointId = measurement.fromPointId == point.id 
            ? measurement.toPointId 
            : measurement.fromPointId;
        
        final otherPoint = allPoints.firstWhere(
          (p) => p.id == otherPointId,
          orElse: () => point,
        );

        if (otherPoint != point) {
          final direction = (otherPoint.position - point.position).normalized();
          final deviationRatio = (measurement.actualValue! - measurement.factoryValue) / measurement.factoryValue;
          
          // Применяем деформацию пропорционально отклонению
          deformedPosition += direction * (deviationRatio * 50);
        }
      }
    }

    return deformedPosition;
  }

  void _drawControlPoints(Canvas canvas, List<ControlPoint> points, Matrix4 matrix) {
    for (final point in points) {
      final position = _project3DPoint(point.position, matrix);
      
      // Определяем цвет точки
      final color = _getPointColor(point);
      
      // Рисуем точку
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(position, point.id == selectedPointId ? 8 : 5, paint);

      // Рисуем обводку
      final strokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(position, point.id == selectedPointId ? 8 : 5, strokePaint);

      // Рисуем метку
      final textPainter = TextPainter(
        text: TextSpan(
          text: point.code,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, position + const Offset(10, -10));
    }
  }

  void _drawMeasurements(Canvas canvas, List<ControlPoint> points, Matrix4 matrix) {
    for (final measurement in measurements) {
      if (measurement.actualValue == null) continue;

      final fromPoint = points.firstWhere(
        (p) => p.id == measurement.fromPointId,
        orElse: () => points.first,
      );
      final toPoint = points.firstWhere(
        (p) => p.id == measurement.toPointId,
        orElse: () => points.first,
      );

      if (fromPoint != points.first && toPoint != points.first) {
        final fromPos = _project3DPoint(fromPoint.position, matrix);
        final toPos = _project3DPoint(toPoint.position, matrix);

        // Рисуем линию измерения
        final paint = Paint()
          ..color = _getMeasurementColor(measurement).withValues(alpha: 0.6)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

        canvas.drawLine(fromPos, toPos, paint);

        // Рисуем значение
        final midPoint = Offset(
          (fromPos.dx + toPos.dx) / 2,
          (fromPos.dy + toPos.dy) / 2,
        );

        final text = '${measurement.deviation > 0 ? '+' : ''}${measurement.deviation.toStringAsFixed(1)}мм';
        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: _getMeasurementColor(measurement),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, midPoint + Offset(-textPainter.width / 2, -20));
      }
    }
  }

  Offset _project3DPoint(vm.Vector3 point, Matrix4 matrix) {
    final transformed = matrix.transform3(point);
    // Простая перспективная проекция
    const perspective = 1000.0;
    final scale = perspective / (perspective + transformed.z);
    return Offset(
      transformed.x * scale,
      transformed.y * scale,
    );
  }

  Color _getPointColor(ControlPoint point) {
    final relatedMeasurements = measurements.where(
      (m) => m.fromPointId == point.id || m.toPointId == point.id,
    );

    if (relatedMeasurements.isEmpty) return Colors.grey;

    var maxSeverity = DeviationSeverity.normal;
    for (final m in relatedMeasurements) {
      if (m.actualValue != null && m.severity.index > maxSeverity.index) {
        maxSeverity = m.severity;
      }
    }

    switch (maxSeverity) {
      case DeviationSeverity.normal:
        return Colors.green;
      case DeviationSeverity.warning:
        return Colors.orange;
      case DeviationSeverity.critical:
        return Colors.deepOrange;
      case DeviationSeverity.severe:
        return Colors.red;
    }
  }

  Color _getMeasurementColor(Measurement measurement) {
    switch (measurement.severity) {
      case DeviationSeverity.normal:
        return Colors.green[700]!;
      case DeviationSeverity.warning:
        return Colors.orange[700]!;
      case DeviationSeverity.critical:
        return Colors.deepOrange[700]!;
      case DeviationSeverity.severe:
        return Colors.red[700]!;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}