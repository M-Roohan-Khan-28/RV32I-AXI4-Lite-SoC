`timescale 1ns/1ps
module sram_test;
  bit clk=0,reset_n=0,en=0,we=0;
  always #5 clk=~clk;
  logic [9:0] addr;
  logic [31:0] wd,rd;
  logic [3:0] strb;
  int checks=0;
  sram dut(clk,reset_n,en,we,addr,wd,strb,rd);
  task automatic write_word(input int a,input logic [31:0] d,input logic [3:0] s);
    @(negedge clk); en=1; we=1; addr=10'(a); wd=d; strb=s;
    @(negedge clk); en=0; we=0;
  endtask
  task automatic read_word(input int a,input logic [31:0] expected);
    @(negedge clk); en=1; we=0; addr=10'(a);
    @(negedge clk); en=0;
    assert(rd===expected) else $fatal(1,"SRAM addr=%0d got=%h expected=%h",a,rd,expected);
    checks++;
  endtask
  initial begin
    repeat(2) @(negedge clk); reset_n=1;
    write_word(0,32'h12345678,15); read_word(0,32'h12345678);
    write_word(512,32'haabbccdd,15); read_word(512,32'haabbccdd);
    write_word(1023,32'hffffffff,15); read_word(1023,32'hffffffff);
    for(int s=0;s<16;s++) begin
      logic [31:0] expected;
      expected=32'h12345678;
      write_word(0,expected,15);
      for(int b=0;b<4;b++) if(s & (1<<b)) expected[b*8+:8]=8'(32'haabbccdd>>(b*8));
      write_word(0,32'haabbccdd,4'(s)); read_word(0,expected);
    end
    reset_n=0; write_word(1023,0,15); reset_n=1; read_word(1023,32'hffffffff);
    $display("PASS SRAM checks=%0d all 16 WSTRB patterns, boundaries, reset retention",checks); $finish;
  end
  initial begin #10000; $fatal(1,"SRAM timeout"); end
endmodule
