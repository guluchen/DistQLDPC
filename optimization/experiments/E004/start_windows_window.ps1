param([switch]$AllowContention, [string]$Prior, [string]$Runtime)
$ErrorActionPreference = 'Stop'
$benchmarkWorkspace = Split-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot)))
if (-not $Prior) { $Prior = Join-Path $benchmarkWorkspace 'E004-windows-tier2-02' }
if (-not $Runtime) { $Runtime = Join-Path $benchmarkWorkspace 'E004-windows-runtime/cygwin' }
$benchmarkOutput = Join-Path $benchmarkWorkspace ('E004-windows-window-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$benchmarkArgs = @('-X', 'utf8', (Join-Path $PSScriptRoot 'run_windows_affinity_tier1.py'),
    '--prior', $Prior, '--cygwin-root', $Runtime, '--output', $benchmarkOutput,
    '--preflight-wait-sec', '30')
if ($AllowContention) { $benchmarkArgs += '--allow-core-contention' }
Write-Host 'H-007 LTO: 48 serial Tier1 comparisons; temporary owned-process affinity and sleep requirement.'
Write-Host 'Default: require a sufficiently idle physical-core/SMT pair. No other programs are closed.'
Write-Host "Evidence: $benchmarkOutput"
& python @benchmarkArgs
exit $LASTEXITCODE
