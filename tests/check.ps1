<#
.SYNOPSIS
检查脚本解析、恢复逻辑和只读电源方案查询。
.DESCRIPTION
通过模拟电源命令验证逻辑，并只读查询本机活动方案；不会启动关屏会话或修改电源设置。
#>

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$tokens = $null
$errors = $null
$implementation = Join-Path $root 'src/MonitorOff.ps1'
$ast = [Management.Automation.Language.Parser]::ParseFile(
    $implementation, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors -join "`n") }

# HOW：只加载函数定义，不在检查中启动实际关屏会话。
$nativeType = Get-Content -Raw -LiteralPath (Join-Path $root 'src/NativeMethods.cs')
Add-Type -TypeDefinition $nativeType
$ast.FindAll({ param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst]
}, $true) | ForEach-Object { Invoke-Expression $_.Extent.Text }

function Assert-True($Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}
function Assert-Throws([scriptblock]$Action, [string]$Message) {
    $failed = $false
    try { & $Action } catch { $failed = $true }
    Assert-True $failed $Message
}

$expectedSize = if ([IntPtr]::Size -eq 8) { 32 } else { 24 }
$reason = [MonitorOffNative+REASON_CONTEXT]::new()
Assert-True ([Runtime.InteropServices.Marshal]::SizeOf($reason) -eq $expectedSize) 'Wrong REASON_CONTEXT ABI size.'

$script:activeScheme = '381b4222-f694-41f0-9685-ff5bb260df2e'
$otherScheme = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
$script:commands = [Collections.Generic.List[string]]::new()
$script:query = ''
$script:failWrite = $false
function Invoke-PowerCfg {
    param([string[]]$Arguments)
    $script:commands.Add(($Arguments -join ' '))
    switch ($Arguments[0]) {
        '/getactivescheme' { "Power scheme GUID: $script:activeScheme" }
        '/q' { $script:query }
        '/setdcvalueindex' { if ($script:failWrite) { throw 'Simulated write failure.' } }
    }
}

foreach ($label in @('Current setting', 'Aktuelle Einstellung', 'Parametre actuel')) {
    $script:query = "Minimum: 0x00000000`nMaximum: 0xffffffff`nStep: 0x00000001`n${label} AC: 0x00000258`n${label} DC: 0xffffffff"
    $timeouts = Get-DisplayTimeouts -Scheme $script:activeScheme
    Assert-True ($timeouts.AC -eq 600 -and $timeouts.DC -eq [uint32]::MaxValue) 'Locale-independent timeout parsing failed.'
}
$script:query = 'Unexpected output'
Assert-Throws { Get-DisplayTimeouts -Scheme $script:activeScheme } 'Malformed query should fail.'
$script:query = "Minimum: 0x00000000`nMaximum: 0xffffffff`nStep: 0x00000001"
Assert-Throws { Get-DisplayTimeouts -Scheme $script:activeScheme } 'Truncated query should fail.'

$script:commands.Clear()
Set-DisplayTimeouts -Scheme $otherScheme -AC 600 -DC 300
Assert-True ($script:commands[0] -eq "/setacvalueindex $otherScheme SUB_VIDEO VIDEOIDLE 600") 'Restore targeted the wrong plan.'
Assert-True (-not ($script:commands -match '^/setactive')) 'Restore switched the active plan.'
$script:commands.Clear()
Set-DisplayTimeouts -Scheme $script:activeScheme -AC 0 -DC 0
Assert-True ($script:commands[-1] -eq "/setactive $script:activeScheme") 'Active plan changes were not applied.'

$tempDirectory = Join-Path ([IO.Path]::GetTempPath()) ('win-monitor-off-check-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tempDirectory | Out-Null
$stateFile = Join-Path $tempDirectory 'state.json'
try {
    @{ Scheme = $otherScheme; AC = 600; DC = 300 } | ConvertTo-Json | Set-Content $stateFile
    $script:failWrite = $true
    Assert-Throws { Restore-DisplayState -StateFile $stateFile } 'Failed restoration should fail.'
    Assert-True (Test-Path $stateFile) 'Failed restoration lost its recovery record.'
    $script:failWrite = $false
    Restore-DisplayState -StateFile $stateFile
    Assert-True (-not (Test-Path $stateFile)) 'Successful restoration left a stale record.'

    '{"AC":0,"DC":300}' | Set-Content $stateFile
    Restore-DisplayState -StateFile $stateFile -WarningAction SilentlyContinue
    Assert-True (-not (Test-Path $stateFile)) 'Legacy recovery failed.'
    '{"Scheme":"invalid","AC":0,"DC":0}' | Set-Content $stateFile
    Assert-Throws { Restore-DisplayState -StateFile $stateFile } 'Invalid scheme should fail.'
    Assert-True (Test-Path $stateFile) 'Invalid recovery record was discarded.'
    '{"Scheme":"8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c","AC":1.5,"DC":300}' | Set-Content $stateFile
    $script:commands.Clear()
    Assert-Throws { Restore-DisplayState -StateFile $stateFile } 'Fractional timeout should fail.'
    Assert-True ($script:commands.Count -eq 0) 'Invalid timeout changed the power plan.'
    Assert-True (Test-Path $stateFile) 'Invalid timeout record was discarded.'
    '{"Scheme":"8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c","AC":null,"DC":300}' | Set-Content $stateFile
    $script:commands.Clear()
    Assert-Throws { Restore-DisplayState -StateFile $stateFile } 'Null timeout should fail.'
    Assert-True ($script:commands.Count -eq 0) 'Null timeout changed the power plan.'
    Assert-True (Test-Path $stateFile) 'Null timeout record was discarded.'
    '{"AC":0}' | Set-Content $stateFile
    Assert-Throws { Restore-DisplayState -StateFile $stateFile -WarningAction SilentlyContinue } 'Missing timeout should fail.'
}
finally {
    Remove-Item -LiteralPath $stateFile -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tempDirectory
}

# HOW：只读查询本机活动方案，确认解析器能处理实际 powercfg 输出。
Remove-Item Function:Invoke-PowerCfg
Invoke-Expression ($ast.Find({ param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -eq 'Invoke-PowerCfg'
}, $true).Extent.Text)
$actual = Get-DisplayTimeouts -Scheme (Get-ActiveScheme)
Assert-True ($null -ne $actual.AC -and $null -ne $actual.DC) 'Read-only powercfg integration failed.'
Write-Output 'Checks passed (no power settings changed).'
