# API Reference - Система геометрии кузова ABRA

## Обзор

Данный документ содержит полный справочник по API системы расчета геометрии кузова ABRA, включая примеры использования, параметры методов и возвращаемые значения.

---

## BodyGeometryCalculator

Основной класс для математических вычислений геометрии кузова.

### Методы

#### calculateDiagonal()
Вычисляет диагональ между двумя контрольными точками в 3D пространстве.

```dart
static double calculateDiagonal(ControlPoint pointA, ControlPoint pointB)
```

**Параметры:**
- `pointA` (ControlPoint): Первая контрольная точка
- `pointB` (ControlPoint): Вторая контрольная точка

**Возвращает:** `double` - Длина диагонали в миллиметрах

**Пример:**
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

---

#### calculateDiagonalFromProjections()
Вычисляет диагональ по известным проекционным длинам.

```dart
static double calculateDiagonalFromProjections(double L, double W, double H)
```

**Параметры:**
- `L` (double): Продольная проекция (Length) в мм
- `W` (double): Поперечная проекция (Width) в мм  
- `H` (double): Вертикальная проекция (Height) в мм

**Возвращает:** `double` - Длина диагонали в миллиметрах

**Формула:** `√(L² + W² + H²)`

**Пример:**
```dart
// Крестовая диагональ Toyota Camry
final diagonal = BodyGeometryCalculator.calculateDiagonalFromProjections(
  2725.0, // База (продольная)
  1520.0, // Колея (поперечная)
  0.0,    // Одинаковая высота
);
print('Крестовая диагональ: ${diagonal.toStringAsFixed(1)}мм'); // 3156.7мм
```

---

#### calculateProjectionFromDiagonal()
Обратное вычисление: находит одну проекцию по диагонали и двум другим проекциям.

```dart
static double calculateProjectionFromDiagonal(
  double diagonal, 
  double projection1, 
  double projection2
)
```

**Параметры:**
- `diagonal` (double): Известная диагональ в мм
- `projection1` (double): Первая известная проекция в мм
- `projection2` (double): Вторая известная проекция в мм

**Возвращает:** `double` - Неизвестная проекция в миллиметрах

**Формула:** `√(diagonal² - projection1² - projection2²)`

**Пример:**
```dart
// Известны: диагональ = 3156.7мм, база = 2725.0мм
// Найти: колею
final trackWidth = BodyGeometryCalculator.calculateProjectionFromDiagonal(
  3156.7, // Крестовая диагональ
  2725.0, // База
  0.0,    // Высота = 0
);
print('Колея: ${trackWidth.toStringAsFixed(1)}мм'); // 1520.0мм
```

---

#### calculateProjections()
Вычисляет проекционные длины между двумя точками по всем трем осям.

```dart
static ProjectionLengths calculateProjections(ControlPoint pointA, ControlPoint pointB)
```

**Параметры:**
- `pointA` (ControlPoint): Первая точка
- `pointB` (ControlPoint): Вторая точка

**Возвращает:** `ProjectionLengths` - Объект с проекциями по трем осям

**Пример:**
```dart
final projections = BodyGeometryCalculator.calculateProjections(pointA, pointB);

print('Продольная проекция: ${projections.longitudinal}мм');
print('Поперечная проекция: ${projections.lateral}мм');
print('Вертикальная проекция: ${projections.vertical}мм');
print('Общая диагональ: ${projections.totalDiagonal}мм');
print('Горизонтальная диагональ: ${projections.horizontalDiagonal}мм');
```

---

#### isTriangleValid()
Проверяет геометрическую корректность треугольника по правилу суммы сторон.

```dart
static bool isTriangleValid(double side1, double side2, double side3)
```

**Параметры:**
- `side1`, `side2`, `side3` (double): Длины сторон треугольника в мм

**Возвращает:** `bool` - true, если треугольник корректен

**Правило:** Сумма любых двух сторон должна быть больше третьей стороны

**Пример:**
```dart
final isValid = BodyGeometryCalculator.isTriangleValid(1520.0, 2725.0, 3156.7);
print('Треугольник корректен: $isValid'); // true

final isInvalid = BodyGeometryCalculator.isTriangleValid(100.0, 200.0, 400.0);
print('Треугольник корректен: $isInvalid'); // false (100+200 < 400)
```

