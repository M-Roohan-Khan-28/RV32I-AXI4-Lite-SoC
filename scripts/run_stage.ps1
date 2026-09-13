param([string]$Top = 'unit_test', [string[]]$Sources = @('rtl/cpu/rv32_pkg.sv','rtl/cpu/alu.sv','tb/tests/unit_test.sv'),
  [string[]]$SimArgs = @(), [string]$LogName = '', [switch]$FullSV, [switch]$SkipCompile)
$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
  $bin = if ($env:MODELSIM_BIN) { $env:MODELSIM_BIN } else { Split-Path (Get-Command vsim.exe -ErrorAction Stop).Source }
  if (!$LogName) { $LogName=$Top }
  if (!(Test-Path work)) { & "$bin/vlib.exe" work; if ($LASTEXITCODE) { throw 'vlib failed' } }
  $defines = if ($FullSV) { @('+define+FULL_SV') } else { @() }
  if (!$SkipCompile) {
    $compileOutput = & "$bin/vlog.exe" -sv +incdir+tb @defines @Sources 2>&1
    $compileOutput | Out-File -Encoding utf8 "logs/$LogName.compile.log"
    $compileOutput | Write-Output
    if ($LASTEXITCODE) { throw 'Compilation failed' }
  }
  $simulationOutput = & "$bin/vsim.exe" -c -onfinish exit $Top @SimArgs -do scripts/batch.do 2>&1
  $simulationOutput | Out-File -Encoding utf8 "logs/$LogName.log"
  $simulationOutput | Write-Output
  if ($LASTEXITCODE) { throw 'Simulation failed' }
  if (Select-String -Quiet -Path "logs/$LogName.log" -Pattern '\*\* (Error|Fatal):|FAIL ') { throw 'Failure in simulation log' }
  if (!(Select-String -Quiet -Path "logs/$LogName.log" -Pattern 'PASS')) { throw 'No PASS result' }
} finally { Pop-Location }
