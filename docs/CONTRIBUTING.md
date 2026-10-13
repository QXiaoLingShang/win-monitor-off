# Contributing

Keep the utility small and keep its behavior in `src/MonitorOff.ps1`. The BAT and root PowerShell scripts are entry points; `src/launcher.c` is an optional native launcher. Keep the English and Simplified Chinese READMEs aligned, and record notable project updates in [CHANGELOG.md](CHANGELOG.md).

Before submitting a change, run the checks with Windows PowerShell 5.1 and PowerShell 7:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\check.ps1
pwsh -NoProfile -File .\tests\check.ps1
pwsh -NoProfile -File .\scripts\package.ps1
```

The checks mock power-plan changes, include a read-only query of the active plan, and do not turn off the display. The package build also requires PowerShell 7 and clang or gcc. Hardware verification steps are in [DEVELOPMENT.md](DEVELOPMENT.md). Report bugs with your Windows version, PowerShell version, launch method, AC or battery status, and the error message. Do not commit generated EXEs or ZIPs.
