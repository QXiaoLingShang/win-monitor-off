<h1 align="center">win-monitor-off</h1>

<p align="center">
  <a href="README.md">English</a> · 简体中文
</p>

你是否遇到过这样的情况：笔记本外接显示器运行着耗时任务，你想关掉屏幕避免光线打扰他人，却发现合上笔记本盖可能让电脑进入睡眠，而只关闭外接显示器又会让笔记本内屏继续亮着？

手动关闭显示器、拔掉连接线或反复合盖不仅繁琐，更糟糕的是，屏幕熄灭的同时系统可能直接进入睡眠，导致后台任务中断。`win-monitor-off` 正是为此设计——它会临时将当前电源方案的显示器空闲关闭时间设为一秒，并请求 Windows 在会话期间保持系统运行。约六秒后，显示器熄灭，原来的关闭时间恢复，后台任务继续运行；按键或移动鼠标会重新点亮显示器并结束本次会话。

## 使用

1. 前往 [Releases 发布页](https://github.com/QXiaoLingShang/win-monitor-off/releases/latest)下载最新的 Windows 完整文件包并解压，保持文件结构不变。
2. 运行 `monitor_off.bat`，然后约六秒内不要操作键盘或鼠标，等待 Windows 关闭显示器。
3. 按任意键或移动鼠标，重新点亮显示器并结束本次会话。

程序无需安装。运行需要 Windows 10 或 11、Windows PowerShell 5.1 或 PowerShell 7，以及修改活动电源方案的权限。

只恢复已保存的显示器关闭时间、不开始新的会话：

```powershell
.\monitor_off.bat -Restore
```

如果程序意外中断，下次启动时会先恢复保存的关闭时间，再开始新的会话。

## 使用限制

- 程序会请求 Windows 关闭显示器，但无法保证显示器一定熄灭。如果屏幕仍亮着，可能是其他应用或 Windows 电源设置要求它保持开启。
- 会话期间不要选择“睡眠”。如果合盖操作设置为让笔记本进入睡眠，请保持笔记本开盖；睡眠会暂停会话，后台任务也可能中断。
- 使用 Modern Standby 的笔记本在电池供电时，Windows 会在设定的系统睡眠超时之后五分钟结束此保持运行请求。长时间运行任务时，请接通电源。

## 参与开发

如何使用 Windows PowerShell 5.1 和 PowerShell 7 运行检查，请见[参与开发指南（英文）](docs/CONTRIBUTING.md)。

构建可选的 EXE 文件包需要 PowerShell 7 以及 clang 或 gcc：

```powershell
pwsh -NoProfile -File .\scripts\package.ps1
```

文件包生成在 `dist/`。运行 `monitor_off.exe` 时，请保持包内文件在一起。

## 项目结构

```text
win-monitor-off/
├── .github/workflows/       # CI 检查和文件包构建
├── docs/
│   ├── CHANGELOG.md         # 英文项目更新记录
│   ├── CONTRIBUTING.md      # 英文参与开发指南
│   └── DEVELOPMENT.md       # 英文开发与实现说明
├── scripts/
│   └── package.ps1          # 构建可选的 EXE 文件包
├── src/
│   ├── MonitorOff.ps1       # 显示器与电源管理逻辑
│   ├── NativeMethods.cs     # Windows API 声明
│   └── launcher.c           # 可选的原生启动器
├── tests/check.ps1          # PowerShell 检查
├── monitor_off.bat          # Windows 启动入口
├── monitor_off.ps1          # PowerShell 启动入口
├── LICENSE                  # MIT 许可证
├── README.md                # 英文介绍与使用说明
└── README.zh-CN.md          # 简体中文介绍与使用说明
```

## 项目文档

- [开发说明（英文）](docs/DEVELOPMENT.md)、[参与开发指南（英文）](docs/CONTRIBUTING.md) 和 [更新记录（英文）](docs/CHANGELOG.md)。

## 许可证

本项目采用 [MIT 许可证](LICENSE)。
