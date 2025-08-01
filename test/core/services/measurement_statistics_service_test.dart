import 'package:flutter_test/flutter_test.dart';
import 'package:abra/core/models/measurement.dart';
import 'package:abra/core/services/measurement_statistics_service.dart';

void main() {
  group('MeasurementStatisticsService', () {
    List<Measurement> createTestMeasurements() {
      return [
        Measurement(
          projectId: 'test',
          fromPointId: 'A',
          toPointId: 'B',
          factoryValue: 100.0,
          actualValue: 101.0, // normal - 1%
          type: MeasurementType.width,
        ),
        Measurement(
          projectId: 'test',
          fromPointId: 'C',
          toPointId: 'D',
          factoryValue: 200.0,
          actualValue: 206.0, // warning - 3%
          type: MeasurementType.length,
        ),
        Measurement(
          projectId: 'test',
          fromPointId: 'E',
          toPointId: 'F',
          factoryValue: 150.0,
          actualValue: 161.0, // critical - 7.3%
          type: MeasurementType.diagonal,
        ),
        Measurement(
          projectId: 'test',
          fromPointId: 'G',
          toPointId: 'H',
          factoryValue: 300.0,
          actualValue: 340.0, // severe - 13.3%
          type: MeasurementType.width,
        ),
        Measurement(
          projectId: 'test',
          fromPointId: 'I',
          toPointId: 'J',
          factoryValue: 250.0,
          actualValue: null, // не измерено
          type: MeasurementType.height,
        ),
      ];
    }

    test('calculateDeviationStatistics должен правильно подсчитывать статистику', () {
      final measurements = createTestMeasurements();
      final stats = MeasurementStatisticsService.calculateDeviationStatistics(measurements);

      expect(stats['total'], 4); // только измеренные
      expect(stats['normal'], 1);
      expect(stats['warning'], 1);
      expect(stats['critical'], 1);
      expect(stats['severe'], 1);
    });

    test('calculateCompletionProgress должен правильно рассчитывать прогресс', () {
      final measurements = createTestMeasurements();
      final progress = MeasurementStatisticsService.calculateCompletionProgress(measurements);

      expect(progress, 0.8); // 4 из 5 измерены = 80%
    });

    test('determineProjectHealth должен правильно определять статус проекта', () {
      // Проект с серьезными отклонениями
      final severeProject = createTestMeasurements();
      expect(
        MeasurementStatisticsService.determineProjectHealth(severeProject),
        ProjectHealthStatus.severe,
      );

      // Проект только с критичными отклонениями
      final criticalProject = [
        Measurement(
          projectId: 'test',
          fromPointId: 'A',
          toPointId: 'B',
          factoryValue: 100.0,
          actualValue: 107.0, // critical
          type: MeasurementType.width,
        ),
        Measurement(
          projectId: 'test',
          fromPointId: 'C',
          toPointId: 'D',
          factoryValue: 100.0,
          actualValue: 108.0, // critical
          type: MeasurementType.width,
        ),
        Measurement(
          projectId: 'test',
          fromPointId: 'E',
          toPointId: 'F',
          factoryValue: 100.0,
          actualValue: 109.0, // critical
          type: MeasurementType.width,
        ),
      ];
      expect(
        MeasurementStatisticsService.determineProjectHealth(criticalProject),
        ProjectHealthStatus.critical,
      );

      // Хороший проект
      final goodProject = [
        Measurement(
          projectId: 'test',
          fromPointId: 'A',
          toPointId: 'B',
          factoryValue: 100.0,
          actualValue: 101.0, // normal
          type: MeasurementType.width,
        ),
      ];
      expect(
        MeasurementStatisticsService.determineProjectHealth(goodProject),
        ProjectHealthStatus.good,
      );
    });

    test('getMostCriticalMeasurements должен возвращать самые критичные измерения', () {
      final measurements = createTestMeasurements();
      final critical = MeasurementStatisticsService.getMostCriticalMeasurements(
        measurements,
        limit: 2,
      );

      expect(critical.length, 2);
      expect(critical[0].severity, DeviationSeverity.severe);
      expect(critical[1].severity, DeviationSeverity.critical);
    });

    test('groupByType должен правильно группировать измерения', () {
      final measurements = createTestMeasurements();
      final groups = MeasurementStatisticsService.groupByType(measurements);

      expect(groups[MeasurementType.width]?.length, 2);
      expect(groups[MeasurementType.length]?.length, 1);
      expect(groups[MeasurementType.diagonal]?.length, 1);
      expect(groups[MeasurementType.height]?.length, 1);
      expect(groups[MeasurementType.reference], null);
    });

    test('calculateAverageDeviationByType должен рассчитывать средние отклонения', () {
      final measurements = createTestMeasurements();
      final averages = MeasurementStatisticsService.calculateAverageDeviationByType(measurements);

      // width: (1% + 13.333...%) / 2 = 7.1666...%
      expect(averages[MeasurementType.width], closeTo(7.167, 0.01));
      
      // length: 3%
      expect(averages[MeasurementType.length], 3.0);
      
      // diagonal: 7.3%
      expect(averages[MeasurementType.diagonal], closeTo(7.33, 0.01));
      
      // height: 0% (не измерено)
      expect(averages[MeasurementType.height], 0.0);
    });
  });
}