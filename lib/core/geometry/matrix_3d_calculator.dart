import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

/// Вспомогательный класс для 3D математических расчетов
class Matrix3DCalculator {
  static const double perspective = 5000.0;
  
  /// Создает матрицу орбитальной камеры
  static Matrix4 createOrbitCamera({
    required double azimuth,
    required double elevation,
    required double distance,
    required vm.Vector3 target,
  }) {
    // Вычисляем позицию камеры в сферических координатах
    final x = distance * math.cos(elevation) * math.cos(azimuth);
    final y = distance * math.sin(elevation);
    final z = distance * math.cos(elevation) * math.sin(azimuth);
    
    final cameraPos = vm.Vector3(x, y, z) + target;
    final up = vm.Vector3(0, 0, -1);
    
    return makeViewMatrix(cameraPos, target, up);
  }
  
  /// Создает матрицу свободной камеры
  static Matrix4 createFreeCamera({
    required vm.Vector3 position,
    required double pitch,
    required double yaw,
    required double roll,
  }) {
    // Создаем направление взгляда камеры
    final forward = vm.Vector3(
      math.sin(yaw) * math.cos(pitch),
      -math.sin(pitch),
      math.cos(yaw) * math.cos(pitch),
    );
    
    final target = position + forward;
    // Используем Z как up для правильной ориентации
    final baseUp = vm.Vector3(0, 0, -1);
    // Применяем roll если нужно
    final up = roll == 0 ? baseUp : vm.Vector3(
      -math.sin(roll),
      0,
      -math.cos(roll),
    );
    
    return makeViewMatrix(position, target, up);
  }
  
  /// Создает матрицу камеры для тестового режима
  static Matrix4 createTestCubeCamera({
    required double azimuth,
    required double elevation,
    required int upVector,
  }) {
    const testDistance = 150.0;
    
    final x = testDistance * math.cos(elevation) * math.cos(azimuth);
    final y = testDistance * math.sin(elevation);
    final z = testDistance * math.cos(elevation) * math.sin(azimuth);
    
    final cameraPos = vm.Vector3(x, y, z);
    final target = vm.Vector3.zero();
    final up = vm.Vector3(0, 0, upVector.toDouble());
    
    return makeViewMatrix(cameraPos, target, up);
  }
  
  /// Создает view матрицу (look-at matrix)
  static Matrix4 makeViewMatrix(vm.Vector3 eye, vm.Vector3 target, vm.Vector3 up) {
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
  
  /// Проецирует 3D точку на 2D экран
  static Offset project3D(vm.Vector3 point, Matrix4 matrix) {
    final transformed = matrix.transform3(point);
    final scale = perspective / (perspective + transformed.z);
    return Offset(
      transformed.x * scale,
      transformed.y * scale,
    );
  }
  
  /// Проверяет видимость грани (backface culling)
  static bool isFaceVisible(List<vm.Vector3> vertices, Matrix4 matrix) {
    if (vertices.length < 3) return true;
    
    // Трансформируем первые 3 вершины
    final v0 = matrix.transform3(vertices[0]);
    final v1 = matrix.transform3(vertices[1]);
    final v2 = matrix.transform3(vertices[2]);
    
    // Вычисляем нормаль грани
    final edge1 = v1 - v0;
    final edge2 = v2 - v0;
    final normal = edge1.cross(edge2);
    
    // Проверяем направление нормали относительно камеры
    return normal.z < 0;
  }
  
  /// Кеш для проекций
  static final Map<String, Offset> _projectionCache = {};
  
  /// Проецирует точку с кешированием
  static Offset projectWithCache(vm.Vector3 point, Matrix4 matrix, String cacheKey) {
    final key = '$cacheKey:${point.x}:${point.y}:${point.z}';
    return _projectionCache[key] ??= project3D(point, matrix);
  }
  
  /// Очищает кеш проекций
  static void clearProjectionCache() {
    _projectionCache.clear();
  }
}