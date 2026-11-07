param([string]$Top = 'unit_test', [string[]]$Sources = @('rtl/cpu/rv32_pkg.sv','rtl/cpu/alu.sv','tb/tests/unit_test.sv'),
  [string[]]$SimArgs = @(), [string]$LogName = '', [switch]$FullSV, [switch]$SkipCompile,
  [string]$OutputDir = '')
$ErrorActionPreference = 'Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
$out=if($OutputDir) {
  if([IO.Path]::IsPathRooted($OutputDir)) { $OutputDir } else { Join-Path $projectRoot $OutputDir }
} else { Join-Path ([IO.Path]::GetTempPath()) ("soc-stage-" + [guid]::NewGuid().ToString('N')) }
New-Item -ItemType Directory -Path $out -Force | Out-Null
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
  $bin = if ($env:MODELSIM_BIN) { $env:MODELSIM_BIN } else { Split-Path (Get-Command vsim.exe -ErrorAction Stop).Source }
  if (!$LogName) { $LogName=$Top }
  if (!(Test-Path work)) { & "$bin/vlib.exe" work; if ($LASTEXITCODE) { throw 'vlib failed' } }
  $defines = if ($FullSV) { @('+define+FULL_SV') } else { @() }
  if (!$SkipCompile) {
    $compileOutput = & "$bin/vlog.exe" -sv +incdir+tb @defines @Sources 2>&1
    $compileOutput | Out-File -Encoding utf8 (Join-Path $out "$LogName.compile.log")
    $compileOutput | Write-Output
    if ($LASTEXITCODE -or ($compileOutput | Out-String) -match '\*\* (Error|Fatal):') { throw 'Compilation failed' }
  }
  $psi=New-Object Diagnostics.ProcessStartInfo
  $psi.FileName="$bin/vsim.exe"
  $psi.WorkingDirectory=$projectRoot
  $safeSimArgs=@($SimArgs | ForEach-Object { if($_ -match '\s') { '"' + $_.Replace('"','\"') + '"' } else { $_ } })
  $psi.Arguments="-c -onfinish exit $Top $($safeSimArgs -join ' ') -do scripts/batch.do"
  $psi.UseShellExecute=$false
  $psi.RedirectStandardOutput=$true
  $psi.RedirectStandardError=$true
  $proc=[Diagnostics.Process]::Start($psi)
  $stdout=$proc.StandardOutput.ReadToEndAsync()
  $stderr=$proc.StandardError.ReadToEndAsync()
  $finished=$proc.WaitForExit(120000)
  if(-not $finished) { $proc.Kill(); $proc.WaitForExit() }
  $simulationOutput=$stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult()
  $simulationOutput | Out-File -Encoding utf8 (Join-Path $out "$LogName.log")
  $simulationOutput | Write-Output
  if(-not $finished) { throw "Simulation timed out after 120 seconds: $Top" }
  if($proc.ExitCode) { throw "Simulation process failed: $Top exit $($proc.ExitCode)" }
  if($simulationOutput -match '\*\* (Error|Fatal):|(?m)^#?\s*FAIL ' -or
     $simulationOutput -notmatch '(?m)^# Errors: 0, Warnings: 0') {
    throw "Failure or missing clean end in simulation log: $Top"
  }
  if($simulationOutput -notmatch '(?m)^# .*PASS') { throw "No PASS result: $Top" }
  Write-Output "STAGE_PASS top=$Top log=$LogName output=$out"
} finally { Pop-Location }
