import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../controllers/camera_controller.dart';
import '../widgets/adaptive_chassis_painter.dart';

/// Панель управления камерой
class CameraControlPanel extends StatelessWidget {
  final CameraController controller;
  final String chassisName;
  final double wheelbase;
  final double trackWidth;
  final VoidCallback onShowHelp;

  const CameraControlPanel({
    super.key,
    required this.controller,
    required this.chassisName,
    required this.wheelbase,
    required this.trackWidth,
    required this.onShowHelp,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информация о каркасе
            Text('Адаптивный каркас', style: Theme.of(context).textTheme.labelSmall),
            Text(chassisName, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text('База: ${wheelbase.toInt()}мм', 
                 style: Theme.of(context).textTheme.bodySmall),
            Text('Колея: ${trackWidth.toInt()}мм', 
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
              selected: {controller.cameraMode},
              onSelectionChanged: (Set<CameraMode> newSelection) {
                controller.setCameraMode(newSelection.first);
              },
            ),
            const SizedBox(height: 8),
            
            // Кнопка сброса камеры
            ElevatedButton.icon(
              onPressed: controller.resetCamera,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Сброс камеры', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 8),
            
            // Статус камеры
            Text('${_getCameraModeDisplayName(controller.cameraMode)}: ${_getCameraStatusText(controller)}', 
                 style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            // Параметры камеры
            _buildCameraParameters(context, controller),
            
            const SizedBox(height: 8),
            
            // Быстрые виды
            Text('Быстрые виды:', style: Theme.of(context).textTheme.labelSmall),
            Row(
              children: [
                _buildQuickViewButton('1', 'Спереди', 1, controller),
                _buildQuickViewButton('2', 'Сбоку', 2, controller),
                _buildQuickViewButton('3', 'Сверху', 3, controller),
                _buildQuickViewButton('4', 'Изо', 4, controller),
              ],
            ),
            
            const Divider(),
            
            // Углы каркаса
            Text('Поворот каркаса:', style: Theme.of(context).textTheme.labelSmall),
            Text('X: ${(controller.chassisRotationX * 180 / math.pi).toStringAsFixed(0)}°  '
                 'Y: ${(controller.chassisRotationY * 180 / math.pi).toStringAsFixed(0)}°  '
                 'Z: ${(controller.chassisRotationZ * 180 / math.pi).toStringAsFixed(0)}°', 
                 style: Theme.of(context).textTheme.bodySmall),
            
            const SizedBox(height: 8),
            
            // Кнопка помощи
            OutlinedButton.icon(
              onPressed: onShowHelp,
              icon: const Icon(Icons.help_outline, size: 16),
              label: const Text('Управление', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getCameraModeDisplayName(CameraMode mode) {
    switch (mode) {
      case CameraMode.orbital:
        return 'Орбита';
      case CameraMode.free:
        return 'Свободно';
      case CameraMode.testCube:
        return 'Тест';
    }
  }

  String _getCameraStatusText(CameraController controller) {
    switch (controller.cameraMode) {
      case CameraMode.orbital:
        return '${controller.distance.toStringAsFixed(0)} ед, ${(controller.azimuth * 180 / math.pi).toStringAsFixed(0)}°';
      case CameraMode.free:
        return '(${controller.freeCameraPosition.x.toStringAsFixed(0)}, ${controller.freeCameraPosition.y.toStringAsFixed(0)}, ${controller.freeCameraPosition.z.toStringAsFixed(0)})';
      case CameraMode.testCube:
        return 'Тестовый куб';
    }
  }

  Widget _buildCameraParameters(BuildContext context, CameraController controller) {
    switch (controller.cameraMode) {
      case CameraMode.orbital:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Расстояние: ${controller.distance.toStringAsFixed(0)}', 
                 style: Theme.of(context).textTheme.bodySmall),
            Text('Азимут: ${(controller.azimuth * 180 / math.pi).toStringAsFixed(0)}°', 
                 style: Theme.of(context).textTheme.bodySmall),
            Text('Наклон: ${(controller.elevation * 180 / math.pi).toStringAsFixed(0)}°', 
                 style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      case CameraMode.free:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Позиция: (${controller.freeCameraPosition.x.toStringAsFixed(0)}, ${controller.freeCameraPosition.y.toStringAsFixed(0)}, ${controller.freeCameraPosition.z.toStringAsFixed(0)})', 
                 style: Theme.of(context).textTheme.bodySmall),
            Text('Поворот: ${(controller.freeCameraYaw * 180 / math.pi).toStringAsFixed(0)}° / ${(controller.freeCameraPitch * 180 / math.pi).toStringAsFixed(0)}°', 
                 style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      case CameraMode.testCube:
        return Text('Тестовый куб 50×50×50', style: Theme.of(context).textTheme.bodySmall);
    }
  }

  Widget _buildQuickViewButton(String number, String label, int view, CameraController controller) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: InkWell(
          onTap: () => controller.setPresetView(view),
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
}