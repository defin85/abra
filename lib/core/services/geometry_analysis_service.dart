import '../models/control_point.dart';
import '../models/measurement.dart';
import '../geometry/body_geometry_calculator.dart';
import '../data/reference_dimensions.dart';
import 'dart:math' as math;

/// Сервис анализа геометрии кузова
/// Реализует практические методы анализа на основе методологии Car-O-Liner
class GeometryAnalysisService {
  
  /// Выполняет полный анализ геометрии кузова
  static BodyGeometryAnalysis performFullAnalysis(
    List<ControlPoint> controlPoints,
    List<Measurement> measurements,
    String vehicleModel,
  ) {
    // Создаем карту измерений для быстрого доступа
    final measurementMap = <String, double>{};
    for (final measurement in measurements) {
      final key = '${measurement.fromPointId}-${measurement.toPointId}';
      if (measurement.actualValue != null) {
        measurementMap[key] = measurement.actualValue!;
      }
    }
    
    // Выполняем диагональную проверку
    final diagonalCheck = BodyGeometryCalculator.performDiagonalCheck(
      controlPoints,
      ReferenceDimensions.toyotaCamryXV70Diagonals,
      tolerance: 2.0,
    );
    
    // Проверяем группы измерений
    final groupResults = <String, GroupValidationResult>{};
    for (final groupName in ReferenceDimensions.measurementGroups.keys) {
      // Конвертируем измерения контрольных точек в диагонали
      final diagonalsForGroup = _convertMeasurementsToDiagonals(
        controlPoints, 
        ReferenceDimensions.getMeasurementGroup(groupName)
      );
      
      groupResults[groupName] = ReferenceDimensions.validateMeasurementGroup(
        groupName, 
        diagonalsForGroup
      );
    }
    
    // Выполняем анализ симметрии
    final symmetryAnalysis = _analyzeSymmetry(controlPoints);
    
    // Проверяем критические размеры
    final criticalAnalysis = _analyzeCriticalDimensions(controlPoints);
    
    // Генерируем рекомендации
    final recommendations = _generateRecommendations(
      diagonalCheck, 
      groupResults, 
      symmetryAnalysis,
      criticalAnalysis,
    );
    
    return BodyGeometryAnalysis(
      overallStatus: _determineOverallStatus(diagonalCheck, groupResults),
      diagonalCheck: diagonalCheck,
      groupResults: groupResults,
      symmetryAnalysis: symmetryAnalysis,
      criticalAnalysis: criticalAnalysis,
      recommendations: recommendations,
      completeness: _calculateCompleteness(controlPoints, measurements),
    );
  }
  
  /// Вычисляет недостающие размеры на основе известных
  static Map<String, double> calculateMissingDimensions(
    List<ControlPoint> knownPoints,
    List<String> requiredDiagonals,
  ) {
    final calculated = <String, double>{};
    
    for (final diagonalKey in requiredDiagonals) {
      final parts = diagonalKey.split('-');
      if (parts.length != 2) continue;
      
      ControlPoint? pointA;
      ControlPoint? pointB;
      
      try {
        pointA = knownPoints.firstWhere((p) => p.code == parts[0]);
      } catch (e) {
        pointA = null;
      }
      
      try {
        pointB = knownPoints.firstWhere((p) => p.code == parts[1]);
      } catch (e) {
        pointB = null;
      }
      
      if (pointA != null && pointB != null) {
        calculated[diagonalKey] = BodyGeometryCalculator.calculateDiagonal(pointA, pointB);
      } else {
        // Пытаемся вычислить через проекции, если есть эталонные данные
        final projections = ReferenceDimensions.toyotaCamryXV70Projections[diagonalKey];
        if (projections != null) {
          calculated[diagonalKey] = BodyGeometryCalculator.calculateDiagonalFromProjections(
            projections.x, 
            projections.y, 
            projections.z
          );
        }
      }
    }
    
    return calculated;
  }
  
  /// Проверяет возможность восстановления геометрии
  static RepairabilityAssessment assessRepairability(
    BodyGeometryAnalysis analysis,
    {double criticalThreshold = 5.0}
  ) {
    final criticalDeviations = analysis.diagonalCheck.criticalDeviations;
    final maxDeviation = criticalDeviations.isEmpty 
        ? 0.0 
        : criticalDeviations.map((d) => d.deviation.abs()).reduce(math.max);
    
    final repairabilityLevel = _determineRepairabilityLevel(maxDeviation, criticalThreshold);
    final estimatedCost = _estimateRepairCost(analysis);
    final repairSteps = _generateRepairSteps(analysis);
    
    return RepairabilityAssessment(
      level: repairabilityLevel,
      maxDeviation: maxDeviation,
      criticalPoints: criticalDeviations.map((d) => '${d.pointA}-${d.pointB}').toList(),
      estimatedCost: estimatedCost,
      repairSteps: repairSteps,
      isEconomicallyViable: estimatedCost.total < 150000, // 150k руб как порог
    );
  }
  
