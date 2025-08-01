import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../../../core/models/control_point.dart';
import '../../../core/models/measurement.dart';
import '../../../core/models/car_model.dart';

class CarBody2DView extends StatefulWidget {
  final CarModel carModel;
  final List<Measurement> measurements;
  final ViewType viewType;
  final bool showFactoryModel;
  final bool showActualModel;
  final Function(ControlPoint)? onPointSelected;
  final String? selectedPointId;

  const CarBody2DView({
    super.key,
    required this.carModel,
    required this.measurements,
    this.viewType = ViewType.side,
    this.showFactoryModel = true,
    this.showActualModel = true,
    this.onPointSelected,
    this.selectedPointId,
  });

  @override
  State<CarBody2DView> createState() => _CarBody2DViewState();
}

class _CarBody2DViewState extends State<CarBody2DView> {
  late TransformationController _transformationController;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.5,
            maxScale: 4.0,
            onInteractionUpdate: (details) {
              setState(() {
                _scale = _transformationController.value.getMaxScaleOnAxis();
              });
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: CarBodyPainter(
                carModel: widget.carModel,
                measurements: widget.measurements,
                viewType: widget.viewType,
                showFactoryModel: widget.showFactoryModel,
                showActualModel: widget.showActualModel,
                selectedPointId: widget.selectedPointId,
                scale: _scale,
                onPointTap: widget.onPointSelected,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: ViewControls(
              viewType: widget.viewType,
              showFactoryModel: widget.showFactoryModel,
              showActualModel: widget.showActualModel,
              onViewTypeChanged: (type) {
                setState(() {});
              },
              onFactoryModelToggled: (show) {
                setState(() {});
              },
              onActualModelToggled: (show) {
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CarBodyPainter extends CustomPainter {
  final CarModel carModel;
  final List<Measurement> measurements;
  final ViewType viewType;
  final bool showFactoryModel;
  final bool showActualModel;
  final String? selectedPointId;
  final double scale;
  final Function(ControlPoint)? onPointTap;

  CarBodyPainter({
    required this.carModel,
    required this.measurements,
    required this.viewType,
    required this.showFactoryModel,
    required this.showActualModel,
    this.selectedPointId,
    required this.scale,
    this.onPointTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const scaleFactor = 0.3; // Масштаб для отображения (мм в пиксели)

    // Рисуем сетку
    _drawGrid(canvas, size);

    // Получаем точки для текущего вида
    final visiblePoints = _getVisiblePoints();

    // Рисуем заводскую модель
    if (showFactoryModel) {
      _drawModel(
        canvas,
        center,
        visiblePoints,
        scaleFactor,
        Colors.blue.withValues(alpha: 0.5),
        false,
      );
    }

    // Рисуем актуальную модель
    if (showActualModel) {
      _drawModel(
        canvas,
        center,
        visiblePoints,
        scaleFactor,
        Colors.red.withValues(alpha: 0.7),
        true,
      );
    }

    // Рисуем контрольные точки
    _drawControlPoints(canvas, center, visiblePoints, scaleFactor);

    // Рисуем размеры
    _drawMeasurements(canvas, center, visiblePoints, scaleFactor);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;

    const gridSize = 50.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  List<ControlPoint> _getVisiblePoints() {
    return carModel.controlPoints.where((point) {
      switch (viewType) {
        case ViewType.top:
          return true;
        case ViewType.side:
          return point.position.y > -100; // Фильтр для бокового вида
        case ViewType.front:
          return point.position.x.abs() < 1000; // Фильтр для переднего вида
        case ViewType.rear:
          return point.position.x.abs() < 1000; // Фильтр для заднего вида
      }
    }).toList();
  }

  void _drawModel(
    Canvas canvas,
    Offset center,
    List<ControlPoint> points,
    double scaleFactor,
    Color color,
    bool useActualMeasurements,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Соединяем точки линиями согласно связям
    for (final point in points) {
      final fromOffset = _projectPoint(point.position, viewType, center, scaleFactor);

      for (final connectedId in point.connectedPointIds) {
        final connectedPoint = points.firstWhere(
          (p) => p.id == connectedId,
          orElse: () => point,
        );
        
        if (connectedPoint != point) {
          var toPosition = connectedPoint.position;
          
          // Применяем деформацию если используем актуальные измерения
          if (useActualMeasurements) {
            toPosition = _applyDeformation(point, connectedPoint, toPosition);
          }
          
          final toOffset = _projectPoint(toPosition, viewType, center, scaleFactor);
          canvas.drawLine(fromOffset, toOffset, paint);
        }
      }
    }
  }

  vm.Vector3 _applyDeformation(
    ControlPoint fromPoint,
    ControlPoint toPoint,
    vm.Vector3 originalPosition,
  ) {
    // Находим измерение между этими точками
    final measurement = measurements.firstWhere(
      (m) => (m.fromPointId == fromPoint.id && m.toPointId == toPoint.id) ||
             (m.fromPointId == toPoint.id && m.toPointId == fromPoint.id),
      orElse: () => measurements.first,
    );

    if (measurement.actualValue != null) {
      final direction = (toPoint.position - fromPoint.position).normalized();
      final deformedPosition = fromPoint.position + direction * (measurement.actualValue!);
      
      // Интерполируем для плавной деформации
      return originalPosition + (deformedPosition - originalPosition) * 0.5;
    }

    return originalPosition;
  }

  void _drawControlPoints(
    Canvas canvas,
    Offset center,
    List<ControlPoint> points,
    double scaleFactor,
  ) {
    for (final point in points) {
      final offset = _projectPoint(point.position, viewType, center, scaleFactor);
      
      // Определяем цвет точки на основе отклонений
      final color = _getPointColor(point);
      
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // Рисуем точку
      canvas.drawCircle(offset, point.id == selectedPointId ? 8 : 5, paint);

      // Рисуем код точки
      final textPainter = TextPainter(
        text: TextSpan(
          text: point.code,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 10 / scale,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, offset + const Offset(8, -8));
    }
  }

  Color _getPointColor(ControlPoint point) {
    // Находим все измерения связанные с этой точкой
    final relatedMeasurements = measurements.where(
      (m) => m.fromPointId == point.id || m.toPointId == point.id,
    );

    if (relatedMeasurements.isEmpty) return Colors.grey;

    // Определяем максимальную степень отклонения
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

  void _drawMeasurements(
    Canvas canvas,
    Offset center,
    List<ControlPoint> points,
    double scaleFactor,
  ) {
    for (final measurement in measurements) {
      final fromPoint = points.firstWhere(
        (p) => p.id == measurement.fromPointId,
        orElse: () => points.first,
      );
      final toPoint = points.firstWhere(
        (p) => p.id == measurement.toPointId,
        orElse: () => points.first,
      );

      if (fromPoint != points.first && toPoint != points.first) {
        final fromOffset = _projectPoint(fromPoint.position, viewType, center, scaleFactor);
        final toOffset = _projectPoint(toPoint.position, viewType, center, scaleFactor);

        // Рисуем размерную линию
        final paint = Paint()
          ..color = Colors.black54
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        canvas.drawLine(fromOffset, toOffset, paint);

        // Рисуем значение
        final midPoint = Offset(
          (fromOffset.dx + toOffset.dx) / 2,
          (fromOffset.dy + toOffset.dy) / 2,
        );

        final text = measurement.actualValue != null
            ? '${measurement.factoryValue.toStringAsFixed(0)} / ${measurement.actualValue!.toStringAsFixed(0)}'
            : measurement.factoryValue.toStringAsFixed(0);

        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: _getMeasurementColor(measurement),
              fontSize: 12 / scale,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, midPoint + Offset(-textPainter.width / 2, -20));
      }
    }
  }

  Color _getMeasurementColor(Measurement measurement) {
    if (measurement.actualValue == null) return Colors.grey;
    
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

  Offset _projectPoint(
    vm.Vector3 position,
    ViewType viewType,
    Offset center,
    double scaleFactor,
  ) {
    switch (viewType) {
      case ViewType.top:
        return center + Offset(position.x * scaleFactor, -position.z * scaleFactor);
      case ViewType.side:
        return center + Offset(position.z * scaleFactor, -position.y * scaleFactor);
      case ViewType.front:
        return center + Offset(position.x * scaleFactor, -position.y * scaleFactor);
      case ViewType.rear:
        return center + Offset(-position.x * scaleFactor, -position.y * scaleFactor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ViewControls extends StatelessWidget {
  final ViewType viewType;
  final bool showFactoryModel;
  final bool showActualModel;
  final Function(ViewType) onViewTypeChanged;
  final Function(bool) onFactoryModelToggled;
  final Function(bool) onActualModelToggled;

  const ViewControls({
    super.key,
    required this.viewType,
    required this.showFactoryModel,
    required this.showActualModel,
    required this.onViewTypeChanged,
    required this.onFactoryModelToggled,
    required this.onActualModelToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Вид',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            SegmentedButton<ViewType>(
              segments: const [
                ButtonSegment(
                  value: ViewType.top,
                  label: Text('Сверху'),
                ),
                ButtonSegment(
                  value: ViewType.side,
                  label: Text('Сбоку'),
                ),
                ButtonSegment(
                  value: ViewType.front,
                  label: Text('Спереди'),
                ),
                ButtonSegment(
                  value: ViewType.rear,
                  label: Text('Сзади'),
                ),
              ],
              selected: {viewType},
              onSelectionChanged: (Set<ViewType> selection) {
                onViewTypeChanged(selection.first);
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 250,
              child: CheckboxListTile(
                dense: true,
                title: const Text('Заводские размеры'),
                subtitle: const Text('Синий', style: TextStyle(color: Colors.blue)),
                value: showFactoryModel,
                onChanged: (value) => onFactoryModelToggled(value ?? true),
              ),
            ),
            SizedBox(
              width: 250,
              child: CheckboxListTile(
                dense: true,
                title: const Text('Фактические размеры'),
                subtitle: const Text('Красный', style: TextStyle(color: Colors.red)),
                value: showActualModel,
                onChanged: (value) => onActualModelToggled(value ?? true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ViewType {
  top,
  side,
  front,
  rear,
}