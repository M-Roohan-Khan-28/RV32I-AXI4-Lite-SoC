`timescale 1ns/1ps
module cpu_test;
  bit clk=0,reset_n=0;
  always #5 clk=~clk;
  logic [31:0] ins,pc,addr,wd,wb;
  logic ff,valid,wr,fault,retire,we;
  logic [3:0] strb;
  logic [4:0] rd;
  instruction_memory im(pc,ins,ff);
  riscv_core core(clk,reset_n,ins,ff,pc,valid,wr,addr,wd,strb,1'b0,1'b0,32'b0,fault,retire,we,rd,wb);
  initial begin
    #1;
    im.imem[0]=32'h00a00093; // x1=10
    im.imem[1]=32'h01400113; // x2=20
    im.imem[2]=32'h002081b3; // x3=30
    im.imem[3]=32'h40118233; // x4=20
    im.imem[4]=32'h00220463; // beq x4,x2,+8
    im.imem[5]=32'hfff00193; // must skip
    im.imem[6]=32'h008002ef; // jal x5,+8, link=28
    im.imem[7]=32'hfff00193; // must skip
    im.imem[8]=32'h0000006f; // terminal loop
    repeat(3) @(negedge clk); reset_n=1;
    repeat(12) @(negedge clk);
    assert(!fault && pc==32 && core.rf.regs[3]===30 && core.rf.regs[4]===20 && core.rf.regs[5]===28)
      else $fatal(1,"CPU arithmetic/branch/jump failed pc=%h",pc);
    $display("PASS CPU without AXI arithmetic, taken branch and JAL"); $finish;
  end
  initial begin #10000; $fatal(1,"CPU timeout"); end
endmodule