  /// Генерирует план измерений для проверки геометрии
  static MeasurementPlan generateMeasurementPlan(
    String vehicleModel,
    {bool prioritizeCritical = true}
  ) {
    final allDiagonals = ReferenceDimensions.toyotaCamryXV70Diagonals.keys.toList();
    const criticalDiagonals = ReferenceDimensions.criticalDiagonals;
    
    final orderedMeasurements = <String>[];
    
    if (prioritizeCritical) {
      // Сначала критические диагонали
      orderedMeasurements.addAll(criticalDiagonals);
      // Затем остальные
      orderedMeasurements.addAll(
        allDiagonals.where((d) => !criticalDiagonals.contains(d))
      );
    } else {
      orderedMeasurements.addAll(allDiagonals);
    }
    
    return MeasurementPlan(
      vehicleModel: vehicleModel,
      measurements: orderedMeasurements.map((key) => PlannedMeasurement(
        diagonalKey: key,
        referenceValue: ReferenceDimensions.getReferenceValue(key, 'diagonal'),
        tolerance: ReferenceDimensions.getToleranceForType('diagonal'),
        priority: criticalDiagonals.contains(key) ? Priority.critical : Priority.normal,
        estimatedTime: criticalDiagonals.contains(key) ? 3 : 2, // минуты
      )).toList(),
      estimatedTotalTime: orderedMeasurements.length * 2.5, // среднее время
    );
  }
  
  // Приватные методы для внутренней логики
  
  static Map<String, double> _convertMeasurementsToDiagonals(
    List<ControlPoint> points, 
    List<String> diagonalKeys
  ) {
    final result = <String, double>{};
    
    for (final key in diagonalKeys) {
      final parts = key.split('-');
      if (parts.length != 2) continue;
      
      ControlPoint? pointA;
      ControlPoint? pointB;
      
      try {
        pointA = points.firstWhere((p) => p.code == parts[0]);
      } catch (e) {
        pointA = null;
      }
      
      try {
        pointB = points.firstWhere((p) => p.code == parts[1]);
      } catch (e) {
        pointB = null;
      }
      
      if (pointA != null && pointB != null) {
        result[key] = BodyGeometryCalculator.calculateDiagonal(pointA, pointB);
      }
    }
    
    return result;
  }
  
  static SymmetryAnalysis _analyzeSymmetry(List<ControlPoint> points) {
    final leftPoints = points.where((p) => p.code.contains('A') || p.code.contains('C') || p.code.contains('K')).toList();
    final rightPoints = points.where((p) => p.code.contains('B') || p.code.contains('G') || p.code.contains('L')).toList();
    
    final symmetryDeviations = <String, double>{};
    double maxDeviation = 0.0;
    
    // Проверяем симметрию по Y координате (поперечная ось)
    for (int i = 0; i < math.min(leftPoints.length, rightPoints.length); i++) {
      final leftY = leftPoints[i].y.abs();
      final rightY = rightPoints[i].y.abs();
      final deviation = (leftY - rightY).abs();
      
      symmetryDeviations['${leftPoints[i].code}-${rightPoints[i].code}'] = deviation;
      maxDeviation = math.max(maxDeviation, deviation);
    }
    
    return SymmetryAnalysis(
      isSymmetric: maxDeviation <= 3.0, // допуск 3мм
      maxDeviation: maxDeviation,
      deviations: symmetryDeviations,
    );
  }
  
  static CriticalDimensionsAnalysis _analyzeCriticalDimensions(List<ControlPoint> points) {
    final criticalResults = <String, bool>{};
    final deviations = <String, double>{};
    
    for (final criticalKey in ReferenceDimensions.criticalDiagonals) {
      final calculated = calculateMissingDimensions(points, [criticalKey]);
      final reference = ReferenceDimensions.getReferenceValue(criticalKey, 'diagonal');
      
      if (calculated.containsKey(criticalKey) && reference > 0) {
        final deviation = calculated[criticalKey]! - reference;
        final isOk = deviation.abs() <= 2.0;
        
        criticalResults[criticalKey] = isOk;
        deviations[criticalKey] = deviation;
      }
    }
    
    return CriticalDimensionsAnalysis(
      allCriticalOk: criticalResults.values.every((ok) => ok),
      results: criticalResults,
      deviations: deviations,
    );
  }
  
  static GeometryStatus _determineOverallStatus(
    DiagonalCheckResult diagonalCheck,
    Map<String, GroupValidationResult> groupResults,
  ) {
    if (diagonalCheck.overallStatus == GeometryStatus.critical) {
      return GeometryStatus.critical;
    }
    
    final hasGroupIssues = groupResults.values.any((result) => !result.isValid);
    
    if (hasGroupIssues) {
      return GeometryStatus.needsAttention;
    }
    
    return GeometryStatus.good;
  }
  
