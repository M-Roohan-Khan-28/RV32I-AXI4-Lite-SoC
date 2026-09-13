# Memory map

| Space | Default byte range | Capacity | Access |
|---|---|---|---|
| Instruction memory | `0x00000000`–`0x00000FFF` | 1024 x 32-bit = 4096 bytes | Direct combinational fetch |
| Data SRAM | `0x10000000`–`0x10000FFF` | 1024 x 32-bit = 4096 bytes | AXI4-Lite via master/slave |

These are separate instruction and data paths, not two slaves in an interconnect. A CPU data load from address zero is invalid even though instructions are stored there. There is exactly one master and one slave.

CPU addresses are byte addresses. A data word index is `(address - SRAM_BASE) >> 2`. The slave validates alignment and the full address range **before** truncating the index to `$clog2(SRAM_DEPTH)` bits. This prevents high addresses aliasing valid words and supports non-power-of-two depths.

The last legal default word address is `0x10000FFC`. `0x10001000`, addresses below the base, and word-misaligned addresses receive `SLVERR = 2'b10`; no SRAM enable is asserted. Valid accesses receive `OKAY = 2'b00`. Invalid reads return zero with SLVERR. The CPU suppresses its own misaligned requests before they reach AXI and halts on a response error.

Little-endian byte lanes: WSTRB[0] controls bits 7:0, [1] controls 15:8, [2] controls 23:16, [3] controls 31:24. Zero WSTRB is a legal no-op store with an OKAY response. CPU SW always uses `4'b1111`; CPU LW consumes the entire word.

SRAM contents are undefined at power-up and are retained through reset. Tests initialize each word before comparing it. Instruction memory defaults to NOP (`00000013`) outside the loaded program but within its configured region; an out-of-region fetch faults. HEX files contain one 32-bit instruction per line in word order, with no byte reversal.

`RESET_PC` sets both the initial PC and instruction-memory base. `IMEM_DEPTH` and `SRAM_DEPTH` are word counts. `SRAM_BASE` relocates data SRAM; software and reference models must be adjusted to match. The generic bus RTL supports these parameters; the main supplied software/OOP tests intentionally target the default map. `axi_reset_test` additionally verifies SRAM depth 3.
