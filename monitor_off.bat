@echo off
rem 显示器关闭期间保持系统运行。
where pwsh.exe >nul 2>&1
if %errorlevel%==0 (
    pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0monitor_off.ps1"
) else (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0monitor_off.ps1"
)
exit /b %errorlevel%
