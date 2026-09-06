@echo off
rem 功能: 让显示器立刻黑屏关闭, 后台程序照常运行。
rem cmd 调用 PowerShell, 在 PS 里预编译出 SendMessage 函数, 再调用它广播关屏命令。
rem
rem   0xffff -> 广播给所有顶层窗口
rem   0x0112 -> 发送系统菜单命令 (WM_SYSCOMMAND)
rem   0xf170 -> 电源管理命令 (SC_MONITORPOWER)
rem   2      -> 关闭显示器 (-1=打开, 1=低功耗)

powershell -NoProfile -Command "Add-Type -Namespace W -Name M -MemberDefinition '[DllImport(\"user32.dll\")] public static extern int SendMessage(int h,int m,int w,int l);';" ^
    "[W.M]::SendMessage(" ^
    "0xffff," ^
    "0x0112," ^
    "0xf170," ^
    "2)"
