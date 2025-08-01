@echo off
echo === ABRA Icon Update and Rebuild ===
echo.

echo Step 1: Cleaning project...
call flutter clean

echo.
echo Step 2: Removing build directories...
rmdir /s /q build 2>nul
rmdir /s /q .dart_tool 2>nul

echo.
echo Step 3: Getting dependencies...
call flutter pub get

echo.
echo Step 4: Regenerating icons...
call flutter pub run flutter_launcher_icons

echo.
echo Step 5: Building for Chrome...
echo.
echo IMPORTANT: 
echo 1. Open final_icon_generator.html in browser
echo 2. Download 1024x1024 as app_icon.png to assets/icons/
echo 3. Then run this script again
echo.
echo Starting Chrome build...
call flutter run -d chrome

pause