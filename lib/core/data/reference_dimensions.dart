import '../geometry/body_geometry_calculator.dart';

/// Система эталонных размеров на основе методологии Car-O-Liner
class ReferenceDimensions {
  
  /// Эталонные диагонали для Toyota Camry XV70 (2018-2023)
  /// Основано на данных Car-O-Liner и заводских спецификациях
  static const Map<String, double> toyotaCamryXV70Diagonals = {
    // Передние диагонали (от передних точек к центральным)
    'A-E': 1847.5,  // Левая передняя стойка к центру пола
    'B-E': 1847.5,  // Правая передняя стойка к центру пола
    'A-F': 2156.3,  // Левая передняя к задней центральной
    'B-F': 2156.3,  // Правая передняя к задней центральной
    
    // Задние диагонали (от задних точек к центральным)
    'K-E': 1963.2,  // Левая задняя к центру пола
    'L-E': 1963.2,  // Правая задняя к центру пола
    'K-D': 2274.1,  // Левая задняя к передней центральной
    'L-D': 2274.1,  // Правая задняя к передней центральной
    
    // Поперечные диагонали (лево-право)
    'A-B': 1520.0,  // Ширина по передним стойкам
    'C-J': 1610.0,  // Ширина по порогам в середине
    'K-L': 1585.0,  // Ширина по задним стойкам
    
    // Продольные размеры
    'A-K': 2725.0,  // Левая сторона (база)
    'B-L': 2725.0,  // Правая сторона (база)
    'D-F': 1350.0,  // Центральная база
    
    // Крестовые диагонали (самые важные для проверки геометрии)
    'A-L': 3156.7,  // Левая передняя к правой задней
    'B-K': 3156.7,  // Правая передняя к левой задней
    
    // Диагонали порогов
    'C-H': 2150.0,  // Левый порог полная длина
    'G-I': 2150.0,  // Правый порог полная длина
    'C-G': 1610.0,  // Ширина порогов спереди
    'H-I': 1585.0,  // Ширина порогов сзади
  };
  
  /// Проекционные размеры (базовые измерения по осям)
  static const Map<String, ProjectionDimensions> toyotaCamryXV70Projections = {
    'A-B': ProjectionDimensions(x: 0, y: 1520, z: 0),      // Ширина передних стоек
    'A-K': ProjectionDimensions(x: 2725, y: 0, z: 0),      // Левая продольная база
    'B-L': ProjectionDimensions(x: 2725, y: 0, z: 0),      // Правая продольная база
    'D-F': ProjectionDimensions(x: 1350, y: 0, z: 0),      // Центральная база
    'C-G': ProjectionDimensions(x: 0, y: 1610, z: 0),      // Ширина порогов
    
    // Вертикальные размеры (высотные отметки)
    'E-M': ProjectionDimensions(x: 0, y: 0, z: 420),       // Высота центрального тоннеля
    'A-J': ProjectionDimensions(x: 0, y: 0, z: 380),       // Высота передней стойки
    'K-N': ProjectionDimensions(x: 0, y: 0, z: 365),       // Высота задней стойки
  };
  
  /// Допуски для различных типов измерений (в мм)
  static const Map<String, double> tolerances = {
    'diagonal': 2.0,      // Диагональные размеры ±2мм
    'longitudinal': 1.5,  // Продольные размеры ±1.5мм
    'lateral': 1.0,       // Поперечные размеры ±1мм
    'vertical': 2.5,      // Вертикальные размеры ±2.5мм
  };
  
  /// Критические диагонали для первоочередной проверки
  static const List<String> criticalDiagonals = [
    'A-L',  // Крестовая диагональ лево-право
    'B-K',  // Крестовая диагональ право-лево
    'A-K',  // Левая продольная база
    'B-L',  // Правая продольная база
    'D-F',  // Центральная база
  ];
  
