`timescale 1ns/1ps
module delayed_core_test;
  import cpu_tb_pkg::*;
  bit clk=0,reset_n=0;
  always #5 clk=~clk;
  logic [31:0] pc,ins,addr,wd,load,wb,sw,sr;
  logic ff,valid,wr,ready,done,error,fault,retire,we,en,swe;
  logic [3:0] strb,ss;
  logic [4:0] rd;
  logic [9:0] sa;
  bit waiting=0;
  logic [31:0] held_pc,held_addr,held_data;
  int waits=0;
  cpu_reference model;
  axi_lite_if m(clk,reset_n),s(clk,reset_n);
  instruction_memory #(.INIT_FILE("programs/isa.hex")) im(pc,ins,ff);
  riscv_core core(clk,reset_n,ins,ff,pc,valid,wr,addr,wd,strb,done,error,load,fault,retire,we,rd,wb);
  axi_lite_master master(clk,reset_n,valid,wr,addr,wd,strb,ready,done,error,load,m);
  axi_delay #(.AW_DELAY(3),.W_DELAY(8),.B_DELAY(9),.AR_DELAY(5),.R_DELAY(11)) delays(m,s);
  axi_lite_slave slave(s,en,swe,sa,sw,ss,sr);
  sram ram(clk,reset_n,en,swe,sa,sw,ss,sr);
  axi_protocol_checker cm(m),cs(s);
  initial begin model=new;repeat(4) @(negedge clk);reset_n=1;end
  always @(posedge clk) if(reset_n) begin
    assert(!fault) else $fatal(1,"delayed core fault");
    if(waiting) assert(pc===held_pc && addr===held_addr && wd===held_data) else $fatal(1,"CPU request changed while waiting");
    waiting=valid && !done;held_pc=pc;held_addr=addr;held_data=wd;
    if(waiting) begin
      waits++;
      assert(!we && !retire) else $fatal(1,"premature delayed retirement");
    end
    if(retire) begin
      model.step(pc,ins,we,rd,wb);
      if(ins==32'h0000006f) begin
        @(negedge clk);
        for(int k=0;k<32;k++) assert(core.rf.regs[k]===model.regs[k]) else $fatal(1,"delayed RF");
        for(int k=0;k<1024;k++) if(model.initialized[k]) assert(ram.mem[k]===model.memory[k]) else $fatal(1,"delayed SRAM");
        assert(cm.writes==4 && cm.reads==5 && waits>100) else $fatal(1,"delayed counts");
        $display("PASS delayed core full ISA retired=%0d waits=%0d writes=%0d reads=%0d",model.retired,waits,cm.writes,cm.reads);$finish;
      end
    end
  end
  initial begin #100000; $fatal(1,"delayed core timeout");end
endmodule
