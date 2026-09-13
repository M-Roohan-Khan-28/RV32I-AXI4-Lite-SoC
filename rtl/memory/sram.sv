module sram #(
  parameter int DEPTH=1024,
  parameter int ADDR_BITS=(DEPTH>1 ? $clog2(DEPTH) : 1)
)(
  input logic clk, reset_n, en, we,
  input logic [ADDR_BITS-1:0] addr,
  input logic [31:0] wdata,
  input logic [3:0] wstrb,
  output logic [31:0] rdata
);
  // No array reset, preserving inference of synchronous RAM. Read-first semantics.
  logic [31:0] mem[0:DEPTH-1];
  always_ff @(posedge clk) begin
    if(reset_n && en && int'(addr)<DEPTH) begin
      rdata<=mem[addr];
      if(we) for(int lane=0;lane<4;lane++)
        if(wstrb[lane]) mem[addr][lane*8+:8]<=wdata[lane*8+:8];
    end
  end
endmodule
