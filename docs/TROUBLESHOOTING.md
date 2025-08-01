# Руководство по устранению неполадок - Система геометрии ABRA

## Обзор

Данное руководство поможет диагностировать и устранить типичные проблемы при работе с системой расчета геометрии кузова ABRA.

---

## Общие проблемы и решения

### 1. Ошибки вычислений

#### Проблема: "Диагональ возвращает NaN или бесконечность"

**Симптомы:**
```dart
final diagonal = BodyGeometryCalculator.calculateDiagonal(pointA, pointB);
print(diagonal); // NaN или Infinity
```

**Причины:**
- Некорректные координаты контрольных точек
- Бесконечные или недопустимые значения в Vector3

**Решение:**
```dart
// Проверка корректности координат
bool validateControlPoint(ControlPoint point) {
  if (!point.position.x.isFinite || 
      !point.position.y.isFinite || 
      !point.position.z.isFinite) {
    print('Ошибка: некорректные координаты точки ${point.code}');
    return false;
  }
  return true;
}

// Использование
if (validateControlPoint(pointA) && validateControlPoint(pointB)) {
  final diagonal = BodyGeometryCalculator.calculateDiagonal(pointA, pointB);
} else {
  print('Невозможно вычислить диагональ: некорректные данные');
}
```

---

#### Проблема: "Неожиданно большие значения диагоналей"

**Симптомы:**
```dart
final diagonal = BodyGeometryCalculator.calculateDiagonal(pointA, pointB);
print(diagonal); // 25000.0 (ожидалось ~1500.0)
```

**Причины:**
- Ошибка в системе координат (метры вместо миллиметров)
- Неправильное масштабирование данных

**Решение:**
```dart
// Проверка диапазона значений
double validateDiagonal(double diagonal, String diagonalKey) {
  const minDiagonal = 100.0;   // 100мм - минимум
  const maxDiagonal = 5000.0;  // 5000мм - максимум
  
  if (diagonal < minDiagonal || diagonal > maxDiagonal) {
    print('Предупреждение: диагональ $diagonalKey = ${diagonal}мм '
          'выходит за разумные пределы');
    
    // Возможное исправление масштаба
    if (diagonal > 10000) {
      print('Возможно, значения в метрах. Конвертирую в мм...');
      return diagonal * 1000; // м → мм
    }
  }
  
  return diagonal;
}
```

---

### 2. Проблемы с эталонными данными

#### Проблема: "Эталонное значение не найдено"

**Симптомы:**
```dart
final reference = ReferenceDimensions.getReferenceValue('A-Z', 'diagonal');
print(reference); // 0.0 (должно быть > 0)
```

**Причины:**
- Неправильный ключ диагонали
- Отсутствие данных для конкретной модели

**Решение:**
```dart
// Проверка существования эталонного значения
double getReferenceValueSafe(String measurementKey, String measurementType) {
  final reference = ReferenceDimensions.getReferenceValue(measurementKey, measurementType);
  
  if (reference <= 0) {
    print('Предупреждение: эталонное значение для $measurementKey не найдено');
    
    // Попробовать вычислить через проекции
    final calculated = ReferenceDimensions.calculateExpectedDiagonal(measurementKey);
    if (calculated > 0) {
      print('Использую расчетное значение: ${calculated}мм');
      return calculated;
    }
    
    // Последняя попытка - поиск похожего ключа
    final similarKey = findSimilarDiagonalKey(measurementKey);
    if (similarKey != null) {
      print('Найден похожий ключ: $similarKey');
      return ReferenceDimensions.getReferenceValue(similarKey, measurementType);
    }
  }
  
  return reference;
}

String? findSimilarDiagonalKey(String key) {
  final allKeys = ReferenceDimensions.toyotaCamryXV70Diagonals.keys;
  
  // Поиск обратной диагонали (A-B → B-A)
  final parts = key.split('-');
  if (parts.length == 2) {
    final reversedKey = '${parts[1]}-${parts[0]}';
    if (allKeys.contains(reversedKey)) {
      return reversedKey;
    }
  }
  
  return null;
}
```

