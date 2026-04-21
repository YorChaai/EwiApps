@echo off
title MiniProject KPI EWI - Backend Server
cd /d "%~dp0"

echo ========================================
echo   MiniProject KPI EWI
echo   Starting Backend Server...
echo ========================================
echo.

cd backend

REM Check if virtual environment exists
if exist "venv\Scripts\activate.bat" (
    echo [INFO] Activating virtual environment...
    call venv\Scripts\activate.bat
) else (
    echo [WARNING] Virtual environment not found. Running without venv...
)

echo [INFO] Starting Flask backend server...
echo [INFO] Press Ctrl+C to stop the server
echo.

REM Start the backend
python app.py

echo.
echo [INFO] Server stopped.
pause