---

#### calculateThirdSideWithAngle()
Вычисляет третью сторону треугольника по двум сторонам и углу между ними (теорема косинусов).

```dart
static double calculateThirdSideWithAngle(
  double sideA, 
  double sideB, 
  double angleInRadians
)
```

**Параметры:**
- `sideA` (double): Первая сторона в мм
- `sideB` (double): Вторая сторона в мм
- `angleInRadians` (double): Угол между сторонами в радианах

**Возвращает:** `double` - Длина третьей стороны в мм

**Формула:** `√(a² + b² - 2ab×cos(C))`

**Пример:**
```dart
import 'dart:math' as math;

// Треугольник со сторонами 1000мм, 1500мм и углом 90°
final thirdSide = BodyGeometryCalculator.calculateThirdSideWithAngle(
  1000.0,
  1500.0, 
  math.pi / 2, // 90° в радианах
);
print('Третья сторона: ${thirdSide.toStringAsFixed(1)}мм'); // 1802.8мм
```

---

#### calculateAngleFromSides()
Находит угол в треугольнике по трем сторонам (обратная теорема косинусов).

```dart
static double calculateAngleFromSides(double opposite, double adjacent1, double adjacent2)
```

**Параметры:**
- `opposite` (double): Сторона, противоположная искомому углу
- `adjacent1` (double): Первая прилежащая сторона
- `adjacent2` (double): Вторая прилежащая сторона

**Возвращает:** `double` - Угол в радианах

**Формула:** `arccos((b² + c² - a²) / (2bc))`

**Пример:**
```dart
final angle = BodyGeometryCalculator.calculateAngleFromSides(
  1520.0, // Противоположная сторона (ширина)
  2725.0, // Прилежащая сторона (база левая)
  2725.0, // Прилежащая сторона (база правая)
);

final angleInDegrees = angle * 180 / math.pi;
print('Угол: ${angleInDegrees.toStringAsFixed(1)}°'); // ~31.0°
```

---

#### calculateWheelbase()
Вычисляет колесную базу как расстояние между передней и задней осями.

```dart
static double calculateWheelbase(
  List<ControlPoint> frontAxisPoints, 
  List<ControlPoint> rearAxisPoints
)
```

**Параметры:**
- `frontAxisPoints` (List<ControlPoint>): Точки передней оси
- `rearAxisPoints` (List<ControlPoint>): Точки задней оси

**Возвращает:** `double` - Колесная база в мм

**Пример:**
```dart
final frontPoints = [pointA, pointB]; // Передние стойки
final rearPoints = [pointK, pointL];  // Задние стойки

final wheelbase = BodyGeometryCalculator.calculateWheelbase(frontPoints, rearPoints);
print('Колесная база: ${wheelbase.toStringAsFixed(1)}мм'); // 2725.0мм
```

---

#### calculateTrackWidth()
Вычисляет ширину колеи между левой и правой сторонами.

```dart
static double calculateTrackWidth(
  List<ControlPoint> leftPoints, 
  List<ControlPoint> rightPoints
)
```

**Параметры:**
- `leftPoints` (List<ControlPoint>): Точки левой стороны
- `rightPoints` (List<ControlPoint>): Точки правой стороны

**Возвращает:** `double` - Ширина колеи в мм

**Пример:**
```dart
final leftPoints = [pointA, pointK];  // Левые стойки
final rightPoints = [pointB, pointL]; // Правые стойки

final trackWidth = BodyGeometryCalculator.calculateTrackWidth(leftPoints, rightPoints);
print('Ширина колеи: ${trackWidth.toStringAsFixed(1)}мм'); // 1520.0мм
```

---

#### validateGoldenTriangle()
Проверяет геометрию "золотого треугольника" между тремя контрольными точками.

```dart
static GeometryValidationResult validateGoldenTriangle(
  ControlPoint pointA, 
  ControlPoint pointB, 
  ControlPoint pointC,
  {double tolerance = 2.0}
)
```

**Параметры:**
- `pointA`, `pointB`, `pointC` (ControlPoint): Вершины треугольника
- `tolerance` (double): Допуск в мм (по умолчанию 2.0)

