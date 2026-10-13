<#
.SYNOPSIS
构建包含原生启动器和 PowerShell 实现的可运行文件包。
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$output = Join-Path $root 'dist'
$source = Join-Path $root 'src'

$compiler = Get-Command clang, gcc -ErrorAction SilentlyContinue |
    Select-Object -First 1
if ($null -eq $compiler) {
    throw 'Install clang or gcc to build the optional launcher.'
}

New-Item -ItemType Directory -Path $output -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'monitor_off.bat') -Destination $output -Force
Copy-Item -LiteralPath (Join-Path $root 'monitor_off.ps1') -Destination $output -Force
$runtimeSource = Join-Path $output 'src'
New-Item -ItemType Directory -Path $runtimeSource -Force | Out-Null
foreach ($name in @('MonitorOff.ps1', 'NativeMethods.cs', 'launcher.c')) {
    Copy-Item -LiteralPath (Join-Path $source $name) -Destination $runtimeSource -Force
}

$executable = Join-Path $output 'monitor_off.exe'
& $compiler.Source -std=c11 -Wall -Wextra -Werror `
    (Join-Path $source 'launcher.c') -o $executable
if ($LASTEXITCODE -ne 0) {
    throw "Launcher build failed with exit code $LASTEXITCODE."
}

Write-Output "Package ready: $output"
