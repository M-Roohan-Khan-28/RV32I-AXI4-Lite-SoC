`timescale 1ns/1ps
module register_file_test;
  bit clk=0, reset_n=0;
  always #5 clk=~clk;
  logic [4:0] r1=0,r2=0,rd=0;
  logic [31:0] data=0,a,b;
  bit we=0;
  register_file dut(clk,reset_n,r1,r2,rd,data,we,a,b);
  initial begin
    repeat(2) @(negedge clk); reset_n=1;
    for (int i=0;i<32;i++) begin
      rd=5'(i); data=32'h12340000+32'(i); we=1;
      @(negedge clk); r1=5'(i); r2=5'(i); #1;
      assert(a===(i==0 ? 0 : data) && b===a) else $fatal(1,"RF x%0d",i);
    end
    we=0; rd=1; data=0; @(negedge clk); r1=1; #1;
    assert(a===32'h12340001) else $fatal(1,"RF disabled write");
    reset_n=0; @(negedge clk); #1;
    assert(a===0) else $fatal(1,"RF reset");
    $display("PASS register_file 32 registers, x0, write inhibit, reset"); $finish;
  end
endmodule
