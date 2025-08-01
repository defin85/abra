import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:abra/providers/measurements_provider.dart';
import 'package:abra/core/models/measurement.dart';

void main() {
  group('MeasurementsProvider', () {
    test('DeviationStats.fromMeasurements должен правильно подсчитывать статистику', () {
      final measurements = [
        Measurement(
          projectId: 'test',
          fromPointId: 'A',
          toPointId: 'B',
          factoryValue: 100.0,
          actualValue: 101.0, // normal
          type: MeasurementType.width,
        ),
        Measurement(
          projectId: 'test',
          fromPointId: 'C',
          toPointId: 'D',
          factoryValue: 100.0,
          actualValue: 103.0, // warning
          type: MeasurementType.width,
        ),
        Measurement(
          projectId: 'test',
          fromPointId: 'E',
          toPointId: 'F',
          factoryValue: 100.0,
          actualValue: null, // не измерено
          type: MeasurementType.width,
        ),
      ];

      final stats = DeviationStats.fromMeasurements(measurements);

      expect(stats.totalMeasured, 2);
      expect(stats.normal, 1); // 1% - normal
      expect(stats.warning, 1); // 3% - warning
      expect(stats.critical, 0);
      expect(stats.severe, 0);
    });

    test('MeasurementsNotifier должен управлять списком измерений', () async {
      final container = ProviderContainer();
      final notifier = container.read(measurementsProvider.notifier);

      // Добавление измерения
      final measurement1 = Measurement(
        projectId: 'test',
        fromPointId: 'A',
        toPointId: 'B',
        factoryValue: 100.0,
        type: MeasurementType.width,
      );
      notifier.addMeasurement(measurement1);
      
      var measurements = container.read(measurementsProvider);
      expect(measurements.length, greaterThan(0));
      expect(measurements.last.id, measurement1.id);

      // Обновление измерения
      final updated = measurement1.copyWith(actualValue: 105.0);
      notifier.updateMeasurement(updated);
      
      measurements = container.read(measurementsProvider);
      final found = measurements.firstWhere((m) => m.id == measurement1.id);
      expect(found.actualValue, 105.0);

      // Удаление измерения
      notifier.removeMeasurement(measurement1.id);
      measurements = container.read(measurementsProvider);
      expect(
        measurements.where((m) => m.id == measurement1.id).isEmpty,
        true,
      );

      container.dispose();
    });

    test('deviationStatsProvider должен реагировать на изменения измерений', () async {
      final container = ProviderContainer();
      final notifier = container.read(measurementsProvider.notifier);

      // Очищаем измерения
      notifier.clearMeasurements();
      
      var stats = container.read(deviationStatsProvider);
      expect(stats.totalMeasured, 0);

      // Добавляем измерение с отклонением
      final measurement = Measurement(
        projectId: 'test',
        fromPointId: 'A',
        toPointId: 'B',
        factoryValue: 100.0,
        actualValue: 112.0, // severe
        type: MeasurementType.width,
      );
      notifier.addMeasurement(measurement);

      stats = container.read(deviationStatsProvider);
      expect(stats.totalMeasured, 1);
      expect(stats.severe, 1);

      container.dispose();
    });
  });
}