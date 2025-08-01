import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' as vm;
import '../../../core/geometry/adaptive_chassis.dart';
import 'draggable_control_panel.dart';

class AdaptiveChassis3D extends StatefulWidget {
  final bool showMeasurements;
  final bool showLabels;
  final bool showDeformed;
  final bool showAxes;
  final bool useCurvedElements;
  final AdaptiveChassis? factoryChassis;
  final AdaptiveChassis? deformedChassis;

  const AdaptiveChassis3D({
    super.key,
    this.showMeasurements = true,
    this.showLabels = true,
    this.showDeformed = false,
    this.showAxes = true,
    this.useCurvedElements = false,
    this.factoryChassis,
    this.deformedChassis,
  });

  @override
  State<AdaptiveChassis3D> createState() => _AdaptiveChassis3DState();
}

enum CameraMode {
  orbital,   // Орбитальная камера (вращение вокруг объекта)
  free,      // Свободная камера (полёт в пространстве)
  testCube,  // Тестовый режим с простым кубом
}

class _AdaptiveChassis3DState extends State<AdaptiveChassis3D> {
  // Режим камеры
  CameraMode _cameraMode = CameraMode.orbital;
  
  // Орбитальная камера - углы поворота вокруг центра объекта
  double _azimuth = 210 * math.pi / 180;    // 210° как на скриншоте
  double _elevation = -30 * math.pi / 180;  // -30° как на скриншоте
  double _distance = 500.0;                 // 500 как на скриншоте
  
  // Параметры тестовой камеры
  final double _testAzimuth = math.pi;             // 180° - правильная ориентация
  final double _testElevation = -math.pi / 4;      // -45° - правильный угол
  final int _testUpVector = -1;                    // -1 для правильной ориентации Z вверх
  
  
  // Свободная камера - позиция и ориентация в пространстве  
  vm.Vector3 _freeCameraPosition = vm.Vector3(1689, -1335, 1674);  // Позиция из скриншота
  double _freeCameraPitch = -math.pi * 30 / 180;  // -30° 
  double _freeCameraYaw = -math.pi * 135 / 180;    // -135° из скриншота
  double _freeCameraRoll = 0.0;    // 0° из скриншота
  
  // Углы поворота каркаса в свободном режиме
  double _chassisRotationX = 0.0;  // Поворот каркаса вокруг оси X
  double _chassisRotationY = 0.0;  // Поворот каркаса вокруг оси Y
  double _chassisRotationZ = 0.0;  // Поворот каркаса вокруг оси Z
  
  // Состояние клавиш для движения WASD
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  
  // Центр вращения (центр шасси автомобиля)
  vm.Vector3 _target = vm.Vector3.zero();
  
  Offset? _lastPanPosition;
  int? _activeMouseButton; // Отслеживаем какая кнопка мыши нажата
  Timer? _movementTimer; // Таймер только когда нужен

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(AdaptiveChassis3D oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    super.dispose();
  }