**Возвращает:** `GeometryValidationResult` - Результат валидации с рекомендациями

**Пример:**
```dart
final result = BodyGeometryCalculator.validateGoldenTriangle(
  pointA, 
  pointE, 
  pointK,
  tolerance: 2.0,
);

print('Треугольник корректен: ${result.isValid}');
print('Рекомендации:');
for (final recommendation in result.recommendations) {
  print('  • $recommendation');
}
```

---

#### performDiagonalCheck()
Выполняет полную проверку диагоналей между контрольными точками.

```dart
static DiagonalCheckResult performDiagonalCheck(
  List<ControlPoint> points,
  Map<String, double> referenceValues,
  {double tolerance = 2.0}
)
```

**Параметры:**
- `points` (List<ControlPoint>): Список контрольных точек
- `referenceValues` (Map<String, double>): Эталонные значения диагоналей
- `tolerance` (double): Допуск в мм

**Возвращает:** `DiagonalCheckResult` - Результат проверки со статистикой

**Пример:**
```dart
final result = BodyGeometryCalculator.performDiagonalCheck(
  controlPoints,
  ReferenceDimensions.toyotaCamryXV70Diagonals,
  tolerance: 2.0,
);

print('Общий статус: ${result.overallStatus}');
print('Измерений в норме: ${result.normalMeasurements}');
print('Критических отклонений: ${result.criticalDeviations.length}');

for (final deviation in result.criticalDeviations) {
  print('${deviation.pointA}-${deviation.pointB}: '
        '${deviation.deviation.toStringAsFixed(1)}мм '
        '(${deviation.deviationPercentage.toStringAsFixed(1)}%)');
}
```

---

## ReferenceDimensions

Класс для работы с эталонными размерами и допусками.

### Константы

#### toyotaCamryXV70Diagonals
Эталонные диагонали для Toyota Camry XV70 (2018-2023).

```dart
static const Map<String, double> toyotaCamryXV70Diagonals
```

**Ключевые размеры:**
```dart
const examples = {
  'A-B': 1520.0,  // Ширина по передним стойкам
  'A-K': 2725.0,  // Левая продольная база
  'B-L': 2725.0,  // Правая продольная база
  'A-L': 3156.7,  // Крестовая диагональ лево-право
  'B-K': 3156.7,  // Крестовая диагональ право-лево
  'K-L': 1585.0,  // Ширина по задним стойкам
};
```

---

#### toyotaCamryXV70Projections
Проекционные размеры для вычисления диагоналей.

```dart
static const Map<String, ProjectionDimensions> toyotaCamryXV70Projections
```

**Пример:**
```dart
const examples = {
  'A-B': ProjectionDimensions(x: 0, y: 1520, z: 0),      // Ширина передних стоек
  'A-K': ProjectionDimensions(x: 2725, y: 0, z: 0),      // Левая база
  'E-M': ProjectionDimensions(x: 0, y: 0, z: 420),       // Высота тоннеля
};
```

---

#### tolerances
Допуски для различных типов измерений.

```dart
static const Map<String, double> tolerances
```

**Значения:**
```dart
const tolerances = {
  'diagonal': 2.0,      // Диагональные размеры ±2мм
  'longitudinal': 1.5,  // Продольные размеры ±1.5мм
  'lateral': 1.0,       // Поперечные размеры ±1мм
  'vertical': 2.5,      // Вертикальные размеры ±2.5мм
};
```

---

#### criticalDiagonals
Список критических диагоналей для первоочередной проверки.

```dart
static const List<String> criticalDiagonals
```

**Значения:**
```dart
const criticalDiagonals = [
  'A-L',  // Крестовая диагональ лево-право
  'B-K',  // Крестовая диагональ право-лево
  'A-K',  // Левая продольная база
  'B-L',  // Правая продольная база
  'D-F',  // Центральная база
];
```

---

#### measurementGroups
Группы связанных измерений для системной проверки.

```dart
static const Map<String, List<String>> measurementGroups
```

**Группы:**
```dart
const measurementGroups = {
  'front_geometry': ['A-B', 'A-E', 'B-E', 'A-F', 'B-F'],
  'rear_geometry': ['K-L', 'K-E', 'L-E', 'K-D', 'L-D'],
  'longitudinal_base': ['A-K', 'B-L', 'D-F'],
  'cross_diagonals': ['A-L', 'B-K'],
  'sill_geometry': ['C-G', 'H-I', 'C-H', 'G-I'],
};
```

