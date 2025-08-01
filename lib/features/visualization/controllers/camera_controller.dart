import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'dart:math' as math;

import '../widgets/adaptive_chassis_painter.dart';

/// Контроллер управления камерой для 3D визуализации
class CameraController extends ChangeNotifier {
  // Режим камеры
  CameraMode _cameraMode = CameraMode.orbital;
  CameraMode get cameraMode => _cameraMode;

  // Орбитальная камера
  double _azimuth = 210 * math.pi / 180;
  double _elevation = -30 * math.pi / 180;
  double _distance = 500.0;
  vm.Vector3 _target = vm.Vector3.zero();

  // Свободная камера
  vm.Vector3 _freeCameraPosition = vm.Vector3(1689, -1335, 1674);
  double _freeCameraPitch = -math.pi * 30 / 180;
  double _freeCameraYaw = -math.pi * 135 / 180;
  final double _freeCameraRoll = 0.0;

  // Углы поворота каркаса
  double _chassisRotationX = 0.0;
  double _chassisRotationY = 0.0;
  double _chassisRotationZ = 0.0;

  // Параметры тестового куба
  final double _testAzimuth = 210 * math.pi / 180;
  final double _testElevation = -30 * math.pi / 180;
  final int _testUpVector = -1;

  // Управление движением
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  Timer? _movementTimer;

  // Геттеры для параметров камеры
  double get azimuth => _azimuth;
  double get elevation => _elevation;
  double get distance => _distance;
  vm.Vector3 get target => _target;
  vm.Vector3 get freeCameraPosition => _freeCameraPosition;
  double get freeCameraPitch => _freeCameraPitch;
  double get freeCameraYaw => _freeCameraYaw;
  double get freeCameraRoll => _freeCameraRoll;
  double get chassisRotationX => _chassisRotationX;
  double get chassisRotationY => _chassisRotationY;
  double get chassisRotationZ => _chassisRotationZ;
  double get testAzimuth => _testAzimuth;
  double get testElevation => _testElevation;
  int get testUpVector => _testUpVector;

  /// Обработка универсального движения мыши
  void handleUniversalMouseMove(Offset delta, int? buttons, PointerEvent event) {
    if (_cameraMode == CameraMode.orbital) {
      if ((buttons ?? 0) & kSecondaryMouseButton != 0) {
        // ПКМ - вращение камеры вокруг объекта
        _azimuth += delta.dx * 0.01;
        _elevation = (_elevation - delta.dy * 0.01).clamp(-math.pi / 2, math.pi / 2);
        notifyListeners();
      } else if ((buttons ?? 0) & kMiddleMouseButton != 0) {
        // СКМ - панорамирование
        final right = vm.Vector3(
          math.cos(_azimuth),
          0,
          math.sin(_azimuth),
        );
        final up = vm.Vector3(0, 1, 0);
        _target += right * delta.dx * 0.5;
        _target += up * -delta.dy * 0.5;
        notifyListeners();
      }
    } else {
      // Свободный режим
      if ((buttons ?? 0) & kSecondaryMouseButton != 0) {
        // ПКМ - поворот взгляда камеры
        _freeCameraYaw += delta.dx * 0.01;
        _freeCameraPitch = (_freeCameraPitch - delta.dy * 0.01).clamp(-math.pi / 2, math.pi / 2);
        notifyListeners();
      } else if ((buttons ?? 0) & kMiddleMouseButton != 0) {
        // СКМ - панорамирование
        final right = vm.Vector3(
          math.cos(_freeCameraYaw) * math.cos(_freeCameraPitch),
          0,
          math.sin(_freeCameraYaw) * math.cos(_freeCameraPitch),
        );
        final up = vm.Vector3(0, 1, 0);
        _freeCameraPosition += right * delta.dx * 0.5;
        _freeCameraPosition += up * -delta.dy * 0.5;
        notifyListeners();
      }
    }

    // Проверяем модификаторы для вращения каркаса
    final isShiftPressed = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
                          HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftRight);
    
