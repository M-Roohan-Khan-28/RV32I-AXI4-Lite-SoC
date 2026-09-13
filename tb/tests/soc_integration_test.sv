`timescale 1ns/1ps
module soc_integration_test;
  bit clk=0,reset_n=0;
  always #5 clk=~clk;
  logic [31:0] pc,ins,wb,ma;
  logic fault,retire,we,mw;
  logic [4:0] rd;
  int waits=0;
  logic [31:0] last_pc;
  bit was_waiting=0;
  riscv_soc_top #(.DEBUG(1)) dut(clk,reset_n,pc,ins,fault,retire,we,rd,wb,ma,mw);
  axi_protocol_checker protocol(dut.axi);
  always @(posedge clk) if(reset_n) begin
    assert(!fault) else $fatal(1,"SoC fault pc=%h",pc);
    if(was_waiting) assert(pc===last_pc) else $fatal(1,"PC changed during wait");
    was_waiting=dut.req_valid && !dut.response_valid;
    last_pc=pc;
    if(was_waiting) begin
      waits++;
      assert(!we && !retire) else $fatal(1,"premature memory retirement");
    end
  end
  initial begin
    if($test$plusargs("WAVES")) begin $dumpfile("logs/integration.vcd"); $dumpvars(0,soc_integration_test); end
    repeat(4) @(negedge clk); reset_n=1;
    wait(pc==24); @(negedge clk);
    assert(dut.core.rf.regs[3]===30 && dut.core.rf.regs[5]===30 && dut.data_sram.mem[0]===30)
      else $fatal(1,"integration expected x3=30 SRAM[0]=30 x5=30");
    assert(protocol.writes==1 && protocol.reads==1 && waits>0) else $fatal(1,"integration traffic/wait counts");
    $display("PASS SOC integration x3=30 SRAM[0x10000000]=30 x5=30 writes=1 reads=1 wait_cycles=%0d",waits); $finish;
  end
  initial begin #10000; $fatal(1,"integration timeout"); end
endmodule
