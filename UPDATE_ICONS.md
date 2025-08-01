# Обновление иконок приложения ABRA

## Быстрый способ

1. **Автоматическая генерация** (уже выполнено):
   ```bash
   flutter pub run flutter_launcher_icons
   ```

2. **Для обновления Windows ICO**:
   - Откройте `create_ico.html` в браузере
   - Загрузите `assets/icons/app_icon_new.png`
   - Скачайте ICO файл
   - Сохраните как `windows/runner/resources/app_icon.ico`

## Ручной способ

### Использование HTML генератора
1. Откройте `generate_icon.html` в браузере
2. Нажмите на нужные размеры для скачивания
3. Сохраните файлы в соответствующие папки

### Расположение иконок

#### Android
- `android/app/src/main/res/mipmap-mdpi/` - 48x48
- `android/app/src/main/res/mipmap-hdpi/` - 72x72
- `android/app/src/main/res/mipmap-xhdpi/` - 96x96
- `android/app/src/main/res/mipmap-xxhdpi/` - 144x144
- `android/app/src/main/res/mipmap-xxxhdpi/` - 192x192

#### iOS
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

#### Web
- `web/icons/Icon-192.png`
- `web/icons/Icon-512.png`

#### Windows
- `windows/runner/resources/app_icon.ico`

## Проверка результата

1. Очистите кэш Flutter:
   ```bash
   flutter clean
   ```

2. Запустите приложение:
   ```bash
   flutter run -d windows
   # или
   flutter run -d chrome
   ```

## Файлы инструментов

- `generate_icon.html` - Генератор PNG иконок из SVG
- `create_ico.html` - Конвертер PNG в ICO для Windows
- `update_icons.bat` - Автоматическое обновление всех иконок
- `generate_icons.bat` - Открытие генератора в браузере