---

#### Проблема: "Противоречивые эталонные данные"

**Симптомы:**
```dart
// A-B = 1520мм, но B-A = 1525мм
final ab = ReferenceDimensions.getReferenceValue('A-B', 'diagonal');
final ba = ReferenceDimensions.getReferenceValue('B-A', 'diagonal');
print('A-B: $ab, B-A: $ba'); // Должны быть равны
```

**Решение:**
```dart
// Проверка симметрии эталонных данных
void validateReferenceDataConsistency() {
  final diagonals = ReferenceDimensions.toyotaCamryXV70Diagonals;
  final inconsistencies = <String>[];
  
  for (final entry in diagonals.entries) {
    final key = entry.key;
    final value = entry.value;
    
    // Проверка обратной диагонали
    final parts = key.split('-');
    if (parts.length == 2) {
      final reversedKey = '${parts[1]}-${parts[0]}';
      final reversedValue = diagonals[reversedKey];
      
      if (reversedValue != null && (value - reversedValue).abs() > 0.1) {
        inconsistencies.add('$key=$value ≠ $reversedKey=$reversedValue');
      }
    }
  }
  
  if (inconsistencies.isNotEmpty) {
    print('Обнаружены противоречия в эталонных данных:');
    for (final inconsistency in inconsistencies) {
      print('  • $inconsistency');
    }
  }
}
```

---

### 3. Проблемы анализа геометрии

#### Проблема: "Анализ завершается с ошибкой"

**Симптомы:**
```dart
final analysis = GeometryAnalysisService.performFullAnalysis(
  controlPoints, measurements, 'Toyota Camry XV70'
);
// Exception: FormatException, StateError, etc.
```

**Причины:**
- Недостаточно контрольных точек
- Отсутствие измерений
- Поврежденные данные

**Решение:**
```dart
BodyGeometryAnalysis? performAnalysisSafe(
  List<ControlPoint> controlPoints,
  List<Measurement> measurements,
  String vehicleModel,
) {
  // Предварительные проверки
  if (controlPoints.isEmpty) {
    print('Ошибка: отсутствуют контрольные точки');
    return null;
  }
  
  if (controlPoints.length < 3) {
    print('Предупреждение: слишком мало контрольных точек (${controlPoints.length})');
    print('Рекомендуется минимум 5 точек для достоверного анализа');
  }
  
  // Проверка корректности данных
  final validPoints = <ControlPoint>[];
  for (final point in controlPoints) {
    if (validateControlPoint(point)) {
      validPoints.add(point);
    } else {
      print('Пропускаю некорректную точку: ${point.code}');
    }
  }
  
  if (validPoints.length < 3) {
    print('Ошибка: недостаточно корректных контрольных точек');
    return null;
  }
  
  try {
    return GeometryAnalysisService.performFullAnalysis(
      validPoints, 
      measurements, 
      vehicleModel
    );
  } catch (e) {
    print('Ошибка анализа геометрии: $e');
    return null;
  }
}
```

---

#### Проблема: "Анализ показывает некорректные результаты"

**Симптомы:**
```dart
final analysis = GeometryAnalysisService.performFullAnalysis(...);
print(analysis.overallStatus); // GeometryStatus.critical
// При визуально нормальном кузове
```

**Диагностика:**
```dart
void debugAnalysisResults(BodyGeometryAnalysis analysis) {
  print('=== ОТЛАДКА АНАЛИЗА ГЕОМЕТРИИ ===');
  
  // Проверка критических отклонений
  final criticalDeviations = analysis.diagonalCheck.criticalDeviations;
  print('Критических отклонений: ${criticalDeviations.length}');
  
  for (final deviation in criticalDeviations) {
    print('${deviation.pointA}-${deviation.pointB}: '
          'измерено=${deviation.measured.toStringAsFixed(1)}мм, '
          'эталон=${deviation.reference.toStringAsFixed(1)}мм, '
          'отклонение=${deviation.deviation.toStringAsFixed(1)}мм');
    
    // Проверка разумности отклонения
    if (deviation.deviation.abs() > 50) {
      print('  ПОДОЗРИТЕЛЬНО: очень большое отклонение!');
      print('  Проверьте корректность координат точек ${deviation.pointA} и ${deviation.pointB}');
    }
  }
  
  // Проверка симметрии
  print('\nСимметрия:');
  print('  Симметричен: ${analysis.symmetryAnalysis.isSymmetric}');
  print('  Макс. отклонение: ${analysis.symmetryAnalysis.maxDeviation.toStringAsFixed(1)}мм');
  
  // Проверка завершенности
  print('\nЗавершенность: ${(analysis.completeness * 100).toStringAsFixed(1)}%');
  if (analysis.completeness < 0.5) {
    print('  ВНИМАНИЕ: низкая завершенность может влиять на точность анализа');
  }
}
```

