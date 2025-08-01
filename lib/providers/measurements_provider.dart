import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/measurement.dart';
import '../core/models/car_model.dart';
import '../core/models/project.dart';
import '../core/data/templates/toyota_camry_template.dart';
import 'project_provider.dart';

// Провайдер для списка измерений
final measurementsProvider = StateNotifierProvider<MeasurementsNotifier, List<Measurement>>((ref) {
  final project = ref.watch(currentProjectProvider);
  final carModel = ref.watch(selectedCarModelProvider);
  return MeasurementsNotifier(ref, project, carModel);
});

// Провайдер для статистики отклонений
final deviationStatsProvider = Provider<DeviationStats>((ref) {
  final measurements = ref.watch(measurementsProvider);
  return DeviationStats.fromMeasurements(measurements);
});

// StateNotifier для управления измерениями
class MeasurementsNotifier extends StateNotifier<List<Measurement>> {
  final Ref ref;
  final Project? project;
  final CarModel? carModel;

  MeasurementsNotifier(this.ref, this.project, this.carModel) : super([]) {
    if (project != null && carModel != null) {
      _initializeDemoMeasurements();
    }
  }

  void _initializeDemoMeasurements() {
    if (carModel == null || project == null) return;

    final defaultMeasurements = ToyotaCamryTemplate.getDefaultMeasurements();
    final measurements = <Measurement>[];

    for (final measurementData in defaultMeasurements) {
      final fromPoint = carModel!.controlPoints.firstWhere(
        (p) => p.code == measurementData['from'],
      );
      final toPoint = carModel!.controlPoints.firstWhere(
        (p) => p.code == measurementData['to'],
      );

      measurements.add(
        Measurement(
          projectId: project!.id,
          fromPointId: fromPoint.id,
          toPointId: toPoint.id,
          factoryValue: measurementData['value'] as double,
          type: MeasurementType.values.firstWhere(
            (t) => t.name == measurementData['type'],
          ),
        ),
      );
    }

    // Добавляем демо отклонения
    if (measurements.length > 3) {
      measurements[0] = measurements[0].copyWith(actualValue: 698.5);
      measurements[1] = measurements[1].copyWith(actualValue: 885.0);
      measurements[2] = measurements[2].copyWith(actualValue: 960.0);
    }

    state = measurements;
  }

  void addMeasurement(Measurement measurement) {
    state = [...state, measurement];
  }

  void updateMeasurement(Measurement measurement) {
    state = state.map((m) => m.id == measurement.id ? measurement : m).toList();
  }

  void updateMeasurementByIndex(int index, Measurement measurement) {
    if (index >= 0 && index < state.length) {
      final newState = [...state];
      newState[index] = measurement;
      state = newState;
    }
  }

  void removeMeasurement(String measurementId) {
    state = state.where((m) => m.id != measurementId).toList();
  }

  void clearMeasurements() {
    state = [];
  }

  void replaceMeasurements(List<Measurement> measurements) {
    state = measurements;
  }
}

// Модель для статистики отклонений
class DeviationStats {
  final int totalMeasured;
  final int normal;
  final int warning;
  final int critical;
  final int severe;

  DeviationStats({
    required this.totalMeasured,
    required this.normal,
    required this.warning,
    required this.critical,
    required this.severe,
  });

  factory DeviationStats.fromMeasurements(List<Measurement> measurements) {
    final measured = measurements.where((m) => m.actualValue != null).toList();
    
    return DeviationStats(
      totalMeasured: measured.length,
      normal: measured.where((m) => m.severity == DeviationSeverity.normal).length,
      warning: measured.where((m) => m.severity == DeviationSeverity.warning).length,
      critical: measured.where((m) => m.severity == DeviationSeverity.critical).length,
      severe: measured.where((m) => m.severity == DeviationSeverity.severe).length,
    );
  }
}