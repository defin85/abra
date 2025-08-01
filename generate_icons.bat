@echo off
echo Opening icon generator in browser...
start "" "%~dp0generate_icon.html"
echo.
echo После генерации иконок:
echo 1. Сохраните 512x512 как app_icon_new.png в assets\icons\
echo 2. Запустите: update_icons.bat
pause