---

### 4. Проблемы производительности

#### Проблема: "Медленные вычисления"

**Симптомы:**
- Долгое выполнение `performFullAnalysis()`
- Зависание UI при расчетах

**Решение:**
```dart
// Асинхронное выполнение анализа
Future<BodyGeometryAnalysis?> performAnalysisAsync(
  List<ControlPoint> controlPoints,
  List<Measurement> measurements,
  String vehicleModel,
) async {
  try {
    // Выполняем тяжелые вычисления в изоляте
    return await compute(_performAnalysisInIsolate, {
      'controlPoints': controlPoints.map((p) => p.toJson()).toList(),
      'measurements': measurements.map((m) => m.toJson()).toList(),
      'vehicleModel': vehicleModel,
    });
  } catch (e) {
    print('Ошибка асинхронного анализа: $e');
    return null;
  }
}

BodyGeometryAnalysis _performAnalysisInIsolate(Map<String, dynamic> data) {
  // Десериализация данных
  final controlPoints = (data['controlPoints'] as List)
      .map((json) => ControlPoint.fromJson(json))
      .toList();
  final measurements = (data['measurements'] as List)
      .map((json) => Measurement.fromJson(json))
      .toList();
  
  // Выполнение анализа
  return GeometryAnalysisService.performFullAnalysis(
    controlPoints, 
    measurements, 
    data['vehicleModel']
  );
}
```

---

#### Проблема: "Превышение лимитов памяти"

**Решение:**
```dart
// Оптимизированная версия для больших наборов данных
BodyGeometryAnalysis performLightweightAnalysis(
  List<ControlPoint> controlPoints,
  List<Measurement> measurements,
  String vehicleModel,
) {
  // Фильтруем только критические точки
  final criticalPointCodes = ['A', 'B', 'K', 'L', 'E', 'D', 'F'];
  final criticalPoints = controlPoints
      .where((p) => criticalPointCodes.contains(p.code))
      .toList();
  
  // Ограничиваем количество диагоналей
  final criticalDiagonals = ReferenceDimensions.criticalDiagonals;
  final limitedReferenceValues = <String, double>{};
  
  for (final diagonal in criticalDiagonals) {
    final value = ReferenceDimensions.toyotaCamryXV70Diagonals[diagonal];
    if (value != null) {
      limitedReferenceValues[diagonal] = value;
    }
  }
  
  // Выполняем облегченный анализ
  final diagonalCheck = BodyGeometryCalculator.performDiagonalCheck(
    criticalPoints,
    limitedReferenceValues,
    tolerance: 2.0,
  );
  
  // Возвращаем упрощенный результат
  return BodyGeometryAnalysis(
    overallStatus: diagonalCheck.overallStatus,
    diagonalCheck: diagonalCheck,
    groupResults: {}, // Пустой для экономии памяти
    symmetryAnalysis: SymmetryAnalysis(
      isSymmetric: true, 
      maxDeviation: 0.0, 
      deviations: {}
    ),
    criticalAnalysis: CriticalDimensionsAnalysis(
      allCriticalOk: diagonalCheck.overallStatus == GeometryStatus.good,
      results: {},
      deviations: {},
    ),
    recommendations: diagonalCheck.criticalDeviations.isEmpty 
        ? ['Геометрия в норме'] 
        : ['Обнаружены отклонения'],
    completeness: criticalPoints.length / criticalPointCodes.length,
  );
}
```

