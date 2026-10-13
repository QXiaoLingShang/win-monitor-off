# Development

## Project layout

```text
win-monitor-off/
├── .github/workflows/       CI checks and package build
├── docs/
│   ├── CHANGELOG.md         Project update history
│   ├── CONTRIBUTING.md      Contribution guide
│   └── DEVELOPMENT.md       Architecture and implementation notes
├── scripts/
│   └── package.ps1          Builds the optional EXE package
├── src/
│   ├── MonitorOff.ps1       Display and power-management behavior
│   ├── NativeMethods.cs     Windows API declarations used by PowerShell
│   └── launcher.c           Optional native launcher
├── tests/
│   └── check.ps1            Safe checks with mocked power-plan commands
├── monitor_off.bat          Windows entry point
├── monitor_off.ps1          PowerShell entry point and option forwarding
├── LICENSE                  MIT License
├── README.md                English overview and usage
└── README.zh-CN.md          Simplified Chinese overview and usage
```

Keep display behavior in `src/MonitorOff.ps1`. The root BAT and PowerShell scripts start it; the C launcher locates PowerShell and forwards supported options such as `-Restore`.

## Runtime flow

The program reads the active plan's display idle timeout (`VIDEOIDLE`) for AC and battery power, then saves those values and the plan identifier in `%LOCALAPPDATA%\win-monitor-off\display-timeout.json`. It creates a `PowerRequestSystemRequired` request so Windows stays awake during the session, temporarily sets both display timeouts to one second, and waits 5.5 seconds for Windows to turn off the display (about six seconds from launch). It then restores the saved timeouts and watches for keyboard or mouse input. Input ends the session and clears the power request. A later launch restores saved values if an earlier process was interrupted.

Microsoft documents `VIDEOIDLE` as the display idle timeout in seconds in [Display idle timeout](https://learn.microsoft.com/en-us/windows-hardware/customize/power-settings/display-settings-display-idle-timeout). A system-required request keeps Windows from entering sleep after inactivity; if Windows enters sleep after a user action, such as closing the lid or choosing Sleep, the request ends. On Modern Standby systems running on battery, Windows may end it five minutes after the system sleep timeout. See Microsoft's [PowerSetRequest documentation](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-powersetrequest).

## Build a package

With PowerShell 7 and clang or gcc installed, run:

```powershell
pwsh -NoProfile -File .\scripts\package.ps1
```

The runnable folder is written to `dist/`. It contains both entry points, the complete `src/` folder, and `monitor_off.exe`, which launches the included PowerShell implementation. Keep those files together when using the package.

If you encounter `native-idle-off-windows-x64.exe`, it is a legacy filename for the same launcher behavior as `monitor_off.exe`; current packages use `monitor_off.exe`. The old `win-monitor-off-windows-x64.exe` belongs to the original implementation and was superseded by the PowerShell-based behavior.

## Checks and manual verification

Run `tests/check.ps1` in Windows PowerShell 5.1 and PowerShell 7. The checks mock power-plan changes, include a read-only query of the active plan, and do not turn off the display. GitHub Actions runs both shells and compiles the C launcher on Windows.

For a manual check, connect AC power, record the active plan's display timeout, run `monitor_off.bat`, and confirm that the display turns off after several seconds, input wakes it, and the original timeout is restored. Also try `monitor_off.bat -Restore` and start a second instance while a session is running. Hardware behavior requires an interactive Windows session and cannot be covered by CI.
