`timescale 1ns/1ps
module unit_test;
  import rv32_pkg::*;
  logic [31:0] a,b,y;
  alu_op_t op;
  int checks=0;
  alu dut(a,b,op,y);
  task automatic check(input alu_op_t operation, input logic [31:0] x,z,expected);
    op=operation; a=x; b=z; #1;
    assert(y===expected) else $fatal(1,"ALU op=%0d a=%h b=%h got=%h expected=%h",op,a,b,y,expected);
    checks++;
  endtask
  initial begin
    check(ALU_ADD,32'hffffffff,1,0);
    check(ALU_SUB,0,1,32'hffffffff);
    check(ALU_AND,32'ha5,32'h0f,5);
    check(ALU_OR,32'ha0,15,32'haf);
    check(ALU_XOR,32'haa,32'hff,32'h55);
    check(ALU_SLT,32'h80000000,1,1);
    check(ALU_SLTU,32'h80000000,1,0);
    check(ALU_SLL,1,33,2);
    check(ALU_SRL,32'h80000000,31,1);
    check(ALU_SRA,32'h80000000,31,32'hffffffff);
    $display("PASS ALU checks=%0d",checks); $finish;
  end
endmodule
