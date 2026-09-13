module pc #(parameter logic [31:0] RESET_PC=0)(
  input logic clk, reset_n, enable,
  input logic [31:0] next_pc,
  output logic [31:0] current_pc
);
  always_ff @(posedge clk)
    if(!reset_n) current_pc<=RESET_PC;
    else if(enable) current_pc<=next_pc;
endmodule
