# Test plan and reproduction

Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_regression.ps1` from the project root. The launcher compiles `scripts/filelist.f` once and runs the suite below. It fails on a nonzero simulator exit, missing PASS, or an Error/Fatal/FAIL marker. Each long-running test has a simulation-time watchdog; unit vector tests terminate after finite checks. Log files are written under `logs/`.

| Order | Top / variant | Test content |
|---|---|---|
| 1 | unit_test | Ten ALU operation checks |
| 2 | register_file_test | All registers, x0, write-disable, reset |
| 3 | decode_test | Positive/negative immediate extremes and field extraction |
| 4 | control_test | Legal/illegal decode and branch comparisons |
| 5 | cpu_test | Standalone core, arithmetic/taken branch/JAL |
| 6 | sram_test | 20 comparisons including all strobes and boundaries |
| 7 | axi_slave_test | 58 accesses, split AW/W, response stalls, range/alignment errors |
| 8 | axi_master_test | 26 accesses, W arrives first; all five channels delayed |
| 9 | axi_reset_test | Partial AW/W reset, stalled B/R reset, concurrent read/write, depth 3 |
| 10 | soc_integration_test | Program load, x3/SRAM/x5 = 30, exact bus count, PC hold; VCD enabled |
| 11 | cpu_isa_test | Combined full subset program; all 31 instructions and 12 branch outcomes |
| 12 | delayed_core_test | Same combined program with long AXI delays |
| 13 | fault_test | Ten illegal, alignment and bounds scenarios; reset recovery |
| 14 | tb_top | OOP directed + seeded random AXI scoreboard/coverage |
| 15–17 | cpu_isa_test PROGRAM overrides | arithmetic.hex, branch.hex, load_store.hex separately |
| 18–19 | axi_master_test AD/WD overrides | AW first and simultaneous AW/W |
| 20–21 | tb_top seed overrides | Additional seeds 17 and 2026 |

The regression explicitly uses seeds 1, 17 and 2026. The generator first writes all 1024 SRAM words, then exercises all strobe masks and repeated/RAW accesses, then generates 256 write/read pairs. Each seed performs 1586 checked transactions (1312 writes, 274 reads). Random data/strobes, address selection, address/data launch skew and response backpressure vary. FULL_SV uses constrained randomization; portable mode uses `$urandom`/`$urandom_range`.

## Program files

| Program | Purpose | Termination |
|---|---|---|
| integration.hex | ADDI 10/20, ADD, LUI, SW, LW | JAL x0,0 at PC 0x18 |
| arithmetic.hex | All arithmetic/logic/shift/compare/upper operations, dependencies | JAL x0,0 |
| branch.hex | Six taken and untaken branches, backward loop, JAL and JALR | JAL x0,0 |
| load_store.hex | First/middle/last data words, negative offset, LW x0 | JAL x0,0 |
| isa.hex | Combined arithmetic, branch and memory program | JAL x0,0 |

`scripts/generate_programs.js` emits the four non-integration HEX files plus `.lst` disassemblies. Its deterministic PRNG makes instruction streams reproducible. No external RISC-V assembler or compiler is required. `integration.S` documents the short integration program. Testbench completion is based on a terminal self-jump; there is no added halt instruction or memory-mapped peripheral.

## Waveforms and debug

The portable regression emits `logs/integration.vcd`. It includes clock/reset, PC/instruction, writeback, the five internal AXI channels, master state and SRAM port signals. `+WAVES` can also be passed to `tb_top` for `logs/axi_oop.vcd`. ModelSim's own `vsim.wlf` is a disposable build output. Open the VCD using a waveform viewer or rerun a test interactively in the simulator.

Integration enables `DEBUG=1` for readable console traces. Other tests use compact summaries. Per-test PASS is conditional on comparisons, not just reaching `$finish`.

## Full simulator mode

Questa: `vsim -c -do "set TOP tb_top; do scripts/run_questa.do"`; repeat with `cpu_isa_test` for instruction/branch coverage. UCDB files are saved on exit. Xcelium: `bash scripts/run_xrun.sh` runs the 14 base tops with coverage enabled. Windows `run_regression.ps1 -FullSV` runs the 21 variants using the licensed simulator available on PATH. These licensed runtime paths are supplied but cannot be executed with the installed Starter license.
