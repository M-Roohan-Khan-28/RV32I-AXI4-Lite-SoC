# Verification plan

| Feature | Test | Expected behavior | Method | Coverage goal |
|---|---|---|---|---|
| ALU | unit_test | Correct wraparound, signed compare, logic and masked shifts | Directed independent constants | All ten operations |
| Register file | register_file_test | Async reads, synchronous writes, ignored x0 writes, reset | Check all registers, disabled write and reset | x0–x31 |
| Immediate/decoder | decode_test | Correct fields and sign extension | Boundary vectors for I/S/B/U/J | Positive/negative signed formats; U pattern |
| Control/branch | control_test | Legal decode, reserved encoding rejection, signed/unsigned conditions | Direct control checks and comparison matrix | All six branch functions |
| Core without AXI | cpu_test | Arithmetic in one datapath, branches/jumps change PC | Short program with expected registers | ADD ADDI SUB BEQ JAL |
| CPU instruction behavior | cpu_isa_test | Correct retirement PC, destination, value and write enable | Independent architectural class model | All 31 requested instruction IDs |
| Branch outcomes | cpu_isa_test | Both taken/untaken; negative displacement loops | Model next-PC checking | 6 x 2 = 12 outcomes |
| CPU memory wait | delayed_core_test | Stable PC/request; no early writeback/retirement | Full program through independently delayed channels | Reads/writes; 100+ wait cycles |
| Fault suppression | fault_test | Halt with no invalid register write; errors propagated | Ten directed illegal/alignment/bounds cases | All defined error classes |
| SRAM | sram_test | Synchronous reads; byte-lane write enables | Write/read expected constants | First/middle/last, all 16 strobes, reset retention |
| Slave independence | axi_slave_test | AW/W can arrive either way; stable B/R | Directed bus tasks and protocol checker | AW first, W first, together |
| Master sequencing | axi_master_test | Independent channel completion, correct errors and no duplicate | Master + delay gates + slave + SRAM | All five delayed channels; three AW/W orders |
| AXI reset/arbitration | axi_reset_test | Aborted partial requests do not leak; completed SRAM writes persist | Reset with AW-only, W-only, stalled B/R; concurrent read/write | Four reset phases, single-port priority, depth 3 |
| OOP memory data | tb_top / axi_test | Observed reads match byte-enabled reference storage | Passive monitor -> mailbox -> scoreboard | 1586 checks/seed, zero failures |
| AXI traffic coverage | tb_top | Legal transactions exercise categories | Explicit counters and optional covergroup | R/W, 4 regions, 16 strobes, 3 orders, RAW/repeated, 5 stall channels |
| Protocol safety | AXI tests/integration | VALID and payload stable under backpressure; no orphan B/R | Procedural assertions + optional SVA | AW/W/AR/B/R checks active |
| Protocol progress | AXI tests/integration | Accepted complete requests finish | 256-cycle bounded checker + optional SVA | Reads and writes; known bounded environment |
| End-to-end SoC | soc_integration_test | x3=30, memory=30, x5=30 | Program, state checks and exact bus counts | Fetch/decode/ALU/store/read/writeback |

## Layered environment

`base_test` defines the common test contract; `axi_test` extends it and runs `environment`. The generator uses a typed mailbox to send transaction objects. The driver converts them to pin activity using a virtual interface and independent AW/W tasks. The monitor samples handshakes at rising edges and reconstructs transactions only after response completion. Separate mailboxes deliver immutable completed observations to scoreboard and coverage. Stimulus changes on falling edges, avoiding sampling races with clocked RTL.

The reference memory is independent of the DUT; initialization comes from observed writes. A four-bit known-byte mask prevents silently comparing uninitialized words. Monitored read data remains four-state logic, so X values are not converted to zero. The driver never tells the scoreboard what a read should return.

The OOP driver issues sequential transactions. Concurrent read/write arbitration and reset during transactions are covered separately by `axi_reset_test`. This keeps the educational class monitor simple and consistent with the one-request CPU master.

The CPU reference model decodes raw instructions independently and implements architectural arithmetic/PC/memory effects without using the RTL control, ALU or immediate functions. Generated programs include negative immediates, masked shifts, rd/rs dependencies, x0 writes and loads, loop branches, JAL/JALR links and SRAM boundary operations.

## Coverage interpretation

Portable coverage counters report bins actually observed, not an estimated simulator coverage percentage. Required counters are checked before tests may PASS. Instruction IDs 0–9 are R-type ALU operations in README order; IDs 10–18 are immediate operations, 19/20 are LW/SW, 21–26 are branches, 27/28 are JAL/JALR and 29/30 are LUI/AUIPC. `7fffffff` means all 31 instructions; branch mask `fff` means all 12 outcomes.

`FULL_SV` additionally provides functional covergroups with instruction/branch crosses and AXI operation/region crosses. Detailed covergroup bins include zero and nonzero channel stalls; the delayed OOP harness alone does not guarantee every optional zero-delay bin. Full covergroup closure must be measured with a licensed simulator, not inferred from the portable mask. No statement/branch/toggle code-coverage goal has been claimed as achieved.

SVA `disable iff` disables checking during reset. The completion bound assumes the peer eventually supplies both write channels and accepts responses; AXI itself has no maximum response latency. A write liveness obligation begins after both AW and W are accepted. Read liveness begins after AR acceptance. Testbench timeout remains the final guard against an incomplete channel that never handshakes.

## Acceptance

All required portable directed, ISA and integration tests must compile, elaborate and PASS with no scoreboard/procedural assertion failures. Full feature sources must compile. Runtime covergroup/constrained-random/SVA execution is a separate acceptance item requiring a supported simulator license; its local status is explicitly recorded in RESULTS.md. Hardware timing, synthesis and ISA compliance certification are outside this simulation deliverable.
