@echo off
title MiniProject KPI EWI - Frontend (Flutter)
cd /d "%~dp0"

echo ========================================
echo   MiniProject KPI EWI
echo   Starting Frontend (Flutter)...
echo ========================================
echo.

cd ..\frontend

REM Check if Flutter is installed
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Flutter not found! Please install Flutter first.
    echo.
    pause
    exit /b 1
)

echo [INFO] Running Flutter app...
echo [INFO] Press Ctrl+C to stop the app
echo.

REM Start Flutter
flutter run

echo.
echo [INFO] Flutter app stopped.
pause
