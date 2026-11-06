param([switch]$FullSV)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
$runner=Join-Path $PSScriptRoot 'run_stage.ps1'
$summary=Join-Path $projectRoot 'logs/regression_summary.log'
"Regression started $(Get-Date -Format o); FULL_SV=$FullSV" | Set-Content -Encoding utf8 $summary
$tops=@('unit_test','register_file_test','decode_test','control_test','cpu_test','sram_test',
  'axi_slave_test','axi_master_test','axi_reset_test','soc_integration_test','cpu_isa_test','delayed_core_test','fault_test','tb_top')
$count=0
foreach($top in $tops) {
  $simArgs=@()
  if($top -eq 'soc_integration_test') { $simArgs=@('+WAVES') }
  if($top -eq 'tb_top') { $simArgs=@('-sv_seed','1') }
  & $runner -Top $top -Sources '-f','scripts/filelist.f' -FullSV:$FullSV -SkipCompile:($count -gt 0) -SimArgs $simArgs
  "PASS $top" | Add-Content -Encoding utf8 $summary
  $count++
}
foreach($program in @('arithmetic','branch','load_store')) {
  & $runner -Top cpu_isa_test -SkipCompile -LogName "cpu_$program" -SimArgs "-gPROGRAM=programs/$program.hex"
  "PASS cpu_$program" | Add-Content -Encoding utf8 $summary
  $count++
}
foreach($config in @(@{Name='address_first';AD=0;WD=7},@{Name='together';AD=0;WD=0})) {
  & $runner -Top axi_master_test -SkipCompile -LogName "master_$($config.Name)" -SimArgs "-gAD=$($config.AD)","-gWD=$($config.WD)"
  "PASS master_$($config.Name)" | Add-Content -Encoding utf8 $summary
  $count++
}
foreach($seed in @(17,2026)) {
  & $runner -Top tb_top -SkipCompile -LogName "oop_seed_$seed" -SimArgs '-sv_seed',"$seed"
  "PASS oop_seed_$seed" | Add-Content -Encoding utf8 $summary
  $count++
}
foreach($seed in @(1,17,2026)) {
  & $runner -Top varying_latency_core_test -SkipCompile -LogName "varying_latency_$seed" -SimArgs "-gSEED=$seed"
  "PASS varying_latency_$seed" | Add-Content -Encoding utf8 $summary
  $count++
}
$result="PASS REGRESSION $count/$count runs; finished $(Get-Date -Format o)"
$result | Add-Content -Encoding utf8 $summary
Write-Output $result
Get-ChildItem (Join-Path $projectRoot 'logs/*.log') | Where-Object { $_.Name -notmatch 'compile|console|summary' } |
  Select-String -Pattern '^# COVERAGE' | ForEach-Object { "$($_.Filename): $($_.Line)" } |
  Set-Content -Encoding utf8 (Join-Path $projectRoot 'logs/coverage_summary.log')
