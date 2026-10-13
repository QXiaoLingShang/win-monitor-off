@echo off
rem Forward supported options such as -Restore to the PowerShell entry point.
where pwsh.exe >nul 2>&1
if not errorlevel 1 (
    pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0monitor_off.ps1" %*
) else (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0monitor_off.ps1" %*
)
exit /b %errorlevel%