### Методы

#### calculateExpectedDiagonal()
Вычисляет ожидаемое значение диагонали по проекциям.

```dart
static double calculateExpectedDiagonal(String diagonalKey)
```

**Параметры:**
- `diagonalKey` (String): Ключ диагонали (например, 'A-B')

**Возвращает:** `double` - Ожидаемое значение в мм

**Пример:**
```dart
final expected = ReferenceDimensions.calculateExpectedDiagonal('A-L');
print('Ожидаемая диагональ A-L: ${expected.toStringAsFixed(1)}мм'); // 3156.7мм
```

---

#### getReferenceValue()
Получает эталонное значение для измерения.

```dart
static double getReferenceValue(String measurementKey, String measurementType)
```

**Параметры:**
- `measurementKey` (String): Ключ измерения
- `measurementType` (String): Тип измерения ('diagonal', 'calculated')

**Возвращает:** `double` - Эталонное значение в мм

**Пример:**
```dart
final reference = ReferenceDimensions.getReferenceValue('A-B', 'diagonal');
print('Эталон A-B: ${reference}мм'); // 1520.0мм
```

---

#### getToleranceForType()
Получает допуск для типа измерения.

```dart
static double getToleranceForType(String measurementType)
```

**Параметры:**
- `measurementType` (String): Тип измерения

**Возвращает:** `double` - Допуск в мм

**Пример:**
```dart
final tolerance = ReferenceDimensions.getToleranceForType('diagonal');
print('Допуск для диагоналей: ±${tolerance}мм'); // ±2.0мм
```

---

#### isCriticalDiagonal()
Проверяет, является ли диагональ критической.

```dart
static bool isCriticalDiagonal(String diagonalKey)
```

**Параметры:**
- `diagonalKey` (String): Ключ диагонали

**Возвращает:** `bool` - true, если диагональ критическая

**Пример:**
```dart
final isCritical = ReferenceDimensions.isCriticalDiagonal('A-L');
print('A-L критическая: $isCritical'); // true

final isNotCritical = ReferenceDimensions.isCriticalDiagonal('C-G');
print('C-G критическая: $isNotCritical'); // false
```

---

#### getMeasurementGroup()
Получает список измерений для группы.

```dart
static List<String> getMeasurementGroup(String groupName)
```

**Параметры:**
- `groupName` (String): Название группы

**Возвращает:** `List<String>` - Список ключей измерений

**Пример:**
```dart
final frontGeometry = ReferenceDimensions.getMeasurementGroup('front_geometry');
print('Передняя геометрия:');
for (final measurement in frontGeometry) {
  print('  • $measurement');
}
// Вывод:
// • A-B
// • A-E  
// • B-E
// • A-F
// • B-F
```

---

#### validateMeasurementGroup()
Валидирует полный набор измерений для группы.

```dart
static GroupValidationResult validateMeasurementGroup(
  String groupName,
  Map<String, double> actualMeasurements,
)
```

**Параметры:**
- `groupName` (String): Название группы
- `actualMeasurements` (Map<String, double>): Фактические измерения

**Возвращает:** `GroupValidationResult` - Результат валидации группы

**Пример:**
```dart
final actualMeasurements = {
  'A-B': 1521.5,  // +1.5мм от эталона
  'A-E': 1845.0,  // -2.5мм от эталона
  'B-E': 1849.0,  // +1.5мм от эталона
};

final result = ReferenceDimensions.validateMeasurementGroup(
  'front_geometry',
  actualMeasurements,
);

print('Группа валидна: ${result.isValid}');
print('Завершенность: ${result.completenessStatus}');
print('Критические отклонения: ${result.criticalDeviations.length}');
```

---

## GeometryAnalysisService

Высокоуровневый сервис для анализа геометрии кузова.

### Методы

#### performFullAnalysis()
Выполняет полный анализ геометрии кузова.

```dart
static BodyGeometryAnalysis performFullAnalysis(
  List<ControlPoint> controlPoints,
  List<Measurement> measurements,
  String vehicleModel,
)
```

