import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/project_provider.dart';
import '../../../providers/measurements_provider.dart';

class ProjectInfoPanel extends ConsumerWidget {
  const ProjectInfoPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(currentProjectProvider);
    final carModel = ref.watch(selectedCarModelProvider);
    final deviationStats = ref.watch(deviationStatsProvider);

    if (project == null || carModel == null) {
      return const Center(child: Text('Нет активного проекта'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Информация о проекте',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Divider(),
                _InfoRow(label: 'Название:', value: project.name),
                _InfoRow(label: 'Автомобиль:', value: carModel.displayName),
                _InfoRow(label: 'Клиент:', value: project.customerName ?? '-'),
                _InfoRow(label: 'Гос. номер:', value: project.plateNumber ?? '-'),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: project.completionProgress,
                  backgroundColor: Colors.grey[300],
                ),
                const SizedBox(height: 4),
                Text(
                  'Прогресс: ${(project.completionProgress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Статистика отклонений',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Divider(),
                _DeviationStatsWidget(stats: deviationStats),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviationStatsWidget extends StatelessWidget {
  final DeviationStats stats;

  const _DeviationStatsWidget({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatRow(
          label: 'Всего измерений:',
          value: stats.totalMeasured.toString(),
          color: Colors.blue,
        ),
        _StatRow(
          label: 'В пределах нормы:',
          value: stats.normal.toString(),
          color: Colors.green,
        ),
        _StatRow(
          label: 'Предупреждение:',
          value: stats.warning.toString(),
          color: Colors.orange,
        ),
        _StatRow(
          label: 'Критично:',
          value: stats.critical.toString(),
          color: Colors.deepOrange,
        ),
        _StatRow(
          label: 'Серьезно:',
          value: stats.severe.toString(),
          color: Colors.red,
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}