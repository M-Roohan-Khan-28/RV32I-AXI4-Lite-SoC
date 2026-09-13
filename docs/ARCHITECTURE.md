# Architecture

Design and Verification of a Single-Cycle RV32I RISC-V SoC with AXI4-Lite SRAM Memory Interface

The core has one combinational fetch/decode/execute/writeback datapath, with no pipeline registers or hazards. Arithmetic, branches and jumps retire in one clock cycle. LW and SW hold the PC and suppress register writes until the memory response arrives. Thus this is a single-cycle/non-pipelined datapath with multi-cycle memory instructions, not a one-clock-per-instruction AXI machine.

Instruction path: PC -> direct combinational instruction memory -> core.

Data path: core/load-store unit -> request/completion interface -> AXI4-Lite master -> AXI4-Lite slave -> synchronous SRAM.

The master accepts one request while idle, independently tracks AW and W completion, and reports completion once B or R has handshaken. A completion state prevents the still-asserted CPU request from being accepted twice. The slave buffers AW and W independently. Its single SRAM port arbitrates completed writes ahead of reads; read data is captured after the synchronous SRAM read edge. B and R responses persist until consumed.

All sequential control uses synchronous active-low reset, named reset_n. SRAM contents are not reset; software/tests initialize words before reading. Register file reset clears all registers. Instruction memory fills unused words with ADDI x0,x0,0 and optionally loads INIT_FILE.

Instruction memory begins at RESET_PC (default zero), with 1024 words. Data SRAM begins at 0x10000000, with 1024 words. Both depths are parameters. XLEN and bus widths are fixed at 32 to implement RV32I; WSTRB has four byte lanes.

Unsupported instructions, misaligned control-flow targets, bad fetches, misaligned data accesses and bus errors halt the core with debug_fault asserted. There are no architectural traps, CSRs or interrupts. Misaligned/out-of-range AXI addresses receive SLVERR and never touch SRAM. JALR clears target bit zero, then enforces four-byte alignment.

Hierarchy: riscv_soc_top contains riscv_core (pc, register_file, instruction_decoder, immediate_generator, control_unit, alu, branch_unit, load_store_unit), instruction_memory, axi_lite_master, axi_lite_slave, sram and the internal axi_lite_if. The interface resides under tb as requested but is also compiled for RTL.

## CPU request/completion contract

| Signal | Producer | Meaning |
|---|---|---|
| req_valid | LSU | A load/store is currently pending; remains high through its completion cycle |
| req_write | LSU | 1 for SW, 0 for LW |
| req_addr | LSU | Byte address, held with the current instruction |
| req_wdata / req_wstrb | LSU | Store register value / four enabled bytes |
| req_ready | Master | Master is idle and can capture a request on the next rising edge |
| response_valid | Master | One-cycle completion indication, distinct from request acceptance |
| response_data | Master | Captured read response data |
| response_error | Master | Captured non-OKAY status |

The CPU holds its entire memory instruction in place, so it does not need a separate request-accepted register. The master latches a request only in IDLE. At a B/R handshake it enters DONE, asserting response_valid. At the following edge the CPU retires the instruction and the master returns to IDLE without accepting the old request. A subsequent memory instruction may present a new request immediately after that edge. An external requester using this master must likewise remove or replace its request at completion.

All ordinary instructions retire when reset is released and no fault is present. Memory instructions additionally require response_valid. Register writeback and PC update use the same retirement enable, so a stalled load cannot corrupt its destination and a store cannot execute its successor early. The instruction memory and register file are combinational read sources; there are no hidden fetch/execute pipeline registers.

## SRAM timing and arbitration

The SRAM reads at the rising edge when en is high and presents registered data after that edge. Writes are byte-enabled at the same edge and use read-first semantics if the port reads and writes the same word. When en is low, rdata holds. The slave issues a legal read, waits one capture cycle, then presents RDATA/RVALID. A write updates SRAM at the write-issue edge and creates BVALID after that edge. Read data and response registers remain independent of later SRAM activity.

Both read and write channels have bounded buffering. A complete write has SRAM-port priority over a queued read. After write issue, BVALID prevents another write from occupying the port until response acceptance; the queued read can proceed. No speculative accesses or duplicate SRAM operations occur while B/R responses are stalled.