**Параметры:**
- `controlPoints` (List<ControlPoint>): Контрольные точки
- `measurements` (List<Measurement>): Измерения
- `vehicleModel` (String): Модель автомобиля

**Возвращает:** `BodyGeometryAnalysis` - Полный анализ геометрии

**Пример:**
```dart
final analysis = GeometryAnalysisService.performFullAnalysis(
  controlPoints,
  measurements,
  'Toyota Camry XV70',
);

print('Статус: ${analysis.overallStatus}');
print('Завершенность: ${(analysis.completeness * 100).toStringAsFixed(1)}%');
print('Симметричен: ${analysis.symmetryAnalysis.isSymmetric}');
print('Критические размеры ОК: ${analysis.criticalAnalysis.allCriticalOk}');

print('\nРекомендации:');
for (final recommendation in analysis.recommendations) {
  print('• $recommendation');
}
```

---

#### calculateMissingDimensions()
Вычисляет недостающие размеры на основе известных точек.

```dart
static Map<String, double> calculateMissingDimensions(
  List<ControlPoint> knownPoints,
  List<String> requiredDiagonals,
)
```

**Параметры:**
- `knownPoints` (List<ControlPoint>): Известные контрольные точки
- `requiredDiagonals` (List<String>): Требуемые диагонали

**Возвращает:** `Map<String, double>` - Карта вычисленных размеров

**Пример:**
```dart
final requiredDiagonals = ['A-B', 'A-K', 'A-L'];
final calculated = GeometryAnalysisService.calculateMissingDimensions(
  controlPoints,
  requiredDiagonals,
);

for (final entry in calculated.entries) {
  print('${entry.key}: ${entry.value.toStringAsFixed(1)}мм');
}
// Вывод:
// A-B: 1520.0мм
// A-K: 2725.0мм  
// A-L: 3156.7мм
```

---

#### assessRepairability()
Оценивает ремонтопригодность на основе анализа геометрии.

```dart
static RepairabilityAssessment assessRepairability(
  BodyGeometryAnalysis analysis,
  {double criticalThreshold = 5.0}
)
```

**Параметры:**
- `analysis` (BodyGeometryAnalysis): Результат анализа геометрии
- `criticalThreshold` (double): Критический порог отклонения в мм

**Возвращает:** `RepairabilityAssessment` - Оценка ремонтопригодности

**Пример:**
```dart
final assessment = GeometryAnalysisService.assessRepairability(
  analysis,
  criticalThreshold: 5.0,
);

print('Уровень: ${assessment.level}');
print('Максимальное отклонение: ${assessment.maxDeviation.toStringAsFixed(1)}мм');
print('Критические точки: ${assessment.criticalPoints.join(', ')}');
print('Стоимость: ${assessment.estimatedCost.total.toStringAsFixed(0)} руб');
print('Экономически целесообразен: ${assessment.isEconomicallyViable ? "Да" : "Нет"}');

print('\nПлан ремонта:');
for (int i = 0; i < assessment.repairSteps.length; i++) {
  print('${i + 1}. ${assessment.repairSteps[i]}');
}
```

---

#### generateMeasurementPlan()
Генерирует план измерений для проверки геометрии.

```dart
static MeasurementPlan generateMeasurementPlan(
  String vehicleModel,
  {bool prioritizeCritical = true}
)
```

**Параметры:**
- `vehicleModel` (String): Модель автомобиля
- `prioritizeCritical` (bool): Приоритизировать критические измерения

**Возвращает:** `MeasurementPlan` - План измерений с временными оценками

**Пример:**
```dart
final plan = GeometryAnalysisService.generateMeasurementPlan(
  'Toyota Camry XV70',
  prioritizeCritical: true,
);

print('Модель: ${plan.vehicleModel}');
print('Всего измерений: ${plan.measurements.length}');
print('Общее время: ${plan.estimatedTotalTime.toStringAsFixed(1)} мин');

print('\nПервые 5 измерений:');
for (int i = 0; i < 5 && i < plan.measurements.length; i++) {
  final measurement = plan.measurements[i];
  print('${i + 1}. ${measurement.diagonalKey}: '
        '${measurement.referenceValue.toStringAsFixed(1)}мм '
        '(±${measurement.tolerance}мм, ${measurement.priority}, '
        '${measurement.estimatedTime}мин)');
}
```

