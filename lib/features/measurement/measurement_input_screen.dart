import 'package:flutter/material.dart';
import '../../core/models/project.dart';
import '../../core/models/car_model.dart';
import '../../core/models/measurement.dart';

class MeasurementInputScreen extends StatefulWidget {
  final Project project;
  final CarModel carModel;
  final List<Measurement> measurements;
  final Function(List<Measurement>) onMeasurementsUpdated;

  const MeasurementInputScreen({
    super.key,
    required this.project,
    required this.carModel,
    required this.measurements,
    required this.onMeasurementsUpdated,
  });

  @override
  State<MeasurementInputScreen> createState() => _MeasurementInputScreenState();
}

class _MeasurementInputScreenState extends State<MeasurementInputScreen> {
  late List<Measurement> _measurements;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _measurements = List.from(widget.measurements);
    
    // Создаем контроллеры для каждого измерения
    for (final measurement in _measurements) {
      _controllers[measurement.id] = TextEditingController(
        text: measurement.actualValue?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ввод измерений'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Сохранить'),
            onPressed: _saveAndClose,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.project.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        widget.carModel.displayName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    '${_measurements.where((m) => m.actualValue != null).length} из ${_measurements.length} измерено',
                  ),
                  avatar: const Icon(Icons.straighten, size: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _measurements.length,
              itemBuilder: (context, index) {
                final measurement = _measurements[index];
                final fromPoint = widget.carModel.controlPoints.firstWhere(
                  (p) => p.id == measurement.fromPointId,
                );
                final toPoint = widget.carModel.controlPoints.firstWhere(
                  (p) => p.id == measurement.toPointId,
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${fromPoint.name} → ${toPoint.name}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${fromPoint.code} - ${toPoint.code}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 120,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Заводской размер',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '${measurement.factoryValue.toStringAsFixed(1)} мм',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: _controllers[measurement.id],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Фактический (мм)',
                              suffixIcon: measurement.actualValue != null
                                  ? Icon(
                                      _getSeverityIcon(measurement.severity),
                                      color: _getSeverityColor(measurement.severity),
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              final doubleValue = double.tryParse(value);
                              setState(() {
                                _measurements[index] = measurement.copyWith(
                                  actualValue: doubleValue,
                                );
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (measurement.actualValue != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getSeverityColor(measurement.severity)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _getSeverityColor(measurement.severity),
                              ),
                            ),
                            child: Text(
                              '${measurement.deviation > 0 ? '+' : ''}${measurement.deviation.toStringAsFixed(1)} мм',
                              style: TextStyle(
                                color: _getSeverityColor(measurement.severity),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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

  Color _getSeverityColor(DeviationSeverity severity) {
    switch (severity) {
      case DeviationSeverity.normal:
        return Colors.green;
      case DeviationSeverity.warning:
        return Colors.orange;
      case DeviationSeverity.critical:
        return Colors.deepOrange;
      case DeviationSeverity.severe:
        return Colors.red;
    }
  }

  void _saveAndClose() {
    widget.onMeasurementsUpdated(_measurements);
    Navigator.pop(context);
  }
}