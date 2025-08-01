import 'package:flutter_riverpod/flutter_riverpod.dart';

// Провайдер для настроек визуализации
final visualizationSettingsProvider = StateNotifierProvider<VisualizationSettingsNotifier, VisualizationSettings>((ref) {
  return VisualizationSettingsNotifier();
});

// Модель настроек визуализации
class VisualizationSettings {
  final bool is3DView;
  final bool useCurvedElements;
  final bool showAxes;
  final bool showControlPoints;
  final bool showMeasurements;
  final bool showLeftPanel;
  final bool showRightPanel;
  final int selectedTabIndex;

  const VisualizationSettings({
    this.is3DView = true,
    this.useCurvedElements = false,
    this.showAxes = true,
    this.showControlPoints = true,
    this.showMeasurements = true,
    this.showLeftPanel = true,
    this.showRightPanel = true,
    this.selectedTabIndex = 0,
  });

  VisualizationSettings copyWith({
    bool? is3DView,
    bool? useCurvedElements,
    bool? showAxes,
    bool? showControlPoints,
    bool? showMeasurements,
    bool? showLeftPanel,
    bool? showRightPanel,
    int? selectedTabIndex,
  }) {
    return VisualizationSettings(
      is3DView: is3DView ?? this.is3DView,
      useCurvedElements: useCurvedElements ?? this.useCurvedElements,
      showAxes: showAxes ?? this.showAxes,
      showControlPoints: showControlPoints ?? this.showControlPoints,
      showMeasurements: showMeasurements ?? this.showMeasurements,
      showLeftPanel: showLeftPanel ?? this.showLeftPanel,
      showRightPanel: showRightPanel ?? this.showRightPanel,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
    );
  }
}

// StateNotifier для управления настройками визуализации
class VisualizationSettingsNotifier extends StateNotifier<VisualizationSettings> {
  VisualizationSettingsNotifier() : super(const VisualizationSettings());

  void toggle3DView() {
    state = state.copyWith(is3DView: !state.is3DView);
  }

  void toggleCurvedElements() {
    state = state.copyWith(useCurvedElements: !state.useCurvedElements);
  }

  void toggleAxes() {
    state = state.copyWith(showAxes: !state.showAxes);
  }

  void toggleControlPoints() {
    state = state.copyWith(showControlPoints: !state.showControlPoints);
  }

  void toggleMeasurements() {
    state = state.copyWith(showMeasurements: !state.showMeasurements);
  }

  void toggleLeftPanel() {
    state = state.copyWith(showLeftPanel: !state.showLeftPanel);
  }

  void toggleRightPanel() {
    state = state.copyWith(showRightPanel: !state.showRightPanel);
  }

  void setTabIndex(int index) {
    state = state.copyWith(selectedTabIndex: index);
  }

  void updateSettings(VisualizationSettings settings) {
    state = settings;
  }
}