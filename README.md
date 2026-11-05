# RV32I-Subset SoC with AXI4-Lite SRAM

**SystemVerilog · 31-instruction RV32I subset · RTL and verification**

A non-pipelined 32-bit processor implementing a 31-instruction RV32I subset, integrated with an AXI4-Lite data path and SRAM. The repository includes unit tests, instruction-reference checks, and SoC integration tests. The introductory integration program adds 10 and 20, stores 30 through AXI4-Lite, and reads it back into a CPU register.

[Architecture](docs/ARCHITECTURE.md) · [Verification plan](docs/VERIFICATION_PLAN.md) · [Recorded results](docs/RESULTS.md) · [Waveforms](waves/README.md)

The publishing copy passed **21/21 portable regression runs** with ModelSim Intel
FPGA Starter Edition 2020.1 on September 13, 2026. Results are retained with their
logs. Synthesis and licensed coverage execution remain outstanding.

A synthesizable educational 32-bit, non-pipelined processor with direct instruction fetch and AXI4-Lite data access. One master connects directly to one SRAM slave. There are no peripherals, pipeline stages, caches or interconnect.

## Architecture

```text
                       +--------------------+
                 PC -->| Instruction memory |-- instruction --+
                 ^     +--------------------+                 |
                 |                                            v
       +---------------------------------------------------------+
       | Core: decode / registers / immediate / ALU / branch / LSU|
       +--------------------+------------------------------------+
                            | request / completion
                            v
                     AXI4-Lite master
                            | AW, W, B, AR, R
                     AXI4-Lite slave
                            | synchronous single-port access
                       4 KiB data SRAM
```

The combinational CPU datapath executes ordinary instructions in one clock cycle. LW/SW require multiple cycles because AXI channels handshake independently and SRAM reads are synchronous. During a memory instruction the PC stays fixed and register writeback is disabled until completion. No second instruction is in flight. See [architecture](docs/ARCHITECTURE.md) and [memory map](docs/MEMORY_MAP.md).

The master latches each request, holds channel VALID and payload until acceptance, and retires it only after B/R. Its DONE state gives the CPU one completion cycle and prevents duplicate requests. The slave stores AW and W separately, supports either arrival order, observes WSTRB, and holds responses during backpressure. It arbitrates its single SRAM port in favor of a complete write over a queued read. AWPROT/ARPROT are present and driven zero; protection attributes are ignored by this unprivileged memory slave.

## Source organization

- `rtl/cpu/`: PC, 32-register file, field decoder, immediate generator, control, ALU, branch unit, LSU, core and shared enumerations.
- `rtl/axi/`: one-outstanding-request master and SRAM slave.
- `rtl/memory/`: direct instruction memory and synchronous SRAM.
- `rtl/riscv_soc_top.sv`: complete SoC with internal AXI connection and debug ports.
- `tb/axi_lite_if.sv`: synthesizable interface and MASTER/SLAVE/MONITOR modports, also used by RTL.
- `tb/`: OOP generator, virtual-interface driver/monitor, mailbox scoreboards, functional coverage, protocol checker, independent CPU reference model and delay model.
- `tb/tests/`: unit, core, SRAM, bus, reset, fault and SoC tests; `tb_top` runs the OOP slave/SRAM environment.
- `programs/`: checked-in HEX programs, address/encoding/disassembly listings and integration assembly.
- `scripts/`: ordered file lists and simulator launchers.
- `sim/`: shell entry point and source-list entry point; use `bash sim/run.sh` with ModelSim/Questa on PATH.
- `waves/`: waveform evidence and screenshot notes.
- `reports/`: coverage summary and explicit synthesis status.
- `logs/`: actual compiler/simulator results, regression summary and integration waveform.
- `docs/`: architecture, memory map, verification/test plans and measured results.

## Implemented instructions

| Group | Instructions |
|---|---|
| Register ALU | ADD SUB AND OR XOR SLT SLTU SLL SRL SRA |
| Immediate ALU | ADDI ANDI ORI XORI SLTI SLTIU SLLI SRLI SRAI |
| Memory | LW SW |
| Branch | BEQ BNE BLT BGE BLTU BGEU |
| Jump | JAL JALR |
| Upper immediate | LUI AUIPC |

This is the **31-instruction RV32I subset requested for Version 1**, not a claim of complete unprivileged ISA compliance. Byte/halfword CPU accesses, FENCE, ECALL/EBREAK, CSRs, privilege, interrupts and all ISA extensions are excluded. WSTRB byte writes are implemented and tested at the AXI/SRAM level.

All registers and buses are 32 bits; the register file has 32 entries with immutable x0. Shift amounts use five low bits. Comparisons and immediates distinguish signed and unsigned operations. JALR clears bit zero and rejects a target with bit one set.

## Reset, parameters and errors

Use a common clock and **synchronous active-low** `reset_n`, held low across at least one rising edge. Reset clears CPU/control state and registers, aborts incomplete AXI transactions, and clears response VALID. SRAM contents and its read-data register are not reset. A write already committed before reset is retained.

