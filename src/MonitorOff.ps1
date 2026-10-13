[CmdletBinding()]
param([switch]$Restore)

$ErrorActionPreference = 'Stop'

# 强制 Windows 使用原生的显示器空闲关闭路径。
# 不发送 SC_MONITORPOWER：在 Modern Standby 笔记本上它可能触发 S0 睡眠。
if (-not ('MonitorOffNative' -as [type])) {
    Add-Type -Path (Join-Path $PSScriptRoot 'NativeMethods.cs')
}

function Invoke-PowerCfg {
    param([Parameter(Mandatory)][string[]]$Arguments)
    & "$env:SystemRoot\System32\powercfg.exe" @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "powercfg failed with exit code ${LASTEXITCODE}: $($Arguments -join ' ')"
    }
}

function Get-ActiveScheme {
    $text = (Invoke-PowerCfg @('/getactivescheme')) -join "`n"
    $match = [regex]::Match($text, '[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}')
    if (-not $match.Success) {
        throw 'Unable to read the active power scheme.'
    }
    $match.Value
}

function Get-DisplayTimeouts {
    param([Parameter(Mandatory)][guid]$Scheme)
    $text = (Invoke-PowerCfg @('/q', $Scheme, 'SUB_VIDEO', 'VIDEOIDLE')) -join "`n"
    # The final two hexadecimal values are AC and DC, regardless of UI language.
    $values = [regex]::Matches($text, '(?im)0x([0-9a-f]+)\s*$')
    # Expect minimum, maximum, increment, AC, DC; reject truncated output.
    if ($values.Count -ne 5) {
        throw 'Unable to parse the active display timeout from powercfg output.'
    }

    [pscustomobject]@{
        Scheme = $Scheme.ToString()
        AC = [Convert]::ToUInt32($values[$values.Count - 2].Groups[1].Value, 16)
        DC = [Convert]::ToUInt32($values[$values.Count - 1].Groups[1].Value, 16)
    }
}

function Set-DisplayTimeouts {
    param(
        [Parameter(Mandatory)][guid]$Scheme,
        [Parameter(Mandatory)][uint32]$AC,
        [Parameter(Mandatory)][uint32]$DC
    )
    # VIDEOIDLE 的单位是秒。设置为 1 秒即可进入正常的显示器空闲关闭路径，
    # 不需要发送显示器电源命令。
    Invoke-PowerCfg @('/setacvalueindex', $Scheme, 'SUB_VIDEO', 'VIDEOIDLE', $AC) | Out-Null
    Invoke-PowerCfg @('/setdcvalueindex', $Scheme, 'SUB_VIDEO', 'VIDEOIDLE', $DC) | Out-Null
    # Do not switch back if the user has selected a different plan.
    if ([guid](Get-ActiveScheme) -eq $Scheme) {
        Invoke-PowerCfg @('/setactive', $Scheme) | Out-Null
    }
}

function ConvertTo-DisplayTimeout {
    param([Parameter(Mandatory)][object]$Value, [Parameter(Mandatory)][string]$Name)
    if ($Value -is [string] -or $Value -is [bool] -or
        $Value -is [array] -or $Value -is [pscustomobject]) {
        throw "The recovery record contains an invalid $Name timeout."
    }
    try { $number = [decimal]$Value }
    catch { throw "The recovery record contains an invalid $Name timeout." }
    if ($number -lt 0 -or $number -gt [uint32]::MaxValue -or
        $number -ne [decimal]::Truncate($number)) {
        throw "The recovery record contains an invalid $Name timeout."
    }
    [uint32]$number
}

