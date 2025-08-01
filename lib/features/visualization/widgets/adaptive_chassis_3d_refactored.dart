import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../../../core/geometry/adaptive_chassis.dart';
import '../controllers/camera_controller.dart';
import 'adaptive_chassis_painter.dart';
import 'camera_control_panel.dart';
import 'draggable_control_panel.dart';

/// Основной виджет 3D визуализации адаптивного каркаса (рефакторинг)
class AdaptiveChassis3D extends StatefulWidget {
  final AdaptiveChassis? factoryChassis;
  final AdaptiveChassis? deformedChassis;
  final bool showMeasurements;
  final bool showLabels;
  final bool showDeformed;
  final bool showAxes;
  final bool useCurvedElements;
  
  const AdaptiveChassis3D({
    super.key,
    this.factoryChassis,
    this.deformedChassis,
    this.showMeasurements = false,
    this.showLabels = true,
    this.showDeformed = false,
    this.showAxes = true,
    this.useCurvedElements = true,
  });

  @override
  State<AdaptiveChassis3D> createState() => _AdaptiveChassis3DState();
}

class _AdaptiveChassis3DState extends State<AdaptiveChassis3D> {
  late CameraController _cameraController;
  
  // Переменные для обработки мыши
  Offset? _lastPanPosition;
  int? _activeMouseButton;

  @override
  void initState() {
    super.initState();
    _cameraController = CameraController();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
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
              _cameraController.handleKeyEvent(event);
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
                  _cameraController.handleUniversalMouseMove(delta, _activeMouseButton, event);
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
                  _cameraController.handleScroll(event);
                }
              },
              child: ListenableBuilder(
                listenable: _cameraController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: AdaptiveChassisPainter(
                      showMeasurements: widget.showMeasurements,
                      showLabels: widget.showLabels,
                      showDeformed: widget.showDeformed,
                      showAxes: widget.showAxes,
                      useCurvedElements: widget.useCurvedElements,
                      cameraMode: _cameraController.cameraMode,
                      azimuth: _cameraController.azimuth,
                      elevation: _cameraController.elevation,
                      distance: _cameraController.distance,
                      target: _cameraController.target,
                      freeCameraPosition: _cameraController.freeCameraPosition,
                      freeCameraPitch: _cameraController.freeCameraPitch,
                      freeCameraYaw: _cameraController.freeCameraYaw,
                      freeCameraRoll: _cameraController.freeCameraRoll,
                      chassisRotationX: _cameraController.chassisRotationX,
                      chassisRotationY: _cameraController.chassisRotationY,
                      chassisRotationZ: _cameraController.chassisRotationZ,
                      factoryChassis: widget.factoryChassis ?? const AdaptiveChassis(
                        wheelbase: 2825,
                        trackWidth: 1545,
                        sillHeight: 120,
                      ),
                      deformedChassis: widget.deformedChassis,
                      testAzimuth: _cameraController.testAzimuth,
                      testElevation: _cameraController.testElevation,
                      testUpVector: _cameraController.testUpVector,
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Панель управления камерой
          DraggableControlPanel(
            title: 'Управление камерой',
            initialPosition: const Offset(20, 20),
            child: CameraControlPanel(
              controller: _cameraController,
              chassisName: 'Toyota Camry XV70',
              wheelbase: widget.factoryChassis?.wheelbase ?? 2825,
              trackWidth: widget.factoryChassis?.trackWidth ?? 1545,
              onShowHelp: _showControlsHelp,
            ),
          ),
        ],
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