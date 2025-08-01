# Система расчета геометрии кузова ABRA

## Обзор

Система расчета геометрии кузова ABRA основана на методологии **Car-O-Liner** и предоставляет комплексный набор инструментов для анализа, расчета и валидации геометрических параметров автомобильных кузовов.

## Архитектура системы

```
lib/core/geometry/
├── body_geometry_calculator.dart    # Математические расчеты
├── reference_dimensions.dart        # Эталонные размеры
└── geometry_analysis_service.dart   # Аналитический сервис
```

## Ключевые компоненты

### 1. BodyGeometryCalculator
Основной класс для математических вычислений геометрии кузова.

### 2. ReferenceDimensions  
Система эталонных размеров и допусков.

### 3. GeometryAnalysisService
Высокоуровневый сервис для полного анализа геометрии.

## Система координат Car-O-Liner

```
        Z (вертикальная ось)
        ↑
        |
        |
        o────→ Y (поперечная ось)
       /
      /
     ↙
    X (продольная ось)
```

- **X**: Продольная ось (от носа к корме автомобиля)
- **Y**: Поперечная ось (от левой стороны к правой)  
- **Z**: Вертикальная ось (от пола к крыше)

## Основные принципы

### 1. Диагональные измерения
Диагонали - основа проверки геометрии кузова. Рассчитываются по формуле:

```dart
diagonal = √(ΔX² + ΔY² + ΔZ²)
```

### 2. Проекционные длины
Размеры по отдельным осям:
- **Продольная проекция (L)**: |X₂ - X₁|
- **Поперечная проекция (W)**: |Y₂ - Y₁|  
- **Вертикальная проекция (H)**: |Z₂ - Z₁|

### 3. Золотой треугольник
Метод проверки геометрии через три ключевые точки, образующие треугольник.

### 4. Крестовые диагонали
Диагонали A-L и B-K - главные индикаторы состояния геометрии кузова.

## Контрольные точки

### Стандартная маркировка точек:
- **A, B**: Передние стойки (левая/правая)
- **C, G**: Пороги передние (левый/правый)
- **D, F**: Центральные точки пола
- **E**: Центр пола
- **H, I**: Пороги задние (левый/правый)
- **K, L**: Задние стойки (левая/правая)
- **M, N**: Высотные отметки

## Основные формулы

### Расчет диагонали по координатам
```dart
double calculateDiagonal(ControlPoint pointA, ControlPoint pointB) {
  final dx = pointB.x - pointA.x;
  final dy = pointB.y - pointA.y;
  final dz = pointB.z - pointA.z;
  
  return math.sqrt(dx * dx + dy * dy + dz * dz);
}
```

### Расчет диагонали по проекциям
```dart
double calculateDiagonalFromProjections(double L, double W, double H) {
  return math.sqrt(L * L + W * W + H * H);
}
```

### Обратный расчет проекции
```dart
double calculateProjectionFromDiagonal(
  double diagonal, 
  double projection1, 
  double projection2
) {
  final remaining = diagonal² - projection1² - projection2²;
  return remaining > 0 ? sqrt(remaining) : 0.0;
}
```

### Теорема косинусов для треугольников
```dart
// Расчет третьей стороны по двум сторонам и углу
double calculateThirdSideWithAngle(double sideA, double sideB, double angle) {
  return math.sqrt(sideA² + sideB² - 2 * sideA * sideB * math.cos(angle));
}

// Расчет угла по трем сторонам
double calculateAngleFromSides(double opposite, double adjacent1, double adjacent2) {
  final cosAngle = (adjacent1² + adjacent2² - opposite²) / (2 * adjacent1 * adjacent2);
  return math.acos(math.max(-1.0, math.min(1.0, cosAngle)));
}
```

## Допуски и точность

### Стандартные допуски:
- **Диагональные размеры**: ±2.0 мм
- **Продольные размеры**: ±1.5 мм  
- **Поперечные размеры**: ±1.0 мм
- **Вертикальные размеры**: ±2.5 мм

### Классификация отклонений:
- **Норма**: ≤ допуска
- **Предупреждение**: 1-2× от допуска
- **Критично**: 2-3× от допуска  
- **Серьезно**: >3× от допуска

## Группы измерений

### 1. Передняя геометрия (front_geometry)
- A-B: Ширина по передним стойкам
- A-E, B-E: Диагонали к центру
- A-F, B-F: Диагонали к задней части

### 2. Задняя геометрия (rear_geometry)  
- K-L: Ширина по задним стойкам
- K-E, L-E: Диагонали к центру
- K-D, L-D: Диагонали к передней части

