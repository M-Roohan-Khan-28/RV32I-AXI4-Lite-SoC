`timescale 1ns/1ps
module fault_test;
  bit clk=0,reset_n=0;
  always #5 clk=~clk;
  logic [31:0] pc,ins,wb,ma;
  logic fault,retire,we,mw;
  logic [4:0] rd;
  int cases=0;
  riscv_soc_top #(.IMEM_DEPTH(8),.INIT_FILE("")) dut(clk,reset_n,pc,ins,fault,retire,we,rd,wb,ma,mw);
  axi_protocol_checker protocol(dut.axi);
  task automatic run_case(input logic [31:0] setup,offender,input int writes_expected=0,reads_expected=0);
    @(negedge clk);reset_n=0;
    repeat(2) @(negedge clk);
    for(int k=0;k<8;k++) dut.imem.imem[k]=32'h00000013;
    dut.imem.imem[0]=setup;dut.imem.imem[1]=offender;
    reset_n=1;
    wait(fault);@(negedge clk);
    assert(pc==4 && dut.core.rf.regs[2]===0 && !we && !retire && !dut.req_valid) else $fatal(1,"fault side effect ins=%h pc=%h",offender,pc);
    repeat(4) @(negedge clk);
    assert(pc==4 && protocol.writes==writes_expected && protocol.reads==reads_expected)
      else $fatal(1,"fault bus/PC expected W=%0d R=%0d got=%0d,%0d",writes_expected,reads_expected,protocol.writes,protocol.reads);
    cases++;
  endtask
  initial begin
    #1;
    run_case(32'h00000013,32'hffffffff); // illegal opcode
    run_case(32'h00000013,32'h02000133); // MUL excluded
    run_case(32'h00000013,32'h02001113); // reserved SLLI
    run_case(32'h100000b7,32'h0010a103); // LW +1
    run_case(32'h100000b7,32'h0020a0a3); // SW +1
    run_case(32'h00000013,32'h0020016f); // JAL target bit 1
    run_case(32'h00600093,32'h00008167); // JALR target bit 1
    run_case(32'h100010b7,32'h0000a103,0,1); // out-of-range LW
    run_case(32'h100010b7,32'h0020a023,1,0); // out-of-range SW
    // Fetch outside the configured eight-word instruction region.
    @(negedge clk);reset_n=0;repeat(2) @(negedge clk);
    dut.imem.imem[0]=32'h0200006f;reset_n=1;
    wait(fault);@(negedge clk);assert(pc==32 && !retire) else $fatal(1,"fetch bounds");cases++;
    $display("PASS CPU faults cases=%0d illegal, misalignment, bus errors, fetch bounds and reset recovery",cases);$finish;
  end
  initial begin #100000; $fatal(1,"fault timeout");end
endmodule
