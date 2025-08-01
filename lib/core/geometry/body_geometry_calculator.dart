import 'dart:math' as math;
import '../models/control_point.dart';

/// Систематический подход к вычислению геометрии кузова
/// на основе методологии Car-O-Liner
class BodyGeometryCalculator {
  
  /// Вычисляет диагональ между двумя контрольными точками
  /// зная их координаты в 3D пространстве
  static double calculateDiagonal(ControlPoint pointA, ControlPoint pointB) {
    final dx = pointB.x - pointA.x;
    final dy = pointB.y - pointA.y;
    final dz = pointB.z - pointA.z;
    
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }
  
  /// Вычисляет диагональ по известным проекционным длинам
  /// L - длина (продольная проекция)
  /// W - ширина (поперечная проекция) 
  /// H - высота (вертикальная проекция)
  static double calculateDiagonalFromProjections(double L, double W, double H) {
    return math.sqrt(L * L + W * W + H * H);
  }
  
  /// Обратное вычисление: находим одну проекцию по диагонали и двум другим
  static double calculateProjectionFromDiagonal(
    double diagonal, 
    double projection1, 
    double projection2
  ) {
    final remaining = diagonal * diagonal - projection1 * projection1 - projection2 * projection2;
    return remaining > 0 ? math.sqrt(remaining) : 0.0;
  }
  
  /// Вычисляет проекционную длину на заданную плоскость
  static ProjectionLengths calculateProjections(ControlPoint pointA, ControlPoint pointB) {
    return ProjectionLengths(
      longitudinal: (pointB.x - pointA.x).abs(),  // Продольная (X)
      lateral: (pointB.y - pointA.y).abs(),       // Поперечная (Y)
      vertical: (pointB.z - pointA.z).abs(),      // Вертикальная (Z)
    );
  }
  
  /// Проверяет геометрическую консистентность треугольника
  /// по правилу: сумма любых двух сторон > третьей стороны
  static bool isTriangleValid(double side1, double side2, double side3) {
    return (side1 + side2 > side3) && 
           (side1 + side3 > side2) && 
           (side2 + side3 > side1);
  }
  
  /// Вычисляет недостающий размер в треугольнике по теореме косинусов
  /// Если известны две стороны и угол между ними
  static double calculateThirdSideWithAngle(
    double sideA, 
    double sideB, 
    double angleInRadians
  ) {
    return math.sqrt(
      sideA * sideA + 
      sideB * sideB - 
      2 * sideA * sideB * math.cos(angleInRadians)
    );
  }
  
  /// Находит угол в треугольнике по трем сторонам (теорема косинусов)
  static double calculateAngleFromSides(double opposite, double adjacent1, double adjacent2) {
    final cosAngle = (adjacent1 * adjacent1 + adjacent2 * adjacent2 - opposite * opposite) / 
                     (2 * adjacent1 * adjacent2);
    
    // Ограничиваем значение косинуса в пределах [-1, 1]
    final clampedCos = math.max(-1.0, math.min(1.0, cosAngle));
    return math.acos(clampedCos);
  }
  
  /// Система координат Car-O-Liner:
  /// - X: продольная ось (от носа к корме)
  /// - Y: поперечная ось (лево-право)
  /// - Z: вертикальная ось (верх-низ)
  
  /// Вычисляет колесную базу (расстояние между осями)
  static double calculateWheelbase(List<ControlPoint> frontAxisPoints, List<ControlPoint> rearAxisPoints) {
    if (frontAxisPoints.isEmpty || rearAxisPoints.isEmpty) return 0.0;
    
    // Берем средние X координаты передней и задней осей
    final frontX = frontAxisPoints.map((p) => p.x).reduce((a, b) => a + b) / frontAxisPoints.length;
    final rearX = rearAxisPoints.map((p) => p.x).reduce((a, b) => a + b) / rearAxisPoints.length;
    
    return (frontX - rearX).abs();
  }
  
  /// Вычисляет ширину колеи (track width)
  static double calculateTrackWidth(List<ControlPoint> leftPoints, List<ControlPoint> rightPoints) {
    if (leftPoints.isEmpty || rightPoints.isEmpty) return 0.0;
    
    // Берем средние Y координаты левой и правой сторон
    final leftY = leftPoints.map((p) => p.y).reduce((a, b) => a + b) / leftPoints.length;
    final rightY = rightPoints.map((p) => p.y).reduce((a, b) => a + b) / rightPoints.length;
    
    return (rightY - leftY).abs();
  }
  