### 3. Продольная база (longitudinal_base)
- A-K: Левая продольная база
- B-L: Правая продольная база  
- D-F: Центральная база

### 4. Крестовые диагонали (cross_diagonals)
- A-L: Левая передняя к правой задней
- B-K: Правая передняя к левой задней

### 5. Геометрия порогов (sill_geometry)
- C-G: Ширина порогов спереди
- H-I: Ширина порогов сзади
- C-H: Левый порог полная длина
- G-I: Правый порог полная длина

## Статусы геометрии

```dart
enum GeometryStatus {
  good,           // В норме - все размеры в допуске
  needsAttention, // Требует внимания - есть отклонения
  critical,       // Критическое состояние - серьезные нарушения
}
```

## Уровни ремонтопригодности

```dart
enum RepairabilityLevel {
  excellent,    // Отличное состояние (≤2мм)
  good,         // Хорошее, легко ремонтируется (≤5мм)  
  difficult,    // Сложный ремонт (≤порога)
  unrepairable, // Экономически нецелесообразен (>порога)
}
```

## Примеры использования

### Базовый расчет диагонали
```dart
final pointA = ControlPoint(
  name: 'Левая передняя стойка',
  code: 'A',
  position: Vector3(0, -760, 0),
);

final pointB = ControlPoint(
  name: 'Правая передняя стойка', 
  code: 'B',
  position: Vector3(0, 760, 0),
);

final diagonal = BodyGeometryCalculator.calculateDiagonal(pointA, pointB);
print('Диагональ A-B: ${diagonal.toStringAsFixed(1)}мм'); // 1520.0мм
```

### Расчет по проекциям
```dart
final diagonal = BodyGeometryCalculator.calculateDiagonalFromProjections(
  2725.0, // Продольная проекция (база)
  1520.0, // Поперечная проекция (колея)  
  0.0,    // Вертикальная проекция
);
print('Крестовая диагональ: ${diagonal.toStringAsFixed(1)}мм'); // 3156.7мм
```

### Полный анализ геометрии
```dart
final analysis = GeometryAnalysisService.performFullAnalysis(
  controlPoints,
  measurements,
  'Toyota Camry XV70',
);

print('Общий статус: ${analysis.overallStatus}');
print('Завершенность: ${(analysis.completeness * 100).toStringAsFixed(1)}%');

for (final recommendation in analysis.recommendations) {
  print('• $recommendation');
}
```

### Проверка ремонтопригодности
```dart
final assessment = GeometryAnalysisService.assessRepairability(
  analysis,
  criticalThreshold: 5.0,
);

print('Уровень ремонтопригодности: ${assessment.level}');
print('Максимальное отклонение: ${assessment.maxDeviation.toStringAsFixed(1)}мм');
print('Ориентировочная стоимость: ${assessment.estimatedCost.total.toStringAsFixed(0)} руб');
print('Экономически целесообразен: ${assessment.isEconomicallyViable ? "Да" : "Нет"}');
```

### Генерация плана измерений
```dart
final plan = GeometryAnalysisService.generateMeasurementPlan(
  'Toyota Camry XV70',
  prioritizeCritical: true,
);

print('Общее время: ${plan.estimatedTotalTime.toStringAsFixed(1)} мин');

for (final measurement in plan.measurements.take(5)) {
  print('${measurement.diagonalKey}: ${measurement.referenceValue}мм '
        '(±${measurement.tolerance}мм, ${measurement.priority})');
}
```

## Структура данных Toyota Camry XV70

### Критические диагонали
```dart
const criticalDiagonals = [
  'A-L',  // Крестовая диагональ лево-право: 3156.7мм
  'B-K',  // Крестовая диагональ право-лево: 3156.7мм  
  'A-K',  // Левая продольная база: 2725.0мм
  'B-L',  // Правая продольная база: 2725.0мм
  'D-F',  // Центральная база: 1350.0мм
];
```

### Основные размеры
```dart
const mainDimensions = {
  'A-B': 1520.0,  // Ширина по передним стойкам
  'K-L': 1585.0,  // Ширина по задним стойкам
  'A-K': 2725.0,  // Колесная база (левая)
  'B-L': 2725.0,  // Колесная база (правая)
  'C-G': 1610.0,  // Ширина порогов спереди
  'H-I': 1585.0,  // Ширина порогов сзади
};
```

## Решение типовых задач

### 1. Вычисление недостающей диагонали
```dart
// Известны: продольная база A-K = 2725мм, поперечная ширина A-B = 1520мм
// Найти: крестовую диагональ A-L

final diagonal = BodyGeometryCalculator.calculateDiagonalFromProjections(
  2725.0, // Продольная проекция  
  1520.0, // Поперечная проекция
  0.0,    // Вертикальная проекция (на одном уровне)
);
// Результат: 3156.7мм
```

