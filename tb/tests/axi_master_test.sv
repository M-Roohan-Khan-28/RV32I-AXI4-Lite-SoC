`timescale 1ns/1ps
module axi_master_test;
  parameter int AD=7,WD=2;
  bit clk=0,reset_n=0,valid=0,wr=0;
  always #5 clk=~clk;
  logic [31:0] addr=0,wd=0,data;
  logic [3:0] strb=15;
  logic ready,done,error,en,we;
  logic [9:0] sa;
  logic [31:0] sw,sr;
  logic [3:0] ss;
  axi_lite_if m(clk,reset_n),s(clk,reset_n);
  axi_lite_master master(clk,reset_n,valid,wr,addr,wd,strb,ready,done,error,data,m);
  axi_delay #(.AW_DELAY(AD),.W_DELAY(WD),.B_DELAY(5),.AR_DELAY(4),.R_DELAY(6)) delays(m,s);
  axi_lite_slave slave(s,en,we,sa,sw,ss,sr);
  sram ram(clk,reset_n,en,we,sa,sw,ss,sr);
  axi_protocol_checker cm(m),cs(s);
  task automatic access(input bit write_op,input logic [31:0] a,d,input bit expected_error=0);
    @(negedge clk); valid=1;wr=write_op;addr=a;wd=d;
    do @(negedge clk); while(!done);
    assert(error===expected_error) else $fatal(1,"master error propagation");
    if(!write_op && !expected_error) assert(data===d) else $fatal(1,"master read mismatch");
    // Hold req_valid through completion just as the CPU does.
    @(negedge clk); valid=0;
    repeat(2) @(negedge clk);
  endtask
  initial begin
    repeat(3) @(negedge clk); reset_n=1;
    for(int i=0;i<12;i++) begin
      access(1,32'h10000000+4*32'(i),32'habcdef00+32'(i));
      access(0,32'h10000000+4*32'(i),32'habcdef00+32'(i));
    end
    access(1,32'h10001000,0,1);access(0,32'h10001000,0,1);
    assert(cm.writes==13 && cm.reads==13 && cs.writes==13 && cs.reads==13)
      else $fatal(1,"duplicate/missing AXI transaction");
    $display("PASS AXI master/slave SRAM 26 transactions with all five channel delays and errors"); $finish;
  end
  initial begin #100000; $fatal(1,"master timeout"); end
endmodule
