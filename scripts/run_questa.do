# Run from riscv_axi_soc: vsim -c -do scripts/run_questa.do
# Select another top: vsim -c -do "set TOP tb_top; do scripts/run_questa.do"
# Requires Questa for covergroups, constrained randomization and SVA.
onerror {quit -code 1}
onbreak {quit -code 1}
if {![file isdirectory work]} {vlib work}
vlog -sv +define+FULL_SV -f scripts/filelist.f
if {![info exists TOP]} {set TOP soc_integration_test}
vsim -coverage -onfinish exit $TOP
coverage save -onexit logs/$TOP.ucdb
run -all
quit -code 0
