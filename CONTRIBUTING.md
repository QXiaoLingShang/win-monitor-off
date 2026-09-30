# Contributing

Keep this utility small: the PowerShell script owns the display-off behavior;
the BAT and C launchers only start it. Keep both READMEs in sync.

Before submitting a change, run the checks with Windows PowerShell 5.1 and
PowerShell 7:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\check.ps1
pwsh -NoProfile -File .\tests\check.ps1
gcc -std=c11 -Wall -Wextra -Werror monitor_off.c -o monitor_off.exe
```

The checks use mocked power-plan commands and do not turn off the display.
For a manual test, connect AC power, note the active plan and display timeouts,
run `monitor_off.bat`, and verify that input wakes the screen and the original
timeouts are restored. Also check duplicate launches and changing the active
plan while the helper is running. Hardware behavior needs an interactive
Windows session; CI cannot verify it.

Report bugs with your Windows version, PowerShell version, launch method,
AC/battery status, and the error message. Do not commit generated EXEs or ZIPs.
