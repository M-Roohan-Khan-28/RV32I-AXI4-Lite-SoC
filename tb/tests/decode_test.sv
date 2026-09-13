`timescale 1ns/1ps
module decode_test;
  import rv32_pkg::*;
  logic [31:0] ins,imm;
  imm_t kind;
  logic [6:0] op,f7;
  logic [4:0] rd,r1,r2;
  logic [2:0] f3;
  immediate_generator ig(ins,kind,imm);
  instruction_decoder dec(ins,op,rd,r1,r2,f3,f7);
  task automatic ck(input imm_t k,input logic [31:0] i,e);
    kind=k; ins=i; #1; assert(imm===e) else $fatal(1,"immediate kind=%d got=%h expected=%h",k,imm,e);
  endtask
  initial begin
    ck(IMM_I,32'h7ff00000,2047); ck(IMM_I,32'h80000000,32'hfffff800);
    ck(IMM_S,32'h7e000f80,2047); ck(IMM_S,32'h80000000,32'hfffff800);
    ck(IMM_B,32'h7e000f80,4094); ck(IMM_B,32'h80000000,32'hfffff000);
    ck(IMM_J,32'h7ffff000,1048574); ck(IMM_J,32'h80000000,32'hfff00000);
    ck(IMM_U,32'habcdefff,32'habcde000);
    ins={7'h20,5'd17,5'd9,3'd5,5'd3,7'h33}; #1;
    assert(op==7'h33 && rd==3 && r1==9 && r2==17 && f3==5 && f7==7'h20) else $fatal(1,"decoder");
    $display("PASS immediate_generator positive/negative I S B U J and decoder"); $finish;
  end
endmodule
