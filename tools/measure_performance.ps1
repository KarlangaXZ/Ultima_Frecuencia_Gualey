param(
    [string]$Label = 'baseline-vsync',
    [switch]$NoVSync,
    [int]$Cap = 0,
    [ValidateRange(6,60)][int]$Cycles = 6
)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputDirectory = Join-Path $projectRoot "test-results/performance/$Label"
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
$enginePath = Join-Path $projectRoot '.tools/godot/Godot_v4.7.2-stable_win64.exe'
$arguments = @('--path', ('"' + $projectRoot + '"'), '--script', 'res://tests/performance_phase_11_1.gd', '--', "--output=res://test-results/performance/$Label")
if ($NoVSync) { $arguments += '--no-vsync' }
if ($Cap -gt 0) { $arguments += "--cap=$Cap" }
$arguments += "--cycles=$Cycles"
$nativeProcess = Start-Process -FilePath $enginePath -ArgumentList $arguments -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $outputDirectory 'stdout.txt') -RedirectStandardError (Join-Path $outputDirectory 'stderr.txt')
$memorySamples = [System.Collections.Generic.List[object]]::new()
while (-not $nativeProcess.HasExited) {
    $nativeProcess.Refresh()
    $stagePath = Join-Path $outputDirectory 'stage.txt'
    $stage = if (Test-Path -LiteralPath $stagePath) { Get-Content -LiteralPath $stagePath -Raw } else { 'startup' }
    $memorySamples.Add([pscustomobject]@{ Time = [DateTime]::UtcNow.ToString('o'); Stage = $stage; WorkingSetMiB = $nativeProcess.WorkingSet64 / 1MB; PrivateMiB = $nativeProcess.PrivateMemorySize64 / 1MB; CPUSeconds = $nativeProcess.TotalProcessorTime.TotalSeconds })
    Start-Sleep -Milliseconds 200
}
$nativeProcess.WaitForExit()
$memorySamples | Export-Csv -LiteralPath (Join-Path $outputDirectory 'process-memory.csv') -NoTypeInformation
Get-Content -LiteralPath (Join-Path $outputDirectory 'stdout.txt')
Get-Content -LiteralPath (Join-Path $outputDirectory 'stderr.txt')
if ($nativeProcess.ExitCode -ne 0) { throw "Godot terminó con código $($nativeProcess.ExitCode)" }
if (Select-String -LiteralPath (Join-Path $outputDirectory 'stderr.txt') -Pattern 'ERROR|WARNING') { throw 'Revisar errores/advertencias de Godot' }