    if (isShiftPressed && (buttons ?? 0) & kSecondaryMouseButton != 0) {
      // Shift + ПКМ - вращение каркаса
      handleChassisRotation(delta);
    }
  }

  /// Обработка прокрутки колеса мыши
  void handleScroll(PointerScrollEvent event) {
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
    notifyListeners();
  }

  /// Обработка клавиатурных событий
  void handleKeyEvent(KeyEvent event) {
    final key = event.logicalKey;
    
    if (event is KeyDownEvent) {
      // Обработка мгновенных команд
      if (key == LogicalKeyboardKey.space) {
        centerCameraOnObject();
        return;
      } else if (key == LogicalKeyboardKey.tab) {
        toggleCameraMode();
        return;
      } else if (key == LogicalKeyboardKey.backspace) {
        resetCamera();
        return;
      } else if (key == LogicalKeyboardKey.digit1) {
        setPresetView(1); // Вид спереди
        return;
      } else if (key == LogicalKeyboardKey.digit2) {
        setPresetView(2); // Вид сбоку
        return;
      } else if (key == LogicalKeyboardKey.digit3) {
        setPresetView(3); // Вид сверху
        return;
      } else if (key == LogicalKeyboardKey.digit4) {
        setPresetView(4); // Изометрия
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
        _movementTimer?.cancel();
      }
    }
  }

  /// Обновление движения камеры на основе нажатых клавиш
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

    // WASD движение камеры
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

    // Q/E для вертикального движения
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

    // Вращение каркаса стрелками
    if (shiftPressed) {
      // Shift + стрелки влево/вправо - вращение вокруг Z
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
        _chassisRotationZ -= baseRotateSpeed;
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
        _chassisRotationZ += baseRotateSpeed;
      }
    } else {
      // Стрелки без модификаторов - вращение вокруг Y
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
        _chassisRotationY -= baseRotateSpeed;
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
        _chassisRotationY += baseRotateSpeed;
      }
    }
    
    // Стрелки вверх/вниз - вращение вокруг X
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      _chassisRotationX -= baseRotateSpeed;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      _chassisRotationX += baseRotateSpeed;
    }

    // Уведомляем слушателей об изменениях
    notifyListeners();
  }

  /// Переключение режима камеры
  void toggleCameraMode() {
    _cameraMode = _cameraMode == CameraMode.orbital 
        ? CameraMode.free 
        : CameraMode.orbital;
    notifyListeners();
  }

  /// Установка режима камеры
  void setCameraMode(CameraMode mode) {
    _cameraMode = mode;
    notifyListeners();
  }

  /// Центрирование камеры на объекте
  void centerCameraOnObject() {
    if (_cameraMode == CameraMode.orbital) {
      _azimuth = 45 * math.pi / 180;
      _elevation = 30 * math.pi / 180;
      _distance = 1200.0;
    } else {
      _freeCameraPosition = vm.Vector3(1689, -1335, 1674);
      _freeCameraYaw = -135 * math.pi / 180;
      _freeCameraPitch = -30 * math.pi / 180;
    }
    notifyListeners();
  }

  /// Сброс камеры к начальному положению
  void resetCamera() {
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
    
    notifyListeners();
  }

  /// Установка предустановленного вида
  void setPresetView(int preset) {
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
    notifyListeners();
  }

  /// Вращение каркаса
  void handleChassisRotation(Offset delta) {
    const sensitivity = 0.01;
    _chassisRotationY += delta.dx * sensitivity;
    _chassisRotationX += delta.dy * sensitivity;
    notifyListeners();
  }

  // Вспомогательные методы
  vm.Vector3 _getCameraForward() {
    if (_cameraMode == CameraMode.free) {
      return vm.Vector3(
        math.sin(_freeCameraYaw) * math.cos(_freeCameraPitch),
        -math.sin(_freeCameraPitch),
        math.cos(_freeCameraYaw) * math.cos(_freeCameraPitch),
      );
    } else {
      final center = vm.Vector3.zero();
      final position = vm.Vector3(
        _distance * math.sin(_azimuth) * math.cos(_elevation),
        _distance * math.sin(_elevation),
        _distance * math.cos(_azimuth) * math.cos(_elevation),
      );
      return (center - position).normalized();
    }
  }

  vm.Vector3 _getCameraRight() {
    final forward = _getCameraForward();
    final up = vm.Vector3(0, 1, 0);
    return forward.cross(up).normalized();
  }

  vm.Vector3 _getCameraUp() {
    return vm.Vector3(0, 1, 0);
  }

  void _moveCameraByVector(vm.Vector3 movement) {
    if (_cameraMode == CameraMode.free) {
      _freeCameraPosition += movement;
    } else {
      const sensitivity = 0.01;
      _azimuth += movement.x * sensitivity;
      _elevation += movement.y * sensitivity;
      _elevation = _elevation.clamp(-math.pi / 2 + 0.1, math.pi / 2 - 0.1);
    }
  }

  void _handleKeyboardZoom(double delta) {
    if (_cameraMode == CameraMode.free) {
      final forward = _getCameraForward();
      _freeCameraPosition += forward * delta;
    } else {
      _distance = (_distance - delta).clamp(50.0, 5000.0);
    }
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    super.dispose();
  }
}