/// Константы для геометрических расчетов и визуализации
class GeometryConstants {
  GeometryConstants._();

  // Параметры камеры по умолчанию
  static const double defaultCameraAzimuth = 0.785398; // math.pi / 4 (45°)
  static const double defaultCameraElevation = -0.523599; // -math.pi / 6 (30°)
  static const double defaultCameraDistance = 500.0;
  
  // Изометрические параметры камеры
  static const double isometricCameraX = 500.0;
  static const double isometricCameraY = 200.0;
  static const double isometricCameraZ = 500.0;
  static const double isometricCameraPitch = -0.615479; // -35.26° в радианах
  static const double isometricCameraYaw = -2.356194; // -math.pi * 0.75
  
  // Параметры отображения
  static const double axisLength = 100.0;
  static const double axisWidth = 2.0;
  static const double controlPointRadius = 6.0;
  static const double selectedPointRadius = 8.0;
  static const double labelFontSize = 12.0;
  
  // Пороги отклонений (в процентах)
  static const double deviationWarningThreshold = 2.0; // 2%
  static const double deviationCriticalThreshold = 5.0; // 5%
  static const double deviationSevereThreshold = 10.0; // 10%
  
  // Параметры анимации
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration cameraMovementInterval = Duration(milliseconds: 16);
  
  // Параметры адаптивной геометрии
  static const double sillWidthReductionFactor = 0.35; // 35% сужение к задней части
  static const double sillHeightPeakFactor = 0.6; // 60% подъем в середине
  static const double subframeWidthFactor = 0.8; // 80% от ширины колеи
  static const double subframeHeightFactor = 0.7; // 70% от высоты порогов
  static const double tunnelHeightFactor = 1.4; // 140% от высоты порогов
  static const double frontLongeronHeightFactor = 2.0; // 200% от высоты порогов
  static const double rearLongeronHeightFactor = 2.2; // 220% от высоты порогов
  
  // Размеры элементов каркаса (относительные коэффициенты)
  static const double elementThicknessBase = 10.0;
  static const double crossMemberWidthFactor = 1.3;
  static const double longeronSegmentLength = 50.0;
  
  // Параметры демо-деформации
  static const double demoFrontDamage = 0.2; // 20%
  static const double demoWheelbaseChange = -15.0; // -15 мм
}

/// Константы для UI элементов
class UIConstants {
  UIConstants._();
  
  // Размеры панелей
  static const double mobilePanelWidth = 280.0;
  static const double tabletPanelWidth = 320.0;
  static const double desktopPanelWidth = 350.0;
  
  // Отступы
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Размеры иконок
  static const double appIconSize = 32.0;
  static const double smallIconSize = 20.0;
  
  // Брейкпоинты для адаптивного дизайна
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  
  // Цвета состояний
  static const double severityColorOpacity = 0.1;
}

/// Константы для измерений
class MeasurementConstants {
  MeasurementConstants._();
  
  // Лимиты для отчетов
  static const int criticalMeasurementsLimit = 5;
  
  // Форматирование
  static const int decimalPlaces = 1;
}

/// Константы для 3D визуализации
class Visualization3DConstants {
  Visualization3DConstants._();
  
  // Параметры проекции
  static const double perspectiveDistance = 1000.0;
  static const double nearClipPlane = 1.0;
  static const double farClipPlane = 10000.0;
  
  // Скорость вращения и масштабирования
  static const double rotationSensitivity = 0.01;
  static const double scaleSensitivity = 0.001;
  static const double minScale = 0.1;
  static const double maxScale = 5.0;
  
  // Скорость движения камеры (свободный режим)
  static const double cameraMovementSpeed = 5.0;
  static const double cameraBoostMultiplier = 3.0;
  static const double cameraCrawlDivisor = 3.0;
}