import '../models/measurement.dart';

/// Сервис для расчета статистики измерений
class MeasurementStatisticsService {
  /// Подсчитывает статистику отклонений для списка измерений
  static Map<String, int> calculateDeviationStatistics(List<Measurement> measurements) {
    final measured = measurements.where((m) => m.actualValue != null).toList();
    
    return {
      'total': measured.length,
      'normal': measured.where((m) => m.severity == DeviationSeverity.normal).length,
      'warning': measured.where((m) => m.severity == DeviationSeverity.warning).length,
      'critical': measured.where((m) => m.severity == DeviationSeverity.critical).length,
      'severe': measured.where((m) => m.severity == DeviationSeverity.severe).length,
    };
  }

  /// Рассчитывает процент завершенности измерений
  static double calculateCompletionProgress(List<Measurement> measurements) {
    if (measurements.isEmpty) return 0.0;
    
    final measuredCount = measurements.where((m) => m.actualValue != null).length;
    return measuredCount / measurements.length;
  }

  /// Определяет общий статус проекта на основе измерений
  static ProjectHealthStatus determineProjectHealth(List<Measurement> measurements) {
    final stats = calculateDeviationStatistics(measurements);
    
    if (stats['severe']! > 0) {
      return ProjectHealthStatus.severe;
    } else if (stats['critical']! > 2) {
      return ProjectHealthStatus.critical;
    } else if (stats['warning']! > 5) {
      return ProjectHealthStatus.warning;
    } else {
      return ProjectHealthStatus.good;
    }
  }

  /// Находит наиболее критичные измерения
  static List<Measurement> getMostCriticalMeasurements(
    List<Measurement> measurements, {
    int limit = 5,
  }) {
    final measured = measurements.where((m) => m.actualValue != null).toList();
    
    measured.sort((a, b) {
      // Сортируем по серьезности отклонения
      final severityCompare = b.severity.index.compareTo(a.severity.index);
      if (severityCompare != 0) return severityCompare;
      
      // При одинаковой серьезности сортируем по проценту отклонения
      return b.deviationPercent.abs().compareTo(a.deviationPercent.abs());
    });
    
    return measured.take(limit).toList();
  }

  /// Группирует измерения по типу
  static Map<MeasurementType, List<Measurement>> groupByType(List<Measurement> measurements) {
    final groups = <MeasurementType, List<Measurement>>{};
    
    for (final measurement in measurements) {
      groups.putIfAbsent(measurement.type, () => []).add(measurement);
    }
    
    return groups;
  }

  /// Рассчитывает среднее отклонение по типам измерений
  static Map<MeasurementType, double> calculateAverageDeviationByType(List<Measurement> measurements) {
    final groups = groupByType(measurements);
    final averages = <MeasurementType, double>{};
    
    groups.forEach((type, typeMeasurements) {
      final measured = typeMeasurements.where((m) => m.actualValue != null).toList();
      if (measured.isEmpty) {
        averages[type] = 0.0;
      } else {
        final sum = measured.fold<double>(0, (sum, m) => sum + m.deviationPercent.abs());
        averages[type] = sum / measured.length;
      }
    });
    
    return averages;
  }
}

/// Статус здоровья проекта
enum ProjectHealthStatus {
  good,
  warning,
  critical,
  severe,
}