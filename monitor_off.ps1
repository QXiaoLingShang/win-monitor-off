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
