`timescale 1ns/1ps
module cpu_isa_test;
  import cpu_tb_pkg::*;
  parameter PROGRAM="programs/isa.hex";
  bit clk=0,reset_n=0;
  always #5 clk=~clk;
  logic [31:0] pc,ins,wb,ma;
  logic fault,retire,we,mw;
  logic [4:0] rd;
  cpu_reference model;
  riscv_soc_top #(.INIT_FILE(PROGRAM)) dut(clk,reset_n,pc,ins,fault,retire,we,rd,wb,ma,mw);
  axi_protocol_checker protocol(dut.axi);
  initial begin model=new;repeat(4) @(negedge clk);reset_n=1;end
  always @(posedge clk) if(reset_n) begin
    assert(!fault) else $fatal(1,"ISA core fault pc=%h ins=%h",pc,ins);
    if(retire) begin
      model.step(pc,ins,we,rd,wb);
      if(ins==32'h0000006f) begin
        @(negedge clk);
        for(int k=0;k<32;k++) assert(dut.core.rf.regs[k]===model.regs[k]) else $fatal(1,"final register x%0d",k);
        for(int k=0;k<1024;k++) if(model.initialized[k])
          assert(dut.data_sram.mem[k]===model.memory[k]) else $fatal(1,"final SRAM word %0d",k);
        if(PROGRAM=="programs/isa.hex") assert(model.instruction_hits==31'h7fffffff && model.branch_hits==12'hfff)
          else $fatal(1,"ISA coverage missing");
        $display("COVERAGE CPU instruction_mask=%h branch_outcomes=%h retired=%0d",model.instruction_hits,model.branch_hits,model.retired);
        $display("PASS CPU ISA program=%s register/writeback/PC/SRAM reference checks",PROGRAM);$finish;
      end
    end
  end
  initial begin #100000; $fatal(1,"ISA timeout");end
endmodule
