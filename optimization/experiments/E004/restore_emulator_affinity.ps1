param([string]$Backup)
$ErrorActionPreference = 'Stop'
if (-not $Backup) {
    $benchmarkWorkspace = Split-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot)))
    $Backup = Join-Path $benchmarkWorkspace 'E004-emulator-affinity-backup-01.json'
}
$benchmarkRecords = @(Get-Content -LiteralPath $Backup -Raw | ConvertFrom-Json)
foreach ($benchmarkRecord in $benchmarkRecords) {
    if ($benchmarkRecord.process -notin @('Ld9BoxHeadless', 'dnplayer')) { throw 'Unexpected process in backup' }
    if ([int64]$benchmarkRecord.original_mask -lt 1 -or [int64]$benchmarkRecord.original_mask -gt 65535) { throw 'Invalid affinity mask' }
    $benchmarkProcess = Get-Process -Id ([int]$benchmarkRecord.pid) -ErrorAction SilentlyContinue
    if (-not $benchmarkProcess) { Write-Host "Exited PID $($benchmarkRecord.pid); skipped"; continue }
    if ($benchmarkProcess.ProcessName -ne $benchmarkRecord.process -or
        $benchmarkProcess.StartTime.ToUniversalTime().ToString('o') -ne $benchmarkRecord.start_time_utc) {
        Write-Host "PID $($benchmarkRecord.pid) identity changed; skipped"
        continue
    }
    $benchmarkProcess.ProcessorAffinity = [IntPtr]([int64]$benchmarkRecord.original_mask)
    $benchmarkProcess.Refresh()
    if ([int64]$benchmarkProcess.ProcessorAffinity -ne [int64]$benchmarkRecord.original_mask) { throw 'Restoration verification failed' }
    Write-Host "Restored $($benchmarkProcess.ProcessName) PID $($benchmarkProcess.Id)"
}
