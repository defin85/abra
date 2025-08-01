import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' as vm;
import '../constants/geometry_constants.dart';

/// Адаптивная геометрия каркаса автомобиля на основе математических уравнений
class AdaptiveChassis {
  final double wheelbase;    // Колесная база (мм)
  final double trackWidth;   // Колея (мм)
  final double sillHeight;   // Высота порогов (мм)
  final double frontOverhang; // Передний свес (мм)
  final double rearOverhang;  // Задний свес (мм)
  final double scale;        // Масштаб для отображения

  const AdaptiveChassis({
    required this.wheelbase,
    required this.trackWidth,
    required this.sillHeight,
    this.frontOverhang = 800.0,
    this.rearOverhang = 1000.0,
    this.scale = 0.1,
  });

  /// Toyota Camry XV70 (2018+) параметры
  factory AdaptiveChassis.toyotaCamry() {
    return const AdaptiveChassis(
      wheelbase: 2825.0,      // мм - реальная колесная база
      trackWidth: 1545.0,     // мм - реальная колея передняя
      sillHeight: 150.0,      // мм - типичная высота порогов
      frontOverhang: 900.0,   // мм
      rearOverhang: 1100.0,   // мм
      scale: 0.08,           // Оптимальный масштаб для отображения
    );
  }

  /// Общая длина автомобиля
  double get totalLength => frontOverhang + wheelbase + rearOverhang;

  /// Генерирует точки левого порога
  List<vm.Vector3> generateLeftSill() {
    final points = <vm.Vector3>[];
    const segmentCount = 8; // Уменьшаем для четкости
    
    for (int i = 0; i <= segmentCount; i++) {
      final t = i / segmentCount; // Параметр от 0 до 1
      // Новая система: X=длина, Y=ширина, Z=высота
      // Передняя часть в положительном X: t=0 -> +X/2, t=1 -> -X/2
      final x = (wheelbase / 2 - t * wheelbase) * scale;
      
      // Очень сильное сужение к задней части
      final widthFactor = 1.0 - GeometryConstants.sillWidthReductionFactor * t;
      final y = -(trackWidth / 2) * widthFactor * scale;
      
      // Очень сильный подъем к центру
      final heightFactor = 1.0 + GeometryConstants.sillHeightPeakFactor * math.sin(t * math.pi);
      final z = sillHeight * heightFactor * scale;
      
      points.add(vm.Vector3(x, y, z));
    }
    
    return points;
  }

  /// Генерирует точки правого порога (симметрично левому)
  List<vm.Vector3> generateRightSill() {
    return generateLeftSill().map((point) => 
      vm.Vector3(point.x, -point.y, point.z)  // В новой системе Y - это ширина
    ).toList();
  }

  /// Генерирует точки переднего подрамника
  List<vm.Vector3> generateFrontSubframe() {
    final points = <vm.Vector3>[];
    // Новая система: X=длина, Y=ширина, Z=высота
    final frontX = -frontOverhang * scale;
    final subframeWidth = trackWidth * GeometryConstants.subframeWidthFactor;
    
    // Трапецеидальная форма подрамника
    const segments = 6;
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final y = (-subframeWidth / 2 + t * subframeWidth) * scale;
      
      // Подрамник ниже порогов
      final z = (sillHeight * GeometryConstants.subframeHeightFactor) * scale;
      
      // Небольшой изгиб для аэродинамики
      final xOffset = GeometryConstants.longeronSegmentLength * math.sin(t * math.pi) * scale;
      
      points.add(vm.Vector3(frontX + xOffset, y, z));
    }
    
