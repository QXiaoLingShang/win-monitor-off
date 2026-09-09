<div align="center">

# win-monitor-off

快速关闭显示器，同时保持 Windows 继续运行。

[English](README.md)

</div>

适用于将 Windows 笔记本作为本地服务器使用的场景。程序关闭显示器，但不会主动让系统进入睡眠；QQ 注入 Hook 等桌面程序可以继续运行。

## 工作方式

脚本先读取当前电源方案的显示器关闭时间，临时改为 1 秒，让 Windows 执行原生的“显示器空闲关闭”路径；约 5 秒后恢复原设置。

程序不会发送 `SC_MONITORPOWER`，不会广播窗口消息，也不会改变显示器拓扑。程序会在后台保持运行，直到键盘或鼠标输入唤醒显示器后自动退出。

如果进程被强制终止，脚本会在 `%LOCALAPPDATA%\win-monitor-off\display-timeout.json` 留下恢复记录；下次启动时会先恢复原来的电源设置。

## 使用

直接双击 [`monitor_off.bat`](monitor_off.bat)。也可以直接运行 [`monitor_off.ps1`](monitor_off.ps1)。显示器关闭期间命令行窗口会保持打开，按键或移动鼠标即可恢复。

如需构建 C 启动器：

```text
gcc monitor_off.c -o monitor_off.exe
```

构建后的 `monitor_off.exe` 必须与 `monitor_off.ps1` 放在同一目录。

## 要求与限制

- Windows PowerShell 5.1 或 PowerShell 7。
- 当前用户需要有权限修改当前电源方案。
- 长时间作为服务器运行时建议接入电源。
- 不要在 Modern Standby 笔记本上使用旧的 `SC_MONITORPOWER` 实现，它可能触发 S0 低功耗空闲并暂停桌面应用。
- 本项目不是 Windows 服务，只在存在物理显示器的交互式用户会话中工作。
