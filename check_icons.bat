@echo off
echo Проверка установленных иконок...
echo.

echo === Android иконки ===
dir /B android\app\src\main\res\mipmap-*\*.png 2>nul
echo.

echo === Web иконки ===
dir /B web\icons\*.png 2>nul
echo.

echo === Windows иконка ===
dir /B windows\runner\resources\*.ico 2>nul
echo.

echo === Assets иконки ===
dir /B assets\icons\*.png 2>nul
echo.

echo.
echo Откройте generate_exact_icon.html в браузере для генерации PNG
echo Затем запустите: flutter pub run flutter_launcher_icons
pause