  static List<String> _generateRecommendations(
    DiagonalCheckResult diagonalCheck,
    Map<String, GroupValidationResult> groupResults,
    SymmetryAnalysis symmetryAnalysis,
    CriticalDimensionsAnalysis criticalAnalysis,
  ) {
    final recommendations = <String>[];
    
    if (!criticalAnalysis.allCriticalOk) {
      recommendations.add('КРИТИЧНО: Проверить базовые размеры кузова на стапеле');
    }
    
    if (!symmetryAnalysis.isSymmetric) {
      recommendations.add('Обнаружена асимметрия кузова (${symmetryAnalysis.maxDeviation.toStringAsFixed(1)}мм)');
    }
    
    for (final criticalDev in diagonalCheck.criticalDeviations) {
      recommendations.add(
        'Диагональ ${criticalDev.pointA}-${criticalDev.pointB}: отклонение ${criticalDev.deviation.toStringAsFixed(1)}мм'
      );
    }
    
    return recommendations;
  }
  
  static double _calculateCompleteness(List<ControlPoint> points, List<Measurement> measurements) {
    final totalRequired = ReferenceDimensions.toyotaCamryXV70Diagonals.length;
    final available = points.length;
    return math.min(1.0, available / totalRequired);
  }
  
  static RepairabilityLevel _determineRepairabilityLevel(double maxDeviation, double threshold) {
    if (maxDeviation <= 2.0) return RepairabilityLevel.excellent;
    if (maxDeviation <= 5.0) return RepairabilityLevel.good;
    if (maxDeviation <= threshold) return RepairabilityLevel.difficult;
    return RepairabilityLevel.unrepairable;
  }
  
  static RepairCost _estimateRepairCost(BodyGeometryAnalysis analysis) {
    // Упрощенная модель оценки стоимости
    const baseRate = 2500.0; // руб за час
    final criticalCount = analysis.diagonalCheck.criticalDeviations.length;
    
    const diagnosticHours = 2.0;
    final repairHours = criticalCount * 3.0;
    final materialsCost = criticalCount * 5000.0;
    
    return RepairCost(
      diagnostic: diagnosticHours * baseRate,
      labor: repairHours * baseRate,
      materials: materialsCost,
    );
  }
  
  static List<String> _generateRepairSteps(BodyGeometryAnalysis analysis) {
    final steps = ['1. Диагностика на стапеле'];
    
    int stepNumber = 2;
    for (final deviation in analysis.diagonalCheck.criticalDeviations) {
      steps.add('$stepNumber. Правка диагонали ${deviation.pointA}-${deviation.pointB}');
      stepNumber++;
    }
    
    steps.add('$stepNumber. Контрольные измерения');
    return steps;
  }
}

// Классы результатов анализа

class BodyGeometryAnalysis {
  final GeometryStatus overallStatus;
  final DiagonalCheckResult diagonalCheck;
  final Map<String, GroupValidationResult> groupResults;
  final SymmetryAnalysis symmetryAnalysis;
  final CriticalDimensionsAnalysis criticalAnalysis;
  final List<String> recommendations;
  final double completeness;
  
  const BodyGeometryAnalysis({
    required this.overallStatus,
    required this.diagonalCheck,
    required this.groupResults,
    required this.symmetryAnalysis,
    required this.criticalAnalysis,
    required this.recommendations,
    required this.completeness,
  });
}

class SymmetryAnalysis {
  final bool isSymmetric;
  final double maxDeviation;
  final Map<String, double> deviations;
  
  const SymmetryAnalysis({
    required this.isSymmetric,
    required this.maxDeviation,
    required this.deviations,
  });
}

class CriticalDimensionsAnalysis {
  final bool allCriticalOk;
  final Map<String, bool> results;
  final Map<String, double> deviations;
  
  const CriticalDimensionsAnalysis({
    required this.allCriticalOk,
    required this.results,
    required this.deviations,
  });
}

class RepairabilityAssessment {
  final RepairabilityLevel level;
  final double maxDeviation;
  final List<String> criticalPoints;
  final RepairCost estimatedCost;
  final List<String> repairSteps;
  final bool isEconomicallyViable;
  
  const RepairabilityAssessment({
    required this.level,
    required this.maxDeviation,
    required this.criticalPoints,
    required this.estimatedCost,
    required this.repairSteps,
    required this.isEconomicallyViable,
  });
}

class RepairCost {
  final double diagnostic;
  final double labor;
  final double materials;
  
  const RepairCost({
    required this.diagnostic,
    required this.labor, 
    required this.materials,
  });
  
  double get total => diagnostic + labor + materials;
}

class MeasurementPlan {
  final String vehicleModel;
  final List<PlannedMeasurement> measurements;
  final double estimatedTotalTime;
  
  const MeasurementPlan({
    required this.vehicleModel,
    required this.measurements,
    required this.estimatedTotalTime,
  });
}

class PlannedMeasurement {
  final String diagonalKey;
  final double referenceValue;
  final double tolerance;
  final Priority priority;
  final int estimatedTime; // в минутах
  
  const PlannedMeasurement({
    required this.diagonalKey,
    required this.referenceValue,
    required this.tolerance,
    required this.priority,
    required this.estimatedTime,
  });
}

enum RepairabilityLevel {
  excellent,    // Отличное состояние
  good,         // Хорошее, легко ремонтируется
  difficult,    // Сложный ремонт
  unrepairable, // Экономически нецелесообразен
}

enum Priority {
  critical,  // Критично
  high,      // Высокий
  normal,    // Обычный
  low,       // Низкий
}