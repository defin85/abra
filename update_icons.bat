@echo off
echo Обновление иконок приложения ABRA...
echo.

REM Генерация иконок через flutter_launcher_icons
echo Шаг 1: Генерация иконок для всех платформ...
call flutter pub run flutter_launcher_icons

REM Создание ICO для Windows (если есть ImageMagick)
echo.
echo Шаг 2: Создание ICO файла для Windows...
where magick >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ImageMagick найден, создаем ICO...
    magick convert assets\icons\app_icon_new.png -resize 16x16 icon-16.png
    magick convert assets\icons\app_icon_new.png -resize 32x32 icon-32.png
    magick convert assets\icons\app_icon_new.png -resize 48x48 icon-48.png
    magick convert assets\icons\app_icon_new.png -resize 256x256 icon-256.png
    magick convert icon-16.png icon-32.png icon-48.png icon-256.png windows\runner\resources\app_icon.ico
    del icon-16.png icon-32.png icon-48.png icon-256.png
    echo ICO файл создан!
) else (
    echo ImageMagick не найден. Для создания ICO файла:
    echo 1. Установите ImageMagick: https://imagemagick.org/script/download.php#windows
    echo 2. Или используйте онлайн конвертер PNG to ICO
    echo 3. Сохраните как windows\runner\resources\app_icon.ico
)

echo.
echo Шаг 3: Очистка кэша Flutter...
call flutter clean

echo.
echo Готово! Иконки обновлены.
echo.
echo Теперь запустите приложение:
echo   flutter run -d windows
echo или
echo   flutter run -d chrome
echo.
pause