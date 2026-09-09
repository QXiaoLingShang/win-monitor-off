$ErrorActionPreference = 'Stop'

# 强制 Windows 使用原生的显示器空闲关闭路径。
# 不发送 SC_MONITORPOWER：在 Modern Standby 笔记本上它可能触发 S0 睡眠。
$nativeType = @'
using System;
using System.Runtime.InteropServices;

public static class MonitorOffNative
{
    [StructLayout(LayoutKind.Sequential)]
    public struct LASTINPUTINFO
    {
        public uint cbSize;
        public uint dwTime;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct REASON_CONTEXT
    {
        public uint Version;
        public uint Flags;
        public IntPtr SimpleReasonString;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr PowerCreateRequest(ref REASON_CONTEXT context);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool PowerSetRequest(IntPtr request, uint type);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool PowerClearRequest(IntPtr request, uint type);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr handle);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool GetLastInputInfo(ref LASTINPUTINFO info);
}
'@

Add-Type -TypeDefinition $nativeType

function Invoke-PowerCfg {
    param([Parameter(Mandatory)][string[]]$Arguments)
    & "$env:SystemRoot\System32\powercfg.exe" @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "powercfg failed with exit code ${LASTEXITCODE}: $($Arguments -join ' ')"
    }
}

function Get-DisplayTimeouts {
    $text = (& "$env:SystemRoot\System32\powercfg.exe" /q SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 2>&1) -join "`n"
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to query the active display timeout.'
    }

    $ac = [regex]::Match($text, '(?im)^\s*.*(?:Current AC Power Setting Index|当前交流电源设置索引).*?0x([0-9a-f]+)\s*$')
    $dc = [regex]::Match($text, '(?im)^\s*.*(?:Current DC Power Setting Index|当前直流电源设置索引).*?0x([0-9a-f]+)\s*$')
    if (-not $ac.Success -or -not $dc.Success) {
        throw 'Unable to parse the active display timeout from powercfg output.'
    }

    [pscustomobject]@{
        AC = [Convert]::ToInt32($ac.Groups[1].Value, 16)
        DC = [Convert]::ToInt32($dc.Groups[1].Value, 16)
    }
}

function Set-DisplayTimeouts {
    param([Parameter(Mandatory)][int]$AC, [Parameter(Mandatory)][int]$DC)
    # VIDEOIDLE 的单位是秒。设置为 1 秒即可进入正常的显示器空闲关闭路径，
    # 不需要发送显示器电源命令。
    Invoke-PowerCfg @('/setacvalueindex', 'SCHEME_CURRENT', 'SUB_VIDEO', 'VIDEOIDLE', $AC)
    Invoke-PowerCfg @('/setdcvalueindex', 'SCHEME_CURRENT', 'SUB_VIDEO', 'VIDEOIDLE', $DC)
    Invoke-PowerCfg @('/setactive', 'SCHEME_CURRENT')
}

$stateDirectory = Join-Path $env:LOCALAPPDATA 'win-monitor-off'
$stateFile = Join-Path $stateDirectory 'display-timeout.json'

# 如果上一次进程被强制终止，启动时恢复之前保存的显示器关闭时间。
if (Test-Path -LiteralPath $stateFile) {
    try {
        $staleState = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
        Set-DisplayTimeouts -AC ([int]$staleState.AC) -DC ([int]$staleState.DC)
        Remove-Item -LiteralPath $stateFile -Force
    }
    catch {
        throw "Unable to recover the previous display timeout: $($_.Exception.Message)"
    }
}

$savedTimeouts = Get-DisplayTimeouts
$stateDirectoryCreated = $false
$stateRestored = $false
$reasonText = [Runtime.InteropServices.Marshal]::StringToHGlobalUni(
    'Keep the system running while the display is natively idle-off')
$reason = [MonitorOffNative+REASON_CONTEXT]::new()
$reason.Version = 0
$reason.Flags = 1 # POWER_REQUEST_CONTEXT_SIMPLE_STRING：使用简单文本说明。
$reason.SimpleReasonString = $reasonText
$powerRequest = [IntPtr]::Zero

try {
    $powerRequest = [MonitorOffNative]::PowerCreateRequest([ref]$reason)
    if ($powerRequest -eq [IntPtr]::Zero -or
        $powerRequest -eq [IntPtr]::new(-1)) {
        throw 'PowerCreateRequest failed.'
    }
    # 在本次关屏会话期间，阻止系统稍后因空闲自动进入睡眠。
    if (-not [MonitorOffNative]::PowerSetRequest($powerRequest, 1)) {
        throw 'PowerSetRequest failed.'
    }

    $before = [MonitorOffNative+LASTINPUTINFO]::new()
    $before.cbSize = [uint32][Runtime.InteropServices.Marshal]::SizeOf($before)
    if (-not [MonitorOffNative]::GetLastInputInfo([ref]$before)) {
        throw 'GetLastInputInfo failed.'
    }

    New-Item -ItemType Directory -Path $stateDirectory -Force | Out-Null
    $stateDirectoryCreated = $true
    [pscustomobject]@{
        AC = $savedTimeouts.AC
        DC = $savedTimeouts.DC
    } | ConvertTo-Json -Compress | Set-Content -LiteralPath $stateFile -Encoding UTF8

    Set-DisplayTimeouts -AC 1 -DC 1
    # 等待 Windows 原生空闲计时器到期。这里使用短暂延时，
    # 用于替代旧的 SC_MONITORPOWER 调用。
    Start-Sleep -Milliseconds 5500

    # 显示器进入空闲关闭状态后，恢复用户原来的关闭时间。
    Set-DisplayTimeouts -AC $savedTimeouts.AC -DC $savedTimeouts.DC

    while ($true) {
        Start-Sleep -Milliseconds 200
        $current = [MonitorOffNative+LASTINPUTINFO]::new()
        $current.cbSize = $before.cbSize
        if ([MonitorOffNative]::GetLastInputInfo([ref]$current) -and
            $current.dwTime -ne $before.dwTime) {
            break
        }
    }
}
finally {
    if ($savedTimeouts) {
        try {
            Set-DisplayTimeouts -AC $savedTimeouts.AC -DC $savedTimeouts.DC
            $stateRestored = $true
        }
        catch {
            Write-Warning $_.Exception.Message
        }
    }
    if ($stateDirectoryCreated -and $stateRestored -and
        (Test-Path -LiteralPath $stateFile)) {
        Remove-Item -LiteralPath $stateFile -Force
    }
    if ($powerRequest -ne [IntPtr]::Zero -and
        $powerRequest -ne [IntPtr]::new(-1)) {
        [void][MonitorOffNative]::PowerClearRequest($powerRequest, 1)
        [void][MonitorOffNative]::CloseHandle($powerRequest)
    }
    if ($reasonText -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::FreeHGlobal($reasonText)
    }
}
