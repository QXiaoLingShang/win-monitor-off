<div align="center">

# win-monitor-off

Turn off the display quickly while keeping Windows running.

[简体中文](README.zh-CN.md)

</div>

This utility is intended for a Windows laptop used as a local server. It turns off the display without deliberately putting the system into sleep, so desktop applications such as injected QQ hooks can continue running.

## How it works

The script temporarily changes the active power plan's display-idle timeout to one second and lets Windows execute its native display-off path. After roughly five seconds it restores the original timeout. It does not send `SC_MONITORPOWER`, broadcast window messages, or change the display topology.

The helper remains alive until keyboard or mouse input wakes the display, then exits. A small recovery record is kept under `%LOCALAPPDATA%\win-monitor-off` so a later launch can restore settings after an abnormal termination.

## Run

Double-click [`monitor_off.bat`](monitor_off.bat). The same behavior can be started from [`monitor_off.ps1`](monitor_off.ps1). The console remains open while the display is off; press a key or move the mouse to restore it.

The optional C launcher can be built with:

```text
gcc monitor_off.c -o monitor_off.exe
```

Keep `monitor_off.exe` beside `monitor_off.ps1`.

## Requirements and limitations

- Windows PowerShell 5.1 or PowerShell 7.
- The active user session must have permission to change its power plan.
- The computer should be connected to AC power for long-running server use.
- Do not use the old `SC_MONITORPOWER` implementation on Modern Standby laptops; it can enter S0 low-power idle and pause desktop applications.
- The script has not been designed as a Windows service. It operates in the interactive user session where the physical display exists.
