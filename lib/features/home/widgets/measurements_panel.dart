import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/measurement.dart';
import '../../../providers/project_provider.dart';
import '../../../providers/measurements_provider.dart';
import '../../measurement/measurement_input_screen.dart';

class MeasurementsPanel extends ConsumerWidget {
  const MeasurementsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurements = ref.watch(measurementsProvider);
    final carModel = ref.watch(selectedCarModelProvider);
    final project = ref.watch(currentProjectProvider);

    if (carModel == null || project == null) {
      return const Center(child: Text('Нет данных'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Измерения',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showMeasurementInput(context, ref),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: measurements.length,
            itemBuilder: (context, index) {
              final measurement = measurements[index];
              final fromPoint = carModel.controlPoints.firstWhere(
                (p) => p.id == measurement.fromPointId,
              );
              final toPoint = carModel.controlPoints.firstWhere(
                (p) => p.id == measurement.toPointId,
              );

              return _MeasurementCard(
                measurement: measurement,
                fromPointCode: fromPoint.code,
                toPointCode: toPoint.code,
                onEdit: () => _editMeasurement(context, ref, measurement, index),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showMeasurementInput(BuildContext context, WidgetRef ref) {
    final project = ref.read(currentProjectProvider);
    final carModel = ref.read(selectedCarModelProvider);
    final measurements = ref.read(measurementsProvider);

    if (project == null || carModel == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeasurementInputScreen(
          project: project,
          carModel: carModel,
          measurements: measurements,
          onMeasurementsUpdated: (updatedMeasurements) {
            ref.read(measurementsProvider.notifier).replaceMeasurements(updatedMeasurements);
          },
        ),
      ),
    );
  }

  void _editMeasurement(BuildContext context, WidgetRef ref, Measurement measurement, int index) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(
          text: measurement.actualValue?.toString() ?? '',
        );
        return AlertDialog(
          title: const Text('Ввод фактического размера'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Фактический размер (мм)',
              hintText: 'Заводской: ${measurement.factoryValue}',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null) {
                  ref.read(measurementsProvider.notifier).updateMeasurementByIndex(
                    index,
                    measurement.copyWith(actualValue: value),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final Measurement measurement;
  final String fromPointCode;
  final String toPointCode;
  final VoidCallback onEdit;

  const _MeasurementCard({
    required this.measurement,
    required this.fromPointCode,
    required this.toPointCode,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: measurement.actualValue != null
          ? _getCardColor(measurement.severity)
          : null,
      child: ListTile(
        title: Text(
          '$fromPointCode - $toPointCode',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Заводской: ${measurement.factoryValue.toStringAsFixed(1)} мм'),
            if (measurement.actualValue != null) ...[
              Text('Фактический: ${measurement.actualValue!.toStringAsFixed(1)} мм'),
              Text(
                'Отклонение: ${measurement.deviation.toStringAsFixed(1)} мм (${measurement.deviationPercent.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: _getTextColor(measurement.severity),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        trailing: measurement.actualValue == null
            ? IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
              )
            : Icon(
                _getSeverityIcon(measurement.severity),
                color: _getTextColor(measurement.severity),
              ),
        onTap: onEdit,
      ),
    );
  }

  Color? _getCardColor(DeviationSeverity severity) {
    switch (severity) {
      case DeviationSeverity.normal:
        return Colors.green.withValues(alpha: 0.1);
      case DeviationSeverity.warning:
        return Colors.orange.withValues(alpha: 0.1);
      case DeviationSeverity.critical:
        return Colors.deepOrange.withValues(alpha: 0.1);
      case DeviationSeverity.severe:
        return Colors.red.withValues(alpha: 0.1);
    }
  }

  Color _getTextColor(DeviationSeverity severity) {
    switch (severity) {
      case DeviationSeverity.normal:
        return Colors.green[700]!;
      case DeviationSeverity.warning:
        return Colors.orange[700]!;
      case DeviationSeverity.critical:
        return Colors.deepOrange[700]!;
      case DeviationSeverity.severe:
        return Colors.red[700]!;
    }
  }

  IconData _getSeverityIcon(DeviationSeverity severity) {
    switch (severity) {
      case DeviationSeverity.normal:
        return Icons.check_circle;
      case DeviationSeverity.warning:
        return Icons.warning;
      case DeviationSeverity.critical:
        return Icons.error;
      case DeviationSeverity.severe:
        return Icons.dangerous;
    }
  }
}