  /// Метод "Золотого треугольника" - проверка геометрии через ключевые диагонали
  static GeometryValidationResult validateGoldenTriangle(
    ControlPoint pointA, 
    ControlPoint pointB, 
    ControlPoint pointC,
    {double tolerance = 2.0} // допуск в мм
  ) {
    final sideAB = calculateDiagonal(pointA, pointB);
    final sideBC = calculateDiagonal(pointB, pointC);
    final sideCA = calculateDiagonal(pointC, pointA);
    
    final isValid = isTriangleValid(sideAB, sideBC, sideCA);
    
    // Вычисляем отклонения от эталонных значений (если есть)
    final deviations = <String, double>{};
    
    return GeometryValidationResult(
      isValid: isValid,
      deviations: deviations,
      recommendations: _generateRecommendations(deviations, tolerance),
    );
  }
  
  /// Система проверки по диагоналям (основа методики Car-O-Liner)
  static DiagonalCheckResult performDiagonalCheck(
    List<ControlPoint> points,
    Map<String, double> referenceValues,
    {double tolerance = 2.0}
  ) {
    final results = <String, DiagonalMeasurement>{};
    
    // Проверяем все возможные диагонали между точками
    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final pointA = points[i];
        final pointB = points[j];
        final diagonalKey = '${pointA.code}-${pointB.code}';
        
        final measured = calculateDiagonal(pointA, pointB);
        final reference = referenceValues[diagonalKey];
        
        if (reference != null) {
          final deviation = measured - reference;
          final isWithinTolerance = deviation.abs() <= tolerance;
          
          results[diagonalKey] = DiagonalMeasurement(
            pointA: pointA.code,
            pointB: pointB.code,
            measured: measured,
            reference: reference,
            deviation: deviation,
            isWithinTolerance: isWithinTolerance,
            projections: calculateProjections(pointA, pointB),
          );
        }
      }
    }
    
    return DiagonalCheckResult(
      measurements: results,
      overallStatus: results.values.every((m) => m.isWithinTolerance) 
        ? GeometryStatus.good 
        : GeometryStatus.needsAttention,
    );
  }
  
  static List<String> _generateRecommendations(Map<String, double> deviations, double tolerance) {
    final recommendations = <String>[];
    
    for (final entry in deviations.entries) {
      if (entry.value.abs() > tolerance) {
        recommendations.add('Проверить точку "${entry.key}" - отклонение ${entry.value.toStringAsFixed(1)}мм');
      }
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Геометрия в пределах допуска');
    }
    
    return recommendations;
  }
}

/// Класс для хранения проекционных длин
class ProjectionLengths {
  final double longitudinal; // X - продольная
  final double lateral;      // Y - поперечная  
  final double vertical;     // Z - вертикальная
  
  const ProjectionLengths({
    required this.longitudinal,
    required this.lateral,
    required this.vertical,
  });
  
  /// Общая диагональ по всем трем проекциям
  double get totalDiagonal => math.sqrt(
    longitudinal * longitudinal + 
    lateral * lateral + 
    vertical * vertical
  );
  
  /// Горизонтальная диагональ (без учета высоты)
  double get horizontalDiagonal => math.sqrt(
    longitudinal * longitudinal + lateral * lateral
  );
}

/// Результат измерения диагонали
class DiagonalMeasurement {
  final String pointA;
  final String pointB;
  final double measured;
  final double reference;
  final double deviation;
  final bool isWithinTolerance;
  final ProjectionLengths projections;
  
  const DiagonalMeasurement({
    required this.pointA,
    required this.pointB,
    required this.measured,
    required this.reference,
    required this.deviation,
    required this.isWithinTolerance,
    required this.projections,
  });
  
  /// Процентное отклонение от эталона
  double get deviationPercentage => (deviation / reference) * 100;
}

/// Результат проверки диагоналей
class DiagonalCheckResult {
  final Map<String, DiagonalMeasurement> measurements;
  final GeometryStatus overallStatus;
  
  const DiagonalCheckResult({
    required this.measurements,
    required this.overallStatus,
  });
  
  /// Получить все критические отклонения
  List<DiagonalMeasurement> get criticalDeviations => 
    measurements.values.where((m) => !m.isWithinTolerance).toList();
  
  /// Количество измерений в норме
  int get normalMeasurements => 
    measurements.values.where((m) => m.isWithinTolerance).length;
}

/// Результат валидации геометрии
class GeometryValidationResult {
  final bool isValid;
  final Map<String, double> deviations;
  final List<String> recommendations;
  
  const GeometryValidationResult({
    required this.isValid,
    required this.deviations,
    required this.recommendations,
  });
}

/// Статус геометрии кузова
enum GeometryStatus {
  good,           // В норме
  needsAttention, // Требует внимания
  critical,       // Критическое состояние
}