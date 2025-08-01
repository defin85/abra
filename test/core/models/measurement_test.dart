import 'package:flutter_test/flutter_test.dart';
import 'package:abra/core/models/measurement.dart';

void main() {
  group('Measurement', () {
    test('должен правильно рассчитывать отклонение', () {
      final measurement = Measurement(
        projectId: 'test-project',
        fromPointId: 'A',
        toPointId: 'B',
        factoryValue: 100.0,
        actualValue: 105.0,
        type: MeasurementType.width,
      );

      expect(measurement.deviation, 5.0);
      expect(measurement.deviationPercent, 5.0);
    });

    test('должен правильно определять серьезность отклонения', () {
      // Норма (< 2%)
      final normal = Measurement(
        projectId: 'test',
        fromPointId: 'A',
        toPointId: 'B',
        factoryValue: 100.0,
        actualValue: 101.5, // 1.5% отклонение
        type: MeasurementType.width,
      );
      expect(normal.severity, DeviationSeverity.normal);

      // Предупреждение (2-5%)
      final warning = Measurement(
        projectId: 'test',
        fromPointId: 'A',
        toPointId: 'B',
        factoryValue: 100.0,
        actualValue: 103.0, // 3% отклонение
        type: MeasurementType.width,
      );
      expect(warning.severity, DeviationSeverity.warning);

      // Критично (5-10%)
      final critical = Measurement(
        projectId: 'test',
        fromPointId: 'A',
        toPointId: 'B',
        factoryValue: 100.0,
        actualValue: 107.0, // 7% отклонение
        type: MeasurementType.width,
      );
      expect(critical.severity, DeviationSeverity.critical);

      // Серьезно (> 10%)
      final severe = Measurement(
        projectId: 'test',
        fromPointId: 'A',
        toPointId: 'B',
        factoryValue: 100.0,
        actualValue: 115.0, // 15% отклонение
        type: MeasurementType.width,
      );
      expect(severe.severity, DeviationSeverity.severe);
    });

    test('должен корректно работать с отрицательными отклонениями', () {
      final measurement = Measurement(
        projectId: 'test',
        fromPointId: 'A',
        toPointId: 'B',
        factoryValue: 100.0,
        actualValue: 92.0, // -8% отклонение
        type: MeasurementType.width,
      );

      expect(measurement.deviation, -8.0);
      expect(measurement.deviationPercent, -8.0);
      expect(measurement.severity, DeviationSeverity.critical);
    });

    test('должен возвращать норму для null actualValue', () {
      final measurement = Measurement(
        projectId: 'test',
        fromPointId: 'A',
        toPointId: 'B',
        factoryValue: 100.0,
        type: MeasurementType.width,
      );

      expect(measurement.deviation, 0.0);
      expect(measurement.deviationPercent, 0.0);
      expect(measurement.severity, DeviationSeverity.normal);
    });

    test('copyWith должен правильно копировать с изменениями', () {
      final original = Measurement(
        projectId: 'test',
        fromPointId: 'A',
        toPointId: 'B',
        factoryValue: 100.0,
        type: MeasurementType.width,
      );

      final updated = original.copyWith(actualValue: 105.0);

      expect(updated.actualValue, 105.0);
      expect(updated.projectId, original.projectId);
      expect(updated.fromPointId, original.fromPointId);
      expect(updated.toPointId, original.toPointId);
      expect(updated.factoryValue, original.factoryValue);
      expect(updated.type, original.type);
    });

    test('toJson и fromJson должны работать корректно', () {
      final measurement = Measurement(
        projectId: 'test',
        fromPointId: 'A',
        toPointId: 'B',
        factoryValue: 100.0,
        actualValue: 105.0,
        type: MeasurementType.diagonal,
        notes: 'Test note',
      );

      final json = measurement.toJson();
      final restored = Measurement.fromJson(json);

      expect(restored.id, measurement.id);
      expect(restored.projectId, measurement.projectId);
      expect(restored.fromPointId, measurement.fromPointId);
      expect(restored.toPointId, measurement.toPointId);
      expect(restored.factoryValue, measurement.factoryValue);
      expect(restored.actualValue, measurement.actualValue);
      expect(restored.type, measurement.type);
      expect(restored.notes, measurement.notes);
    });
  });
}