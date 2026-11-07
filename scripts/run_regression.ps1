param([switch]$FullSV, [string]$OutputDir = '')
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
$runner=Join-Path $PSScriptRoot 'run_stage.ps1'
$out=if($OutputDir) {
  if([IO.Path]::IsPathRooted($OutputDir)) { $OutputDir } else { Join-Path $projectRoot $OutputDir }
} else { Join-Path ([IO.Path]::GetTempPath()) ("soc-regression-" + [guid]::NewGuid().ToString('N')) }
if(Test-Path -LiteralPath $out) { throw "Output directory already exists: $out" }
New-Item -ItemType Directory -Path $out | Out-Null
$summary=Join-Path $out 'regression_summary.log'
$console=Join-Path $out 'console.log'
$revision=(& git -C $projectRoot rev-parse HEAD | Out-String).Trim()
$dirty=[bool](@(git -C $projectRoot status --porcelain).Count)
$bin=if($env:MODELSIM_BIN) { $env:MODELSIM_BIN } else { Split-Path (Get-Command vsim.exe -ErrorAction Stop).Source }
$version=(& "$bin/vsim.exe" -version 2>&1 | Out-String).Trim()
$record=[ordered]@{
  repository='RV32I-AXI4-Lite-SoC'; source_revision=$revision; source_dirty=$dirty
  simulator_version=$version; output_dir=$out; full_sv=[bool]$FullSV
  timeout_seconds_per_simulation=120; expected_runs=24; passed_runs=0
  status='FAIL'; runs=@(); error=$null; started_utc=(Get-Date).ToUniversalTime().ToString('o')
}
"Regression started $(Get-Date -Format o); FULL_SV=$FullSV" | Set-Content -Encoding utf8 $summary
$tops=@('unit_test','register_file_test','decode_test','control_test','cpu_test','sram_test',
  'axi_slave_test','axi_master_test','axi_reset_test','soc_integration_test','cpu_isa_test','delayed_core_test','fault_test','tb_top')
$count=0
try {
foreach($top in $tops) {
  $simArgs=@()
  if($top -eq 'soc_integration_test') { $simArgs=@("+WAVE_FILE=$(Join-Path $out 'integration.vcd')") }
  if($top -eq 'tb_top') { $simArgs=@('-sv_seed','1') }
  & $runner -Top $top -Sources '-f','scripts/filelist.f' -FullSV:$FullSV -SkipCompile:($count -gt 0) -SimArgs $simArgs -OutputDir $out |
    Tee-Object -FilePath $console -Append
  "PASS $top" | Add-Content -Encoding utf8 $summary
  $record.runs += $top
  $count++
}
foreach($program in @('arithmetic','branch','load_store')) {
  & $runner -Top cpu_isa_test -SkipCompile -LogName "cpu_$program" -SimArgs "-gPROGRAM=programs/$program.hex" -OutputDir $out |
    Tee-Object -FilePath $console -Append
  "PASS cpu_$program" | Add-Content -Encoding utf8 $summary
  $record.runs += "cpu_$program"
  $count++
}
foreach($config in @(@{Name='address_first';AD=0;WD=7},@{Name='together';AD=0;WD=0})) {
  & $runner -Top axi_master_test -SkipCompile -LogName "master_$($config.Name)" -SimArgs "-gAD=$($config.AD)","-gWD=$($config.WD)" -OutputDir $out |
    Tee-Object -FilePath $console -Append
  "PASS master_$($config.Name)" | Add-Content -Encoding utf8 $summary
  $record.runs += "master_$($config.Name)"
  $count++
}
foreach($seed in @(17,2026)) {
  & $runner -Top tb_top -SkipCompile -LogName "oop_seed_$seed" -SimArgs '-sv_seed',"$seed" -OutputDir $out |
    Tee-Object -FilePath $console -Append
  "PASS oop_seed_$seed" | Add-Content -Encoding utf8 $summary
  $record.runs += "oop_seed_$seed"
  $count++
}
foreach($seed in @(1,17,2026)) {
  & $runner -Top varying_latency_core_test -SkipCompile -LogName "varying_latency_$seed" -SimArgs "-gSEED=$seed" -OutputDir $out |
    Tee-Object -FilePath $console -Append
  "PASS varying_latency_$seed" | Add-Content -Encoding utf8 $summary
  $record.runs += "varying_latency_$seed"
  $count++
}
$record.passed_runs=$count
if($count -ne 24) { throw "Expected 24 runs, observed $count" }
$result="PASS REGRESSION $count/$count runs; finished $(Get-Date -Format o)"
$result | Add-Content -Encoding utf8 $summary
Write-Output $result
Get-ChildItem (Join-Path $out '*.log') | Where-Object { $_.Name -notmatch 'compile|console|summary' } |
  Select-String -Pattern '^# COVERAGE' | ForEach-Object { "$($_.Filename): $($_.Line)" } |
  Set-Content -Encoding utf8 (Join-Path $out 'coverage_summary.log')
$record.status='PASS'
} catch {
  $record.passed_runs=$count
  $record.error=$_.Exception.Message
  "FAIL REGRESSION after $count runs: $($record.error)" | Add-Content -Encoding utf8 $summary
  throw
} finally {
  $record.finished_utc=(Get-Date).ToUniversalTime().ToString('o')
  $record | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $out 'results.json')
}
