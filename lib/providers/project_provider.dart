import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/project.dart';
import '../core/models/car_model.dart';
import '../core/data/templates/toyota_camry_template.dart';

// Провайдер для текущего проекта
final currentProjectProvider = StateNotifierProvider<ProjectNotifier, Project?>((ref) {
  return ProjectNotifier();
});

// Провайдер для выбранной модели автомобиля
final selectedCarModelProvider = StateProvider<CarModel?>((ref) {
  // По умолчанию загружаем Toyota Camry
  return ToyotaCamryTemplate.createTemplate();
});

// StateNotifier для управления проектом
class ProjectNotifier extends StateNotifier<Project?> {
  ProjectNotifier() : super(null) {
    // Инициализируем демо-проект при создании
    _initializeDemoProject();
  }

  void _initializeDemoProject() {
    final carModel = ToyotaCamryTemplate.createTemplate();
    state = Project(
      name: 'Toyota Camry - Демо',
      carModelId: carModel.id,
      carModel: carModel,
      customerName: 'Иван Иванов',
      plateNumber: 'А123БВ777',
      description: 'Демонстрационный проект для показа возможностей',
    );
  }

  void createProject({
    required String name,
    required CarModel carModel,
    String? customerName,
    String? plateNumber,
    String? description,
  }) {
    state = Project(
      name: name,
      carModelId: carModel.id,
      carModel: carModel,
      customerName: customerName,
      plateNumber: plateNumber,
      description: description,
    );
  }

  void updateProject(Project project) {
    state = project;
  }

  void clearProject() {
    state = null;
  }
}