---

### 5. Проблемы интеграции с UI

#### Проблема: "Зависание интерфейса при анализе"

**Решение:**
```dart
class GeometryAnalysisWidget extends StatefulWidget {
  @override
  _GeometryAnalysisWidgetState createState() => _GeometryAnalysisWidgetState();
}

class _GeometryAnalysisWidgetState extends State<GeometryAnalysisWidget> {
  BodyGeometryAnalysis? _analysis;
  bool _isLoading = false;
  String _progressText = '';
  
  Future<void> _performAnalysisWithProgress() async {
    setState(() {
      _isLoading = true;
      _progressText = 'Подготовка данных...';
    });
    
    try {
      // Этап 1: Валидация данных
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() => _progressText = 'Проверка контрольных точек...');
      
      // Этап 2: Базовые вычисления
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() => _progressText = 'Расчет диагоналей...');
      
      // Этап 3: Анализ геометрии
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() => _progressText = 'Анализ геометрии...');
      
      final analysis = await performAnalysisAsync(
        widget.controlPoints,
        widget.measurements,
        widget.vehicleModel,
      );
      
      setState(() {
        _analysis = analysis;
        _isLoading = false;
        _progressText = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _progressText = 'Ошибка: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(_progressText),
        ],
      );
    }
    
    // Остальной UI...
    return Container();
  }
}
```

---

### 6. Отладочные инструменты

#### Инструмент 1: Проверка целостности данных

```dart
class DataIntegrityChecker {
  static void checkControlPoints(List<ControlPoint> points) {
    print('=== ПРОВЕРКА КОНТРОЛЬНЫХ ТОЧЕК ===');
    print('Всего точек: ${points.length}');
    
    final codes = <String>[];
    for (final point in points) {
      // Проверка уникальности кодов
      if (codes.contains(point.code)) {
        print('ОШИБКА: дублирующийся код ${point.code}');
      }
      codes.add(point.code);
      
      // Проверка корректности координат
      if (!validateControlPoint(point)) {
        print('ОШИБКА: некорректные координаты точки ${point.code}');
      }
      
      // Проверка разумности координат
      if (point.x.abs() > 3000 || point.y.abs() > 1000 || point.z.abs() > 2000) {
        print('ПРЕДУПРЕЖДЕНИЕ: подозрительные координаты точки ${point.code}: '
              '(${point.x}, ${point.y}, ${point.z})');
      }
    }
    
    // Проверка наличия критических точек
    final criticalCodes = ['A', 'B', 'K', 'L', 'E'];
    for (final code in criticalCodes) {
      if (!codes.contains(code)) {
        print('ПРЕДУПРЕЖДЕНИЕ: отсутствует критическая точка $code');
      }
    }
  }
  
  static void checkMeasurements(List<Measurement> measurements) {
    print('=== ПРОВЕРКА ИЗМЕРЕНИЙ ===');
    print('Всего измерений: ${measurements.length}');
    
    for (final measurement in measurements) {
      // Проверка наличия фактического значения
      if (measurement.actualValue == null) {
        print('ПРЕДУПРЕЖДЕНИЕ: отсутствует фактическое значение для '
              '${measurement.fromPointId}-${measurement.toPointId}');
      }
      
      // Проверка разумности значений
      if (measurement.actualValue != null) {
        if (measurement.actualValue! < 50 || measurement.actualValue! > 5000) {
          print('ПРЕДУПРЕЖДЕНИЕ: подозрительное значение ${measurement.actualValue}мм '
                'для ${measurement.fromPointId}-${measurement.toPointId}');
        }
      }
      
      // Проверка отклонений
      if (measurement.deviation.abs() > 100) {
        print('ОШИБКА: очень большое отклонение ${measurement.deviation.toStringAsFixed(1)}мм '
              'для ${measurement.fromPointId}-${measurement.toPointId}');
      }
    }
  }
}
```

#### Инструмент 2: Экспорт данных для анализа

