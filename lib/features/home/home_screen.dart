import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/project_provider.dart';
import '../../providers/visualization_settings_provider.dart';
import '../../providers/measurements_provider.dart';
import '../visualization/widgets/car_body_2d_view.dart';
import '../visualization/widgets/adaptive_chassis_3d_refactored.dart';
import '../../core/geometry/adaptive_chassis.dart';
import '../../shared/utils/responsive_utils.dart';
import '../measurement/measurement_input_screen.dart';
import 'widgets/project_info_panel.dart';
import 'widgets/measurements_panel.dart';
import 'widgets/visualization_controls.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(currentProjectProvider);
    final carModel = ref.watch(selectedCarModelProvider);
    final isMobile = context.isMobile;
    
    if (project == null || carModel == null) {
      return Scaffold(
        appBar: _buildAppBar(context, ref),
        body: const Center(
          child: Text('Нет активного проекта'),
        ),
      );
    }

    if (isMobile) {
      return _buildMobileLayout(context, ref);
    } else {
      return _buildDesktopTabletLayout(context, ref);
    }
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(visualizationSettingsProvider);
    final notifier = ref.read(visualizationSettingsProvider.notifier);

    return Scaffold(
      appBar: _buildAppBar(context, ref),
      drawer: Drawer(
        width: context.panelWidth,
        child: const ProjectInfoPanel(),
      ),
      endDrawer: Drawer(
        width: context.panelWidth,
        child: const MeasurementsPanel(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: settings.selectedTabIndex,
        onTap: (index) => notifier.setTabIndex(index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.view_in_ar),
            label: 'Визуализация',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
      body: _buildMobileBody(context, ref),
    );
  }

  Widget _buildDesktopTabletLayout(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(visualizationSettingsProvider);
    
    return Scaffold(
      appBar: _buildAppBar(context, ref), 
      body: Row(
        children: [
          // Левая панель с информацией о проекте
          if (settings.showLeftPanel)
            Container(
              width: context.panelWidth,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: const ProjectInfoPanel(),
            ),
          // Основная область с визуализацией
          Expanded(
            child: Padding(
              padding: context.responsivePadding,
              child: _buildVisualizationArea(context, ref),
            ),
          ),
          // Правая панель с измерениями
          if (settings.showRightPanel)
            Container(
              width: context.panelWidth,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: const MeasurementsPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildVisualizationArea(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(visualizationSettingsProvider);
    final carModel = ref.watch(selectedCarModelProvider);
    final measurements = ref.watch(measurementsProvider);

    if (settings.is3DView) {
      return Column(
        children: [
          const VisualizationControls(),
          const SizedBox(height: 8),
          Expanded(
            child: AdaptiveChassis3D(
              showMeasurements: settings.showMeasurements,
              showLabels: settings.showControlPoints,
              showAxes: settings.showAxes,
              showDeformed: false,
              useCurvedElements: settings.useCurvedElements,
              factoryChassis: AdaptiveChassis.toyotaCamry(),
              deformedChassis: AdaptiveChassis.toyotaCamry().createDeformed(
                frontDamage: 0.2, // Демо деформация
                wheelbaseChange: -15.0,
              ),
            ),
          ),
        ],
      );
    } else {
      return CarBody2DView(
        carModel: carModel!,
        measurements: measurements,
        viewType: ViewType.side,
        onPointSelected: (point) {
          // TODO: Implement point details dialog
        },
      );
    }
  }

  Widget _buildMobileBody(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(visualizationSettingsProvider);
    
    if (settings.selectedTabIndex == 0) {
      return Padding(
        padding: context.responsivePadding,
        child: _buildVisualizationArea(context, ref),
      );
    } else {
      return const MobileVisualizationSettings();
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    final isMobile = context.isMobile;
    
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.directions_car,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              isMobile ? 'ABRA' : 'Auto Body Repair Assistant',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: isMobile 
        ? _buildMobileActions(context, ref) 
        : _buildDesktopActions(context, ref),
    );
  }

  List<Widget> _buildMobileActions(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(visualizationSettingsProvider.notifier);
    final settings = ref.watch(visualizationSettingsProvider);

    return [
      IconButton(
        icon: Icon(settings.is3DView ? Icons.view_in_ar : Icons.grid_on),
        onPressed: () => notifier.toggle3DView(),
        tooltip: settings.is3DView ? 'Переключить на 2D' : 'Переключить на 3D',
      ),
      PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'measurement':
              _showMeasurementInput(context, ref);
              break;
            case 'report':
              _generateReport(context);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'measurement',
            child: ListTile(
              leading: Icon(Icons.add_chart),
              title: Text('Ввод измерений'),
            ),
          ),
          const PopupMenuItem(
            value: 'report',
            child: ListTile(
              leading: Icon(Icons.picture_as_pdf),
              title: Text('Создать отчет'),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildDesktopActions(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(visualizationSettingsProvider.notifier);
    final settings = ref.watch(visualizationSettingsProvider);

    return [
      IconButton(
        icon: Icon(settings.showLeftPanel ? Icons.first_page : Icons.last_page),
        onPressed: () => notifier.toggleLeftPanel(),
        tooltip: settings.showLeftPanel ? 'Скрыть левую панель' : 'Показать левую панель',
      ),
      IconButton(
        icon: Icon(settings.showRightPanel ? Icons.last_page : Icons.first_page),
        onPressed: () => notifier.toggleRightPanel(),
        tooltip: settings.showRightPanel ? 'Скрыть правую панель' : 'Показать правую панель',
      ),
      IconButton(
        icon: Icon(settings.is3DView ? Icons.view_in_ar : Icons.grid_on),
        onPressed: () => notifier.toggle3DView(),
        tooltip: settings.is3DView ? 'Переключить на 2D' : 'Переключить на 3D',
      ),
      IconButton(
        icon: const Icon(Icons.add_chart),
        onPressed: () => _showMeasurementInput(context, ref),
        tooltip: 'Ввод измерений',
      ),
      IconButton(
        icon: const Icon(Icons.picture_as_pdf),
        onPressed: () => _generateReport(context),
        tooltip: 'Создать отчет',
      ),
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () {},
        tooltip: 'Настройки',
      ),
    ];
  }

  void _showMeasurementInput(BuildContext context, WidgetRef ref) {
    final measurements = ref.read(measurementsProvider);
    final project = ref.read(currentProjectProvider);
    final carModel = ref.read(selectedCarModelProvider);

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

  void _generateReport(BuildContext context) {
    // TODO: Implement PDF report generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Генерация отчета будет реализована позже'),
      ),
    );
  }
}