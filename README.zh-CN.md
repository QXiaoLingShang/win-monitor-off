<div align="center">

# win-monitor-off

快速关闭显示器，同时保持 Windows 继续运行。

[English](README.md)

</div>

一个简单的 Windows 关屏工具，在关闭显示器时请求系统保持运行。适合笔记本运行桌面程序或作为本地服务器的场景。

## 快速开始

下载仓库的[源码 ZIP](https://github.com/QXiaoLingShang/win-monitor-off/archive/refs/heads/main.zip)，解压后双击 `monitor_off.bat`。保持文件在同一目录即可，无需安装或 C 编译器。

启动后约 6 秒内不要操作键盘或鼠标。运行期间命令行窗口保持打开；新的键盘或鼠标输入会结束本次会话，释放保持唤醒的请求，之后 Windows 按原来的电源策略运行。

## 工作方式

脚本先读取当前电源方案的显示器关闭时间，临时改为 1 秒，让 Windows 执行原生的“显示器空闲关闭”路径；约 5 秒后恢复原设置。

程序不会发送 `SC_MONITORPOWER`，不会广播窗口消息，也不会改变显示器拓扑。程序持有 `PowerRequestSystemRequired` 电源请求，直到检测到新的键盘或鼠标输入后退出。

脚本在 `%LOCALAPPDATA%\win-monitor-off\display-timeout.json` 保存电源方案 GUID 及原来的交流、直流显示器关闭时间。即使中途切换电源方案，也只恢复之前记录的方案。同一用户会话中重复启动会被拒绝，以保护恢复记录。

如果进程在恢复设置前被强制终止，下次启动会先恢复原设置。也可以只恢复设置，不启动关屏会话：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\monitor_off.ps1 -Restore
```

## 可选 EXE 启动器

如需构建 C 启动器：

```text
gcc -std=c11 -Wall -Wextra -Werror monitor_off.c -o monitor_off.exe
```

构建后的 `monitor_off.exe` 必须与 `monitor_off.ps1` 放在同一目录。两个启动器都优先使用 PowerShell 7（`pwsh.exe`），找不到时回退到 Windows PowerShell。EXE 负责调用脚本，不能脱离脚本独立使用。

## 要求与限制

- Windows 10/11，安装 Windows PowerShell 5.1 或 PowerShell 7。
- 当前用户需要有权限修改当前电源方案。
- 长时间运行请接入电源。使用电池的 Modern Standby 设备，在系统睡眠超时后 5 分钟会终止保持运行的电源请求；合盖或手动选择睡眠也会覆盖此请求。参见 [Microsoft 电源请求说明](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-powersetrequest)。
- 其他程序的保持显示请求、驱动行为或受管理的电源策略可能阻止关屏。等待约 5 秒并不代表已经确认物理显示器关闭。
- 本项目不是 Windows 服务，只在存在物理显示器的交互式用户会话中工作。

## 开发

验证命令和手动测试步骤见 [CONTRIBUTING.md](CONTRIBUTING.md)。生成的 EXE、ZIP 不进入源码版本控制。GitHub Actions 在 Windows 上检查 PowerShell 兼容性并编译 C 启动器。

## 许可证

[MIT](LICENSE)。