```dart
class DiagnosticExporter {
  static String exportAnalysisReport(BodyGeometryAnalysis analysis) {
    final buffer = StringBuffer();
    
    buffer.writeln('ОТЧЕТ ДИАГНОСТИКИ ГЕОМЕТРИИ КУЗОВА');
    buffer.writeln('Дата: ${DateTime.now()}');
    buffer.writeln('=' * 50);
    
    // Общий статус
    buffer.writeln('ОБЩИЙ СТАТУС: ${analysis.overallStatus}');
    buffer.writeln('Завершенность: ${(analysis.completeness * 100).toStringAsFixed(1)}%');
    buffer.writeln();
    
    // Диагонали
    buffer.writeln('ДИАГОНАЛИ:');
    buffer.writeln('Всего измерений: ${analysis.diagonalCheck.measurements.length}');
    buffer.writeln('В норме: ${analysis.diagonalCheck.normalMeasurements}');
    buffer.writeln('Критических: ${analysis.diagonalCheck.criticalDeviations.length}');
    buffer.writeln();
    
    if (analysis.diagonalCheck.criticalDeviations.isNotEmpty) {
      buffer.writeln('КРИТИЧЕСКИЕ ОТКЛОНЕНИЯ:');
      for (final deviation in analysis.diagonalCheck.criticalDeviations) {
        buffer.writeln('${deviation.pointA}-${deviation.pointB}: '
                      '${deviation.measured.toStringAsFixed(1)}мм '
                      '(эталон: ${deviation.reference.toStringAsFixed(1)}мм, '
                      'отклонение: ${deviation.deviation > 0 ? '+' : ''}'
                      '${deviation.deviation.toStringAsFixed(1)}мм)');
      }
      buffer.writeln();
    }
    
    // Симметрия
    buffer.writeln('СИММЕТРИЯ:');
    buffer.writeln('Симметричен: ${analysis.symmetryAnalysis.isSymmetric}');
    buffer.writeln('Макс. отклонение: ${analysis.symmetryAnalysis.maxDeviation.toStringAsFixed(1)}мм');
    buffer.writeln();
    
    // Рекомендации
    buffer.writeln('РЕКОМЕНДАЦИИ:');
    for (final recommendation in analysis.recommendations) {
      buffer.writeln('• $recommendation');
    }
    
    return buffer.toString();
  }
  
  static Map<String, dynamic> exportRawData(
    List<ControlPoint> controlPoints,
    List<Measurement> measurements,
  ) {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'control_points': controlPoints.map((p) => {
        'code': p.code,
        'name': p.name,
        'x': p.x,
        'y': p.y,
        'z': p.z,
      }).toList(),
      'measurements': measurements.map((m) => {
        'from': m.fromPointId,
        'to': m.toPointId,
        'factory': m.factoryValue,
        'actual': m.actualValue,
        'deviation': m.deviation,
        'type': m.type.name,
      }).toList(),
    };
  }
}
```

---

### 7. Часто задаваемые вопросы

#### Q: Почему диагональ A-B не равна ширине по передним стойкам?

**A:** Это нормально. Диагональ A-B рассчитывается как 3D-расстояние между точками, включая высотную составляющую. Если точки A и B находятся на одной высоте, то диагональ равна поперечному расстоянию.

```dart
// Если A(1362, -760, 365) и B(1362, 760, 365):
final diagonal = sqrt(0² + 1520² + 0²) = 1520.0мм // Равна ширине

// Если высоты разные A(1362, -760, 365) и B(1362, 760, 370):
final diagonal = sqrt(0² + 1520² + 5²) = 1520.01мм // Чуть больше ширины
```

#### Q: Что означает отрицательное отклонение в крестовых диагоналях?

**A:** Отрицательное отклонение означает, что измеренное значение меньше эталонного:
- **A-L = -3мм**: диагональ короче эталона на 3мм
- **B-K = +2мм**: диагональ длиннее эталона на 2мм
- **Разность = 5мм**: указывает на деформацию кузова

#### Q: Можно ли использовать систему для других марок автомобилей?

**A:** Да, но потребуется добавить эталонные данные для конкретной модели:

