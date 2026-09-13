`timescale 1ns/1ps
module axi_slave_test;
  bit clk=0,reset_n=0;
  always #5 clk=~clk;
  axi_lite_if bus(clk,reset_n);
  logic en,we;
  logic [9:0] addr;
  logic [31:0] wd,rd;
  logic [3:0] strb;
  int checks=0;
  axi_lite_slave slave(bus,en,we,addr,wd,strb,rd);
  sram ram(clk,reset_n,en,we,addr,wd,strb,rd);
  axi_protocol_checker protocol(bus);
  task automatic aw(input logic [31:0] a,input int delay_cycles);
    repeat(delay_cycles) @(negedge clk);
    bus.awaddr=a; bus.awvalid=1;
    do @(posedge clk); while(!bus.awready);
    @(negedge clk); bus.awvalid=0;
  endtask
  task automatic w(input logic [31:0] d,input logic [3:0] s,input int delay_cycles);
    repeat(delay_cycles) @(negedge clk);
    bus.wdata=d; bus.wstrb=s; bus.wvalid=1;
    do @(posedge clk); while(!bus.wready);
    @(negedge clk); bus.wvalid=0;
  endtask
  task automatic write_word(input logic [31:0] a,d,input logic [3:0] s,input int ad,dd,input bit error=0);
    @(negedge clk);
    fork aw(a,ad); w(d,s,dd); join
    wait(bus.bvalid); repeat(3) @(negedge clk);
    assert(bus.bvalid && bus.bresp== (error ? 2'b10 : 2'b00)) else $fatal(1,"write response");
    bus.bready=1; @(negedge clk); bus.bready=0; checks++;
  endtask
  task automatic read_word(input logic [31:0] a,expected,input bit error=0);
    @(negedge clk); bus.araddr=a; bus.arvalid=1;
    do @(posedge clk); while(!bus.arready);
    @(negedge clk); bus.arvalid=0;
    wait(bus.rvalid); repeat(4) @(negedge clk);
    assert(bus.rvalid && bus.rresp==(error ? 2'b10 : 2'b00) && bus.rdata===expected)
      else $fatal(1,"read addr=%h got=%h exp=%h resp=%b",a,bus.rdata,expected,bus.rresp);
    bus.rready=1; @(negedge clk); bus.rready=0; checks++;
  endtask
  initial begin
    bus.awvalid=0; bus.wvalid=0; bus.arvalid=0; bus.bready=0; bus.rready=0;
    bus.awaddr=0; bus.wdata=0; bus.wstrb=0; bus.araddr=0; bus.awprot=0; bus.arprot=0;
    repeat(3) @(negedge clk); reset_n=1;
    write_word('h10000000,'h12345678,15,0,5); read_word('h10000000,'h12345678);
    write_word('h10000ffc,'haabbccdd,15,5,0); read_word('h10000ffc,'haabbccdd);
    for(int s=0;s<16;s++) begin
      logic [31:0] expected;
      expected=32'h12345678;
      write_word('h10000800,expected,15,0,0);
      for(int b=0;b<4;b++) if(s & (1<<b)) expected[b*8+:8]=8'(32'haabbccdd>>(b*8));
      write_word('h10000800,'haabbccdd,4'(s),s%3,(s+1)%3);
      read_word('h10000800,expected);
    end
    write_word('h10001000,0,15,0,2,1); read_word('h10001000,0,1);
    write_word('h10000001,0,15,2,0,1); read_word('h10000001,0,1);
    read_word('h10000000,'h12345678); read_word('h10000ffc,'haabbccdd);
    $display("PASS AXI slave checks=%0d AW-first W-first simultaneous, response stalls, WSTRB, errors",checks); $finish;
  end
  initial begin #100000; $fatal(1,"AXI slave timeout"); end
endmodule