function Restore-DisplayState {
    param([Parameter(Mandatory)][string]$StateFile)
    if (-not (Test-Path -LiteralPath $StateFile)) { return }
    $state = Get-Content -Raw -LiteralPath $StateFile | ConvertFrom-Json
    if ($null -eq $state -or $state -is [string] -or $state -is [array]) {
        throw 'The recovery record is invalid.'
    }
    $acProperty = $state.PSObject.Properties['AC']
    $dcProperty = $state.PSObject.Properties['DC']
    if ($null -eq $acProperty -or $null -eq $dcProperty) {
        throw 'The recovery record is missing display timeouts.'
    }
    $ac = ConvertTo-DisplayTimeout -Value $acProperty.Value -Name 'AC'
    $dc = ConvertTo-DisplayTimeout -Value $dcProperty.Value -Name 'DC'

    # Older versions did not record a scheme; retain their recovery behavior.
    if ($null -eq $state.PSObject.Properties['Scheme']) {
        Write-Warning 'Legacy recovery record: restoring the current power scheme.'
        $scheme = [guid](Get-ActiveScheme)
    }
    else {
        try { $scheme = [guid]$state.Scheme }
        catch { throw 'The recovery record contains an invalid power scheme.' }
    }
    Set-DisplayTimeouts -Scheme $scheme -AC $ac -DC $dc
    Remove-Item -LiteralPath $StateFile -Force
}

function Invoke-MonitorOff {
    $stateDirectory = Join-Path $env:LOCALAPPDATA 'win-monitor-off'
    $stateFile = Join-Path $stateDirectory 'display-timeout.json'

    # 如果上一次进程被强制终止，启动时恢复之前保存的显示器关闭时间。
    if (Test-Path -LiteralPath $stateFile) {
        try {
            Restore-DisplayState -StateFile $stateFile
        }
        catch {
            throw "Unable to recover the previous display timeout: $($_.Exception.Message)"
        }
    }

    if ($Restore) { return }

    $savedTimeouts = Get-DisplayTimeouts -Scheme (Get-ActiveScheme)
    $stateSaved = $false
    $stateRestored = $false
    $reasonText = [Runtime.InteropServices.Marshal]::StringToHGlobalUni(
        'Keep the system running while the display is natively idle-off')
    $reason = [MonitorOffNative+REASON_CONTEXT]::new()
    $reason.Version = 0
    $reason.Flags = 1 # POWER_REQUEST_CONTEXT_SIMPLE_STRING：使用简单文本说明。
    $reasonUnion = [MonitorOffNative+REASON_UNION]::new()
    $reasonUnion.SimpleReasonString = $reasonText
    $reason.Reason = $reasonUnion
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
        $savedTimeouts | ConvertTo-Json -Compress | Set-Content -LiteralPath $stateFile -Encoding UTF8
        $stateSaved = $true

        Set-DisplayTimeouts -Scheme $savedTimeouts.Scheme -AC 1 -DC 1
        # 等待 Windows 原生空闲计时器到期。这里使用短暂延时，
        # 用于替代旧的 SC_MONITORPOWER 调用。
        Start-Sleep -Milliseconds 5500

        # 显示器进入空闲关闭状态后，恢复用户原来的关闭时间。
        Restore-DisplayState -StateFile $stateFile
        $stateRestored = $true

        while ($true) {
            Start-Sleep -Milliseconds 200
            $current = [MonitorOffNative+LASTINPUTINFO]::new()
            $current.cbSize = $before.cbSize
            if (-not [MonitorOffNative]::GetLastInputInfo([ref]$current)) {
                throw 'GetLastInputInfo failed.'
            }
            if ($current.dwTime -ne $before.dwTime) {
                break
            }
        }
    }
    finally {
        if ($stateSaved -and -not $stateRestored) {
            try {
                Restore-DisplayState -StateFile $stateFile
                $stateRestored = $true
            }
            catch {
                Write-Warning $_.Exception.Message
            }
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
}

# Serialize recovery and the session so a second launch cannot overwrite state.
$mutex = [Threading.Mutex]::new($false, 'Local\win-monitor-off')
$ownsMutex = $false
try {
    try { $ownsMutex = $mutex.WaitOne(0) }
    catch [Threading.AbandonedMutexException] { $ownsMutex = $true }
    if (-not $ownsMutex) { throw 'win-monitor-off is already running.' }
    Invoke-MonitorOff
}
finally {
    if ($ownsMutex) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}