```dart
// Пример для другой модели
static const Map<String, double> fordFocusMk4Diagonals = {
  'A-B': 1480.0,
  'K-L': 1520.0,
  'A-K': 2648.0,
  'B-L': 2648.0,
  // ... остальные размеры
};
```

#### Q: Как интерпретировать уровень ремонтопригодности?

**A:**
- **Excellent**: Автомобиль в отличном состоянии, ремонт не требуется
- **Good**: Легкий ремонт, экономически целесообразен
- **Difficult**: Сложный ремонт, требует экспертной оценки
- **Unrepairable**: Восстановление нецелесообразно, рекомендуется списание

---

### 8. Логирование и мониторинг

#### Настройка логирования

```dart
import 'package:logging/logging.dart';

void setupGeometryLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
    
    // Сохранение критических ошибок
    if (record.level >= Level.SEVERE) {
      saveErrorLog(record);
    }
  });
}

void saveErrorLog(LogRecord record) {
  // Сохранение в файл или отправка на сервер
  final errorData = {
    'timestamp': record.time.toIso8601String(),
    'level': record.level.name,
    'message': record.message,
    'error': record.error?.toString(),
    'stackTrace': record.stackTrace?.toString(),
  };
  
  // Здесь код сохранения...
}
```

#### Мониторинг производительности

```dart
class PerformanceMonitor {
  static final Map<String, List<int>> _timings = {};
  
  static Future<T> measureAsync<T>(String operation, Future<T> Function() function) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await function();
      _recordTiming(operation, stopwatch.elapsedMilliseconds);
      return result;
    } catch (e) {
      _recordTiming('$operation-ERROR', stopwatch.elapsedMilliseconds);
      rethrow;
    }
  }
  
  static void _recordTiming(String operation, int milliseconds) {
    _timings.putIfAbsent(operation, () => []).add(milliseconds);
    
    // Логирование медленных операций
    if (milliseconds > 1000) {
      Logger.root.warning('Медленная операция $operation: ${milliseconds}мс');
    }
  }
  
  static Map<String, double> getAverageTimings() {
    final averages = <String, double>{};
    
    for (final entry in _timings.entries) {
      final average = entry.value.isNotEmpty 
          ? entry.value.reduce((a, b) => a + b) / entry.value.length 
          : 0.0;
      averages[entry.key] = average;
    }
    
    return averages;
  }
}

// Использование:
final analysis = await PerformanceMonitor.measureAsync(
  'full_geometry_analysis',
  () => performAnalysisAsync(controlPoints, measurements, vehicleModel),
);
```

---

### 9. Контрольный список диагностики

При возникновении проблем проверьте:

#### ✅ Базовые проверки
- [ ] Версия Flutter ≥ 3.0
- [ ] Версия Dart ≥ 3.0  
- [ ] Установлены все зависимости (`flutter pub get`)
- [ ] Нет ошибок компиляции (`flutter analyze`)

#### ✅ Данные
- [ ] Контрольные точки имеют корректные координаты
- [ ] Коды точек уникальны и соответствуют стандарту
- [ ] Измерения содержат фактические значения
- [ ] Эталонные данные загружены для выбранной модели

#### ✅ Вычисления
- [ ] Диагонали возвращают разумные значения (100-5000мм)
- [ ] Отклонения не превышают физически возможные пределы
- [ ] Симметричные диагонали примерно равны

#### ✅ Производительность
- [ ] Анализ завершается за разумное время (<5 сек)
- [ ] Нет утечек памяти при повторных анализах
- [ ] UI остается отзывчивым во время вычислений

---

**Нужна дополнительная помощь?**

1. Проверьте документацию в `docs/GEOMETRY_SYSTEM.md`
2. Изучите примеры в `docs/API_REFERENCE.md`
3. Запустите диагностические инструменты из этого руководства
4. Создайте issue в репозитории проекта с подробным описанием проблемы

---

**Версия**: 1.0  
**Обновлено**: ${DateTime.now().toString().substring(0, 10)}  
**Совместимость**: ABRA v1.0+