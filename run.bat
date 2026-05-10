@echo off
title MiniProject KPI EWI - Control Panel
:menu
cls
cd /d "%~dp0"
echo ========================================
echo   MiniProject KPI EWI - CONTROL PANEL
echo ========================================
echo.
echo   1. Start Backend Server (Flask)
echo   2. Run Health Check (Check Setup)
echo   3. Security Setup (Generate Keys)
echo   4. Exit
echo.
set /p choice="Pilih menu (1-4): "

if "%choice%"=="1" goto start_server
if "%choice%"=="2" goto health_check
if "%choice%"=="3" goto security_setup
if "%choice%"=="4" exit
goto menu

:start_server
echo.
echo ========================================
echo   Starting Backend Server...
echo ========================================
cd backend
if exist "venv\Scripts\activate.bat" (
    call venv\Scripts\activate.bat
)
python app.py
pause
goto menu

:health_check
echo.
echo ========================================
echo   Running Health Check...
echo ========================================
cd backend
if exist "venv\Scripts\activate.bat" (
    call venv\Scripts\activate.bat
)
python scripts\health_check.py
goto menu

:security_setup
echo.
echo ========================================
echo   Running Security Setup...
echo ========================================
cd backend
if exist "venv\Scripts\activate.bat" (
    call venv\Scripts\activate.bat
)
python setup_security.py
goto menu

