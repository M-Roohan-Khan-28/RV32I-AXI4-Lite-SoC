#!/usr/bin/env bash
# Portable ModelSim/Questa integration run. Full licensed coverage uses run_questa.do.
set -euo pipefail
cd "$(dirname "$0")/.."
top="${1:-soc_integration_test}"
[[ "$top" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || { echo "Invalid test module name" >&2; exit 2; }
for tool in vlib vlog vsim; do
  command -v "$tool" >/dev/null || { echo "Missing simulator command: $tool" >&2; exit 127; }
done
mkdir -p logs
[[ -d work ]] || vlib work
vlog -sv -f sim/filelist.f
vsim -c "$top" +WAVES -do 'onerror {quit -code 1}; onbreak {quit -code 1}; run -all; quit -code 0' | tee "logs/$top.shell.log"
if ! grep -q 'PASS' "logs/$top.shell.log" || grep -Eq 'FAIL |\*\* (Error|Fatal)' "logs/$top.shell.log"; then
  echo "Simulation did not pass; see logs/$top.shell.log" >&2
  exit 1
fi
