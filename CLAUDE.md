# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development
- `flutter pub get` - Install dependencies
- `flutter run -d chrome` - Run web version (recommended for development)
- `flutter run -d windows` - Run Windows desktop version
- `flutter run -d android` - Run Android version
- `flutter run -d ios` - Run iOS version (macOS only)

### Code Quality
- `flutter analyze` - Run static analysis
- `flutter test` - Run tests

### Build
- `flutter build web` - Build for web
- `flutter build windows` - Build for Windows
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build for iOS

## Project Overview

ABRA (Auto Body Repair Assistant) is a Flutter application for car body shop workers to diagnose vehicle body deformations. The app uses a custom 3D visualization system built with CustomPainter and vector_math (no external 3D libraries).

### Key Features
- **Adaptive Chassis Geometry**: Mathematical model that generates car frame structure based on real vehicle parameters (wheelbase, track width, sill height)
- **3D Visualization**: Custom 3D rendering with rotation, scaling, and perspective projection
- **Measurement System**: Control points (A-M) for precise measurements with color-coded deviation indicators
- **Deformation Analysis**: Visual comparison between factory specifications and post-accident measurements

## Architecture

### Core Components

#### Models (`lib/core/models/`)
- `Project`: Represents a repair project with measurements, customer info, and completion tracking
- `CarModel`: Defines vehicle specifications with control points and sections
- `Measurement`: Individual measurement data with actual/expected values and deviation calculations
- `ControlPoint`: Defines measurement control points with 3D coordinates

#### Adaptive Geometry (`lib/core/geometry/`)
- `AdaptiveChassis`: Mathematical chassis generation based on vehicle parameters
  - Uses parametric equations to create curved sill geometry
  - Generates control points for measurements
  - Supports deformation simulation with damage coefficients

#### Services (`lib/core/services/`)
- `MeasurementStatisticsService`: Calculates deviation statistics and project health status
- `ReportGenerationService`: Generates PDF reports with measurements and analysis
- `GeometryAnalysisService`: Analyzes geometric deformations

#### Constants (`lib/core/constants/`)
- `GeometryConstants`: Named constants for all geometric calculations
- Eliminates magic numbers throughout the codebase

#### 3D Visualization (`lib/features/visualization/widgets/`)
- `AdaptiveChassis3D`: Main 3D viewer with gesture controls
- `AdaptiveChassisPainter`: CustomPainter implementation for 3D rendering
- **Frame Types**: Different colors for chassis elements (green=subframe, red=sills, blue=rear longerons, etc.)

### State Management
- Uses **Riverpod** for state management with providers:
  - `currentProjectProvider`: Manages active project state
  - `selectedCarModelProvider`: Manages selected car model
  - `measurementsProvider`: Manages measurements list
  - `visualizationSettingsProvider`: Manages UI settings
  - `deviationStatsProvider`: Computed statistics provider
- Models use immutable data structures with copyWith methods

### Database
- **SQLite** (sqflite) for persistent storage
- **Hive** for local caching
- JSON serialization for all models

### Templates
- Pre-configured vehicle templates (Toyota Camry XV70 included)
- Located in `lib/core/data/templates/`

## Development Guidelines

### 3D Rendering System
The app uses a custom 3D engine built on Flutter's CustomPainter:
- Vector math handled by `vector_math` package
- Perspective projection with configurable camera distance
- Matrix transformations for rotation/scaling
- No external 3D libraries used

### Measurement System
- Control points are mathematically generated based on chassis geometry
- Deviations calculated as percentage differences from factory specs
- Color coding: Green (normal), Orange (warning), Red (critical)

### Chassis Generation
- Uses mathematical "trough" shape model for realistic chassis geometry
- Parametric generation allows adaptation to different vehicle models
- Height hierarchy: Central tunnel (1.3x sill height) > Longerons (2.0-2.2x) > Sills (base) > Cross members

### Testing
- Unit tests are in `test/` directory:
  - `test/core/models/` - Model tests for business logic
  - `test/core/services/` - Service tests for calculations
  - `test/providers/` - Provider tests for state management
  - `test/widget_test.dart` - Basic widget tests
- Test coverage includes:
  - Measurement calculations and severity determination
  - Statistical analysis and project health assessment
  - State management and provider reactivity
  - UI smoke tests

### Assets
- Vehicle templates: `assets/templates/`
- Icons: `assets/icons/`
- 3D models: `assets/models/`

## File Organization

```
lib/
├── main.dart                    # App entry point with ProviderScope
├── core/
│   ├── models/                 # Data models (Project, CarModel, Measurement, ControlPoint)
│   ├── geometry/               # Mathematical chassis generation
│   ├── services/               # Business logic services
│   ├── constants/              # Named constants for geometry and UI
│   └── data/templates/         # Vehicle templates
├── features/
│   ├── home/                   # Main application screen
│   │   ├── home_screen.dart    # Refactored main screen (312 lines)
│   │   └── widgets/            # Extracted components
│   │       ├── project_info_panel.dart
│   │       ├── measurements_panel.dart
│   │       └── visualization_controls.dart
│   ├── measurement/            # Measurement input and processing
│   ├── visualization/          # 2D/3D rendering widgets
│   ├── comparison/             # Factory vs actual comparison
│   └── reports/                # PDF/CSV export functionality
├── providers/                  # Riverpod state management
│   ├── project_provider.dart
│   ├── measurements_provider.dart
│   └── visualization_settings_provider.dart
└── shared/
    ├── widgets/                # Reusable UI components
    └── themes/                 # App theming
```

## Platform Notes

- **Web**: Recommended platform for development and primary use
- **Windows**: Desktop version available but may require additional setup
- **Mobile**: Supports iOS/Android but UI optimized for larger screens
- **3D Performance**: Uses Canvas-based rendering, performance scales with complexity

## Recent Refactoring (2025)

The codebase underwent significant refactoring to improve maintainability and scalability:

### Improvements Made
1. **State Management Migration**
   - Migrated from StatefulWidget to Riverpod providers
   - Created dedicated providers for project, measurements, and UI settings
   - Improved separation of concerns and testability

2. **Component Architecture**
   - Split large HomeScreen (839 lines) into smaller components (312 lines)
   - Created reusable widgets for project info, measurements panel, and visualization controls
   - Better code organization and reusability

3. **Business Logic Extraction**
   - Created service layer for business logic
   - `MeasurementStatisticsService` for calculations
   - `ReportGenerationService` for PDF generation
   - Removed business logic from UI components

4. **Code Quality**
   - Replaced magic numbers with named constants
   - Added comprehensive unit tests
   - Fixed all Flutter analyzer warnings
   - Improved type safety

### Test Coverage
- Model tests: Measurement calculations, serialization
- Service tests: Statistics, health assessment, grouping
- Provider tests: State management, reactivity
- Widget tests: Basic UI smoke tests