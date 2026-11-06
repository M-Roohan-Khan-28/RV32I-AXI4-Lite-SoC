# Measured verification results

## Additional transaction-varying latency regression — 6 November 2026

Source revision `14fb8e6a854308aa45c16ab19e44ee3040edb2ea` was compiled
and run in an isolated test clone with ModelSim Intel FPGA Starter Edition
`vsim 2020.1 Simulator 2020.02 Feb 28 2020`:

```powershell
$env:MODELSIM_BIN='C:\intelFPGA\20.1\modelsim_ase\win32aloem'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/run_regression.ps1
```

The extended regression passed **24/24 runs**, wrapper exit **0**, compile
0 errors/0 warnings. The three added tests use deterministic delay seeds
1, 17 and 2026. Each executes the existing full instruction program against
the independent architectural model, checks the register file after every
retirement and compares initialized SRAM words at completion. All three
retired 234 instructions, observed four writes and five reads, and verified
that accepted AW and AR transactions had different stall lengths:

| Seed | CPU wait cycles | AW stall range | AR stall range |
| ---: | ---: | ---: | ---: |
| 1 | 167 | 6–10 | 3–11 |
| 17 | 150 | 2–11 | 2–9 |
| 2026 | 152 | 1–11 | 2–7 |

Fresh summary, compile and 24 simulation logs are retained under
`reports/varying-latency-2026-11-06/`, separate from the historical `logs/`.
The original 21 runs and their old evidence remain identified below. These
new runs do not establish full ISA compliance or licensed coverage.

Environment: Windows, ModelSim Intel FPGA Starter Edition **2020.1**, simulator build dated 2020-02-28. Verification run date: **2026-09-13**. Commands and timestamps are retained in the logs. No external dependencies or RISC-V compiler were installed.

## Portable regression

**21 / 21 runs passed.** The final portable compilation reports zero errors and zero warnings. All runs elaborate and simulate; the launcher rejects missing PASS markers and simulation failures. See [regression summary](../logs/regression_summary.log) and [complete transcript](../logs/regression_console.log).

| Check | Observed result | Evidence |
|---|---|---|
| ALU | Ten operation vectors pass | `logs/unit_test.log` |
| Register file | All 32 registers, ignored x0 writes, write-disable and reset pass | `logs/register_file_test.log` |
| Immediate/decoder/control | Signed immediate extremes and branch/control checks pass | `logs/decode_test.log`, `logs/control_test.log` |
| Standalone CPU | Arithmetic, taken branch and jump pass | `logs/cpu_test.log` |
| SRAM | 20 checks; all 16 WSTRB masks, boundaries and retention pass | `logs/sram_test.log` |
| AXI slave | 58 checked accesses pass | `logs/axi_slave_test.log` |
| AXI master | 26 accesses per run; all three AW/W orders pass | `logs/axi_master_test.log`, `logs/master_address_first.log`, `logs/master_together.log` |
| AXI reset/arbitration | Partial AW/W, stalled B/R reset, concurrent read/write and depth-3 bounds pass | `logs/axi_reset_test.log` |
| SoC integration | x3=30; SRAM at 0x10000000=30; x5=30; exactly one write and one read | `logs/soc_integration_test.log` |
| Integration wait | Nine waiting cycles; PC holds; no early retirement | `logs/soc_integration_test.log` |
| Full instruction program | 235 instructions retired and compared | `logs/cpu_isa_test.log` |
| Delayed full program | 235 retirements, 189 wait cycles, four stores and five loads | `logs/delayed_core_test.log` |
| CPU fault paths | Ten scenarios pass | `logs/fault_test.log` |
| Separate program tests | Arithmetic 190, branch 31, load/store 16 retirements | `logs/cpu_arithmetic.log`, `logs/cpu_branch.log`, `logs/cpu_load_store.log` |
| Layered AXI scoreboard | 1586 checks/seed, zero failures; seeds 1,17,2026 | `logs/tb_top.log`, `logs/oop_seed_17.log`, `logs/oop_seed_2026.log` |

The three OOP seeds total **4758 checked transactions**, comprising 3936 writes and 822 reads. These counts exclude the separate directed bus and CPU tests.

## Observed functional bins

These are measured portable counters, **not simulator covergroup or code-coverage percentages**. [Raw coverage summaries](../logs/coverage_summary.log) preserve the simulator output.

| Category | Hit / target | Raw representation |
|---|---|---|
| Required CPU instructions | 31 / 31 | `instruction_mask=7fffffff` |
| Branch taken/untaken combinations | 12 / 12 | `branch_outcomes=fff` |
| AXI read/write kinds | 2 / 2 | 274 reads and 1312 writes per OOP seed |
| WSTRB patterns | 16 / 16 | `strobes=ffff` |
| SRAM address quarters | 4 / 4 | `regions=1111` |
| AW before W / same cycle / W before AW | 3 / 3 | `AW/W_orders=111` |
| Channels observed under backpressure | 5 / 5 | `delayed_channels=11111` in AW,W,B,AR,R bit order |
| Read-after-write | 272 hits/seed | `RAW=272` |
| Repeated writes | 16 hits/seed | `repeated_writes=16` |

## Full SystemVerilog feature status

`vlog -sv +define+FULL_SV -f scripts/filelist.f` compiles the final SVA, constrained-random and covergroup sources with **zero errors**. Three warnings identify assertion features requiring Questa. See `logs/full_sv_compile.log`.

An explicit runtime capability probe failed at elaboration because this installed edition lacks the verification license:

```text
Unable to checkout verification license - testbench generation feature
(randomize, randcase, randsequence, covergroup) is only supported with QuestaSim.
```

See `logs/full_sv_capability.log`. This is a tool/license limitation, not a passing test and not omitted from the report. **Concurrent SVA execution, solver-based constrained randomization, licensed covergroup percentages, UCDB generation and Xcelium execution have not been verified here.** The functional tests use the portable class environment and procedural assertion equivalents. SVA/covergroups remain in the delivered sources for a licensed Questa/Xcelium run.

## Artifacts and remaining limits

`logs/integration.vcd` is an actual generated waveform; the readable integration trace contains the full fetch/store/load/writeback sequence. All requested RTL, verification files, HEX programs, simulation scripts and design/verification documents are present. There are no placeholder RTL modules.

No synthesis, area report, timing analysis, physical SRAM macro integration, FPGA programming, formal proof or official RISC-V compliance suite was run. The implemented ISA is the requested 31-instruction subset; exclusions are listed in README. Icarus and Verilator were unavailable. The licensed runtime verification items above remain the only simulator-specific verification gap; they must not be represented as completed coverage closure.
