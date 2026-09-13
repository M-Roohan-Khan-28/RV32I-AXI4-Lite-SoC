module register_file (
  input logic clk, reset_n,
  input logic [4:0] rs1_addr, rs2_addr, rd_addr,
  input logic [31:0] rd_data,
  input logic rd_write_enable,
  output logic [31:0] rs1_data, rs2_data
);
  logic [31:0] regs [0:31];
  assign rs1_data = rs1_addr == 0 ? 32'b0 : regs[rs1_addr];
  assign rs2_data = rs2_addr == 0 ? 32'b0 : regs[rs2_addr];
  always_ff @(posedge clk) begin
    if (!reset_n) begin
      for (int i=0; i<32; i++) regs[i] <= 0;
    end else if (rd_write_enable && rd_addr != 0) regs[rd_addr] <= rd_data;
  end
`ifdef FULL_SV
  assert property (@(posedge clk) disable iff (!reset_n) regs[0] == 0);
`endif
endmodule
