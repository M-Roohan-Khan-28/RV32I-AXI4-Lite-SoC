`timescale 1ns/1ps
module tb_top;
  import tb_pkg::*;
  bit clk=0,reset_n=0;
  always #5 clk=~clk;
  axi_lite_if bus(clk,reset_n),slave_bus(clk,reset_n);
  logic en,we;
  logic [9:0] addr;
  logic [31:0] wd,rd;
  logic [3:0] strb;
  axi_delay #(.AW_DELAY(2),.W_DELAY(2),.B_DELAY(3),.AR_DELAY(2),.R_DELAY(3)) delay_model(bus,slave_bus);
  axi_lite_slave dut(slave_bus,en,we,addr,wd,strb,rd);
  sram ram(clk,reset_n,en,we,addr,wd,strb,rd);
  axi_protocol_checker upstream_check(bus),downstream_check(slave_bus);
  axi_test test;
  initial begin
    test=new(bus);test.env.drv.initialize();
    if($test$plusargs("WAVES")) begin $dumpfile("logs/axi_oop.vcd");$dumpvars(0,tb_top); end
    repeat(4) @(negedge clk);reset_n=1;
    test.run();$finish;
  end
  initial begin #2000000; $fatal(1,"OOP test timeout"); end
endmodule
