<div align="center">

# win-monitor-off

Turn off the display quickly while keeping Windows running.

[简体中文](README.zh-CN.md)

</div>

Small Windows utility for turning off the display while requesting that the system stay awake. Useful when a laptop is running desktop applications or acting as a local server.

## Quick start

Download the repository's [source ZIP](https://github.com/QXiaoLingShang/win-monitor-off/archive/refs/heads/main.zip), extract it, and double-click `monitor_off.bat`. Keep the files together. No installation or C compiler is required.

Stop using the keyboard and mouse for about six seconds. The console remains open while the helper runs; new keyboard or mouse input ends the session and releases its keep-awake request. Windows resumes its normal power policy afterward.

## How it works

The script temporarily changes the active power plan's display-idle timeout to one second and lets Windows execute its native display-off path. After roughly five seconds it restores the original timeout. It does not send `SC_MONITORPOWER`, broadcast window messages, or change the display topology.

The helper holds a `PowerRequestSystemRequired` request until new keyboard or mouse input, then exits. It saves both AC and battery timeouts together with the power-plan GUID under `%LOCALAPPDATA%\win-monitor-off\display-timeout.json`. Restoration targets that saved plan even if you switch plans. A second launch in the same session is rejected to protect the recovery record.

If interrupted before restoration, the next launch first restores the saved settings. To restore without starting another display-off session:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\monitor_off.ps1 -Restore
```

## Optional EXE launcher

The optional C launcher can be built with:

```text
gcc -std=c11 -Wall -Wextra -Werror monitor_off.c -o monitor_off.exe
```

Keep `monitor_off.exe` beside `monitor_off.ps1`. Both launchers prefer PowerShell 7 (`pwsh.exe`) and fall back to Windows PowerShell. The EXE delegates to the script; it is not a standalone binary.

## Requirements and limitations

- Windows 10/11 with Windows PowerShell 5.1 or PowerShell 7.
- The active user session must have permission to change its power plan.
- Connect AC power for long-running use. On Modern Standby systems running on battery, Windows ends system power requests five minutes after the sleep timeout expires. Closing the lid or explicitly selecting Sleep also overrides the request. See [Microsoft's power request documentation](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-powersetrequest).
- Applications that request an always-on display, driver behavior, or managed power policies may prevent display-off. The five-second wait does not confirm the physical display state.
- The script has not been designed as a Windows service. It operates in the interactive user session where the physical display exists.

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for checks and manual verification. Generated EXEs and ZIPs are excluded from source control. GitHub Actions checks PowerShell compatibility and builds the C launcher on Windows.

## License

[MIT](LICENSE).
