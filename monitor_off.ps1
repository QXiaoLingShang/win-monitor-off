<#
.SYNOPSIS
关闭显示器，并在收到键盘或鼠标输入后结束会话。
.DESCRIPTION
将实际工作交给 src/MonitorOff.ps1；使用 -Restore 仅恢复上次保存的显示器超时。
.PARAMETER Restore
仅恢复上次保存的显示器超时，不启动新的关屏会话。
#>

[CmdletBinding()]
param([switch]$Restore)

$ErrorActionPreference = 'Stop'
$implementation = Join-Path $PSScriptRoot 'src/MonitorOff.ps1'
try {
    & $implementation -Restore:$Restore
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
