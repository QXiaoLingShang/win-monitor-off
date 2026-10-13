@echo off
rem 用途：调用 PowerShell 入口，并转交 -Restore 等参数。
where pwsh.exe >nul 2>&1
if not errorlevel 1 (
    pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0monitor_off.ps1" %*
) else (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0monitor_off.ps1" %*
)
exit /b %errorlevel%
