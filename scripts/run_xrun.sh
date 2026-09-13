#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p logs
for top in unit_test register_file_test decode_test control_test cpu_test sram_test axi_slave_test axi_master_test axi_reset_test soc_integration_test cpu_isa_test delayed_core_test fault_test tb_top; do
  xrun -64bit -sv +define+FULL_SV -f scripts/filelist.f -top "$top" \
    -coverage all -covoverwrite -covtest "$top" -l "logs/$top.xrun.log"
  if ! grep -q 'PASS' "logs/$top.xrun.log" || grep -Eq 'FAIL |\*E,|\*F,' "logs/$top.xrun.log"; then
    echo "FAIL $top"; exit 1
  fi
done
