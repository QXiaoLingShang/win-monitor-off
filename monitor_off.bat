@echo off
rem 显示器关闭期间保持系统运行。
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0monitor_off.ps1"
exit /b %errorlevel%