  /// Останавливает таймер движения для экономии батареи
  void _stopMovementTimer() {
    _movementTimer?.cancel();
    _movementTimer = null;
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
          // Основная область 3D с обработкой ввода
          Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              _handleKeyEvent(event);
              return KeyEventResult.handled;
            },
            child: Listener(
              onPointerDown: (event) {
                setState(() {
                  _lastPanPosition = event.localPosition;
                  _activeMouseButton = event.buttons;
                });
              },
              onPointerMove: (event) {
                if (_lastPanPosition != null) {
                  final delta = event.localPosition - _lastPanPosition!;
                  _handleUniversalMouseMove(delta, _activeMouseButton, event);
                  setState(() {
                    _lastPanPosition = event.localPosition;
                  });
                }
              },
              onPointerUp: (event) {
                setState(() {
                  _lastPanPosition = null;
                  _activeMouseButton = null;
                });
              },
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  _handleScroll(event);
                }
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: AdaptiveChassisPainter(
                  showMeasurements: widget.showMeasurements,
                  showLabels: widget.showLabels,
                  showDeformed: widget.showDeformed,
                  showAxes: widget.showAxes,
                  useCurvedElements: widget.useCurvedElements,
                  cameraMode: _cameraMode,
                  // Орбитальная камера
                  azimuth: _azimuth,
                  elevation: _elevation,
                  distance: _distance,
                  target: _target,
                  // Свободная камера
                  freeCameraPosition: _freeCameraPosition,
                  freeCameraPitch: _freeCameraPitch,
                  freeCameraYaw: _freeCameraYaw,
                  freeCameraRoll: _freeCameraRoll,
                  // Углы поворота каркаса в свободном режиме
                  chassisRotationX: _chassisRotationX,
                  chassisRotationY: _chassisRotationY,
                  chassisRotationZ: _chassisRotationZ,
                  factoryChassis: widget.factoryChassis ?? AdaptiveChassis.toyotaCamry(),
                  deformedChassis: widget.deformedChassis,
                  // Параметры тестовой камеры
                  testAzimuth: _testAzimuth,
                  testElevation: _testElevation,
                  testUpVector: _testUpVector,
                ),
              ),
            ),
          ),
          // Перетаскиваемая панель управления
          DraggableControlPanel(
            title: 'Управление камерой',
            initialPosition: const Offset(20, 20), // Изменяем на фиксированную позицию слева
            child: _buildControlPanelContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanelContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Адаптивный каркас', style: Theme.of(context).textTheme.labelSmall),
        Text('Toyota Camry XV70', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text('База: ${(widget.factoryChassis?.wheelbase ?? 2825).toInt()}мм', 
             style: Theme.of(context).textTheme.bodySmall),
        Text('Колея: ${(widget.factoryChassis?.trackWidth ?? 1545).toInt()}мм', 
             style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        // Переключатель режима камеры
        SegmentedButton<CameraMode>(
          segments: const [
            ButtonSegment(
              value: CameraMode.orbital,
              label: Text('Орбита'),
              icon: Icon(Icons.threesixty),
            ),
            ButtonSegment(
              value: CameraMode.free,
              label: Text('Свободно'),
              icon: Icon(Icons.open_with),
            ),
            ButtonSegment(
              value: CameraMode.testCube,
              label: Text('Тест'),
              icon: Icon(Icons.view_in_ar),
            ),
          ],
          selected: {_cameraMode},
          onSelectionChanged: (Set<CameraMode> newSelection) {
            setState(() {
              _cameraMode = newSelection.first;
              // При смене режима останавливаем таймер движения
              _stopMovementTimer();
              _pressedKeys.clear();
            });
          },
        ),
        const SizedBox(height: 8),
        
        // Единая кнопка сброса камеры для всех режимов
        ElevatedButton.icon(
          onPressed: () => setState(() {
            if (_cameraMode == CameraMode.orbital) {
              // Сброс орбитальной камеры
              _azimuth = 210 * math.pi / 180;
              _elevation = -30 * math.pi / 180;
              _distance = 500.0;
            } else if (_cameraMode == CameraMode.free) {
              // Сброс свободной камеры
              _freeCameraPosition = vm.Vector3(1689, -1335, 1674);
              _freeCameraPitch = -math.pi * 30 / 180;
              _freeCameraYaw = -math.pi * 135 / 180;
              _freeCameraRoll = 0.0;
            }
            // Сброс углов поворота каркаса
            _chassisRotationX = 0.0;
            _chassisRotationY = 0.0;
            _chassisRotationZ = 0.0;
          }),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Сброс камеры', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(height: 8),
        
        // Единый интерфейс камеры
        Text('${_getCameraModeDisplayName()}: ${_getCameraStatusText()}', 
             style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
        // Основные параметры камеры
        _buildCameraParameters(),
        
        const SizedBox(height: 8),
        
        // Предустановленные виды
        Text('Быстрые виды:', style: Theme.of(context).textTheme.labelSmall),
        Row(
          children: [
            _buildQuickViewButton('1', 'Спереди', 1),
            _buildQuickViewButton('2', 'Сбоку', 2),
            _buildQuickViewButton('3', 'Сверху', 3),
            _buildQuickViewButton('4', 'Изо', 4),
          ],
        ),
        
        const Divider(),
        
        // Углы каркаса
        Text('Поворот каркаса:', style: Theme.of(context).textTheme.labelSmall),
        Text('X: ${(_chassisRotationX * 180 / math.pi).toStringAsFixed(0)}°  '
             'Y: ${(_chassisRotationY * 180 / math.pi).toStringAsFixed(0)}°  '
             'Z: ${(_chassisRotationZ * 180 / math.pi).toStringAsFixed(0)}°', 
             style: Theme.of(context).textTheme.bodySmall),
        
        const SizedBox(height: 8),
        
        // Кнопка помощи
        OutlinedButton.icon(
          onPressed: _showControlsHelp,
          icon: const Icon(Icons.help_outline, size: 16),
          label: const Text('Управление', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
      ],
    );
  }

  /// Универсальная обработка событий клавиатуры
  void _handleKeyEvent(KeyEvent event) {
    final key = event.logicalKey;
    
    if (event is KeyDownEvent) {
      // Обработка мгновенных команд
      if (key == LogicalKeyboardKey.space) {
        _centerCameraOnObject();
        return;
      } else if (key == LogicalKeyboardKey.tab) {
        _toggleCameraMode();
        return;
      } else if (key == LogicalKeyboardKey.backspace) {
        _resetCamera();
        return;
      } else if (key == LogicalKeyboardKey.digit1) {
        _setPresetView(1); // Вид спереди
        return;
      } else if (key == LogicalKeyboardKey.digit2) {
        _setPresetView(2); // Вид сбоку
        return;
      } else if (key == LogicalKeyboardKey.digit3) {
        _setPresetView(3); // Вид сверху
        return;
      } else if (key == LogicalKeyboardKey.digit4) {
        _setPresetView(4); // Изометрия
        return;
      }
      
      // Добавляем клавишу в набор нажатых
      _pressedKeys.add(key);
      
      // Запускаем таймер движения если его нет
      if (_movementTimer == null || !_movementTimer!.isActive) {
        _movementTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
          _updateCameraMovement();
        });
      }
    } else if (event is KeyUpEvent) {
      // Удаляем клавишу из набора нажатых
      _pressedKeys.remove(key);
      
      // Останавливаем таймер если клавиш не нажато
      if (_pressedKeys.isEmpty) {
        _stopMovementTimer();
      }
    }
  }

  /// Обновление позиции камеры на основе нажатых клавиш (универсальное управление)
  void _updateCameraMovement() {
    // Базовые скорости
    double baseMoveSpeed = 10.0;
    double baseRotateSpeed = 0.05;
    double baseZoomSpeed = 50.0;

    // Модификаторы скорости
    final shiftPressed = _pressedKeys.contains(LogicalKeyboardKey.shiftLeft) || 
                        _pressedKeys.contains(LogicalKeyboardKey.shiftRight);
    final ctrlPressed = _pressedKeys.contains(LogicalKeyboardKey.controlLeft) || 
                       _pressedKeys.contains(LogicalKeyboardKey.controlRight);

    // Применяем модификаторы скорости
    if (shiftPressed) {
      baseMoveSpeed *= 3.0; // Ускорение
      baseRotateSpeed *= 3.0;
      baseZoomSpeed *= 3.0;
    } else if (ctrlPressed) {
      baseMoveSpeed *= 0.3; // Точное движение
      baseRotateSpeed *= 0.3;
      baseZoomSpeed *= 0.3;
    }

    vm.Vector3 movement = vm.Vector3.zero();

    // Получаем направления камеры
    final forward = _getCameraForward();
    final right = _getCameraRight();
    final up = _getCameraUp();

    // WASD движение камеры - работает в обоих режимах
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW)) {
      movement += forward * baseMoveSpeed;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS)) {
      movement -= forward * baseMoveSpeed;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA)) {
      movement -= right * baseMoveSpeed;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD)) {
      movement += right * baseMoveSpeed;
    }

    // Q/E для вертикального движения камеры
    if (_pressedKeys.contains(LogicalKeyboardKey.keyQ)) {
      movement -= up * baseMoveSpeed;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyE)) {
      movement += up * baseMoveSpeed;
    }

    // R/F для зума с клавиатуры
    if (_pressedKeys.contains(LogicalKeyboardKey.keyR)) {
      _handleKeyboardZoom(baseZoomSpeed);
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyF)) {
      _handleKeyboardZoom(-baseZoomSpeed);
    }

    // Применяем движение камеры
    if (movement.length > 0) {
      _moveCameraByVector(movement);
    }

    // Вращение каркаса стрелками (точное позиционирование)
    if (shiftPressed) {
      // Shift + стрелки влево/вправо - вращение вокруг Z (крен)
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
        _chassisRotationZ -= baseRotateSpeed;
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
        _chassisRotationZ += baseRotateSpeed;
      }
    } else {
      // Стрелки без модификаторов - вращение вокруг Y (рыскание)
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
        _chassisRotationY -= baseRotateSpeed;
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
        _chassisRotationY += baseRotateSpeed;
      }
    }
    
    // Стрелки вверх/вниз - вращение вокруг X (тангаж)
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      _chassisRotationX -= baseRotateSpeed;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      _chassisRotationX += baseRotateSpeed;
    }

    // Обновляем состояние
    setState(() {});
  }


  /// Универсальная обработка движения мыши
  void _handleUniversalMouseMove(Offset delta, int? buttons, PointerEvent event) {
    if (_cameraMode == CameraMode.orbital) {
      if ((buttons ?? 0) & kSecondaryMouseButton != 0) {
        // ПКМ - вращение камеры вокруг объекта
        setState(() {
          _azimuth += delta.dx * 0.01;
          _elevation = (_elevation - delta.dy * 0.01).clamp(-math.pi / 2, math.pi / 2);
        });
      } else if ((buttons ?? 0) & kMiddleMouseButton != 0) {
        // СКМ - панорамирование
        setState(() {
          final right = vm.Vector3(
            math.cos(_azimuth),
            0,
            math.sin(_azimuth),
          );
          final up = vm.Vector3(0, 1, 0);
          _target += right * delta.dx * 0.5;
          _target += up * -delta.dy * 0.5;
        });
      }
    } else {
      // Свободный режим
      if ((buttons ?? 0) & kSecondaryMouseButton != 0) {
        // ПКМ - поворот взгляда камеры
        setState(() {
          _freeCameraYaw += delta.dx * 0.01;
          _freeCameraPitch = (_freeCameraPitch - delta.dy * 0.01).clamp(-math.pi / 2, math.pi / 2);
        });
      } else if ((buttons ?? 0) & kMiddleMouseButton != 0) {
        // СКМ - панорамирование
        setState(() {
          final right = vm.Vector3(
            math.cos(_freeCameraYaw) * math.cos(_freeCameraPitch),
            0,
            math.sin(_freeCameraYaw) * math.cos(_freeCameraPitch),
          );
          final up = vm.Vector3(0, 1, 0);
          _freeCameraPosition += right * delta.dx * 0.5;
          _freeCameraPosition += up * -delta.dy * 0.5;
        });
      }
    }
  }

  /// Обработка прокрутки колеса мыши
  void _handleScroll(PointerScrollEvent event) {
    setState(() {
      final scrollDelta = event.scrollDelta.dy;
      if (_cameraMode == CameraMode.orbital) {
        // Орбитальный режим - изменение дистанции
        _distance = (_distance + scrollDelta * 0.5).clamp(100, 2000);
      } else {
        // Свободный режим - движение вперед/назад
        final forward = vm.Vector3(
          math.sin(_freeCameraYaw) * math.cos(_freeCameraPitch),
          -math.sin(_freeCameraPitch),
          -math.cos(_freeCameraYaw) * math.cos(_freeCameraPitch),
        );
        _freeCameraPosition += forward * -scrollDelta * 0.5;
      }
    });
  }

  /// Получает направление "вперед" для камеры
  vm.Vector3 _getCameraForward() {
    if (_cameraMode == CameraMode.free) {
      return vm.Vector3(
        math.sin(_freeCameraYaw) * math.cos(_freeCameraPitch),
        -math.sin(_freeCameraPitch),
        math.cos(_freeCameraYaw) * math.cos(_freeCameraPitch),
      );
    } else {
      // В орбитальном режиме "вперед" - это направление к центру
      final center = vm.Vector3.zero();
      final position = vm.Vector3(
        _distance * math.sin(_azimuth) * math.cos(_elevation),
        _distance * math.sin(_elevation),
        _distance * math.cos(_azimuth) * math.cos(_elevation),
      );
      return (center - position).normalized();
    }
  }

  /// Получает направление "вправо" для камеры
  vm.Vector3 _getCameraRight() {
    final forward = _getCameraForward();
    final up = vm.Vector3(0, 1, 0);
    return forward.cross(up).normalized();
  }

  /// Получает направление "вверх" для камеры
  vm.Vector3 _getCameraUp() {
    return vm.Vector3(0, 1, 0);
  }

  /// Перемещает камеру на заданный вектор
  void _moveCameraByVector(vm.Vector3 movement) {
    if (_cameraMode == CameraMode.free) {
      _freeCameraPosition += movement;
    } else {
      // В орбитальном режиме движение изменяет азимут и элевацию
      const sensitivity = 0.01;
      _azimuth += movement.x * sensitivity;
      _elevation += movement.y * sensitivity;
      _elevation = _elevation.clamp(-math.pi / 2 + 0.1, math.pi / 2 - 0.1);
    }
  }

  /// Обрабатывает зум с клавиатуры
  void _handleKeyboardZoom(double delta) {
    if (_cameraMode == CameraMode.free) {
      final forward = _getCameraForward();
      _freeCameraPosition += forward * delta;
    } else {
      _distance = (_distance - delta).clamp(50.0, 5000.0);
    }
  }

  /// Центрирует камеру на объекте
  void _centerCameraOnObject() {
    if (_cameraMode == CameraMode.orbital) {
      _azimuth = 45 * math.pi / 180;
      _elevation = 30 * math.pi / 180;
      _distance = 1200.0;
    } else {
      _freeCameraPosition = vm.Vector3(1689, -1335, 1674);
      _freeCameraYaw = -135 * math.pi / 180;
      _freeCameraPitch = -30 * math.pi / 180;
    }
  }

  /// Переключает режим камеры
  void _toggleCameraMode() {
    setState(() {
      _cameraMode = _cameraMode == CameraMode.orbital 
          ? CameraMode.free 
          : CameraMode.orbital;
    });
  }

  /// Сбрасывает камеру к начальному положению
  void _resetCamera() {
    setState(() {
      if (_cameraMode == CameraMode.orbital) {
        _distance = 1200.0;
        _azimuth = 45 * math.pi / 180;
        _elevation = 30 * math.pi / 180;
      } else {
        _freeCameraPosition = vm.Vector3(1689, -1335, 1674);
        _freeCameraYaw = -135 * math.pi / 180;
        _freeCameraPitch = -30 * math.pi / 180;
      }
      
      // Сброс поворотов каркаса
      _chassisRotationX = 0.0;
      _chassisRotationY = 0.0;
      _chassisRotationZ = 0.0;
    });
  }

  /// Устанавливает предустановленный вид
  void _setPresetView(int preset) {
    setState(() {
      switch (preset) {
        case 1: // Вид спереди
          _azimuth = 0;
          _elevation = 0;
          break;
        case 2: // Вид сбоку
          _azimuth = 90 * math.pi / 180;
          _elevation = 0;
          break;
        case 3: // Вид сверху
          _azimuth = 0;
          _elevation = 90 * math.pi / 180;
          break;
        case 4: // Изометрическая проекция
          _azimuth = 210 * math.pi / 180;
          _elevation = -30 * math.pi / 180;
          break;
      }
    });
  }

  /// Получает отображаемое имя режима камеры
  String _getCameraModeDisplayName() {
    switch (_cameraMode) {
      case CameraMode.orbital:
        return 'Орбита';
      case CameraMode.free:
        return 'Свободно';
      case CameraMode.testCube:
        return 'Тест';
    }
  }

  /// Получает статус камеры в зависимости от режима
  String _getCameraStatusText() {
    switch (_cameraMode) {
      case CameraMode.orbital:
        return '${_distance.toStringAsFixed(0)} ед, ${(_azimuth * 180 / math.pi).toStringAsFixed(0)}°';
      case CameraMode.free:
        return '(${_freeCameraPosition.x.toStringAsFixed(0)}, ${_freeCameraPosition.y.toStringAsFixed(0)}, ${_freeCameraPosition.z.toStringAsFixed(0)})';
      case CameraMode.testCube:
        return 'Тестовый куб';
    }
  }

  /// Строит параметры камеры в зависимости от режима
  Widget _buildCameraParameters() {
    switch (_cameraMode) {
      case CameraMode.orbital:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Расстояние: ${_distance.toStringAsFixed(0)}', 
                     style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed: () => setState(() => _distance = (_distance - 50).clamp(50.0, 5000.0)),
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  onPressed: () => setState(() => _distance = (_distance + 50).clamp(50.0, 5000.0)),
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            Row(
              children: [
                Text('Азимут: ${(_azimuth * 180 / math.pi).toStringAsFixed(0)}°', 
                     style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.rotate_left, size: 16),
                  onPressed: () => setState(() => _azimuth -= math.pi / 12),
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.rotate_right, size: 16),
                  onPressed: () => setState(() => _azimuth += math.pi / 12),
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            Row(
              children: [
                Text('Наклон: ${(_elevation * 180 / math.pi).toStringAsFixed(0)}°', 
                     style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  onPressed: () => setState(() => _elevation = (_elevation + math.pi / 12).clamp(-math.pi / 2 + 0.1, math.pi / 2 - 0.1)),
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  onPressed: () => setState(() => _elevation = (_elevation - math.pi / 12).clamp(-math.pi / 2 + 0.1, math.pi / 2 - 0.1)),
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        );
      case CameraMode.free:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Позиция: (${_freeCameraPosition.x.toStringAsFixed(0)}, ${_freeCameraPosition.y.toStringAsFixed(0)}, ${_freeCameraPosition.z.toStringAsFixed(0)})', 
                 style: Theme.of(context).textTheme.bodySmall),
            Text('Поворот: ${(_freeCameraYaw * 180 / math.pi).toStringAsFixed(0)}° / ${(_freeCameraPitch * 180 / math.pi).toStringAsFixed(0)}°', 
                 style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      case CameraMode.testCube:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Тестовый куб 50×50×50', style: Theme.of(context).textTheme.bodySmall),
            Text('Азимут: ${(_testAzimuth * 180 / math.pi).toStringAsFixed(0)}°', 
                 style: Theme.of(context).textTheme.bodySmall),
          ],
        );
    }
  }

  /// Строит кнопку быстрого вида
  Widget _buildQuickViewButton(String number, String label, int view) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: InkWell(
          onTap: () => _setPresetView(view),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Text(number, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Показывает диалог с подсказками по управлению
  void _showControlsHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Управление камерой'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Универсальное управление:', 
                   style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('🖱️ Мышь:'),
              const Text('• ПКМ + движение — вращение камеры'),
              const Text('• СКМ + движение — панорамирование'),
              const Text('• Колесо — зум'),
              const Text('• Shift + ПКМ — вращение каркаса'),
              const SizedBox(height: 8),
              const Text('⌨️ Клавиатура:'),
              const Text('• WASD — движение камеры'),
              const Text('• Q/E — вверх/вниз'),
              const Text('• R/F — зум с клавиатуры'),
              const Text('• Стрелки — точное вращение каркаса'),
              const SizedBox(height: 8),
              const Text('⚡ Быстрые команды:'),
              const Text('• Space — центрировать на объекте'),
              const Text('• Tab — переключить режим камеры'),
              const Text('• Backspace — сброс камеры'),
              const Text('• 1-4 — предустановленные виды'),
              const SizedBox(height: 8),
              const Text('🎛️ Модификаторы:'),
              const Text('• Shift — ускорение (×3)'),
              const Text('• Ctrl — точность (×0.3)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }
}

class AdaptiveChassisPainter extends CustomPainter {
  final bool showMeasurements;
  final bool showLabels;
  final bool showDeformed;
  final bool showAxes;
  final bool useCurvedElements;
  final CameraMode cameraMode;
  // Орбитальная камера
  final double azimuth;
  final double elevation;
  final double distance;
  final vm.Vector3 target;
  
  // Центр экрана для проекции
  late Offset screenCenter;
  // Свободная камера
  final vm.Vector3 freeCameraPosition;
  final double freeCameraPitch;
  final double freeCameraYaw;
  final double freeCameraRoll;
  // Углы поворота каркаса в свободном режиме
  final double chassisRotationX;
  final double chassisRotationY;
  final double chassisRotationZ;
  final AdaptiveChassis factoryChassis;
  final AdaptiveChassis? deformedChassis;
  // Параметры тестовой камеры
  final double testAzimuth;
  final double testElevation;
  final int testUpVector;

  AdaptiveChassisPainter({
    required this.showMeasurements,
    required this.showLabels,
    required this.showDeformed,
    required this.showAxes,
    required this.useCurvedElements,
    required this.cameraMode,
    required this.azimuth,
    required this.elevation,
    required this.distance,
    required this.target,
    required this.freeCameraPosition,
    required this.freeCameraPitch,
    required this.freeCameraYaw,
    required this.freeCameraRoll,
    required this.chassisRotationX,
    required this.chassisRotationY,
    required this.chassisRotationZ,
    required this.factoryChassis,
    this.deformedChassis,
    required this.testAzimuth,
    required this.testElevation,
    required this.testUpVector,
  });

  @override
  void paint(Canvas canvas, Size size) {
    screenCenter = Offset(size.width / 2, size.height / 2);
    
    // Выбираем матрицу трансформации в зависимости от режима камеры
    final Matrix4 matrix;
    if (cameraMode == CameraMode.testCube) {
      // Тестовый режим - простая орбитальная камера с фиксированными параметрами
      matrix = _createTestCubeCamera(screenCenter);
    } else if (cameraMode == CameraMode.orbital) {
      matrix = _createOrbitCamera(screenCenter);
    } else {
      // Свободная камера (полёт в пространстве)
      matrix = _createFreeCamera(screenCenter);
    }
    
    if (cameraMode == CameraMode.testCube) {
      // Рисуем только тестовый куб и оси
      _drawAxes(canvas, matrix);
      _drawTestCube(canvas, matrix);
      return;
    }
    
    // Теперь геометрия AdaptiveChassis использует стандартную систему координат
    // X=длина, Y=ширина, Z=высота - базовые повороты не нужны
    final objectMatrix = Matrix4.identity();
    
    // В свободном режиме добавляем вращение каркаса
    if (cameraMode == CameraMode.free) {
      objectMatrix
        ..rotateX(chassisRotationX)
        ..rotateY(chassisRotationY)
        ..rotateZ(chassisRotationZ);
    }
    
    final finalMatrix = matrix * objectMatrix;

    // Рисуем оси координат (если включены)
    if (showAxes) {
      _drawAxes(canvas, matrix);
    }

    // Рисуем заводской каркас (с поворотом)
    _drawChassis(canvas, finalMatrix, factoryChassis, false);

    // Рисуем деформированный каркас (если включен)
    if (showDeformed && deformedChassis != null) {
      _drawChassis(canvas, finalMatrix, deformedChassis!, true);
    }

    // Рисуем контрольные точки (если включены)
    if (showLabels) {
      _drawControlPoints(canvas, finalMatrix, factoryChassis);
    }

    // Рисуем измерения (если включены)
    if (showMeasurements) {
      _drawMeasurements(canvas, finalMatrix, factoryChassis);
    }
  }

  void _drawAxes(Canvas canvas, Matrix4 matrix) {
    const axisLength = 200.0;
    
    final origin = _project3D(vm.Vector3.zero(), matrix);
    
    // Автомобильная система координат:
    // X - продольная ось (вперед/назад) - красный
    final xEnd = _project3D(vm.Vector3(axisLength, 0, 0), matrix);
    canvas.drawLine(origin, xEnd, Paint()..color = Colors.red..strokeWidth = 2);
    _drawAxisLabel(canvas, xEnd, 'X', Colors.red);

    // Y - поперечная ось (влево/вправо) - зеленый
    final yEnd = _project3D(vm.Vector3(0, axisLength, 0), matrix);
    canvas.drawLine(origin, yEnd, Paint()..color = Colors.green..strokeWidth = 2);
    _drawAxisLabel(canvas, yEnd, 'Y', Colors.green);

    // Z - вертикальная ось (вверх/вниз) - синий
    final zEnd = _project3D(vm.Vector3(0, 0, axisLength), matrix);
    canvas.drawLine(origin, zEnd, Paint()..color = Colors.blue..strokeWidth = 2);
    _drawAxisLabel(canvas, zEnd, 'Z', Colors.blue);
  }

  void _drawAxisLabel(Canvas canvas, Offset position, String label, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: const Offset(1, 1),
              blurRadius: 2,
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    // Позиционируем подпись рядом с концом оси
    final offset = Offset(
      position.dx + 10,
      position.dy - textPainter.height / 2,
    );
    
    textPainter.paint(canvas, offset);
  }

  void _drawChassis(Canvas canvas, Matrix4 matrix, AdaptiveChassis chassis, bool isDeformed) {
    final elements = useCurvedElements 
      ? chassis.generateChassisElementsWithCurves()
      : chassis.generateChassisElements();
    
    for (final element in elements) {
      final paint = _getPaintForFrameType(element.type, isDeformed);
      _drawChassisElement(canvas, matrix, element, paint);
    }
  }

  Paint _getPaintForFrameType(FrameType type, bool isDeformed) {
    Color color;
    double strokeWidth = 3.0;
    
    switch (type) {
      case FrameType.subframe:
        color = Colors.green[700]!;  // Передние лонжероны
        break;
      case FrameType.rearLongeron:
        color = Colors.blue[700]!;   // Задние лонжероны
        break;
      case FrameType.sill:
        color = Colors.red[700]!;    // Пороги
        break;
      case FrameType.tunnel:
        color = Colors.indigo[600]!; // Тоннель (тёмно-синий)
        strokeWidth = 2.5;
        break;
      case FrameType.crossMember:
        color = Colors.grey[600]!;   // Поперечины
        strokeWidth = 2.0;
        break;
    }
    
    if (isDeformed) {
      color = color.withValues(alpha: 0.6);
      strokeWidth *= 0.8;
    }
    
    return Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
  }

  void _drawChassisElement(Canvas canvas, Matrix4 matrix, ChassisElement element, Paint paint) {
    // Если есть кастомный путь, рисуем простую кривую линию
    if (element.customPath != null && element.customPath!.length > 1) {
      final path = element.customPath!;
      
      // Проецируем все точки пути
      final projectedPath = path.map((v) => _project3D(v, matrix)).toList();
      
      // Рисуем простую кривую толстой линией
      final curvePaint = Paint()
        ..color = paint.color
        ..strokeWidth = paint.strokeWidth + 2
        ..style = PaintingStyle.stroke;
      
      // Соединяем все точки линиями
      for (int i = 0; i < projectedPath.length - 1; i++) {
        canvas.drawLine(projectedPath[i], projectedPath[i + 1], curvePaint);
      }
      
      // Добавляем маленькие кружки на точках кривой для наглядности
      final pointPaint = Paint()
        ..color = paint.color.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      
      for (final point in projectedPath) {
        canvas.drawCircle(point, 3, pointPaint);
      }
    } else {
      // Стандартная отрисовка коробки
      final vertices = element.generateVertices();
      final edges = element.getEdges();
      final projectedVertices = vertices.map((v) => _project3D(v, matrix)).toList();
      
      // Рисуем все рёбра коробки
      for (final edge in edges) {
        final p1 = projectedVertices[edge[0]];
        final p2 = projectedVertices[edge[1]];
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  void _drawControlPoints(Canvas canvas, Matrix4 matrix, AdaptiveChassis chassis) {
    final controlPoints = chassis.generateControlPoints();
    
    controlPoints.forEach((label, point) {
      final projected = _project3D(point, matrix);
      
      // Точка
      final pointPaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(projected, 6, pointPaint);
      
      // Обводка
      final strokePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawCircle(projected, 6, strokePaint);
      
      // Метка
      if (showLabels) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, projected + const Offset(8, -8));
      }
    });
  }

  void _drawMeasurements(Canvas canvas, Matrix4 matrix, AdaptiveChassis chassis) {
    final measurePaint = Paint()
      ..color = Colors.orange[700]!
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final controlPoints = chassis.generateControlPoints();
    
    // Основные измерения
    _drawMeasurement(canvas, matrix, controlPoints['A']!, controlPoints['B']!, 
                    '${(chassis.trackWidth * 0.8).toInt()}', measurePaint);
    _drawMeasurement(canvas, matrix, controlPoints['C']!, controlPoints['E']!, 
                    '${chassis.trackWidth.toInt()}', measurePaint);
    _drawMeasurement(canvas, matrix, controlPoints['G']!, controlPoints['H']!, 
                    '${chassis.trackWidth.toInt()}', measurePaint);
    _drawMeasurement(canvas, matrix, controlPoints['I']!, controlPoints['J']!, 
                    '${chassis.trackWidth.toInt()}', measurePaint);
    _drawMeasurement(canvas, matrix, controlPoints['K']!, controlPoints['M']!, 
                    '${chassis.trackWidth.toInt()}', measurePaint);
  }

  void _drawMeasurement(Canvas canvas, Matrix4 matrix, vm.Vector3 start, vm.Vector3 end, 
                        String value, Paint paint) {
    final p1 = _project3D(start, matrix);
    final p2 = _project3D(end, matrix);
    
    canvas.drawLine(p1, p2, paint);
    
    final midPoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$value мм',
        style: TextStyle(
          color: Colors.orange[700],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white.withValues(alpha: 0.9),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, midPoint - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  Offset _project3D(vm.Vector3 point, Matrix4 matrix) {
    final transformed = matrix.transform3(point);
    // Увеличиваем perspective для более ортографической проекции
    const perspective = 5000.0;
    final scale = perspective / (perspective + transformed.z);
    return Offset(
      screenCenter.dx + transformed.x * scale,
      screenCenter.dy + transformed.y * scale,
    );
  }

  /// Создает матрицу орбитальной камеры
  Matrix4 _createOrbitCamera(Offset screenCenter) {
    // Вычисляем позицию камеры в сферических координатах
    // Камера вращается вокруг центра (0,0,0) на расстоянии distance
    final x = distance * math.cos(elevation) * math.cos(azimuth);
    final y = distance * math.sin(elevation);
    final z = distance * math.cos(elevation) * math.sin(azimuth);
    
    final cameraPos = vm.Vector3(x, y, z);  // Позиция камеры относительно центра
    final lookAtTarget = vm.Vector3.zero(); // Камера всегда смотрит на центр
    final up = vm.Vector3(0, 0, -1);       // Z вниз для правильной ориентации
    
    // Создаем view матрицу (look-at) без смещения экрана
    // Смещение будет добавлено в _project3D
    return _makeViewMatrix(cameraPos, lookAtTarget, up);
  }

  /// Создает матрицу свободной камеры
  Matrix4 _createFreeCamera(Offset screenCenter) {
    // Создаем направление взгляда камеры
    final forward = vm.Vector3(
      math.sin(freeCameraYaw) * math.cos(freeCameraPitch),
      -math.sin(freeCameraPitch),
      math.cos(freeCameraYaw) * math.cos(freeCameraPitch),
    );
    
    final target = freeCameraPosition + forward;
    // Используем Z как up для правильной ориентации
    final baseUp = vm.Vector3(0, 0, -1);
    // Применяем roll если нужно
    final up = freeCameraRoll == 0 ? baseUp : vm.Vector3(
      -math.sin(freeCameraRoll),
      0,
      -math.cos(freeCameraRoll),
    );
    
    // Создаем view матрицу для свободной камеры без смещения экрана
    return _makeViewMatrix(freeCameraPosition, target, up);
  }

  /// Создает матрицу камеры для тестового куба
  Matrix4 _createTestCubeCamera(Offset screenCenter) {
    // Стандартная изометрическая проекция для автомобильной системы координат
    // X - вперед (к наблюдателю), Y - вправо, Z - вверх
    const testDistance = 150.0;
    
    // Используем настраиваемые параметры
    final x = testDistance * math.cos(testElevation) * math.cos(testAzimuth);
    final y = testDistance * math.sin(testElevation);
    final z = testDistance * math.cos(testElevation) * math.sin(testAzimuth);
    
    final cameraPos = vm.Vector3(x, y, z);
    final target = vm.Vector3.zero();
    final up = vm.Vector3(0, 0, testUpVector.toDouble());  // Настраиваемый up вектор
    
    // Создаем view матрицу без смещения экрана
    return _makeViewMatrix(cameraPos, target, up);
  }

  /// Рисует тестовый куб 50x50x50 в центре координат с цветными гранями
  void _drawTestCube(Canvas canvas, Matrix4 matrix) {
    const cubeSize = 50.0;
    const half = cubeSize / 2;
    
    // 8 вершин куба в мировой системе координат
    // X - вправо, Y - вверх, Z - к наблюдателю
    final vertices = [
      vm.Vector3(-half, -half, -half), // 0: X-, Y-, Z- (левый-нижний-дальний)
      vm.Vector3(half, -half, -half),  // 1: X+, Y-, Z- (правый-нижний-дальний)
      vm.Vector3(half, half, -half),   // 2: X+, Y+, Z- (правый-верхний-дальний)
      vm.Vector3(-half, half, -half),  // 3: X-, Y+, Z- (левый-верхний-дальний)
      vm.Vector3(-half, -half, half),  // 4: X-, Y-, Z+ (левый-нижний-ближний)
      vm.Vector3(half, -half, half),   // 5: X+, Y-, Z+ (правый-нижний-ближний)
      vm.Vector3(half, half, half),    // 6: X+, Y+, Z+ (правый-верхний-ближний)
      vm.Vector3(-half, half, half),   // 7: X-, Y+, Z+ (левый-верхний-ближний)
    ];
    
    final projectedVertices = vertices.map((v) => _project3D(v, matrix)).toList();
    
    // Для автомобильной системы координат:
    // X - вперед, Y - вправо, Z - вверх
    final coloredFaces = [
      // Грань X+ (передняя, на плоскости YZ) - зеленая  
      {'vertices': [1, 5, 6, 2], 'color': Colors.green[600]!, 'name': 'X+ (перед, плоскость YZ)'},
      // Грань Z+ (верхняя/крыша, на плоскости XY) - красная
      {'vertices': [4, 5, 6, 7], 'color': Colors.red[600]!, 'name': 'Z+ (крыша, плоскость XY)'},
    ];
    
    
    // Рисуем цветные грани
    for (final face in coloredFaces) {
      final faceVertices = (face['vertices'] as List<int>)
          .map((i) => projectedVertices[i])
          .toList();
      
      final path = Path();
      path.moveTo(faceVertices[0].dx, faceVertices[0].dy);
      for (int i = 1; i < faceVertices.length; i++) {
        path.lineTo(faceVertices[i].dx, faceVertices[i].dy);
      }
      path.close();
      
      final fillPaint = Paint()
        ..color = (face['color'] as Color).withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawPath(path, fillPaint);
    }
    
    // Рисуем все ребра куба серым цветом
    final edges = [
      [0, 1], [1, 2], [2, 3], [3, 0], // Задняя грань
      [4, 5], [5, 6], [6, 7], [7, 4], // Передняя грань  
      [0, 4], [1, 5], [2, 6], [3, 7], // Соединяющие ребра
    ];
    
    final edgePaint = Paint()
      ..color = Colors.grey[700]!
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    for (final edge in edges) {
      final p1 = projectedVertices[edge[0]];
      final p2 = projectedVertices[edge[1]];
      canvas.drawLine(p1, p2, edgePaint);
    }
  }
  
  /// Создает view матрицу (look-at matrix)
  Matrix4 _makeViewMatrix(vm.Vector3 eye, vm.Vector3 target, vm.Vector3 up) {
    final zAxis = (eye - target).normalized();
    final xAxis = up.cross(zAxis).normalized();
    final yAxis = zAxis.cross(xAxis);
    
    return Matrix4(
      xAxis.x,   yAxis.x,   zAxis.x,   0,
      xAxis.y,   yAxis.y,   zAxis.y,   0,
      xAxis.z,   yAxis.z,   zAxis.z,   0,
      -xAxis.dot(eye), -yAxis.dot(eye), -zAxis.dot(eye), 1,
    );
  }

  @override
  bool shouldRepaint(covariant AdaptiveChassisPainter oldDelegate) {
    return oldDelegate.showMeasurements != showMeasurements ||
           oldDelegate.showLabels != showLabels ||
           oldDelegate.showDeformed != showDeformed ||
           oldDelegate.showAxes != showAxes ||
           oldDelegate.useCurvedElements != useCurvedElements ||
           oldDelegate.cameraMode != cameraMode ||
           oldDelegate.azimuth != azimuth ||
           oldDelegate.elevation != elevation ||
           oldDelegate.distance != distance ||
           oldDelegate.target != target ||
           oldDelegate.freeCameraPosition != freeCameraPosition ||
           oldDelegate.freeCameraPitch != freeCameraPitch ||
           oldDelegate.freeCameraYaw != freeCameraYaw ||
           oldDelegate.freeCameraRoll != freeCameraRoll ||
           oldDelegate.chassisRotationX != chassisRotationX ||
           oldDelegate.chassisRotationY != chassisRotationY ||
           oldDelegate.chassisRotationZ != chassisRotationZ ||
           oldDelegate.factoryChassis != factoryChassis ||
           oldDelegate.deformedChassis != deformedChassis ||
           oldDelegate.testAzimuth != testAzimuth ||
           oldDelegate.testElevation != testElevation ||
           oldDelegate.testUpVector != testUpVector;
  }
}