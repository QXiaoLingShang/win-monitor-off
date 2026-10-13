<h1 align="center">win-monitor-off</h1>

<p align="center">
  <a href="README.md">English</a> · 简体中文
</p>

你是否遇到过这样的情况：笔记本外接显示器运行着耗时任务，你想关掉屏幕避免光线打扰他人，却发现合上笔记本盖可能让电脑进入睡眠，而只关闭外接显示器又会让笔记本内屏继续亮着？

手动关闭显示器、拔掉连接线或反复合盖不仅繁琐，更糟糕的是，屏幕熄灭的同时系统可能直接进入睡眠，导致后台任务中断。`win-monitor-off` 正是为此设计——它会临时将当前电源方案的显示器空闲关闭时间设为一秒，并请求 Windows 在会话期间保持系统运行。约六秒后，显示器熄灭，原来的关闭时间恢复，后台任务继续运行；按键或移动鼠标会重新点亮显示器并结束本次会话。

## 安装

1. 下载 [源码 ZIP](https://github.com/QXiaoLingShang/win-monitor-off/archive/refs/heads/main.zip) 并解压。
2. 保持解压后的文件结构完整。
3. 运行 `monitor_off.bat`。

运行要求：Windows 10 或 11、Windows PowerShell 5.1 或 PowerShell 7，以及修改活动电源方案的权限。

## 使用

启动后约六秒内不要操作键盘或鼠标，等待 Windows 关闭显示器。之后按键或移动鼠标，显示器会重新点亮，本次会话结束。

只恢复已保存的显示器关闭时间、不开始新的会话：

```powershell
.\monitor_off.bat -Restore
```

如果程序意外中断，下次启动时会先恢复保存的关闭时间，再开始新的会话。

## 局限

- 如果电源设置会在合盖时让 Windows 进入睡眠，请在会话期间保持笔记本开盖。用户选择“睡眠”也会结束保持系统运行的请求，后台任务可能中断。
- 使用 Modern Standby 的笔记本在电池供电时，Windows 可能在系统睡眠超时五分钟后结束保持运行的请求。

## 开发

开发检查步骤见[参与开发指南（英文）](docs/CONTRIBUTING.md)。请分别使用 Windows PowerShell 5.1 和 PowerShell 7 运行检查。

如需构建可选的 EXE 文件包，请安装 PowerShell 7 和 clang 或 gcc，然后运行：

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