---

## Типы данных

### ProjectionLengths
Класс для хранения проекционных длин.

```dart
class ProjectionLengths {
  final double longitudinal; // X - продольная
  final double lateral;      // Y - поперечная  
  final double vertical;     // Z - вертикальная
  
  // Вычисляемые свойства
  double get totalDiagonal;      // Полная диагональ √(L²+W²+H²)
  double get horizontalDiagonal; // Горизонтальная диагональ √(L²+W²)
}
```

### DiagonalMeasurement
Результат измерения диагонали.

```dart
class DiagonalMeasurement {
  final String pointA;                // Код первой точки
  final String pointB;                // Код второй точки  
  final double measured;              // Измеренное значение
  final double reference;             // Эталонное значение
  final double deviation;             // Отклонение (measured - reference)
  final bool isWithinTolerance;       // В пределах допуска
  final ProjectionLengths projections; // Проекционные длины
  
  // Вычисляемые свойства
  double get deviationPercentage; // Процентное отклонение
}
```

### DiagonalCheckResult
Результат проверки диагоналей.

```dart
class DiagonalCheckResult {
  final Map<String, DiagonalMeasurement> measurements; // Все измерения
  final GeometryStatus overallStatus;                  // Общий статус
  
  // Вычисляемые свойства
  List<DiagonalMeasurement> get criticalDeviations; // Критические отклонения
  int get normalMeasurements;                        // Количество нормальных измерений
}
```

### BodyGeometryAnalysis
Полный анализ геометрии кузова.

```dart
class BodyGeometryAnalysis {
  final GeometryStatus overallStatus;                         // Общий статус
  final DiagonalCheckResult diagonalCheck;                    // Проверка диагоналей
  final Map<String, GroupValidationResult> groupResults;     // Результаты по группам
  final SymmetryAnalysis symmetryAnalysis;                   // Анализ симметрии
  final CriticalDimensionsAnalysis criticalAnalysis;         // Критические размеры
  final List<String> recommendations;                        // Рекомендации
  final double completeness;                                  // Завершенность (0.0-1.0)
}
```

### RepairabilityAssessment
Оценка ремонтопригодности.

```dart
class RepairabilityAssessment {
  final RepairabilityLevel level;         // Уровень ремонтопригодности
  final double maxDeviation;              // Максимальное отклонение
  final List<String> criticalPoints;     // Критические точки
  final RepairCost estimatedCost;         // Ориентировочная стоимость
  final List<String> repairSteps;        // Этапы ремонта
  final bool isEconomicallyViable;       // Экономическая целесообразность
}
```

### RepairCost
Структура стоимости ремонта.

```dart
class RepairCost {
  final double diagnostic; // Стоимость диагностики
  final double labor;      // Стоимость работ
  final double materials;  // Стоимость материалов
  
  double get total; // Общая стоимость
}
```

---

## Перечисления (Enums)

### GeometryStatus
Статус геометрии кузова.

```dart
enum GeometryStatus {
  good,           // В норме - все размеры в допуске
  needsAttention, // Требует внимания - есть отклонения
  critical,       // Критическое состояние - серьезные нарушения
}
```

### RepairabilityLevel
Уровень ремонтопригодности.

```dart
enum RepairabilityLevel {
  excellent,    // Отличное состояние (≤2мм)
  good,         // Хорошее, легко ремонтируется (≤5мм)
  difficult,    // Сложный ремонт (до критического порога)
  unrepairable, // Экономически нецелесообразен (>критического порога)
}
```

### Priority
Приоритет измерения.

```dart
enum Priority {
  critical,  // Критично - первоочередные измерения
  high,      // Высокий приоритет
  normal,    // Обычный приоритет
  low,       // Низкий приоритет
}
```

---

## Примеры интеграции

### Использование в виджете Flutter

