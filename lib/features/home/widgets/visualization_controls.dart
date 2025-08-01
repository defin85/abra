import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/visualization_settings_provider.dart';

class VisualizationControls extends ConsumerWidget {
  const VisualizationControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(visualizationSettingsProvider);
    final notifier = ref.read(visualizationSettingsProvider.notifier);

    return Column(
      children: [
        // Основные переключатели
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Режим отображения: '),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Прямые элементы'),
                  icon: Icon(Icons.square_outlined),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Изогнутые элементы'),
                  icon: Icon(Icons.waves),
                ),
              ],
              selected: {settings.useCurvedElements},
              onSelectionChanged: (Set<bool> newSelection) {
                notifier.toggleCurvedElements();
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Дополнительные настройки отображения
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: settings.showAxes,
                  onChanged: (value) => notifier.toggleAxes(),
                ),
                const Text('Координатные оси'),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: settings.showControlPoints,
                  onChanged: (value) => notifier.toggleControlPoints(),
                ),
                const Text('Контрольные точки'),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: settings.showMeasurements,
                  onChanged: (value) => notifier.toggleMeasurements(),
                ),
                const Text('Размеры'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class MobileVisualizationSettings extends ConsumerWidget {
  const MobileVisualizationSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(visualizationSettingsProvider);
    final notifier = ref.read(visualizationSettingsProvider.notifier);

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
                  'Настройки отображения',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Изогнутые элементы'),
                  subtitle: const Text('Использовать изогнутую геометрию'),
                  value: settings.useCurvedElements,
                  onChanged: (value) => notifier.toggleCurvedElements(),
                ),
                SwitchListTile(
                  title: const Text('Координатные оси'),
                  subtitle: const Text('Показывать оси координат'),
                  value: settings.showAxes,
                  onChanged: (value) => notifier.toggleAxes(),
                ),
                SwitchListTile(
                  title: const Text('Контрольные точки'),
                  subtitle: const Text('Показывать точки измерений'),
                  value: settings.showControlPoints,
                  onChanged: (value) => notifier.toggleControlPoints(),
                ),
                SwitchListTile(
                  title: const Text('Размеры'),
                  subtitle: const Text('Показывать размеры и отклонения'),
                  value: settings.showMeasurements,
                  onChanged: (value) => notifier.toggleMeasurements(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}