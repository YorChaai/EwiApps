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
echo   3. Start Both (Backend + Frontend - Local)
echo   4. Start Backend + Cloudflare Tunnel (Remote Only)
echo   5. Start All (Backend + Frontend + Cloudflare)
echo   6. Exit
echo.

choice /C 123456 /M "Select option"

if %errorlevel%==1 goto backend
if %errorlevel%==2 goto frontend
if %errorlevel%==3 goto both
if %errorlevel%==4 goto tunnel
if %errorlevel%==5 goto start_all
if %errorlevel%==6 goto end

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
    echo [INFO] Starting Frontend for Mobile...
    start "Frontend Flutter" cmd /k "cd /d "%~dp0\frontend" && flutter run"
)
goto end

:tunnel
echo.
echo [INFO] Starting Backend Server...
start "Backend Server" cmd /k "cd /d "%~dp0\backend" && if exist venv\Scripts\activate.bat call venv\Scripts\activate.bat && python app.py"
timeout /t 3 /nobreak >nul
echo.
echo [INFO] Starting Cloudflare Tunnel...
echo [HINT] Salin URL https://xxxx.trycloudflare.com yang muncul nanti.
start "Cloudflare Tunnel" cmd /k "cd /d "%~dp0\tools\cloudflare" && python capture_tunnel.py"
goto end

:start_all
echo.
echo [INFO] Starting Backend Server...
start "Backend Server" cmd /k "cd /d "%~dp0\backend" && if exist venv\Scripts\activate.bat call venv\Scripts\activate.bat && python app.py"
timeout /t 2 /nobreak >nul
echo.
echo [INFO] Starting Cloudflare Tunnel...
start "Cloudflare Tunnel" cmd /k "cd /d "%~dp0\tools\cloudflare" && python capture_tunnel.py"
timeout /t 2 /nobreak >nul
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
    echo [INFO] Starting Frontend for Mobile...
    start "Frontend Flutter" cmd /k "cd /d "%~dp0\frontend" && flutter run"
)
goto end

:end
echo.
echo [INFO] Launching complete.
exit /b 0