```dart
class GeometryAnalysisWidget extends StatefulWidget {
  final List<ControlPoint> controlPoints;
  final List<Measurement> measurements;
  
  @override
  _GeometryAnalysisWidgetState createState() => _GeometryAnalysisWidgetState();
}

class _GeometryAnalysisWidgetState extends State<GeometryAnalysisWidget> {
  BodyGeometryAnalysis? _analysis;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _performAnalysis();
  }
  
  Future<void> _performAnalysis() async {
    setState(() => _isLoading = true);
    
    try {
      final analysis = GeometryAnalysisService.performFullAnalysis(
        widget.controlPoints,
        widget.measurements,
        'Toyota Camry XV70',
      );
      
      setState(() {
        _analysis = analysis;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка анализа: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_analysis == null) {
      return const Center(child: Text('Нет данных для анализа'));
    }
    
    return Column(
      children: [
        _buildStatusCard(_analysis!),
        _buildDiagonalsCard(_analysis!),
        _buildRecommendationsCard(_analysis!),
      ],
    );
  }
  
  Widget _buildStatusCard(BodyGeometryAnalysis analysis) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Общий статус', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getStatusIcon(analysis.overallStatus),
                  color: _getStatusColor(analysis.overallStatus),
                ),
                const SizedBox(width: 8),
                Text(_getStatusText(analysis.overallStatus)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: analysis.completeness,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getStatusColor(analysis.overallStatus),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Завершенность: ${(analysis.completeness * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDiagonalsCard(BodyGeometryAnalysis analysis) {
    final criticalDeviations = analysis.diagonalCheck.criticalDeviations;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Диагонали', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Измерений в норме: ${analysis.diagonalCheck.normalMeasurements}'),
            Text('Критических отклонений: ${criticalDeviations.length}'),
            if (criticalDeviations.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Критические отклонения:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...criticalDeviations.map((deviation) => Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  '${deviation.pointA}-${deviation.pointB}: '
                  '${deviation.deviation > 0 ? '+' : ''}'
                  '${deviation.deviation.toStringAsFixed(1)}мм',
                  style: TextStyle(
                    color: deviation.deviation.abs() > 5 ? Colors.red : Colors.orange,
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecommendationsCard(BodyGeometryAnalysis analysis) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Рекомендации', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (analysis.recommendations.isEmpty)
              const Text('Нет рекомендаций')
            else
              ...analysis.recommendations.map((recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(recommendation)),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }
  
  IconData _getStatusIcon(GeometryStatus status) {
    switch (status) {
      case GeometryStatus.good:
        return Icons.check_circle;
      case GeometryStatus.needsAttention:
        return Icons.warning;
      case GeometryStatus.critical:
        return Icons.error;
    }
  }
  
  Color _getStatusColor(GeometryStatus status) {
    switch (status) {
      case GeometryStatus.good:
        return Colors.green;
      case GeometryStatus.needsAttention:
        return Colors.orange;
      case GeometryStatus.critical:
        return Colors.red;
    }
  }
  
  String _getStatusText(GeometryStatus status) {
    switch (status) {
      case GeometryStatus.good:
        return 'В норме';
      case GeometryStatus.needsAttention:
        return 'Требует внимания';
      case GeometryStatus.critical:
        return 'Критическое состояние';
    }
  }
}
```

---

## Обработка ошибок

### Типичные исключения

```dart
try {
  final diagonal = BodyGeometryCalculator.calculateDiagonal(pointA, pointB);
} catch (e) {
  if (e is ArgumentError) {
    print('Некорректные параметры: $e');
  } else if (e is StateError) {
    print('Некорректное состояние: $e');
  } else {
    print('Неожиданная ошибка: $e');
  }
}
```

### Валидация входных данных

```dart
bool validateControlPoint(ControlPoint point) {
  if (point.code.isEmpty) {
    throw ArgumentError('Код контрольной точки не может быть пустым');
  }
  
  if (!point.position.isFinite) {
    throw ArgumentError('Координаты точки должны быть конечными числами');
  }
  
  return true;
}

bool validateDiagonal(double diagonal) {
  if (diagonal <= 0) {
    throw ArgumentError('Диагональ должна быть положительным числом');
  }
  
  if (diagonal > 10000) {
    throw ArgumentError('Диагональ слишком большая (>${diagonal}мм)');
  }
  
  return true;
}
```

---

**Версия API**: 1.0  
**Совместимость**: Flutter 3.0+, Dart 3.0+  
**Последнее обновление**: ${DateTime.now().toString().substring(0, 10)}