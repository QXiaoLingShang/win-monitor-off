<div align="center">

# win-monitor-off

Turn your monitor off — keep your PC awake.

[English](README.md) · [简体中文](README.zh-CN.md)

</div>

Instantly powers the display down without putting your PC to sleep — downloads, renders and other background tasks keep running. Move the mouse or press any key to wake the screen.

## Run

| File | How |
| ---- | --- |
| `monitor_off.bat` | Double-click. |
| `monitor_off.c` | Build once, then run. |

```
gcc monitor_off.c -o monitor_off.exe -luser32
monitor_off.exe
```