    return points;
  }

  /// Генерирует точки центрального тоннеля
  List<vm.Vector3> generateCentralTunnel() {
    final points = <vm.Vector3>[];
    const segmentCount = 10;
    
    for (int i = 0; i <= segmentCount; i++) {
      final t = i / segmentCount;
      // Новая система: X=длина, Y=ширина, Z=высота
      // Передняя часть в положительном X: t=0 -> +X/2, t=1 -> -X/2
      final x = (wheelbase / 2 - t * wheelbase) * scale;
      
      // Тоннель по центру
      const y = 0.0;
      
      // Высота тоннеля выше порогов для прохождения трансмиссии
      final tunnelHeight = sillHeight * GeometryConstants.tunnelHeightFactor;
      final z = tunnelHeight * scale;
      
      points.add(vm.Vector3(x, y, z));
    }
    
    return points;
  }

  /// Генерирует контрольные точки для измерений
  Map<String, vm.Vector3> generateControlPoints() {
    final elements = generateChassisElements();
    final leftFrontLongeron = elements.firstWhere((e) => e.id == 'leftFrontLongeron');
    final rightFrontLongeron = elements.firstWhere((e) => e.id == 'rightFrontLongeron');
    final leftRearLongeron = elements.firstWhere((e) => e.id == 'leftRearLongeron');
    final rightRearLongeron = elements.firstWhere((e) => e.id == 'rightRearLongeron');
    final leftSill = elements.firstWhere((e) => e.id == 'leftSill');
    final rightSill = elements.firstWhere((e) => e.id == 'rightSill');
    
    return {
      // Передние точки на лонжеронах
      'A': vm.Vector3(leftFrontLongeron.center.x + (frontOverhang * 0.3) * scale, leftFrontLongeron.center.y, 
                     leftFrontLongeron.center.z),
      'B': vm.Vector3(rightFrontLongeron.center.x + (frontOverhang * 0.3) * scale, rightFrontLongeron.center.y, 
                     rightFrontLongeron.center.z),
      
      // Точки на переходе лонжерон-порог
      'C': vm.Vector3(leftSill.center.x + (wheelbase * 0.4) * scale, leftSill.center.y, 
                     leftSill.center.z),
      'E': vm.Vector3(rightSill.center.x + (wheelbase * 0.4) * scale, rightSill.center.y, 
                     rightSill.center.z),
      
      // Дополнительные точки на лонжеронах
      'D': vm.Vector3(leftFrontLongeron.center.x - (frontOverhang * 0.2) * scale, leftFrontLongeron.center.y, 
                     leftFrontLongeron.center.z),
      'F': vm.Vector3(rightFrontLongeron.center.x - (frontOverhang * 0.2) * scale, rightFrontLongeron.center.y, 
                     rightFrontLongeron.center.z),
      
      // Центральные точки на порогах
      'G': vm.Vector3(0, leftSill.center.y, leftSill.center.z),
      'H': vm.Vector3(0, rightSill.center.y, rightSill.center.z),
      
      // Задние точки на переходе порог-лонжерон
      'I': vm.Vector3(leftSill.center.x - (wheelbase * 0.4) * scale, leftSill.center.y, 
                     leftSill.center.z),
      'J': vm.Vector3(rightSill.center.x - (wheelbase * 0.4) * scale, rightSill.center.y, 
                     rightSill.center.z),
      
      // Самые задние точки на лонжеронах
      'K': vm.Vector3(leftRearLongeron.center.x - (rearOverhang * 0.3) * scale, leftRearLongeron.center.y, 
                     leftRearLongeron.center.z),
      'L': vm.Vector3(leftRearLongeron.center.x - (rearOverhang * 0.3) * scale, 0, 
                     leftRearLongeron.center.z),
      'M': vm.Vector3(rightRearLongeron.center.x - (rearOverhang * 0.3) * scale, rightRearLongeron.center.y, 
                     rightRearLongeron.center.z),
    };
  }

  /// Генерирует элементы каркаса с ломаными линиями для порогов
  List<ChassisElement> generateChassisElementsWithCurves() {
    final elements = <ChassisElement>[];
    
    // Генерируем изогнутые пороги
    final leftSillPath = generateLeftSill();
    final rightSillPath = generateRightSill();
    
    // Добавляем изогнутые пороги как элементы с кастомным путем
    elements.add(ChassisElement(
      'leftSillCurved',
      leftSillPath[leftSillPath.length ~/ 2], // Центр в середине пути
      vm.Vector3(50 * scale, 80 * scale, 10 * scale), // Размер сегмента
      FrameType.sill,
      leftSillPath,
    ));
    
    elements.add(ChassisElement(
      'rightSillCurved',
      rightSillPath[rightSillPath.length ~/ 2], // Центр в середине пути
      vm.Vector3(50 * scale, 80 * scale, 10 * scale), // Размер сегмента
      FrameType.sill,
      rightSillPath,
    ));
    
    // Добавляем остальные элементы из стандартной генерации
    elements.addAll(generateChassisElements().where((e) => 
      e.id != 'leftSill' && e.id != 'rightSill' // Исключаем прямые пороги
    ));
    
    return elements;
  }

  /// Генерирует основные элементы каркаса как 3D коробки (форма корыта)
  List<ChassisElement> generateChassisElements() {
    return [
      // ЛЕВЫЕ ЛОНЖЕРОНЫ (значительно выше днища)
      // Левый передний лонжерон
      // Новая система: X=длина, Y=ширина, Z=высота
      // Передняя часть должна быть в положительном X (направление движения)
      ChassisElement(
        'leftFrontLongeron',
        vm.Vector3((wheelbase/2 + frontOverhang/2) * scale, -(trackWidth/2.5) * scale, (sillHeight * 2.2) * scale),
        vm.Vector3(frontOverhang * scale, 100 * scale, 60 * scale),
        FrameType.subframe,
      ),
      
      // Левый задний лонжерон
      ChassisElement(
        'leftRearLongeron',
        vm.Vector3(-(wheelbase/2 + rearOverhang/2) * scale, -(trackWidth/2.5) * scale, (sillHeight * 2.0) * scale),
        vm.Vector3(rearOverhang * scale, 100 * scale, 70 * scale),
        FrameType.rearLongeron,
      ),
      
      // ПРАВЫЕ ЛОНЖЕРОНЫ (значительно выше днища)
      // Правый передний лонжерон
      ChassisElement(
        'rightFrontLongeron',
        vm.Vector3((wheelbase/2 + frontOverhang/2) * scale, (trackWidth/2.5) * scale, (sillHeight * 2.2) * scale),
        vm.Vector3(frontOverhang * scale, 100 * scale, 60 * scale),
        FrameType.subframe,
      ),
      
      // Правый задний лонжерон
      ChassisElement(
        'rightRearLongeron',
        vm.Vector3(-(wheelbase/2 + rearOverhang/2) * scale, (trackWidth/2.5) * scale, (sillHeight * 2.0) * scale),
        vm.Vector3(rearOverhang * scale, 100 * scale, 70 * scale),
        FrameType.rearLongeron,
      ),
      
      // ПОРОГИ (соединяют лонжероны)
      // Левый порог
      ChassisElement(
        'leftSill',
        vm.Vector3(0, -(trackWidth/2) * scale, sillHeight * scale),
        vm.Vector3(wheelbase * scale, 50 * scale, 80 * scale),
        FrameType.sill,
      ),
      
      // Правый порог
      ChassisElement(
        'rightSill',
        vm.Vector3(0, (trackWidth/2) * scale, sillHeight * scale),
        vm.Vector3(wheelbase * scale, 50 * scale, 80 * scale),
        FrameType.sill,
      ),
      
      // ЦЕНТРАЛЬНЫЕ ЭЛЕМЕНТЫ
      // Центральный тоннель (чуть выше порогов и поперечин)
      ChassisElement(
        'tunnel',
        vm.Vector3(0, 0, (sillHeight * 1.3) * scale),
        vm.Vector3(wheelbase * scale, 400 * scale, 50 * scale),
        FrameType.tunnel,
      ),
      
      // ПОПЕРЕЧНЫЕ СВЯЗИ (на уровне порогов)
      // Передняя поперечина
      ChassisElement(
        'frontCross',
        vm.Vector3((wheelbase/3) * scale, 0, sillHeight * scale),
        vm.Vector3(80 * scale, trackWidth * scale, 40 * scale),
        FrameType.crossMember,
      ),
      
      // Центральная поперечина
      ChassisElement(
        'centerCross',
        vm.Vector3(0, 0, sillHeight * scale),
        vm.Vector3(80 * scale, trackWidth * scale, 40 * scale),
        FrameType.crossMember,
      ),
      
      // Задняя поперечина
      ChassisElement(
        'rearCross',
        vm.Vector3(-(wheelbase/3) * scale, 0, sillHeight * scale),
        vm.Vector3(80 * scale, trackWidth * scale, 40 * scale),
        FrameType.crossMember,
      ),
    ];
  }


  /// Создает деформированную версию каркаса
  AdaptiveChassis createDeformed({
    double wheelbaseChange = 0.0,
    double trackWidthChange = 0.0,
    double frontDamage = 0.0,    // Коэффициент повреждения передней части (0-1)
    double rearDamage = 0.0,     // Коэффициент повреждения задней части (0-1)
    double sideDamage = 0.0,     // Боковое повреждение (0-1)
  }) {
    return AdaptiveChassis(
      wheelbase: wheelbase + wheelbaseChange,
      trackWidth: trackWidth + trackWidthChange * (1 - sideDamage),
      sillHeight: sillHeight * (1 - frontDamage * 0.3 - rearDamage * 0.2),
      frontOverhang: frontOverhang * (1 - frontDamage * 0.5),
      rearOverhang: rearOverhang * (1 - rearDamage * 0.4),
      scale: scale,
    );
  }
}