### 2. Проверка симметрии кузова
```dart
final leftPoints = controlPoints.where((p) => p.code.startsWith('A')).toList();
final rightPoints = controlPoints.where((p) => p.code.startsWith('B')).toList();

final symmetryAnalysis = GeometryAnalysisService._analyzeSymmetry(controlPoints);
print('Симметричен: ${symmetryAnalysis.isSymmetric}');
print('Максимальное отклонение: ${symmetryAnalysis.maxDeviation.toStringAsFixed(1)}мм');
```

### 3. Расчет стоимости ремонта
```dart
final repairCost = GeometryAnalysisService._estimateRepairCost(analysis);
print('Диагностика: ${repairCost.diagnostic.toStringAsFixed(0)} руб');
print('Работы: ${repairCost.labor.toStringAsFixed(0)} руб');  
print('Материалы: ${repairCost.materials.toStringAsFixed(0)} руб');
print('Итого: ${repairCost.total.toStringAsFixed(0)} руб');
```

## Интеграция с основным приложением

### В сервисе проекта:
```dart
class ProjectService {
  static Future<BodyGeometryAnalysis> analyzeProjectGeometry(Project project) async {
    final controlPoints = await _loadControlPoints(project.id);
    final measurements = await _loadMeasurements(project.id);
    
    return GeometryAnalysisService.performFullAnalysis(
      controlPoints,
      measurements, 
      project.carModel?.name ?? 'Unknown',
    );
  }
}
```

### В UI компонентах:
```dart
class GeometryAnalysisWidget extends StatelessWidget {
  final BodyGeometryAnalysis analysis;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatusIndicator(analysis.overallStatus),
        _buildCriticalDeviations(analysis.diagonalCheck.criticalDeviations),
        _buildRecommendations(analysis.recommendations),
        _buildRepairabilityAssessment(analysis),
      ],
    );
  }
}
```

## Расширение системы

### Добавление нового автомобиля:
1. Создать константы размеров в `ReferenceDimensions`
2. Добавить проекционные размеры  
3. Определить критические диагонали
4. Настроить группы измерений
5. Установить допуски для конкретной модели

### Пример для нового автомобиля:
```dart
static const Map<String, double> fordFocusMk4Diagonals = {
  'A-B': 1480.0,  // Ширина по передним стойкам
  'K-L': 1520.0,  // Ширина по задним стойкам  
  'A-K': 2648.0,  // Колесная база
  'B-L': 2648.0,  // Колесная база
  // ... остальные размеры
};
```

## Производительность

### Оптимизация вычислений:
- Кэширование результатов расчетов
- Ленивая загрузка эталонных данных
- Использование изолятов для тяжелых вычислений
- Пакетная обработка измерений

### Рекомендации:
- Группировать похожие вычисления
- Использовать Stream для длительных операций
- Кэшировать часто используемые диагонали
- Ограничивать количество одновременных расчетов

## Отладка и диагностика

### Логирование:
```dart
// Включить детальное логирование
Logger.root.level = Level.FINE;

// Логировать все вычисления диагоналей
final diagonal = BodyGeometryCalculator.calculateDiagonal(pointA, pointB);
Logger.root.info('Diagonal ${pointA.code}-${pointB.code}: ${diagonal}mm');
```

### Валидация входных данных:
```dart
assert(pointA.position.isFinite, 'Point A coordinates must be finite');
assert(pointB.position.isFinite, 'Point B coordinates must be finite');
assert(diagonal > 0, 'Diagonal must be positive');
```

## Тестирование

### Юнит-тесты:
```dart
test('calculateDiagonal should return correct distance', () {
  final pointA = ControlPoint(code: 'A', position: Vector3(0, 0, 0));
  final pointB = ControlPoint(code: 'B', position: Vector3(3, 4, 0));
  
  final result = BodyGeometryCalculator.calculateDiagonal(pointA, pointB);
  
  expect(result, closeTo(5.0, 0.001));
});
```

### Интеграционные тесты:
```dart
testWidgets('geometry analysis should complete successfully', (tester) async {
  final analysis = GeometryAnalysisService.performFullAnalysis(
    testControlPoints,
    testMeasurements,
    'Test Vehicle',
  );
  
  expect(analysis.overallStatus, isA<GeometryStatus>());
  expect(analysis.completeness, inInclusiveRange(0.0, 1.0));
});
```

---

**Версия документации**: 1.0  
**Дата обновления**: ${DateTime.now().toString().substring(0, 10)}  
**Совместимость**: Flutter 3.0+, Dart 3.0+