  /// Группы связанных измерений для системной проверки
  static const Map<String, List<String>> measurementGroups = {
    'front_geometry': ['A-B', 'A-E', 'B-E', 'A-F', 'B-F'],
    'rear_geometry': ['K-L', 'K-E', 'L-E', 'K-D', 'L-D'],
    'longitudinal_base': ['A-K', 'B-L', 'D-F'],
    'cross_diagonals': ['A-L', 'B-K'],
    'sill_geometry': ['C-G', 'H-I', 'C-H', 'G-I'],
  };
  
  /// Вычисляет ожидаемое значение диагонали по проекциям
  static double calculateExpectedDiagonal(String diagonalKey) {
    final projections = toyotaCamryXV70Projections[diagonalKey];
    if (projections == null) {
      // Если нет данных по проекциям, используем прямое значение
      return toyotaCamryXV70Diagonals[diagonalKey] ?? 0.0;
    }
    
    return BodyGeometryCalculator.calculateDiagonalFromProjections(
      projections.x, 
      projections.y, 
      projections.z
    );
  }
  
  /// Получает эталонное значение с учетом типа измерения
  static double getReferenceValue(String measurementKey, String measurementType) {
    switch (measurementType) {
      case 'diagonal':
        return toyotaCamryXV70Diagonals[measurementKey] ?? 0.0;
      case 'calculated':
        return calculateExpectedDiagonal(measurementKey);
      default:
        return toyotaCamryXV70Diagonals[measurementKey] ?? 0.0;
    }
  }
  
  /// Получает допуск для типа измерения
  static double getToleranceForType(String measurementType) {
    return tolerances[measurementType] ?? tolerances['diagonal']!;
  }
  
  /// Проверяет, является ли диагональ критической
  static bool isCriticalDiagonal(String diagonalKey) {
    return criticalDiagonals.contains(diagonalKey);
  }
  
  /// Получает группу измерений для системной проверки
  static List<String> getMeasurementGroup(String groupName) {
    return measurementGroups[groupName] ?? [];
  }
  
  /// Валидирует полный набор измерений для конкретной группы
  static GroupValidationResult validateMeasurementGroup(
    String groupName,
    Map<String, double> actualMeasurements,
  ) {
    final groupMeasurements = getMeasurementGroup(groupName);
    final results = <String, bool>{};
    final deviations = <String, double>{};
    
    for (final measurementKey in groupMeasurements) {
      final actual = actualMeasurements[measurementKey];
      final reference = getReferenceValue(measurementKey, 'diagonal');
      final tolerance = getToleranceForType('diagonal');
      
      if (actual != null && reference > 0) {
        final deviation = actual - reference;
        final isValid = deviation.abs() <= tolerance;
        
        results[measurementKey] = isValid;
        deviations[measurementKey] = deviation;
      }
    }
    
    final overallValid = results.values.every((result) => result);
    
    return GroupValidationResult(
      groupName: groupName,
      isValid: overallValid,
      results: results,
      deviations: deviations,
      completeness: results.length / groupMeasurements.length,
    );
  }
}

/// Класс для хранения проекционных размеров
class ProjectionDimensions {
  final double x; // Продольная проекция
  final double y; // Поперечная проекция
  final double z; // Вертикальная проекция
  
  const ProjectionDimensions({
    required this.x,
    required this.y,
    required this.z,
  });
}

/// Результат валидации группы измерений
class GroupValidationResult {
  final String groupName;
  final bool isValid;
  final Map<String, bool> results;
  final Map<String, double> deviations;
  final double completeness; // Процент завершенности измерений в группе
  
  const GroupValidationResult({
    required this.groupName,
    required this.isValid,
    required this.results,
    required this.deviations,
    required this.completeness,
  });
  
  /// Получить критические отклонения в группе
  List<MapEntry<String, double>> get criticalDeviations {
    return deviations.entries
        .where((entry) => entry.value.abs() > ReferenceDimensions.getToleranceForType('diagonal'))
        .toList();
  }
  
  /// Получить статус завершенности
  String get completenessStatus {
    if (completeness >= 1.0) return 'Полная';
    if (completeness >= 0.8) return 'Достаточная';
    if (completeness >= 0.5) return 'Частичная';
    return 'Недостаточная';
  }
}