/// Типы элементов каркаса для разного отображения
enum FrameType {
  sill,         // Пороги - красный
  subframe,     // Передние лонжероны - зеленый
  rearLongeron, // Задние лонжероны - синий
  tunnel,       // Тоннель - тёмно-синий
  crossMember,  // Поперечины - серый
}

/// Элемент каркаса как 3D коробка
class ChassisElement {
  final String id;
  final vm.Vector3 center;    // Центр элемента
  final vm.Vector3 size;      // Размеры (ширина, высота, длина)
  final FrameType type;
  final List<vm.Vector3>? customPath; // Опциональный путь для ломаных линий
  
  const ChassisElement(this.id, this.center, this.size, this.type, [this.customPath]);
  
  /// Генерирует 8 вершин коробки
  List<vm.Vector3> generateVertices() {
    final halfSize = size * 0.5;
    
    return [
      // Нижние вершины
      center + vm.Vector3(-halfSize.x, -halfSize.y, -halfSize.z),
      center + vm.Vector3(halfSize.x, -halfSize.y, -halfSize.z),
      center + vm.Vector3(halfSize.x, -halfSize.y, halfSize.z),
      center + vm.Vector3(-halfSize.x, -halfSize.y, halfSize.z),
      // Верхние вершины
      center + vm.Vector3(-halfSize.x, halfSize.y, -halfSize.z),
      center + vm.Vector3(halfSize.x, halfSize.y, -halfSize.z),
      center + vm.Vector3(halfSize.x, halfSize.y, halfSize.z),
      center + vm.Vector3(-halfSize.x, halfSize.y, halfSize.z),
    ];
  }
  
  /// Генерирует рёбра коробки для отрисовки
  List<List<int>> getEdges() {
    return [
      // Нижнее основание
      [0, 1], [1, 2], [2, 3], [3, 0],
      // Верхнее основание
      [4, 5], [5, 6], [6, 7], [7, 4],
      // Вертикальные рёбра
      [0, 4], [1, 5], [2, 6], [3, 7],
    ];
  }
}