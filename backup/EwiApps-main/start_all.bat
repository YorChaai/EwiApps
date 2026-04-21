@echo off
setlocal EnableDelayedExpansion
title MiniProject KPI EWI - Full Stack Launcher
cd /d "%~dp0"

echo ========================================
echo   MiniProject KPI EWI
echo   Full Stack Launcher
echo ========================================
echo.
echo   1. Start Backend Server
echo   2. Start Frontend (Flutter)
echo   3. Start Both (Backend + Frontend)
echo   4. Exit
echo.

choice /C 1234 /M "Select option"

if %errorlevel%==1 goto backend
if %errorlevel%==2 goto frontend
if %errorlevel%==3 goto both
if %errorlevel%==4 goto end

:backend
echo.
echo [INFO] Starting Backend Server...
start "Backend Server" cmd /k "cd /d "%~dp0\backend" && if exist venv\Scripts\activate.bat call venv\Scripts\activate.bat && python app.py"
goto end

:frontend
echo.
echo [INFO] Starting Frontend (Flutter)...
start "Frontend Flutter" cmd /k "cd /d "%~dp0\frontend" && flutter run"
goto end

:both
echo.
echo [INFO] Starting Backend Server...
start "Backend Server" cmd /k "cd /d "%~dp0\backend" && if exist venv\Scripts\activate.bat call venv\Scripts\activate.bat && python app.py"
timeout /t 3 /nobreak >nul
echo.
echo   Platform untuk Frontend:
echo   1. Windows (Desktop)
echo   2. Android (Device/Emulator)
echo.
choice /C 12 /M "Select platform"

if !errorlevel!==1 (
    echo [INFO] Starting Frontend for Windows...
    start "Frontend Flutter" cmd /k "cd /d "%~dp0\frontend" && flutter run -d windows"
) else (
    echo [INFO] Starting Frontend for Android...
    start "Frontend Flutter" cmd /k "cd /d "%~dp0\frontend" && flutter run -d android"
)
goto end

:end
echo.
echo [INFO] Launching complete.
exit /b 0
