<h1 align="center">win-monitor-off</h1>

<p align="center">
  English · <a href="README.zh-CN.md">简体中文</a>
</p>

Have you ever been running a long task on a laptop connected to an external monitor and wanted to turn off the screens so the light would not disturb others, only to realize that closing the lid may put the computer to sleep while turning off only the external monitor leaves the laptop's built-in display on?

Manually switching off the monitor, unplugging it, or repeatedly closing the lid gets tedious. Worse, the system may go to sleep as the screens turn off, interrupting background tasks. `win-monitor-off` was built for this: it temporarily sets the active power plan's display idle timeout to one second and asks Windows to keep the system running during the session. About six seconds later, the displays turn off and the original timeout is restored while background tasks continue. Keyboard or mouse input wakes the displays and ends the session.

## Usage

1. Download the [latest complete Windows package](https://github.com/QXiaoLingShang/win-monitor-off/releases/latest) and extract it. Keep the extracted folder structure intact.
2. Run `monitor_off.bat`. Leave the keyboard and mouse idle for about six seconds while Windows turns off the displays.
3. Press a key or move the mouse to wake the displays and end the session.

No installation is needed. The tool requires Windows 10 or 11, Windows PowerShell 5.1 or PowerShell 7, and permission to change the active power plan.

To restore saved display timeouts without starting a new session, run:

```powershell
.\monitor_off.bat -Restore
```

If the program is interrupted, the next launch restores the saved timeouts before starting a new session.

## Limitations

- The tool asks Windows to turn off the displays, but cannot guarantee that they do. If a display stays on, another app or a Windows power setting may be keeping it awake.
- Do not choose Sleep during a session. If closing the lid is configured to put the laptop to sleep, keep the lid open; sleep suspends the session and may pause background work.
- On a Modern Standby laptop running on battery, Windows ends this keep-awake request five minutes after the configured sleep timeout. Connect the laptop to AC power for longer tasks.

## For contributors

The [contribution guide](docs/CONTRIBUTING.md) explains how to run the checks with Windows PowerShell 5.1 and PowerShell 7.

To build the optional EXE package, use PowerShell 7 with clang or gcc installed:

```powershell
pwsh -NoProfile -File .\scripts\package.ps1
```

The package is created in `dist/`. Keep its files together when running `monitor_off.exe`.

## Project structure

```text
win-monitor-off/
├── .github/workflows/       # CI checks and package build
├── docs/
│   ├── CHANGELOG.md         # Project update history
│   ├── CONTRIBUTING.md      # Contribution guide
│   └── DEVELOPMENT.md       # Architecture and implementation notes
├── scripts/
│   └── package.ps1          # Builds the optional EXE package
├── src/
│   ├── MonitorOff.ps1       # Display and power-management behavior
│   ├── NativeMethods.cs     # Windows API declarations
│   └── launcher.c           # Optional native launcher
├── tests/check.ps1          # PowerShell checks
├── monitor_off.bat          # Windows entry point
├── monitor_off.ps1          # PowerShell entry point
├── LICENSE                  # MIT License
├── README.md                # English overview and usage
└── README.zh-CN.md          # Simplified Chinese overview and usage
```

## Documentation

- [Development guide](docs/DEVELOPMENT.md), [contribution guide](docs/CONTRIBUTING.md), and [changelog](docs/CHANGELOG.md).

## License

This project is licensed under the [MIT License](LICENSE).
