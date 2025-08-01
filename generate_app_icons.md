# Генерация иконок приложения ABRA

## Необходимые размеры иконок

### Android (android/app/src/main/res/)
- mipmap-mdpi: 48x48
- mipmap-hdpi: 72x72
- mipmap-xhdpi: 96x96
- mipmap-xxhdpi: 144x144
- mipmap-xxxhdpi: 192x192

### iOS (ios/Runner/Assets.xcassets/AppIcon.appiconset/)
- 20x20 (1x, 2x, 3x)
- 29x29 (1x, 2x, 3x)
- 40x40 (1x, 2x, 3x)
- 60x60 (2x, 3x)
- 76x76 (1x, 2x)
- 83.5x83.5 (2x)
- 1024x1024 (App Store)

### Web (web/icons/)
- Icon-192.png
- Icon-512.png
- Icon-maskable-192.png
- Icon-maskable-512.png

### Windows (windows/runner/resources/)
- app_icon.ico (содержит 16x16, 32x32, 48x48, 256x256)

## Рекомендуемый инструмент

Используйте [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) для автоматической генерации:

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon_new.png"
  adaptive_icon_background: "#4A90E2"
  adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"
  web:
    generate: true
    image_path: "assets/icons/app_icon_new.png"
  windows:
    generate: true
    image_path: "assets/icons/app_icon_new.png"
```

## Команда для генерации
```bash
flutter pub run flutter_launcher_icons
```

## Альтернативный вариант - создание PNG из SVG

Для конвертации SVG в PNG можно использовать:
1. Inkscape: `inkscape -w 512 -h 512 app_icon_new.svg -o app_icon_new.png`
2. ImageMagick: `convert -background none -size 512x512 app_icon_new.svg app_icon_new.png`
3. Онлайн сервисы: svgtopng.com, cloudconvert.com

## Структура иконки ABRA

Новая иконка содержит:
- Градиентный синий фон (#4A90E2 → #2E5CB8)
- Стилизованный автомобильный каркас в изометрии
- Контрольные точки измерений
- Измерительные линии оранжевого цвета
- Название "ABRA"
- Декоративные элементы

Иконка выполнена в современном flat-стиле с градиентами, что соответствует Material Design и iOS Human Interface Guidelines.