Top parameters: `IMEM_DEPTH=1024`, `SRAM_DEPTH=1024`, `RESET_PC=0`, `SRAM_BASE=32'h10000000`, `INIT_FILE="programs/integration.hex"`, `DEBUG=0`. Depths count words and must be positive; base addresses must be word-aligned and regions must fit the 32-bit address space. Non-power-of-two data depths are supported and tested. ISA and bus widths are intentionally fixed, not misleadingly parameterized as RV64-compatible.

Instruction memory pre-fills NOPs and loads `INIT_FILE` with `$readmemh`. Data words must be initialized before reads. Invalid AXI addresses return SLVERR without SRAM access. Illegal instructions, misalignment, fetch bounds violations and bus errors latch `debug_fault`; the CPU holds its PC until reset. No architectural exception/trap machinery is implemented.

## Simulation

Tested locally with **ModelSim Intel FPGA Starter Edition 2020.1**. Run commands from `riscv_axi_soc` unless stated otherwise. Put the simulator executables on PATH, or set `MODELSIM_BIN` for the PowerShell launcher.

```powershell
# Entire portable regression: 21 runs, including three random seeds.
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_regression.ps1

# One test, compiling the complete ordered source list.
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ./scripts/run_stage.ps1 -Top soc_integration_test -Sources '-f','scripts/filelist.f' -SimArgs '+WAVES'"

# Regenerate the committed programs; requires Node.js, no npm packages.
node scripts/generate_programs.js
```

Questa, with a verification license:

```text
vsim -c -do scripts/run_questa.do
vsim -c -do "set TOP tb_top; do scripts/run_questa.do"
vsim -c -do "set TOP cpu_isa_test; do scripts/run_questa.do"
vcover report -details -cvg logs/tb_top.ucdb
```

`run_questa.do` enables `FULL_SV` and saves UCDB on exit. On Windows, `scripts/run_regression.ps1 -FullSV` exercises the full regression with a compatible simulator on PATH; use the Questa `.do` launcher when collecting UCDB databases.

Xcelium, with a verification license:

```bash
bash scripts/run_xrun.sh
```

`FULL_SV` enables SVA, covergroups/crosses and constrained randomization. The available Starter license compiles these sources but refuses to elaborate covergroups/randomization; it does not execute concurrent assertions. The portable path still uses classes, inheritance, virtual interfaces, mailboxes, seeded pseudorandom stimulus, procedural assertions, a memory scoreboard and explicit coverage counters. **Portable counters are not a UCDB/code-coverage report.** Full Questa/Xcelium execution remains unverified here; see [results](docs/RESULTS.md).

Icarus and Verilator were not available. Icarus generally cannot run this interface/class environment. No claim of complete Icarus or Verilator compatibility is made; use a simulator supporting the supplied SV interfaces/classes, or port a reduced harness. The RTL-only list is `scripts/rtl.f`; it must be invoked from the project root because it uses relative paths.

## Verification and expected output

Verification proceeds from ALU/register/decode/control unit tests through a standalone core, SRAM, slave/SRAM, master/slave/SRAM, SoC, layered AXI environment and full instruction reference model. [Verification plan](docs/VERIFICATION_PLAN.md) and [test plan](docs/TEST_PLAN.md) map features to checks.

Expected integration result:

```text
PASS SOC integration x3=30 SRAM[0x10000000]=30 x5=30 writes=1 reads=1 wait_cycles=9
```

The reference model checks each retired instruction's PC, register write enable, destination and result, then all final registers and initialized SRAM words. The complete ISA program reaches all 31 instruction bins and all 12 branch outcomes. AXI scoreboards compare actual monitored read data against independent byte-enabled reference storage. Protocol checks cover stalled VALID/payload stability, unsolicited responses and bounded completion. The 256-cycle completion bound is a verification environment assumption, not an AXI protocol timing requirement.

`DEBUG=1` prints cycle, PC, instruction, source operands, destination, ALU, writeback, memory request, master state, AXI handshakes/responses and SRAM activity. `+WAVES` on integration/OOP tests emits VCD under `logs/`. The integration test always enables the readable trace.

## Limitations and Version 2 candidates

No pipeline, interconnect, peripherals, MMU, cache, DMA, OS support or interrupts are included. SRAM is inferred synchronous RTL storage, not a transistor-level macro; synthesis, FPGA timing closure and hardware implementation have not been run. Instruction memory initialization/inference depends on the target tool. There is one CPU memory request in flight; the slave can buffer a read separately from a write but deliberately provides modest throughput. There is no hardware timeout if an external response never arrives.

Possible later work, only after an explicit scope change: additional byte/halfword CPU instructions, a larger ISA compliance suite, formal protocol proofs, synthesis/resource/timing reports and target-specific RAM inference validation. Licensed covergroup/SVA regression and additional seeds can also extend verification without changing the architecture.
