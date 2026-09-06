<div align="center">

# win-monitor-off

一键熄屏，电脑不休眠。

[English](README.md) · [简体中文](README.zh-CN.md)

</div>

一键让显示器断电黑屏，电脑本身不休眠，下载、渲染等后台任务照常运行。移动鼠标或按任意键即可点亮。

## 运行

| 文件 | 用法 |
| ---- | ---- |
| `monitor_off.bat` | 双击即可 |
| `monitor_off.c` | 先编译，再运行 |

```
gcc monitor_off.c -o monitor_off.exe -luser32
monitor_off.exe
```
