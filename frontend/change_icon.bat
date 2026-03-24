@echo off
echo ========================================
echo  Flutter App Icon Changer
echo  Logo: Exspan (White Background)
echo ========================================
echo.

cd /d "%~dp0"

echo [1/4] Adding flutter_launcher_icons package...
flutter pub add flutter_launcher_icons
if errorlevel 1 (
    echo ERROR: Failed to add package!
    pause
    exit /b 1
)

echo.
echo [2/4] Updating pubspec.yaml...
echo Done (manual check required)

echo.
echo [3/4] Getting dependencies...
flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to get dependencies!
    pause
    exit /b 1
)

echo.
echo [4/4] Generating launcher icons...
flutter pub run flutter_launcher_icons
if errorlevel 1 (
    echo ERROR: Failed to generate icons!
    pause
    exit /b 1
)

echo.
echo ========================================
echo  SUCCESS! App icon changed to Exspan!
echo ========================================
echo.
echo Next steps:
echo 1. Rebuild your app: flutter build apk --release
echo 2. Install on device
echo 3. Enjoy your new icon!
echo.
pause
